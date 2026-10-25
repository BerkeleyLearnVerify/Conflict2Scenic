#################################
# MAP AND MODEL                 #
#################################

# Selected Town04 for four-approach junctions with crossing straight routes and sufficient approaches.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_PREP_TIME = VerifaiRange(0.6, 0.9)
param EGO_THROTTLE = VerifaiRange(0.35, 0.45)
param EGO_REVERSE_TIME = VerifaiRange(5, 6)
param EGO_BRAKE = VerifaiRange(0.8, 1.0)
param AGENT1_SPEED = VerifaiRange(3, 4)
param AGENT1_RESPONSE_DIST = VerifaiRange(10, 12)
param AGENT1_REACTION_TIME = VerifaiRange(0.3, 0.5)
param AGENT1_BRAKE = VerifaiRange(0.7, 0.9)

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

from math import cos

@distributionFunction
def haveCrossingHeadings(first, second):
    return abs(cos(first - second)) < 0.5

@distributionFunction
def remainingLaneDistance(lane, start):
    line = lane.centerline.lineString
    return line.length - line.project(ShapelyPoint(start.x, start.y))

@distributionFunction
def hasStraightReverseEntry(lane, connection):
    approach = lane.centerline.lineString
    line = connection.centerline.lineString
    if approach.length < 5 or line.length < 5:
        return False
    p = approach.interpolate(approach.length - 5)
    q = approach.interpolate(approach.length)
    a = line.interpolate(0)
    b = line.interpolate(line.length)
    dx = q.x - p.x
    dy = q.y - p.y
    length = (dx * dx + dy * dy) ** 0.5
    cross = abs(dx * (b.y - q.y) - dy * (b.x - q.x)) / length
    dot = dx * (b.x - q.x) + dy * (b.y - q.y)
    return q.distance(a) < 0.5 and cross < 0.5 and dot > 0 and line.length - a.distance(b) < 0.02

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, egoInitLane.maneuvers))
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, egoManeuver.conflictingManeuvers))
agent1InitLane = agent1Maneuver.startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]
egoRemaining = remainingLaneDistance(egoInitLane, egoSpawnPt.position)
agent1Remaining = remainingLaneDistance(agent1InitLane, agent1SpawnPt.position)

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

behavior Agent1Behavior(trajectory):
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)
    interrupt when (distance from self to ego) < globalParameters.AGENT1_RESPONSE_DIST:
        do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory) for globalParameters.AGENT1_REACTION_TIME seconds
        take SetThrottleAction(0)
        while True:
            take SetBrakeAction(globalParameters.AGENT1_BRAKE)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    facing egoSpawnPt.heading + 180 deg,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior(agent1Trajectory)

#################################
# REQUIREMENTS                  #
#################################

require egoRemaining >= 5
require egoRemaining <= 7
require agent1Remaining >= 12
require agent1Remaining <= 16
require hasStraightCorridor(egoInitLane, egoSpawnPt.position, 10, egoRemaining)
require hasStraightReverseEntry(egoInitLane, egoManeuver.connectingLane)
require haveCrossingHeadings(egoSpawnPt.heading, agent1SpawnPt.heading)
