################################################
# MAP AND MODEL
################################################

# Selected Town01 for long straight single-lane two-way roads with sidewalks on both sides.
param map = localPath('../../../maps/Town01.xodr')
model scenic.simulators.metadrive.model

################################################
# CONSTANTS
################################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(2.5, 3)
param EGO_CRUISE_SPEED = VerifaiRange(7, 8)
param EGO_THROTTLE = VerifaiRange(0.45, 0.55)
param AGENT1_SPEED = VerifaiRange(1.2, 1.4)
param PED1_DIST = VerifaiRange(18, 20)
param PED1_LAT_OFFSET = VerifaiRange(5.3, 5.5)
param RESPONSE_DIST = VerifaiRange(15, 16)
param RESUME_DIST = 20

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for crossing and clearance')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

@distributionFunction
def laneStation(lane, position):
    return lane.centerline.lineString.project(ShapelyPoint(position.x, position.y))

@distributionFunction
def straightLane(lane, minimumLength, maximumLength):
    line = lane.centerline.lineString
    if not minimumLength <= line.length <= maximumLength:
        return False
    chord = ShapelyPoint(line.coords[0]).distance(ShapelyPoint(line.coords[-1]))
    return chord > 0 and line.length / chord < 1.0001

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

################################################
# SPATIAL RELATIONS
################################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.PED1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.PED1_LAT_OFFSET, 0, 0)
agent1EndPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (-8, 0, 0)
crossingClearancePt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.PED1_DIST + 25)

################################################
# AGENT BEHAVIORS
################################################

# Ego creates the closing-gap conflict after the pedestrian has started crossing.
behavior Accelerate():
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for 1 seconds
    do Accelerate() for 3 seconds
    do FollowLaneBehavior(target_speed=globalParameters.EGO_CRUISE_SPEED)

behavior WalkTo(endPt, speed):
    while distance from self to endPt >= 0.5:
        take SetWalkingSpeedAction(speed)
    while True:
        take SetWalkingSpeedAction(0)

behavior Agent1Behavior(endPt):
    try:
        do WalkTo(endPt, globalParameters.AGENT1_SPEED)
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        while distance from self to ego <= globalParameters.RESUME_DIST:
            take SetWalkingSpeedAction(0)
        do WalkTo(endPt, globalParameters.AGENT1_SPEED)

################################################
# SCENARIO SPECIFICATION
################################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior()

agent1 = new Pedestrian at agent1SpawnPt,
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)

################################################
# REQUIREMENTS
################################################

require straightLane(egoInitLane, 100, 300)
require laneStation(egoInitLane, egoSpawnPt.position) >= 10
require not hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require not hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require agent1SpawnPt.position in network.walkableRegion
require agent1EndPt.position in network.walkableRegion
require network.laneSectionAt(agent1LongSpawnPt, reject="crossing must stay on ego lane").lane is egoInitLane
require network.laneSectionAt(crossingClearancePt, reject="crossing needs downstream clearance").lane is egoInitLane

terminate after 16 seconds
