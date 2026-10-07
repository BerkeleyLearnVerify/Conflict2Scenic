#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(1, 2)
param AGENT1_DIST = VerifaiRange(12, 16)
param AGENT1_THROTTLE = VerifaiRange(0.2, 0.3)

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

behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

behavior Agent1Behavior():
    take SetReverseAction(True)
    while True:
        take SetThrottleAction(globalParameters.AGENT1_THROTTLE)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    facing agent1SpawnPt.heading + 180 deg,
    with blueprint MODEL,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

require agent1InitLane is egoInitLane
require abs(agent1SpawnPt.heading - egoSpawnPt.heading) < 5 deg
