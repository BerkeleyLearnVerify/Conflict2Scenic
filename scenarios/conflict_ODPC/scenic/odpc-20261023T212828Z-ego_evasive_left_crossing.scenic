#################################
# MAP AND MODEL                 #
#################################

# Selected Town04 for an inspected four-way junction with opposing single-lane approaches and both turns.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 9)
param AGENT1_SPEED = VerifaiRange(6, 8)
param DIVERSION_DIST = VerifaiRange(42, 45)
param REACTION_TIME = VerifaiRange(0.25, 0.45)
param RESPONSE_DIST = VerifaiRange(13, 16)
param AGENT1_BRAKE = VerifaiRange(0.7, 0.9)

#################################
# SPATIAL RELATIONS             #
#################################

# Physical coordinates locate inspected approach windows; no XML ID is used as a Scenic ID.
# Town04 source junction 1452: road 9, lane -1 at s=35 m; road 10, lane +1 at s=15 m.
egoAnchor = new OrientedPoint at Vector(176.30729, 169.65302)
agent1Anchor = new OrientedPoint at Vector(225.59641, 172.87253)

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1InitLane = Uniform(*filter(lambda m:
    m.type is ManeuverType.STRAIGHT,
    Uniform(*filter(lambda m:
        m.type is ManeuverType.STRAIGHT,
        egoInitLane.maneuvers)
    ).reverseManeuvers)
).startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline

egoManeuver = Uniform(*filter(lambda m: m.type is ManeuverType.LEFT_TURN, egoInitLane.maneuvers))
egoTrajectory = [egoInitLane, egoManeuver.connectingLane, egoManeuver.endLane]
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, agent1InitLane.maneuvers))
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]

#################################
# AGENT BEHAVIORS               #
#################################

# Chosen initiating circumstance: emergency diversion away from an abstracted surface hazard ahead.
# The hazard motivates ego's decision; it is not an additional modeled conflict partner.
behavior EgoBehavior(trajectory):
    take SetSpeedAction(globalParameters.EGO_SPEED)
    try:
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)
    interrupt when (distance from self to agent1) < globalParameters.DIVERSION_DIST:
        do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)

behavior Agent1Behavior(trajectory):
    take SetSpeedAction(globalParameters.AGENT1_SPEED)
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)
    interrupt when (network.laneAt(ego) is egoManeuver.connectingLane) or ((distance from self to ego) < globalParameters.RESPONSE_DIST):
        do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory) for globalParameters.REACTION_TIME seconds
        while True:
            take SetBrakeAction(globalParameters.AGENT1_BRAKE)

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

# The windows select the inspected opposing legal directions and keep both cars before the junction.
require (distance from egoSpawnPt to egoAnchor) < 3
require (distance from agent1SpawnPt to agent1Anchor) < 3
require agent1Maneuver in egoManeuver.conflictingManeuvers
