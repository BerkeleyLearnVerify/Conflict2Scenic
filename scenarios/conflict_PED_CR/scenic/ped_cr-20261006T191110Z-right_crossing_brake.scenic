#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 9)
param AGENT1_DIST = VerifaiRange(20, 26)
param AGENT1_LAT_OFFSET = VerifaiRange(-5, -4)
param AGENT1_SPEED = VerifaiRange(1.4, 1.8)
param AGENT1_END_LAT_OFFSET = VerifaiRange(4, 5)
param SAFETY_DIST = VerifaiRange(11, 14)
param EGO_BRAKE = VerifaiRange(0.65, 0.85)

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

agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENT1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)
agent1EndPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_END_LAT_OFFSET, 0, 0)

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when withinDistanceToAnyObjs(self, globalParameters.SAFETY_DIST):
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
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)

#################################
# REQUIREMENTS                  #
#################################

# The crossing needs no adjacent-lane requirement.
