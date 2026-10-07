#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(4, 6)
param AGENTSTATIC_DIST = VerifaiRange(16, 20)
param AGENT1_SPEED = VerifaiRange(1.1, 1.4)
param SAFETY_DIST = VerifaiRange(8, 10)
param EGO_BRAKE = VerifaiRange(0.7, 1.0)
VEHICLE_SAFETY_DIST = 6

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance < 0 or endDistance > centerline.length:
        raise RejectionException('not enough lane for the pedestrian path')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)

param AGENT1_LAT_OFFSET = VerifaiRange(-0.2, 0.2)

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agentStaticRefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.AGENTSTATIC_DIST
agentStaticInitLane = network.laneSectionAt(agentStaticRefPt, reject="agentStatic reference not in a lane").laneToLeft.lane
agentStaticSpawnPt = new OrientedPoint at agentStaticInitLane.centerline.project(agentStaticRefPt.position), facing roadDirection

agent1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.AGENTSTATIC_DIST - 1.0)
agent1SpawnPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (globalParameters.AGENT1_LAT_OFFSET, 0, 0)

agent1EndPt = new OrientedPoint at agent1LongSpawnPt offset along roadDirection by (-2.5, 0, 0)

#################################
# AGENT BEHAVIORS               #
#################################

# The pedestrian initiates the movement; ego reacts to its proximity.
behavior EgoBehavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (distance from self to agent1) < globalParameters.SAFETY_DIST or (distance from self to agentStatic) < VEHICLE_SAFETY_DIST:
        while True:
            take SetBrakeAction(globalParameters.EGO_BRAKE)

behavior Agent1Behavior(endPt):
    while distance from self to endPt >= 0.5:
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

agent1 = new Pedestrian at agent1SpawnPt,
    facing toward agent1EndPt,
    with regionContainedIn road,
    with behavior Agent1Behavior(agent1EndPt)

agentStatic = new Car at agentStaticSpawnPt,
    with blueprint MODEL,
    with behavior AgentStaticBehavior()

#################################
# REQUIREMENTS                  #
#################################

# The moving pedestrian starts in the trafficway beside the stopped vehicle.
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require (distance from agent1EndPt to agentStatic) < 3.5
