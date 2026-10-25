#################################
# MAP AND MODEL                 #
#################################

# Selected Town01 for long straight 4 m lanes supporting reverse travel toward a lawful follower.
param map = localPath('../../../maps/Town01.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_REVERSE_SPEED = VerifaiRange(2, 3)
param EGO_THROTTLE = VerifaiRange(0.2, 0.35)
param AGENT1_SPEED = VerifaiRange(4, 5)
param AGENT1_DIST = VerifaiRange(25, 30)
param RESPONSE_DIST = VerifaiRange(19, 22)
param REACTION_TIME = VerifaiRange(0.2, 0.4)
param AGENT1_BRAKE = VerifaiRange(0.8, 1.0)
param PREPARATION_TIME = 1
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

agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

#################################
# AGENT BEHAVIORS               #
#################################

behavior HoldStopped():
    while True:
        take SetSpeedAction(0)

behavior ReverseMotion():
    take SetReverseAction(True)
    while True:
        if abs(self.speed) < globalParameters.EGO_REVERSE_SPEED:
            take SetThrottleAction(globalParameters.EGO_THROTTLE)
        else:
            take SetThrottleAction(0)

behavior EgoBehavior():
    do HoldStopped() for globalParameters.PREPARATION_TIME seconds
    do ReverseMotion() for globalParameters.MOTION_WINDOW seconds
    while True:
        take SetBrakeAction(1)

behavior Agent1Behavior():
    do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for globalParameters.PREPARATION_TIME seconds
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
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

require agent1InitLane is egoInitLane
require hasStraightCorridor(egoInitLane, egoSpawnPt.position, 70, 20)
require hasStraightCorridor(agent1InitLane, agent1SpawnPt.position, 15, 55)
