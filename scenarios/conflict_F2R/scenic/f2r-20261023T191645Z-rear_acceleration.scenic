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
# Speeds in m/s, centerline distances in m, durations in s; throttle in [0, 1].
param INITIAL_SPEED = VerifaiRange(7, 8)
param AGENT1_DIST = VerifaiRange(23, 26)
param EGO_THROTTLE = VerifaiRange(0.45, 0.6)
param ACCELERATION_DURATION = VerifaiRange(1.3, 1.6)
param EGO_TARGET_SPEED = VerifaiRange(13, 14)

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

behavior AccelerationPulse():
    while True:
        take SetBrakeAction(0), SetThrottleAction(globalParameters.EGO_THROTTLE)

# Ego initiates closure from behind; the exposed leader keeps a steady course.
behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.INITIAL_SPEED) for 2 seconds
    do AccelerationPulse() for globalParameters.ACCELERATION_DURATION seconds
    do FollowLaneBehavior(target_speed=globalParameters.EGO_TARGET_SPEED)

behavior Agent1Behavior():
    do FollowLaneBehavior(target_speed=globalParameters.INITIAL_SPEED)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.INITIAL_SPEED,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with speed globalParameters.INITIAL_SPEED,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

# A common lane enforces the input's same-lane, same-direction interaction.
require sameLane(egoInitLane, agent1InitLane)
# Reserve a straight non-intersection corridor for the full behavior horizon.
require straightWindowFits(egoInitLane, egoSpawnPt.position, 5, 155)

# Conflict opportunity only: there is no collision requirement.
terminate after HORIZON seconds
