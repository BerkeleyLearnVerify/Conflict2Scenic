#################################
# MAP AND MODEL                 #
#################################

# Selected Town01: long straight, single-lane-per-direction corridors.
# Source roads 4 and 12 provide 224 m of XML-supported geometry;
# the straight-window requirement selects usable geometry without source IDs.
param map = localPath('../../../maps/Town01.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
HORIZON = 8
# Speeds in m/s, centerline distances in m, durations in s; brake in [0, 1].
param EGO_SPEED = VerifaiRange(11, 12)
param AGENT1_SPEED = VerifaiRange(6, 7)
param AGENT1_DIST = VerifaiRange(26, 29)
param BRAKING_DIST = VerifaiRange(12, 14)
param LATE_REACTION_TIME = VerifaiRange(0.5, 0.7)
param EGO_BRAKE = VerifaiRange(0.8, 0.95)
param BRAKE_DURATION = VerifaiRange(1.2, 1.5)

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction

@distributionFunction
def sameLane(first, second):
    return first is second

@distributionFunction
def straightWindowFits(lane, start, behind, ahead):
    centerline = lane.centerline.lineString
    station = centerline.project(ShapelyPoint(start.x, start.y))
    first = centerline.interpolate(0)
    last = centerline.interpolate(centerline.length)
    chord = ((last.x - first.x)**2 + (last.y - first.y)**2)**0.5
    return (centerline.length >= 180
            and centerline.length - chord < 0.05
            and station >= behind + 5
            and station + ahead + 5 <= centerline.length)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

#################################
# AGENT BEHAVIORS               #
#################################

behavior ApplyBrakes(brake):
    while True:
        take SetThrottleAction(0), SetBrakeAction(brake)

# Ego creates the conflict by closing too far before correcting its speed.
# Agent1's response policy is to maintain its existing lane and steady speed.
behavior EgoBehavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (distance from self to agent1) < globalParameters.BRAKING_DIST:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for globalParameters.LATE_REACTION_TIME seconds
        do ApplyBrakes(globalParameters.EGO_BRAKE) for globalParameters.BRAKE_DURATION seconds
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)

behavior Agent1Behavior():
    do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with speed globalParameters.AGENT1_SPEED,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

# A common lane enforces the input's same-lane, same-direction interaction.
require sameLane(egoInitLane, agent1InitLane)
# Reserve a straight non-intersection corridor for the full behavior horizon.
require straightWindowFits(egoInitLane, egoSpawnPt.position, 5, 140)

# Conflict opportunity only: there is no collision requirement.
terminate after HORIZON seconds
