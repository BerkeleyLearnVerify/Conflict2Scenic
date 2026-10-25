#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for long two-lane approaches and crossing/turning movements coexisting at four-way junctions.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(5.5, 6.5)
param AGENT1_SPEED = VerifaiRange(5.5, 6.5)
param PREP_TIME = VerifaiRange(0.4, 0.7)
param EGO_APPROACH_MIN = 38
param EGO_APPROACH_MAX = 44
param AGENT1_APPROACH_MIN = 38
param AGENT1_APPROACH_MAX = 44
param EGO_BYPASS_DIST = VerifaiRange(8, 12)
param RESPONSE_DIST = VerifaiRange(65, 70)
param AGENT1_BYPASS_DIST = VerifaiRange(8, 12)

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

@distributionFunction
def adjacentSectionAt(point, side):
    section = network.laneSectionAt(point, reject="evasion point is not in a lane")
    adj = section._laneToLeft if side == 'left' else section._laneToRight
    if adj is None or adj.group is not section.group:
        raise RejectionException('evasion requires a same-direction adjacent lane')
    return adj

@distributionFunction
def remainingApproach(lane, position):
    line = lane.centerline.lineString
    return line.length - line.project(ShapelyPoint(position.x, position.y))

@distributionFunction
def crossingApproaches(firstLane, secondLane):
    first = firstLane.centerline.lineString
    second = secondLane.centerline.lineString
    if first.length < 5 or second.length < 5:
        return False
    a = first.interpolate(first.length - 5)
    b = first.interpolate(first.length - 1)
    c = second.interpolate(second.length - 5)
    d = second.interpolate(second.length - 1)
    ux, uy = b.x - a.x, b.y - a.y
    vx, vy = d.x - c.x, d.y - c.y
    norm = ((ux * ux + uy * uy) * (vx * vx + vy * vy)) ** 0.5
    return norm > 0 and abs(ux * vx + uy * vy) < 0.3 * norm

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
egoTargetLaneSection = adjacentSectionAt(egoSpawnPt, 'right')
egoTargetLane = egoTargetLaneSection.lane
egoTargetRefPt = new OrientedPoint at egoTargetLane.centerline.project(egoSpawnPt.position), facing roadDirection
egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, egoTargetLane.maneuvers))
egoTrajectory = [egoTargetLane, egoManeuver.connectingLane, egoManeuver.endLane]

agent1InitLane = Uniform(*filter(lambda m:
    m.type is ManeuverType.STRAIGHT,
    egoManeuver.conflictingManeuvers)
).startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline
agent1TargetLaneSection = adjacentSectionAt(agent1SpawnPt, 'left')
agent1TargetLane = agent1TargetLaneSection.lane
agent1TargetRefPt = new OrientedPoint at agent1TargetLane.centerline.project(agent1SpawnPt.position), facing roadDirection
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, agent1TargetLane.maneuvers))
agent1Trajectory = [agent1TargetLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]

egoRemaining = remainingApproach(egoInitLane, egoSpawnPt.position)
agent1Remaining = remainingApproach(agent1InitLane, agent1SpawnPt.position)

#################################
# AGENT BEHAVIORS               #
#################################

# Input roles: ego initiates the prior lateral evasion; agent1 responds on the crossing roadway.
# Lane change precedes intersection traversal; the driver decision has no added obstacle actor.
behavior EgoBehavior(trajectory):
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for globalParameters.PREP_TIME seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when hasSameDirectionAdjacentLane(self.laneSection, 'right') and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToRight.lane, globalParameters.EGO_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=egoTargetLaneSection, target_speed=globalParameters.EGO_SPEED)
        do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)

behavior Agent1Behavior(trajectory):
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (network.laneAt(ego) is egoTargetLane) and ((distance from self to ego) < globalParameters.RESPONSE_DIST) and (network.laneAt(self) is agent1InitLane) and hasSameDirectionAdjacentLane(self.laneSection, 'left') and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.AGENT1_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=agent1TargetLaneSection, target_speed=globalParameters.AGENT1_SPEED)
        do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior(egoTrajectory)

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior(agent1Trajectory)

#################################
# REQUIREMENTS                  #
#################################

egoApproachMin = globalParameters.EGO_APPROACH_MIN
egoApproachMax = globalParameters.EGO_APPROACH_MAX
agent1ApproachMin = globalParameters.AGENT1_APPROACH_MIN
agent1ApproachMax = globalParameters.AGENT1_APPROACH_MAX
egoSpeed = globalParameters.EGO_SPEED
agent1Speed = globalParameters.AGENT1_SPEED

require hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require egoTargetLane in intersection.incomingLanes
require agent1InitLane in intersection.incomingLanes
require crossingApproaches(egoInitLane, agent1InitLane)
require agent1Maneuver in egoManeuver.conflictingManeuvers
require egoRemaining >= egoApproachMin
require egoRemaining <= egoApproachMax
require agent1Remaining >= agent1ApproachMin
require agent1Remaining <= agent1ApproachMax
require remainingApproach(egoTargetLane, egoTargetRefPt.position) >= egoApproachMin
#require abs(egoRemaining / egoSpeed - agent1Remaining / agent1Speed) < 0.6
require hasSameDirectionAdjacentLane(agent1.laneSection, 'left')
require agent1TargetLane in intersection.incomingLanes
require remainingApproach(agent1TargetLane, agent1TargetRefPt.position) >= agent1ApproachMin
