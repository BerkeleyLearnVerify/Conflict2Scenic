#################################
# MAP AND MODEL                 #
#################################

# Selected Town04 for four-way single-lane junctions with turns and through traffic sharing an exit lane.
param map = localPath('../../../maps/Town04.xodr')
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

#################################
# AGENT BEHAVIORS               #
#################################

# Ego initiates the conflict by turning; agent1 responds on the receiving road.
behavior EgoBehavior(trajectory):
    take SetSpeedAction(globalParameters.EGO_SPEED)
    do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)

behavior Agent1Behavior(trajectory):
    take SetSpeedAction(globalParameters.AGENT1_SPEED)
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
