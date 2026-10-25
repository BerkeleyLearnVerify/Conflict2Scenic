#################################
# MAP AND MODEL                 #
#################################

# Selected Town01 for long straight 4 m lanes supporting a same-lane wrong-way encounter.
param map = localPath('../../../maps/Town01.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(3, 4)
param EGO_THROTTLE = VerifaiRange(0.25, 0.4)
param AGENT1_SPEED = VerifaiRange(5, 6)
param AGENT1_DIST = VerifaiRange(40, 45)
param RESPONSE_DIST = VerifaiRange(28, 32)
param REACTION_TIME = VerifaiRange(0.2, 0.4)
param AGENT1_BRAKE = VerifaiRange(0.8, 1.0)
param MOTION_WINDOW = 6

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction

@distributionFunction
def hasStraightCorridor(lane, start, behind, ahead):
    line = lane.centerline.lineString
    center = line.project(ShapelyPoint(start.x, start.y))
    lo = center - behind
    hi = center + ahead
    if lo < 0 or hi > line.length:
        return False
    first = line.interpolate(lo)
    last = line.interpolate(hi)
    chord = first.distance(last)
    if chord < hi - lo - 0.001:
        return False
    dx = last.x - first.x
    dy = last.y - first.y
    for index in range(int(hi - lo) + 2):
        point = line.interpolate(min(lo + index, hi))
        offset = abs(dx * (point.y - first.y) - dy * (point.x - first.x)) / chord
        if offset > 0.05:
            return False
    return True

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

# Ego will face against roadDirection: its physical front is at a negative lane offset.
agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

#################################
# AGENT BEHAVIORS               #
#################################

# Explicit throttle preserves ego's wrong-way heading on the constrained straight corridor.
behavior WrongWayMotion():
    while True:
        if self.speed < globalParameters.EGO_SPEED:
            take SetThrottleAction(globalParameters.EGO_THROTTLE)
        else:
            take SetThrottleAction(0)

behavior EgoBehavior():
    do WrongWayMotion() for globalParameters.MOTION_WINDOW seconds
    while True:
        take SetBrakeAction(1)

behavior Agent1Behavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for globalParameters.REACTION_TIME seconds
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
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

require agent1InitLane is egoInitLane
require hasStraightCorridor(egoInitLane, egoSpawnPt.position, 90, 20)
require hasStraightCorridor(agent1InitLane, agent1SpawnPt.position, 15, 70)
