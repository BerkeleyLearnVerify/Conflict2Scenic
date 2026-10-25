# Intersection Turn Into Path

This conflict group involves interactions that occur as a result of one of the actors moving on to a trafficway via a turning maneuver into the path of another actor that is operating in the trafficway being turned on to.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Left turn with ego braking](scenic/itip-20260930T013402Z-left_turn_ego_brakes.scenic) | `agent1` | `ego` | `agent1` turns left into the lane that `ego` is proceeding into; `ego` brakes when the turning car comes close. | [MP4](visualizations/itip-20260930T013402Z-left_turn_ego_brakes.mp4) |
| [Right turn with ego braking](scenic/itip-20260930T013402Z-right_turn_ego_brakes.scenic) | `agent1` | `ego` | `agent1` turns right into the lane that `ego` is proceeding into; `ego` brakes when the turning car comes close. | [MP4](visualizations/itip-20260930T013402Z-right_turn_ego_brakes.mp4) |
| [Right turn with ego continuing](scenic/itip-20260930T013402Z-right_turn_ego_continues.scenic) | `agent1` | `ego` | `agent1` turns right into the lane that `ego` is proceeding into; `ego` continues straight behind the slower turning car. | [MP4](visualizations/itip-20260930T013402Z-right_turn_ego_continues.mp4) |
| [Left entry with responder braking](scenic/itip-20261023T211949Z-left_entry_with_responder_braking.scenic) | `ego` | `agent1` | `ego` turns left into the receiving lane used by through-moving `agent1`; `agent1` continues briefly after detecting the entry, then brakes. | [MP4](visualizations/itip-20261023T211949Z-left_entry_with_responder_braking.mp4) |
| [Left entry with right evasion](scenic/itip-20261023T211949Z-left_entry_with_right_evasion.scenic) | `ego` | `agent1` | `ego` turns left into the inner receiving lane ahead of through-moving `agent1`; once on that road, `agent1` evades into a clear same-direction lane to its right. | [MP4](visualizations/itip-20261023T211949Z-left_entry_with_right_evasion.mp4) |
| [Right entry ahead of through car](scenic/itip-20261023T211949Z-right_entry_ahead_of_through_car.scenic) | `ego` | `agent1` | `ego` turns right into the receiving lane just ahead of faster through-moving `agent1`; `agent1` continues on its planned straight route at its target speed. | [MP4](visualizations/itip-20261023T211949Z-right_entry_ahead_of_through_car.mp4) |
| [Right entry with left evasion](scenic/itip-20261023T211949Z-right_entry_with_left_evasion.scenic) | `ego` | `agent1` | `ego` turns right into the outer receiving lane ahead of through-moving `agent1`; once on that road, `agent1` evades into a clear same-direction lane to its left. | [MP4](visualizations/itip-20261023T211949Z-right_entry_with_left_evasion.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
