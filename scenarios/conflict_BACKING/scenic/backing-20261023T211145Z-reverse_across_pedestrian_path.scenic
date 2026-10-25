#################################
# MAP AND MODEL                 #
#################################

# Selected Town01 for straight single-lane roads with room for the backing corridor.
param map = localPath('../../../maps/Town01.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_PREP_TIME = VerifaiRange(0.6, 0.9)
param EGO_THROTTLE = VerifaiRange(0.25, 0.35)
param EGO_REVERSE_TIME = VerifaiRange(3, 4)
param EGO_BRAKE = VerifaiRange(0.8, 1.0)
param AGENT1_DIST = VerifaiRange(5, 7)
param AGENT1_LAT_OFFSET = VerifaiRange(1.3, 1.5)
param AGENT1_CROSSING_DISTANCE = VerifaiRange(3, 3.2)
param AGENT1_SPEED = VerifaiRange(0.8, 1.0)
param AGENT1_RESPONSE_DIST = VerifaiRange(2.5, 3.0)

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def hasStraightCorridor(lane, start, backward, forward):
    line = lane.centerline.lineString
    origin = line.project(ShapelyPoint(start.x, start.y))
    low = origin - backward
    high = origin + forward
    if low < 0 or high > line.length + 0.000001:
        return False
    high = min(high, line.length)
    chord = line.interpolate(low).distance(line.interpolate(high))
    return high - low - chord < 0.01

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for the pedestrian offset')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
# The pedestrian starts on the roadway; the selected lane is its initial allowed region.
road = egoInitLane
agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, -globalParameters.AGENT1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)
agent1EndPt = new OrientedPoint at agent1SpawnPt offset along roadDirection by (-globalParameters.AGENT1_CROSSING_DISTANCE, 0, 0)

#################################
# AGENT BEHAVIORS               #
#################################

# Ego is the reversing initiator; agent1 carries the selected responder policy.
behavior HoldPosition():
    while True:
        take SetSpeedAction(0)

behavior ReverseMotion():
    take SetReverseAction(True)
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

behavior EgoBehavior():
    do HoldPosition() for globalParameters.EGO_PREP_TIME seconds
    do ReverseMotion() for globalParameters.EGO_REVERSE_TIME seconds
    take SetThrottleAction(0)
    while True:
        take SetBrakeAction(globalParameters.EGO_BRAKE)

behavior Agent1Behavior(endPt):
    try:
        while distance from self to endPt >= 0.5:
            take SetWalkingSpeedAction(globalParameters.AGENT1_SPEED)
        while True:
            take SetWalkingSpeedAction(0)
    interrupt when (distance from self to ego) < globalParameters.AGENT1_RESPONSE_DIST:
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
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)

#################################
# REQUIREMENTS                  #
#################################

require hasStraightCorridor(egoInitLane, egoSpawnPt.position, 26, 25)
