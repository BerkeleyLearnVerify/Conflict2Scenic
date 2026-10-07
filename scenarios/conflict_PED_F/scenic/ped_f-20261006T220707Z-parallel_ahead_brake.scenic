#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

# Input: ego is the car responder; agent1 is the pedestrian initiator.
# The pedestrian initiates the conflict by walking ahead of ego in the same direction at a lower speed. Ego closes the gap and brakes. The schema crossing value denotes the walking behavior; its path is strictly longitudinal, with no attempt to cross the roadway.
# Distances in meters, speeds in m/s, delays in seconds.
MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(6, 8)
param AGENT1_DIST = VerifaiRange(18, 24)
param AGENT1_LAT_OFFSET = VerifaiRange(-0.2, 0.2)
param AGENT1_SPEED = VerifaiRange(1.0, 1.5)
param WALK_DISTANCE = VerifaiRange(28, 36)
param RESPONSE_DIST = VerifaiRange(8, 12)
param REACTION_DELAY = VerifaiRange(0.2, 0.5)
param EGO_BRAKE = VerifaiRange(0.8, 1.0)

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for the longitudinal pedestrian path')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENT1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)

agent1LongEndPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENT1_DIST + globalParameters.WALK_DISTANCE)
agent1EndPt = new OrientedPoint at agent1LongEndPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior(partner):
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (distance from self to partner) < globalParameters.RESPONSE_DIST:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for globalParameters.REACTION_DELAY seconds
        while True:
            take SetThrottleAction(0), SetBrakeAction(globalParameters.EGO_BRAKE)

behavior Agent1Behavior(endPt):
    while distance from self to endPt >= 0.5:
        take SetWalkingSpeedAction(globalParameters.AGENT1_SPEED)
    while True:
        take SetWalkingSpeedAction(0)

#################################
# SCENARIO SPECIFICATION        #
#################################

agent1 = new Pedestrian at agent1SpawnPt,
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior(agent1)

#################################
# REQUIREMENTS                  #
#################################

# Longitudinal lane bounds are enforced by pointAheadOnLane.
