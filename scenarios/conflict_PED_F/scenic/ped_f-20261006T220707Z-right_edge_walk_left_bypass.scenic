#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

# Input: ego is the car responder; agent1 is the pedestrian initiator.
# The pedestrian initiates the conflict by walking slowly forward within the trafficway, near the right side of ego lane. Ego responds by changing into a clear same-direction left lane. The schema crossing value denotes walking parallel to the roadway, without lateral crossing.
# Distances in meters, speeds in m/s, delays in seconds.
MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(5, 7)
param AGENT1_DIST = VerifaiRange(20, 26)
param AGENT1_LAT_OFFSET = VerifaiRange(0.7, 1.0)
param AGENT1_SPEED = VerifaiRange(1.0, 1.5)
param WALK_DISTANCE = VerifaiRange(28, 36)
param RESPONSE_DIST = VerifaiRange(18, 22)
param BYPASS_CLEARANCE = VerifaiRange(10, 14)

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

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

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
    interrupt when ((distance from self to partner) < globalParameters.RESPONSE_DIST) and (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.BYPASS_CLEARANCE):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

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

require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
