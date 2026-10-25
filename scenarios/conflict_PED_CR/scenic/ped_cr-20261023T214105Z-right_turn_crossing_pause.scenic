################################################
# MAP AND MODEL
################################################

# Selected Town04 for four-approach junction turns into single-lane roads with bilateral sidewalks.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

################################################
# CONSTANTS
################################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(4.5, 5)
param CROSSING_DISTANCE = VerifaiRange(6, 8)
param AGENT1_SPEED = VerifaiRange(0.8, 1)
param PED1_LAT_OFFSET = VerifaiRange(3.8, 4)
param RESPONSE_DIST = VerifaiRange(12, 13)
param RESUME_DIST = 18

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAtLaneDistance(lane, distance):
    centerline = lane.centerline.lineString
    if distance < 0 or distance > centerline.length:
        raise RejectionException('lane too short for selected crossing')
    point = centerline.interpolate(distance)
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

@distributionFunction
def relativePosition(lane, start, target):
    line = lane.centerline.lineString
    station = line.project(ShapelyPoint(start.x, start.y))
    before = line.interpolate(max(0, station - 0.25))
    after = line.interpolate(min(line.length, station + 0.25))
    dx, dy = after.x - before.x, after.y - before.y
    norm = (dx * dx + dy * dy) ** 0.5
    if norm == 0:
        raise RejectionException('undefined lane tangent')
    tx, ty = target.x - start.x, target.y - start.y
    return ((tx * dy - ty * dx) / norm, (tx * dx + ty * dy) / norm)

################################################
# SPATIAL RELATIONS
################################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.RIGHT_TURN, egoInitLane.maneuvers))
egoTrajectory = [egoInitLane, egoManeuver.connectingLane, egoManeuver.endLane]
crossingLane = egoManeuver.endLane
agent1LongSpawnPt = new OrientedPoint at pointAtLaneDistance(crossingLane, globalParameters.CROSSING_DISTANCE), facing roadDirection
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.PED1_LAT_OFFSET, 0, 0)
agent1EndPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (-7.4, 0, 0)
crossingSection = network.laneSectionAt(agent1LongSpawnPt, reject="crossing must be on outgoing road")
pedestrianRelativePosition = relativePosition(egoInitLane, egoSpawnPt.position, agent1SpawnPt.position)

################################################
# AGENT BEHAVIORS
################################################

# Ego's commitment to the turn initiates the conflict; pedestrian walking predates it.
behavior EgoBehavior(trajectory):
    do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)

behavior WalkTo(endPt, speed):
    while distance from self to endPt >= 0.5:
        take SetWalkingSpeedAction(speed)
    while True:
        take SetWalkingSpeedAction(0)

behavior Agent1Behavior(endPt):
    try:
        do WalkTo(endPt, globalParameters.AGENT1_SPEED)
    interrupt when (ego.laneSection.lane is not egoInitLane) and (distance from self to ego) < globalParameters.RESPONSE_DIST:
        while distance from self to ego <= globalParameters.RESUME_DIST:
            take SetWalkingSpeedAction(0)
        do WalkTo(endPt, globalParameters.AGENT1_SPEED)

################################################
# SCENARIO SPECIFICATION
################################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior(egoTrajectory)

agent1 = new Pedestrian at agent1SpawnPt,
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)

################################################
# REQUIREMENTS
################################################

require straightLane(egoInitLane, 30, 90)
require straightLane(crossingLane, 30, 90)
require egoInitLane.centerline.lineString.length - laneStation(egoInitLane, egoSpawnPt.position) >= 6
require egoInitLane.centerline.lineString.length - laneStation(egoInitLane, egoSpawnPt.position) <= 9
require egoManeuver.connectingLane.centerline.lineString.length >= 8
require egoManeuver.connectingLane.centerline.lineString.length <= 25
require not hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require not hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require not hasSameDirectionAdjacentLane(crossingSection, 'left')
require not hasSameDirectionAdjacentLane(crossingSection, 'right')
require crossingSection.lane is crossingLane
require agent1SpawnPt.position in network.walkableRegion
require agent1EndPt.position in network.walkableRegion
require pedestrianRelativePosition[1] > 0
require pedestrianRelativePosition[0] > 0

terminate after 18 seconds
