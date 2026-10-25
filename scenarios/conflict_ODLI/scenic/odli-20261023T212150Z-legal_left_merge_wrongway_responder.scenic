#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for coexisting 3.5 m adjacent lanes and long straight portions on road 37.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(5, 6)
param EGO_BYPASS_DIST = VerifaiRange(8, 10)
param AGENT1_SPEED = VerifaiRange(3, 4)
param AGENT1_THROTTLE = VerifaiRange(0.25, 0.4)
param AGENT1_DIST = VerifaiRange(40, 45)
param RESPONSE_DIST = VerifaiRange(28, 32)
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

agent1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENT1_DIST
agent1RefSection = network.laneSectionAt(agent1RefPt, reject="agent1 reference not in a lane")
agent1InitLane = agent1RefSection.laneToLeft.lane
agent1SpawnPt = new OrientedPoint at agent1InitLane.centerline.project(agent1RefPt.position), facing roadDirection

#################################
# AGENT BEHAVIORS               #
#################################

behavior LegalMergeMotion():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for globalParameters.PREPARATION_TIME seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.EGO_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

behavior EgoBehavior():
    do LegalMergeMotion() for globalParameters.MOTION_WINDOW seconds
    while True:
        take SetBrakeAction(1)

# Agent1 already travels wrong-way; ego's lane entry initiates the conflict.
behavior WrongWayMotion():
    while True:
        if self.speed < globalParameters.AGENT1_SPEED:
            take SetThrottleAction(globalParameters.AGENT1_THROTTLE)
        else:
            take SetThrottleAction(0)

behavior Agent1Behavior():
    do WrongWayMotion() for globalParameters.PREPARATION_TIME seconds
    try:
        do WrongWayMotion()
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        do WrongWayMotion() for globalParameters.REACTION_TIME seconds
        while True:
            take SetBrakeAction(globalParameters.AGENT1_BRAKE)

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

require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require hasSameDirectionAdjacentLane(agent1RefSection, 'left')
require agent1RefSection.lane is egoInitLane
require ego.laneSection._laneToLeft.lane is agent1InitLane if ego.laneSection._laneToLeft is not None else True
require hasStraightCorridor(egoInitLane, egoSpawnPt.position, 10, 105)
require hasStraightCorridor(agent1InitLane, agent1SpawnPt.position, 55, 15)
