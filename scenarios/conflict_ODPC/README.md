# Opposite Direction Prior Circumstances

This conflict group involves two roadway actors traveling in opposite directions in their respective trafficways when one actor performs a lateral evasive action, loses control, or experiences a prior collision that results in an interaction with the other actor.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Lateral evasion](scenic/odpc-20261005T194712Z-lateral_evasion.scenic) | `agent1` | `ego` | Oncoming `agent1` evades left across the path of `ego`, which brakes. | [MP4](visualizations/odpc-20261005T194712Z-lateral_evasion.mp4) |
| [Loss of control acceleration](scenic/odpc-20261005T194712Z-loss_of_control_acceleration.scenic) | `agent1` | `ego` | Oncoming `agent1` accelerates along a prescribed leftward deflection representing loss of control; `ego` brakes after a response delay. | [MP4](visualizations/odpc-20261005T194712Z-loss_of_control_acceleration.mp4) |
| [Prior collision displacement](scenic/odpc-20261005T194712Z-prior_collision_displacement.scenic) | `agent1` | `ego` | Oncoming `agent1` follows a leftward deflection representing displacement from an assumed prior collision; `ego` commands a stop. | [MP4](visualizations/odpc-20261005T194712Z-prior_collision_displacement.mp4) |
| [Ego evasive left convergence](scenic/odpc-20261023T212828Z-ego_evasive_left_convergence.scenic) | `ego` | `agent1` | `ego` makes an emergency left diversion at a junction to avoid an abstracted road-surface hazard, converging with opposite-approach `agent1` turning right into the same exit lane; `agent1` brakes after a reaction delay. | [MP4](visualizations/odpc-20261023T212828Z-ego_evasive_left_convergence.mp4) |
| [Ego evasive left crossing](scenic/odpc-20261023T212828Z-ego_evasive_left_crossing.scenic) | `ego` | `agent1` | `ego` makes an emergency left diversion at a junction to avoid an abstracted road-surface hazard, crossing the straight path of oncoming `agent1`; `agent1` brakes after a reaction delay. | [MP4](visualizations/odpc-20261023T212828Z-ego_evasive_left_crossing.mp4) |
| [Ego evasive right convergence](scenic/odpc-20261023T212828Z-ego_evasive_right_convergence.scenic) | `ego` | `agent1` | `ego` makes an emergency right diversion at a junction to avoid an abstracted road-surface hazard, converging with opposite-approach `agent1` turning left into the same exit lane; `agent1` brakes after a reaction delay. | [MP4](visualizations/odpc-20261023T212828Z-ego_evasive_right_convergence.mp4) |
| [Ego steering loss on bend](scenic/odpc-20261023T212828Z-ego_steering_loss_on_bend.scenic) | `ego` | `agent1` | `ego` applies throttle along its initial tangent instead of steering around a right-hand bend, intruding toward the opposing lane; legally approaching `agent1` brakes after a reaction delay. | [MP4](visualizations/odpc-20261023T212828Z-ego_steering_loss_on_bend.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
