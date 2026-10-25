#################################
# MAP AND MODEL                 #
#################################

# Selected Town04: junction 1452 supplies single-lane lateral straight/left crossings with 36-72 m approaches.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 8)
param AGENT1_SPEED = VerifaiRange(5, 6)
MIN_APPROACH = 12
MAX_APPROACH = 24
MIN_ARRIVAL_LEAD = 0.1
MAX_ARRIVAL_LEAD = 0.45

from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def crossingGeometry(egoLane, egoTurn, egoStart, otherLane, otherTurn, otherStart):
    egoLine = egoTurn.connectingLane.centerline.lineString
    otherLine = otherTurn.connectingLane.centerline.lineString
    if not egoLine.crosses(otherLine):
        raise RejectionException('connecting paths must cross inside the junction')
    crossing = egoLine.intersection(otherLine)
    if crossing.geom_type != 'Point':
        raise RejectionException('one distinct interior crossing is required')
    egoApproach = egoLane.centerline.lineString
    otherApproach = otherLane.centerline.lineString
    egoRemaining = egoApproach.length - egoApproach.project(ShapelyPoint(egoStart.x, egoStart.y))
    otherRemaining = otherApproach.length - otherApproach.project(ShapelyPoint(otherStart.x, otherStart.y))
    e0 = egoApproach.interpolate(max(0, egoApproach.length - 1))
    e1 = egoApproach.interpolate(egoApproach.length)
    o0 = otherApproach.interpolate(max(0, otherApproach.length - 1))
    o1 = otherApproach.interpolate(otherApproach.length)
    ex, ey = e1.x - e0.x, e1.y - e0.y
    ox, oy = o1.x - o0.x, o1.y - o0.y
    norm = ((ex * ex + ey * ey) * (ox * ox + oy * oy)) ** 0.5
    if norm == 0 or abs(ex * ox + ey * oy) >= 0.5 * norm:
        raise RejectionException('approaches must be lateral, rather than parallel or opposing')
    side = (ex * oy - ey * ox) / norm
    return (egoRemaining, otherRemaining,
            egoRemaining + egoLine.project(crossing),
            otherRemaining + otherLine.project(crossing), side)

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, egoInitLane.maneuvers))

# Bind the responder's actual maneuver to the initiator's selected crossing path.
agent1Maneuver = Uniform(*filter(lambda m:
    m.type is ManeuverType.LEFT_TURN,
    egoManeuver.conflictingManeuvers))
agent1InitLane = agent1Maneuver.startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline

egoTrajectory = [egoInitLane, egoManeuver.connectingLane, egoManeuver.endLane]
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]
crossingData = crossingGeometry(egoInitLane, egoManeuver, egoSpawnPt.position,
    agent1InitLane, agent1Maneuver, agent1SpawnPt.position)
arrivalLead = crossingData[3] / globalParameters.AGENT1_SPEED - crossingData[2] / globalParameters.EGO_SPEED

#################################
# AGENT BEHAVIORS               #
#################################

# Ego creates the conflict by entering its crossing path without yielding.
behavior EgoBehavior(trajectory):
    do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)

# Agent1's response policy is to continue the committed turn.
behavior Agent1Behavior(trajectory):
    do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with speed globalParameters.EGO_SPEED,
    with behavior EgoBehavior(egoTrajectory)

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with speed globalParameters.AGENT1_SPEED,
    with behavior Agent1Behavior(agent1Trajectory)

#################################
# REQUIREMENTS                  #
#################################

require agent1InitLane in intersection.incomingLanes
require agent1InitLane is not egoInitLane
require crossingData[0] >= MIN_APPROACH
require crossingData[0] <= MAX_APPROACH
require crossingData[1] >= MIN_APPROACH
require crossingData[1] <= MAX_APPROACH
# The signed approach tangent distinguishes traffic from ego's right.
require crossingData[4] > 0.5
require arrivalLead >= MIN_ARRIVAL_LEAD
require arrivalLead <= MAX_ARRIVAL_LEAD
