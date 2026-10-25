#################################
# MAP AND MODEL                 #
#################################

# Selected Town01 for long straight 4 m driving lanes supporting non-crossing pedestrian occupancy.
param map = localPath('../../../maps/Town01.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(5, 6)
param AGENT1_DIST = VerifaiRange(23, 26)
param AGENT1_LAT_OFFSET = VerifaiRange(-0.1, 0.1)
param EGO_BRAKE_DIST = VerifaiRange(9, 11)
param EGO_BRAKE = VerifaiRange(0.65, 0.85)

# Speeds are m/s, distances are m, and brake/throttle inputs are normalized.
# Input roles: ego car initiator; agent1 pedestrian responder, stationary throughout.
# Assumption: unmarked straight trafficway occupancy; no crossing or collision requirement.

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for the longitudinal offset')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

@distributionFunction
def hasStraightRoom(lane, start, forwardDistance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    if startDistance < 5 or startDistance + forwardDistance > centerline.length:
        return False
    rear = centerline.interpolate(startDistance - 5)
    front = centerline.interpolate(startDistance + forwardDistance)
    if rear.distance(front) < forwardDistance + 5 - 0.01:
        return False
    return True

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENT1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)

#################################
# AGENT BEHAVIORS               #
#################################

# Ego creates forward closure toward a stationary pedestrian before braking.
behavior EgoBehavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (distance from self to agent1) < globalParameters.EGO_BRAKE_DIST:
        while True:
            take SetBrakeAction(globalParameters.EGO_BRAKE)

behavior Agent1Behavior():
    while True:
        take SetWalkingSpeedAction(0)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Pedestrian at agent1SpawnPt,
    with regionContainedIn road,
    facing roadDirection,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

# Reserve a straight corridor including 5 m behind ego and 40 m ahead.
require hasStraightRoom(egoInitLane, egoSpawnPt.position, 40)
require network.laneSectionAt(agent1SpawnPt, reject="pedestrian not in ego lane").lane is egoInitLane
