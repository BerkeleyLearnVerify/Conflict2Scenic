# Backing

This conflict group includes interactions where at least one road user is moving in reverse.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Lead reverse brake](scenic/backing-20261007T003235Z-lead_reverse_brake.scenic) | `agent1` | `ego` | `agent1` reverses toward approaching `ego` from ahead in the same lane; `ego` brakes. | [MP4](visualizations/backing-20261007T003235Z-lead_reverse_brake.mp4) |
| [Rear reverse follow](scenic/backing-20261007T003235Z-rear_reverse_follow.scenic) | `agent1` | `ego` | `agent1` faces opposite the traffic direction and reverses toward `ego` from behind; `ego` continues following the lane. | [MP4](visualizations/backing-20261007T003235Z-rear_reverse_follow.mp4) |
| [Right reverse merge brake](scenic/backing-20261007T003235Z-right_reverse_merge_brake.scenic) | `agent1` | `ego` | `agent1` backs laterally from the right lane into the path of approaching `ego`; `ego` brakes. | [MP4](visualizations/backing-20261007T003235Z-right_reverse_merge_brake.mp4) |
| [Pedestrian crossing reverse brake](scenic/backing-20261007T003235Z-pedestrian_crossing_reverse_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses right to left behind reversing `ego`; `ego` brakes as the pedestrian enters its path. | [MP4](visualizations/backing-20261007T003235Z-pedestrian_crossing_reverse_brake.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
