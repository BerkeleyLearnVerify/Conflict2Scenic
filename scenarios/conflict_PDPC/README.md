# Perpendicular Direction Prior Circumstances

This conflict group occurs when two roadway actors operating on crossing roadways interact after at least one actor has performed a lateral evasive action, lost control, or experienced a prior collision.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Left evasion cross brake](scenic/pdpc-20261005T185227Z-left_evasion_cross_brake.scenic) | `agent1` | `ego` | `agent1` evades left on a lateral approach, then crosses the intersection; `ego` brakes. | [MP4](visualizations/pdpc-20261005T185227Z-left_evasion_cross_brake.mp4) |
| [Left evasion stop in crossing](scenic/pdpc-20261005T185227Z-left_evasion_stop_in_crossing.scenic) | `agent1` | `ego` | `agent1` evades left on a lateral approach, then stops in the crossing; `ego` continues straight. | [MP4](visualizations/pdpc-20261005T185227Z-left_evasion_stop_in_crossing.mp4) |
| [Right evasion cross counter evasion](scenic/pdpc-20261005T185227Z-right_evasion_cross_counter_evasion.scenic) | `agent1` | `ego` | `agent1` evades right on a lateral approach, then crosses the intersection; `ego` responds by changing lanes left. | [MP4](visualizations/pdpc-20261005T185227Z-right_evasion_cross_counter_evasion.mp4) |
| [Left escape before crossing with braking](scenic/pdpc-20261023T213516Z-left_escape_crossing_brake.scenic) | `ego` | `agent1` | `ego` makes an evasive left lane change before proceeding straight into an intersection; `agent1` approaches straight on the perpendicular roadway and brakes in response. | [MP4](visualizations/pdpc-20261023T213516Z-left_escape_crossing_brake.mp4) |
| [Left escape before crossing a turning responder](scenic/pdpc-20261023T213516Z-left_escape_turning_responder.scenic) | `ego` | `agent1` | `ego` makes an evasive left lane change before proceeding straight into an intersection; `agent1` follows a conflicting left-turn route from the perpendicular roadway and brakes when ego comes close. | [MP4](visualizations/pdpc-20261023T213516Z-left_escape_turning_responder.mp4) |
| [Right escape with accelerating clearance](scenic/pdpc-20261023T213516Z-right_escape_accelerating_clearance.scenic) | `ego` | `agent1` | `ego` makes an evasive right lane change before proceeding straight into an intersection; `agent1` accelerates on its perpendicular straight route to clear the crossing. | [MP4](visualizations/pdpc-20261023T213516Z-right_escape_accelerating_clearance.mp4) |
| [Right escape with successive evasions](scenic/pdpc-20261023T213516Z-right_escape_successive_evasions.scenic) | `ego` | `agent1` | `ego` makes an evasive right lane change before proceeding straight into an intersection; `agent1` responds on the perpendicular approach by changing left, then follows a straight route that still crosses ego's path. | [MP4](visualizations/pdpc-20261023T213516Z-right_escape_successive_evasions.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
