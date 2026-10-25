#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for four-way turns into two-lane roads with a same-direction escape lane to the left.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction

MODEL = 'vehicle.lincoln.mkz_2017'
# Speeds are m/s; distances are m; entry gaps and reaction delays are seconds.
param EGO_SPEED = VerifaiRange(4.5, 5.5)
param AGENT1_SPEED = VerifaiRange(7.5, 9)
param ENTRY_GAP = VerifaiRange(0.8, 1.8)

@distributionFunction
def remainingLaneDistance(lane, point):
    centerline = lane.centerline.lineString
    return centerline.length - centerline.project(ShapelyPoint(point.x, point.y))

param AGENT1_SAFETY_DIST = VerifaiRange(15, 20)
param AGENT1_BYPASS_DIST = VerifaiRange(12, 16)

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

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

# The straight reference identifies a lateral approach, independent of ego's turn.
egoThroughManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, egoInitLane.maneuvers))
agent1InitLane = Uniform(*filter(lambda m:
    m.type is ManeuverType.STRAIGHT,
    egoThroughManeuver.conflictingManeuvers)
).startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline

egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.RIGHT_TURN, egoInitLane.maneuvers))
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, agent1InitLane.maneuvers))
egoTrajectory = [egoInitLane, egoManeuver.connectingLane, egoManeuver.endLane]
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]
receivingLane = egoManeuver.endLane

# Nominal arrival times couple the entry to the faster through vehicle.
egoEntryTime = (remainingLaneDistance(egoInitLane, egoSpawnPt.position) + egoManeuver.connectingLane.centerline.lineString.length) / globalParameters.EGO_SPEED
agent1EntryTime = (remainingLaneDistance(agent1InitLane, agent1SpawnPt.position) + agent1Maneuver.connectingLane.centerline.lineString.length) / globalParameters.AGENT1_SPEED

receivingProbe = new OrientedPoint in receivingLane.centerline
receivingSection = network.laneSectionAt(receivingProbe, reject="receiving lane has no lane section")

#################################
# AGENT BEHAVIORS               #
#################################

# Ego initiates the conflict by turning; agent1 responds on the receiving road.
behavior EgoBehavior(trajectory):
    take SetSpeedAction(globalParameters.EGO_SPEED)
    do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)

behavior Agent1Behavior(trajectory):
    take SetSpeedAction(globalParameters.AGENT1_SPEED)
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)
    interrupt when (network.laneAt(self) is receivingLane) and (network.laneAt(ego) is receivingLane) and ((distance from self to ego) < globalParameters.AGENT1_SAFETY_DIST) and hasSameDirectionAdjacentLane(self.laneSection, 'left') and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.AGENT1_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.AGENT1_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)

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

# Sharing the actual exit lane excludes an unrelated cross-traffic crossing.
require agent1InitLane in intersection.incomingLanes
require agent1InitLane is not egoInitLane
require agent1Maneuver.endLane is receivingLane
require remainingLaneDistance(egoInitLane, egoSpawnPt.position) >= 8
require remainingLaneDistance(egoInitLane, egoSpawnPt.position) <= 14
require remainingLaneDistance(agent1InitLane, agent1SpawnPt.position) >= 12
require remainingLaneDistance(agent1InitLane, agent1SpawnPt.position) <= 45
entryGap = globalParameters.ENTRY_GAP
require agent1EntryTime >= egoEntryTime + entryGap
require agent1EntryTime <= egoEntryTime + entryGap + 0.3
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require hasSameDirectionAdjacentLane(agent1.laneSection, 'left')
require hasSameDirectionAdjacentLane(receivingSection, 'left')
require receivingLane.centerline.lineString.length >= 40
require receivingSection._laneToLeft.lane.centerline.lineString.length >= 40
