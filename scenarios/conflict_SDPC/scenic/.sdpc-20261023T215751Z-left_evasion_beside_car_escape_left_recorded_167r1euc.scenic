#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for long straight three-lane corridors supporting the required same-direction evasion and response.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
EGO_PREP_TIME = 2
HORIZON = 7
param EGO_SPEED = VerifaiRange(8, 9)
param AGENT1_OFFSET = VerifaiRange(-1, 1)
param EGO_BYPASS_DIST = VerifaiRange(0.1, 0.2)
param REACTION_DELAY = VerifaiRange(0.3, 0.5)
param RESPONSE_DIST = VerifaiRange(14, 18)
param AGENT1_BYPASS_DIST = VerifaiRange(5, 7)

# Distances are meters, target speeds m/s, times seconds, and braking a normalized command.
# The small ego bypass threshold represents emergency evasion with limited gap acceptance.

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction

def hasSameDirectionAdjacentLane(laneSection, side):
    if laneSection is None:
        return False
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

@distributionFunction
def hasStraightClearance(lane, position, behind, ahead):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(position.x, position.y))
    if startDistance < behind or startDistance + ahead > centerline.length:
        return False
    first = centerline.interpolate(startDistance - behind)
    last = centerline.interpolate(startDistance + ahead)
    return first.distance(last) >= 0.99999 * (behind + ahead)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
egoInitLaneSection = network.laneSectionAt(egoSpawnPt, reject="ego spawn not in a lane")

agent1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENT1_OFFSET
agent1InitLane = network.laneSectionAt(agent1RefPt, reject="agent1 not in a lane").laneToLeft.lane
agent1SpawnPt = new OrientedPoint at agent1InitLane.centerline.project(agent1RefPt.position), facing roadDirection
agent1InitLaneSection = network.laneSectionAt(agent1SpawnPt, reject="agent1 spawn not in a lane")

#################################
# AGENT BEHAVIORS               #
#################################

# Ego initiates a lateral evasion at 2 s; no prior collision or additional actor is assumed.
behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for EGO_PREP_TIME seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when hasSameDirectionAdjacentLane(self._laneSection, 'left') and not withinDistanceToObjsInTargetLane(self, self._laneSection._laneToLeft.lane, globalParameters.EGO_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self._laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

behavior Agent1Behavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for (EGO_PREP_TIME + globalParameters.REACTION_DELAY) seconds
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when ((distance from self to ego) < globalParameters.RESPONSE_DIST) and hasSameDirectionAdjacentLane(self._laneSection, 'left') and not withinDistanceToObjsInTargetLane(self, self._laneSection._laneToLeft.lane, globalParameters.AGENT1_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self._laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

# Use fixed spawn geometry when these expressions are re-evaluated in simulation.
require hasSameDirectionAdjacentLane(egoInitLaneSection, 'left')
require hasSameDirectionAdjacentLane(agent1InitLaneSection, 'left')
require network.laneAt(egoSpawnPt) is egoInitLane
require network.laneAt(agent1SpawnPt) is agent1InitLane
require agent1InitLane is egoInitLaneSection.laneToLeft.lane
require hasStraightClearance(egoInitLane, egoSpawnPt.position, 25, 95)
require hasStraightClearance(agent1InitLane, agent1SpawnPt.position, 5, 85)
require hasStraightClearance(egoInitLaneSection.laneToLeft.lane, egoSpawnPt.position, 25, 95)
require hasStraightClearance(agent1InitLaneSection.laneToLeft.lane, agent1SpawnPt.position, 5, 85)

terminate after HORIZON seconds


# Automatically added polygon records
record ego._boundingPolygon as egoPoly
record (ego._lane.polygon if ego._lane is not None else None) as egoLanePoly
record agent1._boundingPolygon as agent1Poly
record (agent1._lane.polygon if agent1._lane is not None else None) as agent1LanePoly
