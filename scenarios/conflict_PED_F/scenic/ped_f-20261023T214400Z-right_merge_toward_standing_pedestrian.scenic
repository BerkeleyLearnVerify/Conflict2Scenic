#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for straight adjacent same-direction lanes with sufficient merge and stopping room.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(3, 4)
param AGENT1_DIST = VerifaiRange(23, 26)
param AGENT1_LAT_OFFSET = VerifaiRange(3.4, 3.6)
param EGO_BRAKE_DIST = VerifaiRange(9, 11)
param EGO_BRAKE = VerifaiRange(0.65, 0.85)
param EGO_BYPASS_DIST = VerifaiRange(5, 6)

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

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENT1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)

egoTargetLane = network.laneSectionAt(egoSpawnPt, reject="ego spawn not in a lane").laneToRight.lane
agent1TargetLane = network.laneSectionAt(agent1LongSpawnPt, reject="pedestrian reference not in a lane").laneToRight.lane

#################################
# AGENT BEHAVIORS               #
#################################

# Ego initiates the merge; the pedestrian holds position in the destination lane.
behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for 1 seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (self.laneSection._laneToRight is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToRight.lane, globalParameters.EGO_BYPASS_DIST):
        try:
            do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToRight, target_speed=globalParameters.EGO_SPEED)
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
require hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require hasSameDirectionAdjacentLane(network.laneSectionAt(agent1LongSpawnPt, reject="pedestrian reference not in a lane"), 'right')
require agent1TargetLane is egoTargetLane
require network.laneSectionAt(agent1SpawnPt, reject="pedestrian not in destination lane").lane is egoTargetLane
require hasStraightRoom(egoTargetLane, egoSpawnPt.position, 40)
