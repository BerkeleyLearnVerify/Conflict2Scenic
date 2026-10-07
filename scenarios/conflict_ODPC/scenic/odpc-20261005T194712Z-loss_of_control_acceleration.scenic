#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 9)
param SAFETY_DIST = VerifaiRange(16, 20)
param AGENT1_APPROACH_SPEED = VerifaiRange(5, 7)
param AGENT1_SPEED = VerifaiRange(11, 14)
param AGENT1_THROTTLE = VerifaiRange(0.5, 0.8)
param EGO_BRAKE = VerifaiRange(0.6, 0.9)

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, egoInitLane.maneuvers))
egoTrajectory = [egoInitLane, egoManeuver.connectingLane, egoManeuver.endLane]

agent1InitLane = Uniform(*filter(lambda m:
    m.type is ManeuverType.STRAIGHT,
    egoManeuver.reverseManeuvers)
).startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline

# This connector encodes the initiating deflection across the opposing path.
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.LEFT_TURN, agent1InitLane.maneuvers))
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior(trajectory):
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)
    interrupt when withinDistanceToAnyObjs(self, globalParameters.SAFETY_DIST):
        do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory) for 0.7 seconds
        take SetBrakeAction(globalParameters.EGO_BRAKE)

behavior Agent1Behavior(trajectory):
    # Acceleration with a prescribed loss-of-control deflection surrogate.
    do FollowLaneBehavior(target_speed=globalParameters.AGENT1_APPROACH_SPEED) for 5 seconds
    take SetThrottleAction(globalParameters.AGENT1_THROTTLE)
    do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior(egoTrajectory)

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior(agent1Trajectory)

#################################
# REQUIREMENTS                  #
#################################

# Opposing initial approaches and a deflection that crosses ego's straight route.
require agent1InitLane is not egoInitLane
require agent1Maneuver in egoManeuver.conflictingManeuvers
require (distance from ego to agent1) > 22
require (distance from ego to agent1) < 48
require not hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require not hasSameDirectionAdjacentLane(ego.laneSection, 'right')
