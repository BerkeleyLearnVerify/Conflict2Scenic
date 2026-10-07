# Same Direction Prior Circumstances

This conflict group involves two roadway actors operating on the same trafficway in the same direction when one actor performs a lateral evasive action, loses control, or experiences a prior collision that results in an interaction with the other actor.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Front evasion brake](scenic/sdpc-20261005T191502Z-front_evasion_brake.scenic) | `agent1` | `ego` | `agent1` evades right from the left lane ahead into the lane of `ego`, which brakes. | [MP4](visualizations/sdpc-20261005T191502Z-front_evasion_brake.mp4) |
| [Front evasion escape left](scenic/sdpc-20261005T191502Z-front_evasion_escape_left.scenic) | `agent1` | `ego` | `agent1` evades left from the right lane ahead into the lane of `ego`, which escapes to the left lane. | [MP4](visualizations/sdpc-20261005T191502Z-front_evasion_escape_left.mp4) |
| [Rear evasion closing](scenic/sdpc-20261005T191502Z-rear_evasion_closing.scenic) | `agent1` | `ego` | Faster `agent1` approaches from behind in the right lane and evades left into the lane of `ego`, which continues following its lane. | [MP4](visualizations/sdpc-20261005T191502Z-rear_evasion_closing.mp4) |
| [Alongside evasion escape right](scenic/sdpc-20261005T191502Z-alongside_evasion_escape_right.scenic) | `agent1` | `ego` | Alongside `agent1` evades right from the left lane into the lane of `ego`, which escapes to the right lane. | [MP4](visualizations/sdpc-20261005T191502Z-alongside_evasion_escape_right.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
