#################################
# MAP AND MODEL                 #
#################################

# Selected Town04 for full-width adjacent driving lanes with long straight sections for stopped-car access.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
# Distances in meters; speeds in m/s; controls are dimensionless.
CORRIDOR_LENGTH = 38
from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for the trafficway interaction')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

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

param EGO_SPEED = VerifaiRange(3, 3.5)
param EGO_BYPASS_DIST = VerifaiRange(2.5, 3)
param EGO_BRAKE_DIST = VerifaiRange(5.5, 6.5)
param AGENTSTATIC_DIST = VerifaiRange(18, 19)
param AGENT1_LAT_OFFSET = VerifaiRange(-2.15, -2.05)
param AGENT1_SPEED = VerifaiRange(0.6, 0.8)
param AGENT1_RESPONSE_DIST = VerifaiRange(11, 12)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
corridorEndPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, CORRIDOR_LENGTH)

agentStaticSpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENTSTATIC_DIST
agentStaticInitLane = network.laneSectionAt(agentStaticSpawnPt, reject="agentStatic not in a lane").lane
targetInitLane = network.laneSectionAt(agentStaticSpawnPt, reject="bypass reference not in a lane").laneToLeft.lane
agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENTSTATIC_DIST - 0.2)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in the trafficway").lane
agent1EndPt = new OrientedPoint at agent1SpawnPt offset along roadDirection by (-0.8, 0, 0)

road = egoInitLane.union(agent1InitLane).union(agentStaticInitLane)

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED) for 1 seconds
    try:
        try:
            do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
        interrupt when (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.EGO_BYPASS_DIST):
            do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
            do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when ((distance from self to agent1) < globalParameters.EGO_BRAKE_DIST) or ((distance from self to agentStatic) < globalParameters.EGO_BRAKE_DIST):
        while True:
            take SetBrakeAction(1)

behavior Agent1Behavior(endPt):
    try:
        while distance from self to endPt >= 0.1:
            take SetWalkingSpeedAction(globalParameters.AGENT1_SPEED)
        while True:
            take SetWalkingSpeedAction(0)
    interrupt when (distance from self to ego) < globalParameters.AGENT1_RESPONSE_DIST:
        while True:
            take SetWalkingSpeedAction(0)

behavior AgentStaticBehavior():
    while True:
        take SetSpeedAction(0)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()

agentStatic = new Car at agentStaticSpawnPt,
    with blueprint MODEL,
    with behavior AgentStaticBehavior()

agent1 = new Pedestrian at agent1SpawnPt,
    with regionContainedIn road,
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)

#################################
# REQUIREMENTS                  #
#################################

# Keep the entire approach on one nearly straight lane corridor.
require (distance from egoSpawnPt to corridorEndPt) > CORRIDOR_LENGTH - 0.01
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require agentStaticInitLane == egoInitLane
require agent1InitLane == targetInitLane

