#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for three adjacent 3.5 m lanes and long straight portions supporting rightward evasion.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(3, 4)
param EGO_THROTTLE = VerifaiRange(0.25, 0.4)
param AGENT1_SPEED = VerifaiRange(5, 6)
param AGENT1_DIST = VerifaiRange(40, 45)
param RESPONSE_DIST = VerifaiRange(34, 38)
param REACTION_TIME = VerifaiRange(0.2, 0.4)
param AGENT1_BYPASS_DIST = VerifaiRange(8, 10)
param MOTION_WINDOW = 6

from math import hypot
from shapely.geometry import Point as ShapelyPoint
from shapely.ops import substring
from scenic.core.distributions import distributionFunction
from scenic.core.regions import PolylineRegion

@distributionFunction
def hasStraightCorridor(lane, start, behind, ahead):
    line = lane.centerline.lineString
    center = line.project(ShapelyPoint(start.x, start.y))
    lo = center - behind
    hi = center + ahead
    if lo < 0 or hi > line.length:
        return False
    first = line.interpolate(lo)
    last = line.interpolate(hi)
    chord = first.distance(last)
    if chord < hi - lo - 0.001:
        return False
    dx = last.x - first.x
    dy = last.y - first.y
    for index in range(int(hi - lo) + 2):
        point = line.interpolate(min(lo + index, hi))
        offset = abs(dx * (point.y - first.y) - dy * (point.x - first.x)) / chord
        if offset > 0.05:
            return False
    return True

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

def straightIntervals(line):
    intervals = []
    start = 0
    distance = 0
    direction = None
    coordinates = list(line.coords)
    for first, last in zip(coordinates, coordinates[1:]):
        dx, dy = last[0] - first[0], last[1] - first[1]
        length = hypot(dx, dy)
        if length == 0:
            continue
        current = (dx / length, dy / length)
        if direction is not None:
            cross = direction[0] * current[1] - direction[1] * current[0]
            dot = direction[0] * current[0] + direction[1] * current[1]
            if abs(cross) > 0.000001 or dot <= 0:
                intervals.append((start, distance))
                start = distance
        direction = current
        distance += length
    intervals.append((start, distance))
    return intervals

def compatibleSpawnRegions(roadNetwork):
    candidates = []
    for lane in roadNetwork.lanes:
        if not any(
            hasSameDirectionAdjacentLane(section, 'left') and
            hasSameDirectionAdjacentLane(section, 'right')
            for section in lane.sections
        ):
            continue
        line = lane.centerline.lineString
        for start, end in straightIntervals(line):
            # Ego needs 90 m behind. Agent1's 70 m forward corridor extends
            # up to 30 m ahead of ego with the full 40-45 m initial gap.
            lo, hi = start + 90 + 0.1, end - 30 - 0.1
            if hi > lo:
                candidates.append((lane, PolylineRegion(polyline=substring(line, lo, hi))))
    if not candidates:
        raise ValueError('No middle-lane straight corridor supports this scenario')
    return candidates

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

# Choose usable straight portions before sampling; requirements below still
# validate the actual lane sections and the parallel escape corridor.
spawnChoice = Uniform(*compatibleSpawnRegions(network))
egoInitLane = spawnChoice[0]
egoSpawnPt = new OrientedPoint in spawnChoice[1]

# Ego faces against roadDirection, so agent1 is physically ahead at a negative lane offset.
agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitSection = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane")
agent1InitLane = agent1InitSection.lane
agent1EscapeLane = agent1InitSection.laneToRight.lane
agent1EscapePt = new OrientedPoint at agent1EscapeLane.centerline.project(agent1SpawnPt.position), facing roadDirection

#################################
# AGENT BEHAVIORS               #
#################################

behavior WrongWayMotion():
    while True:
        if self.speed < globalParameters.EGO_SPEED:
            take SetThrottleAction(globalParameters.EGO_THROTTLE)
        else:
            take SetThrottleAction(0)

behavior EgoBehavior():
    do WrongWayMotion() for globalParameters.MOTION_WINDOW seconds
    while True:
        take SetBrakeAction(1)

behavior EvasiveMotion():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (distance from self to ego) < globalParameters.RESPONSE_DIST:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for globalParameters.REACTION_TIME seconds
        try:
            do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
        interrupt when (self.laneSection._laneToRight is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToRight.lane, globalParameters.AGENT1_BYPASS_DIST):
            do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToRight, target_speed=globalParameters.AGENT1_SPEED)
            do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)

behavior Agent1Behavior():
    do EvasiveMotion() for globalParameters.MOTION_WINDOW seconds
    while True:
        take SetBrakeAction(1)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    facing egoSpawnPt.heading + 180 deg,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior()

#################################
# REQUIREMENTS                  #
#################################

require agent1InitLane is egoInitLane
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
require hasSameDirectionAdjacentLane(ego.laneSection, 'right')
require hasSameDirectionAdjacentLane(agent1.laneSection, 'right')
require hasStraightCorridor(egoInitLane, egoSpawnPt.position, 90, 20)
require hasStraightCorridor(agent1InitLane, agent1SpawnPt.position, 15, 70)
require hasStraightCorridor(agent1EscapeLane, agent1EscapePt.position, 15, 70)
