# Perpendicular Direction Prior Circumstances

This conflict group occurs when two roadway actors operating on crossing roadways interact after at least one actor has performed a lateral evasive action, lost control, or experienced a prior collision.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Left evasion cross brake](scenic/pdpc-20261005T185227Z-left_evasion_cross_brake.scenic) | `agent1` | `ego` | `agent1` evades left on a lateral approach, then crosses the intersection; `ego` brakes. | [MP4](visualizations/pdpc-20261005T185227Z-left_evasion_cross_brake.mp4) |
| [Left evasion stop in crossing](scenic/pdpc-20261005T185227Z-left_evasion_stop_in_crossing.scenic) | `agent1` | `ego` | `agent1` evades left on a lateral approach, then stops in the crossing; `ego` continues straight. | [MP4](visualizations/pdpc-20261005T185227Z-left_evasion_stop_in_crossing.mp4) |
| [Right evasion cross counter evasion](scenic/pdpc-20261005T185227Z-right_evasion_cross_counter_evasion.scenic) | `agent1` | `ego` | `agent1` evades right on a lateral approach, then crosses the intersection; `ego` responds by changing lanes left. | [MP4](visualizations/pdpc-20261005T185227Z-right_evasion_cross_counter_evasion.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
