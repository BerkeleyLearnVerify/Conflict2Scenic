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
| [Close pass of standing road-edge pedestrian](scenic/ped_f-20261023T214400Z-close_pass_of_standing_road_edge_pedestrian.scenic) | `ego` | `agent1` | `ego` follows its lane closely past pedestrian `agent1` standing near the right edge of the driving lane, then brakes; the pedestrian remains stationary without crossing. | [MP4](visualizations/ped_f-20261023T214400Z-close_pass_of_standing_road_edge_pedestrian.mp4) |
| [Forward closure toward standing pedestrian](scenic/ped_f-20261023T214400Z-forward_closure_to_standing_pedestrian.scenic) | `ego` | `agent1` | `ego` advances toward pedestrian `agent1` standing near the lane center, then brakes as the gap closes; the pedestrian remains stationary. | [MP4](visualizations/ped_f-20261023T214400Z-forward_closure_to_standing_pedestrian.mp4) |
| [Launch toward standing pedestrian](scenic/ped_f-20261023T214400Z-launch_toward_standing_pedestrian.scenic) | `ego` | `agent1` | `ego` starts from rest and accelerates toward pedestrian `agent1` standing ahead near the lane center, then brakes as the gap closes; the pedestrian remains stationary. | [MP4](visualizations/ped_f-20261023T214400Z-launch_toward_standing_pedestrian.mp4) |
| [Left merge toward standing pedestrian](scenic/ped_f-20261023T214400Z-left_merge_toward_standing_pedestrian.scenic) | `ego` | `agent1` | `ego` changes left toward pedestrian `agent1` standing in the adjacent same-direction lane, then brakes as the gap closes; the pedestrian remains stationary. | [MP4](visualizations/ped_f-20261023T214400Z-left_merge_toward_standing_pedestrian.mp4) |
| [Right merge toward standing pedestrian](scenic/ped_f-20261023T214400Z-right_merge_toward_standing_pedestrian.scenic) | `ego` | `agent1` | `ego` changes right toward pedestrian `agent1` standing in the adjacent same-direction lane, then brakes as the gap closes; the pedestrian remains stationary. | [MP4](visualizations/ped_f-20261023T214400Z-right_merge_toward_standing_pedestrian.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
