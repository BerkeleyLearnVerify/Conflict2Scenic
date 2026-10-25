# Turn Into Path Opposite Direction

This conflict group occurs when one roadway actor changes vehicle-operated trafficways through a turning maneuver and interacts with another roadway actor, with one of the actors operating opposite to the trafficway's intended direction of travel.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Left turn with wrong-way approach](scenic/tipod-20261001T012059Z-left_turn_wrong_way_approach.scenic) | `agent1` | `ego` | `agent1` turns left into a lane where `ego` approaches against the intended travel direction; `ego` continues under throttle. | [MP4](visualizations/tipod-20261001T012059Z-left_turn_wrong_way_approach.mp4) |
| [Left turn with wrong-way stop](scenic/tipod-20261001T012059Z-left_turn_wrong_way_stop.scenic) | `agent1` | `ego` | `agent1` turns left into a lane where `ego` travels against the intended direction; `ego` stops when the turning car comes close, obstructing the turn exit. | [MP4](visualizations/tipod-20261001T012059Z-left_turn_wrong_way_stop.mp4) |
| [Right turn with wrong-way braking](scenic/tipod-20261001T012059Z-right_turn_wrong_way_braking.scenic) | `agent1` | `ego` | `agent1` turns right into a lane where `ego` approaches against the intended travel direction; `ego` brakes when the turning car comes close. | [MP4](visualizations/tipod-20261001T012059Z-right_turn_wrong_way_braking.mp4) |
| [Ego left turn meets backing car](scenic/tipod-20261023T220245Z-left_turn_meets_backing_car.scenic) | `ego` | `agent1` | `ego` turns left into an exit lane where `agent1` is backing toward the junction while facing the intended lane direction; `agent1` brakes as ego commits and comes close, with an emergency brake available to ego at a smaller gap. | [MP4](visualizations/tipod-20261023T220245Z-left_turn_meets_backing_car.mp4) |
| [Ego left turn meets wrong-way driver](scenic/tipod-20261023T220245Z-left_turn_meets_wrong_way_driver.scenic) | `ego` | `agent1` | `ego` turns left into an exit lane where `agent1` is driving toward the junction against the intended direction; `agent1` brakes as ego commits and comes close, with an emergency brake available to ego at a smaller gap. | [MP4](visualizations/tipod-20261023T220245Z-left_turn_meets_wrong_way_driver.mp4) |
| [Ego right turn meets backing car](scenic/tipod-20261023T220245Z-right_turn_meets_backing_car.scenic) | `ego` | `agent1` | `ego` turns right into an exit lane where `agent1` is backing toward the junction while facing the intended lane direction; `agent1` brakes as ego commits and comes close, with an emergency brake available to ego at a smaller gap. | [MP4](visualizations/tipod-20261023T220245Z-right_turn_meets_backing_car.mp4) |
| [Ego right turn meets wrong-way driver](scenic/tipod-20261023T220245Z-right_turn_meets_wrong_way_driver.scenic) | `ego` | `agent1` | `ego` turns right into an exit lane where `agent1` is driving toward the junction against the intended direction; `agent1` brakes as ego commits and comes close, with an emergency brake available to ego at a smaller gap. | [MP4](visualizations/tipod-20261023T220245Z-right_turn_meets_wrong_way_driver.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
