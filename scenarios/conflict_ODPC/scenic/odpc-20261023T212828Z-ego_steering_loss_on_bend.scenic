#################################
# MAP AND MODEL                 #
#################################

# Selected Town07 for an inspected undivided right-hand bend with opposing 3.2 m lanes and no median.
param map = localPath('../../../maps/Town07.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 9)
param EGO_THROTTLE = VerifaiRange(0.15, 0.25)
param AGENT1_SPEED = VerifaiRange(5, 7)
param RESPONSE_DIST = VerifaiRange(15, 18)
param REACTION_TIME = VerifaiRange(0.25, 0.45)
param AGENT1_BRAKE = VerifaiRange(0.7, 0.9)

#################################
# SPATIAL RELATIONS             #
#################################

# Source road 20 has directly adjoining driving lanes +1/-1 and constant width here.
# Ego uses +1 at s=143 m, decreasing s: the positive-curvature reference arc bends right in ego's travel direction.
# Agent1 uses -1 near s=111 m, increasing s, legally approaching the same bend.
# Coordinates identify physical lane locations without assuming a Scenic mapping of XML IDs.
egoAnchor = new OrientedPoint at Vector(56.49864, 140.39116)
agent1Anchor = new OrientedPoint at Vector(66.72898, 110.94339)

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

# On this non-intersection segment, locate the inspected opposing lane directly at its physical anchor.
agent1InitLane = network.laneSectionAt(agent1Anchor, reject="agent1 anchor outside the inspected opposing lane").lane
agent1SpawnPt = new OrientedPoint at agent1InitLane.centerline.project(agent1Anchor.position), facing roadDirection

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    # Steering control is unavailable from the start; no lane controller supplies steering.
    # At the default neutral steering, powered motion follows the initial tangent across the bend.
    take SetSpeedAction(globalParameters.EGO_SPEED)
    while True:
        take SetThrottleAction(globalParameters.EGO_THROTTLE)

behavior Agent1Behavior():
    take SetSpeedAction(globalParameters.AGENT1_SPEED)
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for globalParameters.REACTION_TIME seconds
        while True:
            take SetBrakeAction(globalParameters.AGENT1_BRAKE)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

# The narrow window selects ego's legal lane on the inspected arc, rather than another curve in the map.
require (distance from egoSpawnPt to egoAnchor) < 10
require (distance from agent1SpawnPt to agent1Anchor) < 10
require egoInitLane is not agent1InitLane
