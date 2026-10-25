#################################
# MAP AND MODEL                 #
#################################

# Selected Town04 for four-way turns into straight single-lane exits, evidenced together at junction 1452.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

from scenic.core.distributions import distributionFunction, RejectionException

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(3, 4)
param EGO_INIT_DIST = VerifaiRange(6, 9)
param AGENT1_INIT_DIST = VerifaiRange(8, 11)
param AGENT1_THROTTLE = VerifaiRange(0.18, 0.25)
param AGENT1_REACTION_DIST = VerifaiRange(10, 12)
param AGENT1_BRAKE = VerifaiRange(0.8, 1.0)
param EGO_SAFETY_DIST = VerifaiRange(4, 5)
param EGO_BRAKE = VerifaiRange(0.8, 1.0)

@distributionFunction
def pointAtLaneDistance(lane, distance):
    centerline = lane.centerline.lineString
    if distance < 3 or distance > centerline.length - 3:
        raise RejectionException('insufficient lane length for spawn clearance')
    point = centerline.interpolate(distance)
    return Vector(point.x, point.y)

@distributionFunction
def isStraightLane(lane):
    points = list(lane.centerline.lineString.coords)
    start = points[0]
    end = points[-1]
    dx = end[0] - start[0]
    dy = end[1] - start[1]
    length = (dx * dx + dy * dy) ** 0.5
    if length < 30:
        return False
    # Bound lateral deviation as well as excess length to exclude bends/backtracking.
    deviation = max(abs(dx * (p[1] - start[1]) - dy * (p[0] - start[0])) / length for p in points)
    return deviation < 0.05 and lane.centerline.lineString.length - length < 0.05

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.LEFT_TURN, egoInitLane.maneuvers))
egoTrajectory = [egoInitLane, egoManeuver.connectingLane, egoManeuver.endLane]
egoSpawnPt = new OrientedPoint at pointAtLaneDistance(egoInitLane, egoInitLane.centerline.lineString.length - globalParameters.EGO_INIT_DIST), facing roadDirection

# The lateral actor approaches on the OUTGOING lane in counterflow, so legal incoming-lane placement would erase the conflict.
agent1InitLane = egoManeuver.endLane
agent1SpawnPt = new OrientedPoint at pointAtLaneDistance(agent1InitLane, globalParameters.AGENT1_INIT_DIST), facing roadDirection

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior(trajectory):
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)
    interrupt when withinDistanceToAnyObjs(self, globalParameters.EGO_SAFETY_DIST):
        while True:
            take SetBrakeAction(globalParameters.EGO_BRAKE)

# Agent1 faces with traffic but backs against its intended direction.
# Ego initiates by turning; agent1 reacts only once ego has entered that turn.
behavior Agent1Behavior():
    take SetReverseAction(True)
    while ((network.laneAt(ego) is not egoManeuver.connectingLane) and (network.laneAt(ego) is not agent1InitLane)) or ((distance from self to ego) > globalParameters.AGENT1_REACTION_DIST):
        take SetThrottleAction(globalParameters.AGENT1_THROTTLE)
    take SetThrottleAction(0)
    while True:
        take SetBrakeAction(globalParameters.AGENT1_BRAKE)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior(egoTrajectory)

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

require isStraightLane(egoInitLane)
require isStraightLane(agent1InitLane)
require not hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require not hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require not hasSameDirectionAdjacentLane(agent1.laneSection, 'left')
require not hasSameDirectionAdjacentLane(agent1.laneSection, 'right')
require (distance from ego to agent1) > 12
