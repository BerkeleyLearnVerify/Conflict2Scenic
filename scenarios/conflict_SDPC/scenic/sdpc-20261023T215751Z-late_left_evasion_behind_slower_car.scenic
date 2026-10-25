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
param EGO_SPEED = VerifaiRange(10, 11)
param AGENT1_SPEED = VerifaiRange(7, 8)
param AGENT1_DIST = VerifaiRange(17, 19)
param EGO_BYPASS_DIST = VerifaiRange(0.1, 0.2)

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

agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

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
    # The responder maintains its lane and target speed during the exposure.
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

# Use fixed spawn geometry when these expressions are re-evaluated in simulation.
require hasSameDirectionAdjacentLane(egoInitLaneSection, 'left')
require network.laneAt(egoSpawnPt) is egoInitLane
require network.laneAt(agent1SpawnPt) is agent1InitLane
require agent1InitLane is egoInitLane
require hasStraightClearance(egoInitLane, egoSpawnPt.position, 25, 95)
require hasStraightClearance(agent1InitLane, agent1SpawnPt.position, 5, 85)
require hasStraightClearance(egoInitLaneSection.laneToLeft.lane, egoSpawnPt.position, 25, 95)

terminate after HORIZON seconds
