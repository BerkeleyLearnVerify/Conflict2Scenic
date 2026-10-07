#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(9, 11)
param EGO_THROTTLE = VerifaiRange(0.35, 0.55)
param DEPARTURE_DISTANCE = VerifaiRange(40, 45)

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance > centerline.length:
        raise RejectionException('not enough lane ahead for the departure')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
laneAheadPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.DEPARTURE_DISTANCE)
departureProbe = new OrientedPoint at egoSpawnPt offset along egoSpawnPt.heading by (0, globalParameters.DEPARTURE_DISTANCE, 0)

#################################
# AGENT BEHAVIORS               #
#################################

# Ego initiates the departure by omitting steering on a bend.
behavior EgoBehavior():
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior()

#################################
# REQUIREMENTS                  #
#################################

require (distance from laneAheadPt to departureProbe) > 8
require departureProbe.position not in road
