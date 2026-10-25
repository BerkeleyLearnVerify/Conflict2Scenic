#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for compact urban adjacent lanes with continuous 3.5 m driving widths.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
# Speeds are m/s, distances are m, delays are s; controls are unitless.
param EGO_SPEED = VerifaiRange(8, 8.5)
param AGENT1_SPEED = VerifaiRange(11, 11.5)
param AGENT1_DIST = VerifaiRange(8, 10)
PREPARE_TIME = 0.6
RESPONSE_DELAY = 0.15
RESPONSE_DISTANCE = 14
FORWARD_CLEARANCE = 90
REAR_CLEARANCE = 15
# A small gap threshold allows the initiating close lateral incursion.
EGO_BYPASS_DIST = 2
param AGENT1_BYPASS_DIST = VerifaiRange(6, 8)

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
    if laneSection is None:
        return False
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

@distributionFunction
def hasLaneClearance(lane, start, ahead, behind):
    centerline = lane.centerline.lineString
    along = centerline.project(ShapelyPoint(start.x, start.y))
    return along >= behind and along + ahead <= centerline.length

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
egoInitLaneSection = network.laneSectionAt(egoSpawnPt, reject="ego spawn not in a lane")

agent1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1RefPt, reject="agent1 reference not in a lane").laneToLeft.lane
agent1SpawnPt = new OrientedPoint at agent1InitLane.centerline.project(agent1RefPt.position), facing roadDirection
agent1InitLaneSection = network.laneSectionAt(agent1SpawnPt, reject="agent1 spawn not in a lane")

#################################
# AGENT BEHAVIORS               #
#################################

# Input role: ego initiates; the preparation preserves initially separate lanes.
behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for PREPARE_TIME seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when hasSameDirectionAdjacentLane(self._laneSection, 'left') and (self._laneSection._laneToLeft.lane is agent1InitLane) and not withinDistanceToObjsInTargetLane(self, self._laneSection._laneToLeft.lane, EGO_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self._laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

# Input role: agent1 responds only after ego encroaches into its initial lane.
behavior Agent1Behavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (network.laneAt(ego) is agent1InitLane) and ((distance from self to ego) < RESPONSE_DISTANCE):
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for RESPONSE_DELAY seconds
        try:
            do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
        interrupt when hasSameDirectionAdjacentLane(self._laneSection, 'right') and not withinDistanceToObjsInTargetLane(self, self._laneSection._laneToRight.lane, globalParameters.AGENT1_BYPASS_DIST):
            do LaneChangeBehavior(laneSectionToSwitch=self._laneSection._laneToRight, target_speed=globalParameters.AGENT1_SPEED)
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

# Keep initial-lane checks tied to fixed spawn points: requirement expressions
# can be evaluated again during simulation, after the cars have changed lanes.
require hasSameDirectionAdjacentLane(egoInitLaneSection, 'left')
require agent1InitLane is egoInitLaneSection.laneToLeft.lane
require network.laneAt(egoSpawnPt) is egoInitLane
require network.laneAt(agent1SpawnPt) is agent1InitLane
require egoInitLane is not agent1InitLane
# Keep both cars away from lane ends throughout preparation and the conflict.
require hasLaneClearance(egoInitLane, egoSpawnPt.position, FORWARD_CLEARANCE, REAR_CLEARANCE)
require hasLaneClearance(agent1InitLane, agent1SpawnPt.position, FORWARD_CLEARANCE, REAR_CLEARANCE)
require hasSameDirectionAdjacentLane(agent1InitLaneSection, 'right')
require agent1InitLaneSection.laneToRight.lane is egoInitLane
