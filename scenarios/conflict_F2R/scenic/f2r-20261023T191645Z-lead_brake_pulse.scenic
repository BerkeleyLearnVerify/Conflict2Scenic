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
param CRUISE_SPEED = VerifaiRange(9, 10)
param AGENT1_DIST = VerifaiRange(17, 20)
param EGO_BRAKE = VerifaiRange(0.65, 0.8)
param EGO_BRAKE_DURATION = VerifaiRange(0.7, 0.9)
param RESPONSE_DIST = VerifaiRange(14, 16)
param REACTION_TIME = VerifaiRange(0.3, 0.5)
param AGENT1_BRAKE = VerifaiRange(0.75, 0.9)
param RESPONSE_BRAKE_DURATION = VerifaiRange(1.0, 1.2)

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

agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

#################################
# AGENT BEHAVIORS               #
#################################

behavior ApplyBrakes(brake):
    while True:
        take SetThrottleAction(0), SetBrakeAction(brake)

# Ego initiates the temporary lead-car slowdown; agent1 reacts from behind.
behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.CRUISE_SPEED) for 2 seconds
    do ApplyBrakes(globalParameters.EGO_BRAKE) for globalParameters.EGO_BRAKE_DURATION seconds
    do FollowLaneBehavior(target_speed=globalParameters.CRUISE_SPEED)

behavior Agent1Behavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.CRUISE_SPEED)
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        do FollowLaneBehavior(target_speed=globalParameters.CRUISE_SPEED) for globalParameters.REACTION_TIME seconds
        do ApplyBrakes(globalParameters.AGENT1_BRAKE) for globalParameters.RESPONSE_BRAKE_DURATION seconds
        do FollowLaneBehavior(target_speed=globalParameters.CRUISE_SPEED)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.CRUISE_SPEED,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with speed globalParameters.CRUISE_SPEED,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

# A common lane enforces the input's same-lane, same-direction interaction.
require sameLane(egoInitLane, agent1InitLane)
# Reserve a straight non-intersection corridor for the full behavior horizon.
require straightWindowFits(egoInitLane, egoSpawnPt.position, 25, 110)

# Conflict opportunity only: there is no collision requirement.
terminate after HORIZON seconds
