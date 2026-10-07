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
param AGENT1_SPEED = VerifaiRange(8, 10)
PREPARATION_TIME = 2

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group
param RESPONSE_DIST = VerifaiRange(25, 30)
param EGO_BYPASS_DIST = VerifaiRange(8, 12)

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

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
    egoManeuver.conflictingManeuvers)
).startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline
agent1InitSection = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane")
agent1TargetLane = agent1InitSection.laneToRight.lane
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, agent1TargetLane.maneuvers))
agent1Trajectory = [agent1TargetLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior(trajectory):
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)
    interrupt when (agent1.laneSection.lane is not agent1InitLane) and (distance from self to agent1) < globalParameters.RESPONSE_DIST and (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.EGO_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.EGO_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

behavior Agent1Behavior(trajectory):
    # The prior circumstance is a completed evasive lane change on the approach.
    do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for PREPARATION_TIME seconds
    do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToRight, target_speed=globalParameters.AGENT1_SPEED)
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

require hasSameDirectionAdjacentLane(agent1.laneSection, 'right')
require agent1TargetLane in intersection.incomingLanes
require agent1Maneuver in egoManeuver.conflictingManeuvers
require agent1Maneuver not in egoManeuver.reverseManeuvers
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')

