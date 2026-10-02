#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 10)
param AGENT1_SPEED = VerifaiRange(6, 9)
param AGENT1_THROTTLE = VerifaiRange(0.15, 0.25)
param AGENT1_DIST = VerifaiRange(30, 35) #VerifaiRange(50, 65)
param RESPONSE_DIST = VerifaiRange(12, 18) #VerifaiRange(32, 38)
param EGO_BYPASS_DIST = VerifaiRange(5, 7)

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

agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when ((distance from self to agent1) < globalParameters.RESPONSE_DIST) and (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.EGO_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

# Preserve the wrong-way heading: direct throttle supplies acceleration
# without a lane-following controller steering back to the intended direction.
behavior Agent1Behavior():
    take SetSpeedAction(globalParameters.AGENT1_SPEED)
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

#require agent1InitLane is egoInitLane
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
#require not hasSameDirectionAdjacentLane(ego.laneSection, 'right')

