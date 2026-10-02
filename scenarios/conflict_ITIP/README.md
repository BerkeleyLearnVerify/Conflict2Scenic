# Intersection Turn Into Path

This conflict group involves interactions that occur as a result of one of the actors moving on to a trafficway via a turning maneuver into the path of another actor that is operating in the trafficway being turned on to.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Left turn with ego braking](scenic/itip-20260930T013402Z-left_turn_ego_brakes.scenic) | `agent1` | `ego` | `agent1` turns left into the lane that `ego` is proceeding into; `ego` brakes when the turning car comes close. | [MP4](visualizations/itip-20260930T013402Z-left_turn_ego_brakes.mp4) |
| [Right turn with ego braking](scenic/itip-20260930T013402Z-right_turn_ego_brakes.scenic) | `agent1` | `ego` | `agent1` turns right into the lane that `ego` is proceeding into; `ego` brakes when the turning car comes close. | [MP4](visualizations/itip-20260930T013402Z-right_turn_ego_brakes.mp4) |
| [Right turn with ego continuing](scenic/itip-20260930T013402Z-right_turn_ego_continues.scenic) | `agent1` | `ego` | `agent1` turns right into the lane that `ego` is proceeding into; `ego` continues straight behind the slower turning car. | [MP4](visualizations/itip-20260930T013402Z-right_turn_ego_continues.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
