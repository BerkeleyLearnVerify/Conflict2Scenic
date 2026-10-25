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

param EGO_SPEED = VerifaiRange(3.5, 4)
param EGO_BRAKE_DIST = VerifaiRange(4.5, 5.5)
param AGENTSTATIC_DIST = VerifaiRange(17, 18)
param AGENT1_LAT_OFFSET = VerifaiRange(1.25, 1.35)
param AGENT1_CLEARANCE = VerifaiRange(0.65, 0.75)
param AGENT1_RESPONSE_DIST = VerifaiRange(9, 10)
param AGENT1_SPEED = VerifaiRange(0.9, 1.1)

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
corridorEndPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, CORRIDOR_LENGTH)

agentStaticRefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENTSTATIC_DIST
agentStaticInitLane = network.laneSectionAt(agentStaticRefPt, reject="agentStatic reference not in a lane").laneToRight.lane
agentStaticSpawnPt = new OrientedPoint at agentStaticInitLane.centerline.project(agentStaticRefPt.position), facing roadDirection

agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENTSTATIC_DIST)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in the trafficway").lane
agent1EndPt = new OrientedPoint at agent1SpawnPt offset along roadDirection by (globalParameters.AGENT1_CLEARANCE, 0, 0)

road = egoInitLane.union(agent1InitLane).union(agentStaticInitLane)

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (distance from self to agent1) < globalParameters.EGO_BRAKE_DIST:
        while True:
            take SetBrakeAction(1)

behavior Agent1Behavior(endPt):
    # The access task is pre-existing; walking is a response to ego's closure.
    while (distance from self to ego) > globalParameters.AGENT1_RESPONSE_DIST:
        take SetWalkingSpeedAction(0)
    while distance from self to endPt >= 0.1:
        take SetWalkingSpeedAction(globalParameters.AGENT1_SPEED)
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
require hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require agent1InitLane == egoInitLane

require network.laneSectionAt(agentStaticRefPt, reject="agentStatic reference left ego lane").lane == egoInitLane
