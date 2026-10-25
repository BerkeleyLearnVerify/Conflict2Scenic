################################################
# MAP AND MODEL
################################################

# Selected Town05 for straight two-lane carriageways coexisting with sidewalks on both sides.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

################################################
# CONSTANTS
################################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(4.5, 5)
param EGO_BYPASS_DIST = VerifaiRange(1, 2)
param PED1_DIST = VerifaiRange(19, 21)
param PED1_LAT_OFFSET = VerifaiRange(7.1, 7.3)
param AGENT1_SPEED = VerifaiRange(1.2, 1.4)
param AGENT1_CLEAR_SPEED = VerifaiRange(3, 3.4)
param RESPONSE_DIST = VerifaiRange(13, 14)

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

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

################################################
# SPATIAL RELATIONS
################################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
egoInitSection = network.laneSectionAt(egoSpawnPt, reject="ego needs an inner lane section")
egoTargetSection = egoInitSection.laneToRight
agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.PED1_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.PED1_LAT_OFFSET, 0, 0)
agent1EndPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (-10.8, 0, 0)
targetCrossingPt = new OrientedPoint at egoTargetSection.lane.centerline.project(agent1LongSpawnPt.position), facing roadDirection
crossingClearancePt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.PED1_DIST + 12)

################################################
# AGENT BEHAVIORS
################################################

# Ego's right lane change creates the conflict with an existing transverse walk.
behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for 0.75 seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (self.laneSection._laneToRight is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToRight.lane, globalParameters.EGO_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToRight, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

behavior WalkTo(endPt, speed):
    while distance from self to endPt >= 0.5:
        take SetWalkingSpeedAction(speed)
    while True:
        take SetWalkingSpeedAction(0)

behavior Agent1Behavior(endPt):
    try:
        do WalkTo(endPt, globalParameters.AGENT1_SPEED)
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        do WalkTo(endPt, globalParameters.AGENT1_CLEAR_SPEED)

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

require straightLane(egoInitLane, 45, 90)
require straightLane(egoTargetSection.lane, 45, 90)
require laneStation(egoInitLane, egoSpawnPt.position) >= 8
require hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require not hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require not hasSameDirectionAdjacentLane(egoTargetSection, 'right')
require agent1SpawnPt.position in network.walkableRegion
require agent1EndPt.position in network.walkableRegion
require network.laneSectionAt(agent1LongSpawnPt, reject="crossing must stay on ego lane").lane is egoInitLane
require network.laneSectionAt(targetCrossingPt, reject="crossing must reach target lane").lane is egoTargetSection.lane
require network.laneSectionAt(crossingClearancePt, reject="lane change needs downstream clearance").lane is egoInitLane

terminate after 16 seconds
