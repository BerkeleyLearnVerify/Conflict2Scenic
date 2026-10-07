#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param AGENT1_DIST = VerifaiRange(8, 10)
param AGENT1_LAT_OFFSET = VerifaiRange(3, 3.5)
param AGENT1_SPEED = VerifaiRange(0.9, 1.3)
param EGO_THROTTLE = VerifaiRange(0.12, 0.2)
param SAFETY_DIST = VerifaiRange(5, 6)
param EGO_BRAKE = VerifaiRange(0.7, 0.9)

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for the crossing')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

road = network.drivableRegion
agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, -globalParameters.AGENT1_DIST), facing roadDirection
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)
agent1EndPt = new OrientedPoint at agent1SpawnPt offset along roadDirection by (-7, 0, 0)

#################################
# AGENT BEHAVIORS               #
#################################

behavior ReverseMotion():
    take SetReverseAction(True)
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

behavior EgoBehavior():
    try:
        do ReverseMotion()
    interrupt when (distance from self to agent1) < globalParameters.SAFETY_DIST:
        take SetThrottleAction(0)
        while True:
            take SetBrakeAction(globalParameters.EGO_BRAKE)

behavior Agent1Behavior(endPt):
    while distance from self to endPt >= 0.5:
        take SetWalkingSpeedAction(globalParameters.AGENT1_SPEED)
    while True:
        take SetWalkingSpeedAction(0)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Pedestrian at agent1SpawnPt,
    with regionContainedIn road.union(network.walkableRegion),
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)

#################################
# REQUIREMENTS                  #
#################################

require network.laneSectionAt(agent1LongSpawnPt, reject="crossing point not in a lane").lane is egoInitLane
require abs(agent1LongSpawnPt.heading - egoSpawnPt.heading) < 5 deg
