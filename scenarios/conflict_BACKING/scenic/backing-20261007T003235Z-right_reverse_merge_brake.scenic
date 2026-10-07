#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(3, 4)
param AGENT1_DIST = VerifaiRange(13, 17)
param AGENT1_THROTTLE = VerifaiRange(0.12, 0.22)
param SAFETY_DIST = VerifaiRange(9, 11)
param EGO_BRAKE = VerifaiRange(0.7, 0.9)

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENT1_DIST
agent1RefLaneSection = network.laneSectionAt(agent1RefPt, reject="agent1 reference point not in a lane")
agent1InitLane = agent1RefLaneSection.laneToRight.lane
agent1SpawnPt = new OrientedPoint at agent1InitLane.centerline.project(agent1RefPt.position), facing roadDirection

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (distance from self to agent1) < globalParameters.SAFETY_DIST:
        take SetThrottleAction(0)
        while True:
            take SetBrakeAction(globalParameters.EGO_BRAKE)

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
    facing agent1SpawnPt.heading - 90 deg,
    with blueprint MODEL,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

require hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require hasSameDirectionAdjacentLane(agent1RefLaneSection, 'right')
require agent1RefLaneSection.lane is egoInitLane
require abs(agent1SpawnPt.heading - egoSpawnPt.heading) < 5 deg
