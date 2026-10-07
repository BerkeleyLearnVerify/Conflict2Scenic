
#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(4, 6)
param AGENT1_SPEED = VerifaiRange(12, 14)
param AGENT1_DIST = VerifaiRange(10, 16)
param AGENT1_BYPASS_DIST = VerifaiRange(1, 2)

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1RefPt, reject="agent1 not in a lane").laneToRight.lane
agent1SpawnPt = new OrientedPoint at agent1InitLane.centerline.project(agent1RefPt.position), facing roadDirection

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

# Agent1's lateral evasive action creates the conflict after preparation.
behavior Agent1Behavior():
    do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for 8 seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.AGENT1_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.AGENT1_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)

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

require hasSameDirectionAdjacentLane(agent1.laneSection, 'left')
require not hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require hasSameDirectionAdjacentLane(ego.laneSection, 'right')
