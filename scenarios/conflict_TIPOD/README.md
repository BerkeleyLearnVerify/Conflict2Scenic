# Turn Into Path Opposite Direction

This conflict group occurs when one roadway actor changes vehicle-operated trafficways through a turning maneuver and interacts with another roadway actor, with one of the actors operating opposite to the trafficway's intended direction of travel.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Left turn with wrong-way approach](scenic/tipod-20261001T012059Z-left_turn_wrong_way_approach.scenic) | `agent1` | `ego` | `agent1` turns left into a lane where `ego` approaches against the intended travel direction; `ego` continues under throttle. | [MP4](visualizations/tipod-20261001T012059Z-left_turn_wrong_way_approach.mp4) |
| [Left turn with wrong-way stop](scenic/tipod-20261001T012059Z-left_turn_wrong_way_stop.scenic) | `agent1` | `ego` | `agent1` turns left into a lane where `ego` travels against the intended direction; `ego` stops when the turning car comes close, obstructing the turn exit. | [MP4](visualizations/tipod-20261001T012059Z-left_turn_wrong_way_stop.mp4) |
| [Right turn with wrong-way braking](scenic/tipod-20261001T012059Z-right_turn_wrong_way_braking.scenic) | `agent1` | `ego` | `agent1` turns right into a lane where `ego` approaches against the intended travel direction; `ego` brakes when the turning car comes close. | [MP4](visualizations/tipod-20261001T012059Z-right_turn_wrong_way_braking.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
