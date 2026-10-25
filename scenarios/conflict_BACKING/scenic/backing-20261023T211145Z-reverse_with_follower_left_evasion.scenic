#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for a straight two-lane corridor for the following car to evade left.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_PREP_TIME = VerifaiRange(0.6, 0.9)
param EGO_THROTTLE = VerifaiRange(0.25, 0.35)
param EGO_REVERSE_TIME = VerifaiRange(3, 4)
param EGO_BRAKE = VerifaiRange(0.8, 1.0)
param AGENT1_DIST = VerifaiRange(17, 21)
param AGENT1_SPEED = VerifaiRange(3, 4)
param AGENT1_RESPONSE_DIST = VerifaiRange(14, 16)
param AGENT1_BYPASS_DIST = VerifaiRange(8, 10)

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

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane
agent1EscapeLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").laneToLeft.lane
agent1EscapePt = new OrientedPoint at agent1EscapeLane.centerline.project(agent1SpawnPt.position), facing roadDirection

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

behavior Agent1Behavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (distance from self to ego) < globalParameters.AGENT1_RESPONSE_DIST and (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.AGENT1_BYPASS_DIST):
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

require hasStraightCorridor(egoInitLane, egoSpawnPt.position, 26, 25)
require agent1InitLane is egoInitLane
require hasSameDirectionAdjacentLane(agent1.laneSection, 'left')
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require hasStraightCorridor(agent1EscapeLane, agent1EscapePt.position, 4, 40)
