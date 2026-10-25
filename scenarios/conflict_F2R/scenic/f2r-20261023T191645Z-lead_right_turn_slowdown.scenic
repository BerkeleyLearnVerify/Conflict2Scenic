#################################
# MAP AND MODEL                 #
#################################

# Selected Town04: four-approach junctions with right turns and sufficient
# common approach length; source junction 1452 provides XML evidence.
# Source XML IDs are evidence only; lane and maneuver constraints select the scene.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
HORIZON = 10
# Speeds in m/s and centerline distances in m.
param APPROACH_SPEED = VerifaiRange(7.5, 8.5)
param AGENT1_DIST = VerifaiRange(14, 16)
param EGO_TURN_SPEED = VerifaiRange(3, 4)
param AGENT1_TURN_SPEED = VerifaiRange(3, 4)
param RESPONSE_DIST = VerifaiRange(12, 14)

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction

@distributionFunction
def sameLane(first, second):
    return first is second

@distributionFunction
def laneLength(lane):
    return lane.centerline.lineString.length

@distributionFunction
def laneStation(lane, start):
    centerline = lane.centerline.lineString
    return centerline.project(ShapelyPoint(start.x, start.y))

@distributionFunction
def distanceToLaneEnd(lane, start):
    centerline = lane.centerline.lineString
    return centerline.length - centerline.project(ShapelyPoint(start.x, start.y))

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.RIGHT_TURN, egoInitLane.maneuvers))
egoTrajectory = [egoInitLane, egoManeuver.connectingLane, egoManeuver.endLane]
agent1Trajectory = egoTrajectory

#################################
# AGENT BEHAVIORS               #
#################################

# Ego's planned turn slowdown initiates the conflict on the common approach.
behavior EgoBehavior(trajectory):
    do FollowLaneBehavior(target_speed=globalParameters.APPROACH_SPEED) for 1 seconds
    do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_TURN_SPEED, trajectory=trajectory)

# Agent1 uses the very same incoming lane, connector, and outgoing lane.
behavior Agent1Behavior(trajectory):
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.APPROACH_SPEED, trajectory=trajectory)
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_TURN_SPEED, trajectory=trajectory)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.APPROACH_SPEED,
    with behavior EgoBehavior(egoTrajectory)

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with speed globalParameters.APPROACH_SPEED,
    with behavior Agent1Behavior(agent1Trajectory)

#################################
# REQUIREMENTS                  #
#################################

# Same incoming lane fixes direction and preserves front-to-rear geometry.
require sameLane(egoInitLane, agent1InitLane)
require laneLength(egoInitLane) >= 55
require laneStation(egoInitLane, agent1SpawnPt.position) >= 5
require distanceToLaneEnd(egoInitLane, egoSpawnPt.position) >= 28
require distanceToLaneEnd(egoInitLane, egoSpawnPt.position) <= 30
require laneLength(egoManeuver.endLane) >= 40

# Shared route and controller timing create an opportunity; collision is optional.
terminate after HORIZON seconds
