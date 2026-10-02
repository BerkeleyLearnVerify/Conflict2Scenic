#################################
# MAP AND MODEL                 #
#################################

param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(5, 8)
param AGENT1_SPEED = VerifaiRange(8, 10)
param EGO_THROTTLE = VerifaiRange(0.2, 0.35)

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
agent1InitLane = Uniform(*intersection.incomingLanes)
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.LEFT_TURN, agent1InitLane.maneuvers))
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]

# Ego occupies the receiving trafficway, travelling back toward the turn.
egoInitLane = agent1Maneuver.endLane
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
turnConflictPt = new OrientedPoint in agent1Maneuver.connectingLane.centerline

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    # Ego continues into the turn exit against the intended lane direction.
    take SetSpeedAction(globalParameters.EGO_SPEED)
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

behavior Agent1Behavior(trajectory):
    # Agent1 creates the conflict by turning into the wrong-way ego's path.
    do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    facing egoSpawnPt.heading + 180 deg,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior(agent1Trajectory)

#################################
# REQUIREMENTS                  #
#################################

# Keep both partners near the selected turn, on distinct trafficways.
require egoInitLane is not agent1InitLane
require (distance from ego to agent1) > 12
require (distance from ego to agent1) < 55
require (distance from ego to turnConflictPt) > 25
require (distance from agent1 to turnConflictPt) < 15
