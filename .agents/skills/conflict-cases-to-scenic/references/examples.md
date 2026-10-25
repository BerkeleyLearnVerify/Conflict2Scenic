# General Scenic generation examples

These examples show how to translate resolved-realization JSON into complete Scenic programs after the input group property and resolved realization have supplied the interaction constraints, positions, maneuvers, road conditions, and role-specific behavior. They are syntax examples shared by all conflict groups. Do not infer a conflict group's semantics from them.

Resolved-realization JSON is an intermediate representation, not an additional field in the user's conflict-case input. Its complete schema is defined in [the input and output contract](conflict-case-contract.md).

Follow [map selection](map-selection.md) for each realization. The examples assume programs are written to `scenarios/conflict_<ID>/scenic/`; recompute map paths for other output directories. Example 1 selects Town05 for sustained same-direction adjacent lanes. Example 2 selects Town04 for its four-approach junction candidates. Neither map is a fixed default.

## Example 1: lane-relative placement and lane change

Resolved realization:

```json
{
  "agents": {
    "agent1": {
      "type": "car",
      "maneuver": "lane_change_left",
      "position": "behind_ego",
      "order": 1
    }
  },
  "road": {
    "intersection": "no",
    "left_lane_exists": "yes",
    "right_lane_exists": "no"
  },
  "comments": "Ego follows its lane while agent1 approaches from behind and changes left."
}
```

Scenic program:

```scenic
#################################
# MAP AND MODEL                 #
#################################

# Selected Town05 for a same-direction lane to the left.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 10)
param AGENT1_DIST = VerifaiRange(8, 12)
param AGENT1_SPEED = VerifaiRange(7, 10)
param AGENT1_BYPASS_DIST = VerifaiRange(8, 12)

def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False

def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group

#################################
# SPATIAL RELATIONS             #
#################################

egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.AGENT1_DIST
agent1InitLane = network.laneSectionAt(agent1SpawnPt, reject="agent1 not in a lane").lane

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

behavior Agent1Behavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (self.laneSection._laneToLeft is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToLeft.lane, globalParameters.AGENT1_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToLeft, target_speed=globalParameters.AGENT1_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)

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

require hasSameDirectionAdjacentLane(agent1.laneSection, 'left')
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
```

## Example 2: conflicting lane at an intersection

Resolved realization:

```json
{
  "agents": {
    "agent1": {
      "type": "car",
      "maneuver": "passing_intersection",
      "position": "lateral_lane_at_intersection",
      "order": 1
    }
  },
  "road": {
    "intersection": "yes",
    "left_lane_exists": "no",
    "right_lane_exists": "no"
  },
  "comments": "Agent1 crosses on a conflicting lateral lane while ego approaches the intersection."
}
```

Scenic program:

```scenic
#################################
# MAP AND MODEL                 #
#################################

# Selected Town04 for four-approach junctions with crossing straight movements.
param map = localPath('../../../maps/Town04.xodr')
model scenic.simulators.metadrive.model

#################################
# CONSTANTS                     #
#################################

MODEL = 'vehicle.lincoln.mkz_2017'
param EGO_SPEED = VerifaiRange(7, 10)
param AGENT1_SPEED = VerifaiRange(7, 10)
param AGENT1_INIT_DIST = VerifaiRange(15, 20)

#################################
# SPATIAL RELATIONS             #
#################################

intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline

agent1InitLane = Uniform(*filter(lambda m:
      m.type is ManeuverType.STRAIGHT,
      Uniform(*filter(lambda m:
          m.type is ManeuverType.STRAIGHT,
          egoInitLane.maneuvers)
      ).conflictingManeuvers)
).startLane
agent1SpawnPt = new OrientedPoint in agent1InitLane.centerline

#################################
# AGENT BEHAVIORS               #
#################################

behavior EgoBehavior():
    do FollowLaneBehavior(target_speed=globalParameters.EGO_SPEED)

agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.STRAIGHT, agent1InitLane.maneuvers))
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]
behavior Agent1Behavior(trajectory):
    do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)

#################################
# SCENARIO SPECIFICATION        #
#################################

ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()

agent1 = new Car at agent1SpawnPt,
    with blueprint MODEL,
    with behavior Agent1Behavior(agent1Trajectory)

#################################
# REQUIREMENTS                  #
#################################

```

For a concrete conflict case, keep this program structure and choose the position, maneuver, timing, parameters, and requirements from the relevant conflict-group guidance. If ego is the initiator, include the optional top-level `ego` object in the resolved-realization JSON and assign that initiating behavior to `ego`; do not preserve the example's passive ego behavior merely because it appears here.
