#################################
# MAP AND MODEL                 #
#################################

# Selected Town01 for a long straight single-lane trafficway supporting rear access at a stopped car.
param map = localPath('../../../maps/Town01.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
# Distances in meters; speeds in m/s; controls are dimensionless.
CORRIDOR_LENGTH = 38
from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for the trafficway interaction')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

param EGO_SPEED = VerifaiRange(2.5, 3)
param EGO_THROTTLE = VerifaiRange(0.18, 0.23)
param EGO_BRAKE_DIST = VerifaiRange(6, 7)
param AGENT1_DIST = VerifaiRange(16, 17)
param REAR_ACCESS_GAP = VerifaiRange(3.2, 3.4)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
corridorEndPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, CORRIDOR_LENGTH)

agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENT1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (0, 0, 0)
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in the trafficway").lane
agentStaticSpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENT1_DIST + globalParameters.REAR_ACCESS_GAP
agentStaticInitLane = network.laneSectionAt(agentStaticSpawnPt, reject="agentStatic not in a lane").lane

road = egoInitLane.union(agent1InitLane).union(agentStaticInitLane)

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    # Establish forward motion before the initiating acceleration.
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for 1 seconds
    while (distance from self to agent1) > globalParameters.EGO_BRAKE_DIST:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)
    take SetThrottleAction(0)
    while True:
        take SetBrakeAction(1)

behavior Agent1Behavior():
    while True:
        take SetWalkingSpeedAction(0)

behavior AgentStaticBehavior():
    while True:
        take SetSpeedAction(0)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()

agentStatic = new Car at agentStaticSpawnPt,
    with blueprint MODEL,
    with behavior AgentStaticBehavior()

agent1 = new Pedestrian at agent1SpawnPt,
    with regionContainedIn road,
    facing roadDirection,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

# Keep the entire approach on one nearly straight lane corridor.
require (distance from egoSpawnPt to corridorEndPt) > CORRIDOR_LENGTH - 0.01
require agent1InitLane == egoInitLane
require agentStaticInitLane == egoInitLane

