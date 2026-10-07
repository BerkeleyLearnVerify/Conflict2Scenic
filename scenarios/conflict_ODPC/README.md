# Opposite Direction Prior Circumstances

This conflict group involves two roadway actors traveling in opposite directions in their respective trafficways when one actor performs a lateral evasive action, loses control, or experiences a prior collision that results in an interaction with the other actor.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Lateral evasion](scenic/odpc-20261005T194712Z-lateral_evasion.scenic) | `agent1` | `ego` | Oncoming `agent1` evades left across the path of `ego`, which brakes. | [MP4](visualizations/odpc-20261005T194712Z-lateral_evasion.mp4) |
| [Loss of control acceleration](scenic/odpc-20261005T194712Z-loss_of_control_acceleration.scenic) | `agent1` | `ego` | Oncoming `agent1` accelerates along a prescribed leftward deflection representing loss of control; `ego` brakes after a response delay. | [MP4](visualizations/odpc-20261005T194712Z-loss_of_control_acceleration.mp4) |
| [Prior collision displacement](scenic/odpc-20261005T194712Z-prior_collision_displacement.scenic) | `agent1` | `ego` | Oncoming `agent1` follows a leftward deflection representing displacement from an assumed prior collision; `ego` commands a stop. | [MP4](visualizations/odpc-20261005T194712Z-prior_collision_displacement.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
