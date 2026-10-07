# Pedestrian Forward

This conflict group involves a vehicle traveling forward interacting with a pedestrian within the trafficway who moves parallel to the roadway or remains stationary without attempting to cross.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Stationary ahead brake](scenic/ped_f-20261006T220707Z-stationary_ahead_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` stands in the lane center ahead of approaching `ego`; `ego` brakes after a reaction delay. | [MP4](visualizations/ped_f-20261006T220707Z-stationary_ahead_brake.mp4) |
| [Parallel ahead brake](scenic/ped_f-20261006T220707Z-parallel_ahead_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` walks ahead in the same direction at a lower speed; `ego` closes the gap and brakes. | [MP4](visualizations/ped_f-20261006T220707Z-parallel_ahead_brake.mp4) |
| [Opposing walk brake](scenic/ped_f-20261006T220707Z-opposing_walk_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` walks toward `ego` along the same lane; `ego` brakes as separation decreases. | [MP4](visualizations/ped_f-20261006T220707Z-opposing_walk_brake.mp4) |
| [Right edge walk left bypass](scenic/ped_f-20261006T220707Z-right_edge_walk_left_bypass.scenic) | `agent1` | `ego` | Pedestrian `agent1` walks slowly forward near the right side of the lane; `ego` changes lanes left to pass. | [MP4](visualizations/ped_f-20261006T220707Z-right_edge_walk_left_bypass.mp4) |
| [Left edge standing right bypass](scenic/ped_f-20261006T220707Z-left_edge_standing_right_bypass.scenic) | `agent1` | `ego` | Pedestrian `agent1` stands near the left side of the lane; `ego` changes lanes right to pass. | [MP4](visualizations/ped_f-20261006T220707Z-left_edge_standing_right_bypass.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
