# Scenic generation guide

You are an expert in the Scenic programming language. Convert each concrete realization of a conflict case into valid Scenic code. A realization supplies the agents' types, maneuvers, positions, order, and road conditions chosen from the conflict-case constraints and input group property.

Use this guide and [the examples](examples.md) as the only Scenic syntax references. Do not inspect a local Scenic repository. Do not compile, sample, or simulate generated programs.

A Scenic program consists of these sections:

- `MAP AND MODEL`: map and driving model
- `CONSTANTS`: parameters and constants
- `SPATIAL RELATIONS`: initial positions and trajectories
- `AGENT BEHAVIORS`: agent behaviors
- `SCENARIO SPECIFICATION`: object instances and behaviors
- `REQUIREMENTS`: conditions required of the scenario

Follow the syntax below strictly. Use generally available normal behaviors: `FollowLaneBehavior`, `FollowTrajectoryBehavior`, and `LaneChangeBehavior`.

## Map and model

Choose the map using [map selection](map-selection.md), honoring explicit user choices and matching each realization against the eligible local maps. Preserve the user-supplied model or use `scenic.simulators.metadrive.model`. Map paths must resolve relative to the generated program's directory. For example, a program in `scenarios/conflict_<ID>/scenic/` whose realization matches Town05 uses:

```scenic
# Selected Town05 for same-direction adjacent lanes and roadside sidewalks.
param map = localPath('../../../maps/Town05.xodr')
model scenic.simulators.metadrive.model
```

This is an example selection, not a fixed default. Recompute the path for other output locations and include the selection rationale in a comment occupying at most one line in the generated Scenic program unless comments are forbidden. A capable map still requires the lane, maneuver, and spatial constraints below; do not assume every location in it satisfies the realization. Source XML IDs in the map-selection reference are inspection aids, not guaranteed Scenic IDs.

## Constants

Define all parameters and constants used by the scenario. Define constants with assignments, for example:

```scenic
MODEL = 'vehicle.lincoln.mkz_2017'
```

Define sampled continuous parameters using `param` and `VerifaiRange`:

```scenic
param EGO_SPEED = VerifaiRange(7, 10)
```

Refer to sampled parameters elsewhere as `globalParameters.EGO_SPEED`. Note that the lengths of the ranges must be non-zero. For example, `VerifaiRange(0.7, 0.7)` is invalid.

## Spatial relations

First determine whether the concrete realization involves an intersection. For an intersection realization, use:

```scenic
intersection = Uniform(*filter(lambda i: i.is4Way, network.intersections))
egoInitLane = Uniform(*intersection.incomingLanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
```

For a non-intersection realization, use:

```scenic
egoInitLane = Uniform(*network.lanes)
egoSpawnPt = new OrientedPoint in egoInitLane.centerline
```

Map each chosen position to the corresponding construction below. Replace `car1` and parameter names consistently with the actual partner ID. Whenever calling `network.laneSectionAt(point)`, always pass a reject message. For pedestrians, refer to the `Pedestrian` section.

### `in_front_of_ego`

```scenic
car1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.CAR1_DIST
car1InitLane = network.laneSectionAt(car1SpawnPt, reject="car1 not in a lane").lane
```

For multiple agents in front, use increasing positive, non-overlapping distance ranges according to their 1-based outward order; for example, order 1 can use `[8, 12]` and order 2 `[16, 20]`.

### `behind_ego`

```scenic
car1SpawnPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.CAR1_DIST
car1InitLane = network.laneSectionAt(car1SpawnPt, reject="car1 not in a lane").lane
```

For multiple agents behind, use increasing positive distance ranges according to their 1-based outward order.

### `left_front_of_ego`

```scenic
car1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.CAR1_DIST
car1InitLane = network.laneSectionAt(car1RefPt, reject="car1 not in a lane").laneToLeft.lane
car1SpawnPt = new OrientedPoint at car1InitLane.centerline.project(car1RefPt.position), facing roadDirection
```

Use a positive distance range. For multiple agents, increase ranges according to outward order.

### `left_of_ego`

```scenic
car1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.CAR1_OFFSET
car1InitLane = network.laneSectionAt(car1RefPt, reject="car1 not in a lane").laneToLeft.lane
car1SpawnPt = new OrientedPoint at car1InitLane.centerline.project(car1RefPt.position), facing roadDirection
```

Define `CAR1_OFFSET` with a small symmetric range, such as `param CAR1_OFFSET = VerifaiRange(-5, 5)`.

### `left_behind_of_ego`

```scenic
car1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.CAR1_DIST
car1InitLane = network.laneSectionAt(car1RefPt, reject="car1 not in a lane").laneToLeft.lane
car1SpawnPt = new OrientedPoint at car1InitLane.centerline.project(car1RefPt.position), facing roadDirection
```

Use a positive distance range. For multiple agents, increase ranges according to outward order.

### `right_front_of_ego`

```scenic
car1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.CAR1_DIST
car1InitLane = network.laneSectionAt(car1RefPt, reject="car1 not in a lane").laneToRight.lane
car1SpawnPt = new OrientedPoint at car1InitLane.centerline.project(car1RefPt.position), facing roadDirection
```

Use a positive distance range. For multiple agents, increase ranges according to outward order.

### `right_of_ego`

```scenic
car1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for globalParameters.CAR1_OFFSET
car1InitLane = network.laneSectionAt(car1RefPt, reject="car1 not in a lane").laneToRight.lane
car1SpawnPt = new OrientedPoint at car1InitLane.centerline.project(car1RefPt.position), facing roadDirection
```

Define `CAR1_OFFSET` with a small symmetric range, such as `param CAR1_OFFSET = VerifaiRange(-5, 5)`.

### `right_behind_of_ego`

```scenic
car1RefPt = new OrientedPoint following roadDirection from egoSpawnPt for -globalParameters.CAR1_DIST
car1InitLane = network.laneSectionAt(car1RefPt, reject="car1 not in a lane").laneToRight.lane
car1SpawnPt = new OrientedPoint at car1InitLane.centerline.project(car1RefPt.position), facing roadDirection
```

Use a positive distance range. For multiple agents, increase ranges according to outward order.

### `lateral_lane_at_intersection`

```scenic
car1InitLane = Uniform(*filter(lambda m:
      m.type is ManeuverType.STRAIGHT,
      Uniform(*filter(lambda m:
          m.type is ManeuverType.STRAIGHT,
          egoInitLane.maneuvers)
      ).conflictingManeuvers)
).startLane
car1SpawnPt = new OrientedPoint in car1InitLane.centerline
```

### `oncoming_lane`

```scenic
car1InitLane = Uniform(*filter(lambda m:
      m.type is ManeuverType.STRAIGHT,
      Uniform(*filter(lambda m:
          m.type is ManeuverType.STRAIGHT,
          egoInitLane.maneuvers)
      ).reverseManeuvers)
).startLane
car1SpawnPt = new OrientedPoint in car1InitLane.centerline
```

### Pedestrians

Pedestrians' spawm points are defined using offsets from ego's spawn point. For longitudinal offsets along the road direction, first define a helper function:

```scenic
from shapely.geometry import Point as ShapelyPoint
from scenic.core.distributions import distributionFunction, RejectionException

@distributionFunction
def pointAheadOnLane(lane, start, distance):
    centerline = lane.centerline.lineString
    startDistance = centerline.project(ShapelyPoint(start.x, start.y))
    endDistance = startDistance + distance
    if endDistance > centerline.length:
        raise RejectionException('not enough lane ahead for the crossing')
    point = centerline.interpolate(endDistance)
    return Vector(point.x, point.y)
```

Then, forward or backward longitudinal offsets along the road direction:

```scenic
ped1LongSpawnPt = new OrientedPoint at pointAheadOnLane(egoInitLane, egoSpawnPt.position, globalParameters.PED1_DIST)
```

Finally, apply lateral offsets:

```scenic
ped1SpawnPt = new OrientedPoint at ped1LongSpawnPt offset along roadDirection by (globalParameters.PED1_LAT_OFFSET, 0, 0)
```

Adjust the offset values according to the desired position in the realization.

## Agent behaviors

Define the behavior of every agent using the maneuver selected for the concrete realization. Apply these mappings to ego as well as other partners: conflict roles may require ego to brake, accelerate, change lanes, or perform another initiating or responding maneuver.

### Follow lane

```scenic
behavior Agent1Behavior():
    do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
```

### Left turn, right turn, or passing an intersection

```scenic
agent1Maneuver = Uniform(*filter(lambda m: m.type is ManeuverType.LEFT_TURN, agent1InitLane.maneuvers))
agent1Trajectory = [agent1InitLane, agent1Maneuver.connectingLane, agent1Maneuver.endLane]
behavior Agent1Behavior(trajectory):
    do FollowTrajectoryBehavior(target_speed=globalParameters.AGENT1_SPEED, trajectory=trajectory)
```

Replace `ManeuverType.LEFT_TURN` with `ManeuverType.RIGHT_TURN` or `ManeuverType.STRAIGHT` for right-turn or passing-intersection realizations. Do not add extra expressions to the lambda function.

### Change lane left or right

Define this helper once when a lane-change behavior is used:

```scenic
def withinDistanceToObjsInTargetLane(vehicle, targetLane, thresholdDistance):
    for obj in simulation().objects:
        if obj is vehicle:
            continue
        if network.laneAt(obj) is not targetLane:
            continue
        if (distance from vehicle to obj) < thresholdDistance:
            return True
    return False
```

For a right lane change:

```scenic
behavior Agent1Behavior():
    try:
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
    interrupt when (self.laneSection._laneToRight is not None) and not withinDistanceToObjsInTargetLane(self, self.laneSection._laneToRight.lane, globalParameters.AGENT1_BYPASS_DIST):
        do LaneChangeBehavior(laneSectionToSwitch=self.laneSection._laneToRight, target_speed=globalParameters.AGENT1_SPEED)
        do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED)
```

Replace `_laneToRight` with `_laneToLeft` throughout for a left lane change.

### Braking

```scenic
behavior Agent1Behavior():
    do FollowLaneBehavior(target_speed=globalParameters.AGENT1_SPEED) for 2 seconds
    take SetBrakeAction(globalParameters.AGENT1_BRAKE)
```

### Accelerating

```scenic
behavior Agent1Behavior():
    take SetThrottleAction(globalParameters.AGENT1_THROTTLE)
```

### Stopping

```scenic
behavior Agent1Behavior():
    take SetSpeedAction(0)
```

### Reversing

```scenic
behavior Agent1Behavior():
    take SetReverseAction(True)
    take SetThrottleAction(globalParameters.AGENT1_THROTTLE)
```

### Walking (for pedestrians)

Set a target point for the pedestrian to walk toward, for example:

```scenic
agent1EndPt = new OrientedPoint at agent1SpawnPt offset along roadDirection by (-5, 0, 0)
```

You may use the `pointAheadOnLane` function to help determine the target point. Then, the pedestrian will walk toward that point until it is reached, and then stop:

```scenic
behavior Agent1Behavior(endPt):
    while distance from self to endPt >= 0.5:
        take SetWalkingSpeedAction(globalParameters.AGENT1_SPEED)
    while True:
        take SetWalkingSpeedAction(0)
```

Finally, when instantiating the pedestrian, make the agent face toward the target point (see `Scenario specification` below).

### Standing

```scenic
behavior Agent1Behavior():
    take SetWalkingSpeedAction(0)
```

### Notes

Note 1. By default, the ego agent is a car with `FollowLaneBehavior`. If the realization requires ego to perform a different maneuver, define an `EgoBehavior` using the same mappings above. If ego performs a braking maneuver to avoid a collision with any object within a threshold distance, use a try-interrupt block to implement. For example,
```scenic
behavior EgoBehavior(trajectory):
    try:
        do FollowTrajectoryBehavior(target_speed=globalParameters.EGO_SPEED, trajectory=trajectory)
    interrupt when withinDistanceToAnyObjs(self, globalParameters.SAFETY_DIST):
        take SetBrakeAction(globalParameters.EGO_BRAKE)
```
`withinDistanceToAnyObjs` is a helper that already exists in Scenic.

Note 2. The `for X seconds` operator can only be used with `do Behavior()` statements. It cannot be used with `take Action()` statements.

Note 3. `laneToRight` and `laneToLeft` are properties of a lane section, not a lane. Use `self.laneSection._laneToRight.lane` or `self.laneSection._laneToLeft.lane` to access the adjacent lane.

## Scenario specification

Instantiate each partner with the class matching its type, spawn point, and behavior. For example:

```scenic
ego = new Car at egoSpawnPt,
    with blueprint MODEL,
    with behavior EgoBehavior()
```

Note 1. To create an agent facing the opposite direction of its lane, add `facing agent1SpawnPt.heading + 180 deg,` to the agent's construction. The specific number (e.g., `180 deg`) may vary depending on the agent's intended facing.

Note 2. For walking pedestrians, add `facing toward agent1EndPt,` to the pedestrian's construction so that it faces toward its target point:

```scenic
agent1 = new Pedestrian at agent1SpawnPt,
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)
```

Note 3. By default, a pedestrian is specified with `with regionContainedIn network.walkableRegion,` which restricts the pedestrian to walkable areas. If the pedestrian is spawned on a roadway, you must explicitly specify `with regionContainedIn road,` to allow the pedestrian to be spawned there:

```scenic
agent1 = new Pedestrian at agent1SpawnPt,
    with regionContainedIn road,
    facing toward agent1EndPt,
    with behavior Agent1Behavior(agent1EndPt)
```
This only corresponds to the pedestrian's initial spawn point. The pedestrian may later walk off the road. If the pedestrian is spawned on a sidewalk, no need to specify anything. If the pedestrian may be spawned on a sidewalk or road, you may specify `with regionContainedIn road.union(network.walkableRegion),` to allow both.

## Requirements

Define this helper once when an adjacent-lane requirement is needed:

```scenic
def hasSameDirectionAdjacentLane(laneSection, side):
    adj = laneSection._laneToLeft if side == 'left' else laneSection._laneToRight
    return adj is not None and adj.group is laneSection.group
```

For an agent changing right or left, require a same-direction adjacent lane on that side:

```scenic
require hasSameDirectionAdjacentLane(agent1.laneSection, 'right')
```

For a position left of ego (`left_of_ego`, `left_front_of_ego`, or `left_behind_of_ego`), require:

```scenic
require hasSameDirectionAdjacentLane(ego.laneSection, 'left')
```

Use the analogous right-side requirement for positions right of ego. Also add left/right lane-existence requirements selected as part of the concrete road realization. Do not add duplicate requirements. No need to require that a specific adjacent lane doesn't exist (e.g., no need to specify `require not hasSameDirectionAdjacentLane(ego.laneSection, 'left')`) unless it's essential to the conflict case.
