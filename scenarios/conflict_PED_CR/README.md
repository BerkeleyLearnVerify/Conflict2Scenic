# Pedestrian Crossing Road

This conflict group involves an actor traveling along a trafficway interacting with a pedestrian crossing that trafficway without traveling along or onto another trafficway.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Right crossing brake](scenic/ped_cr-20261006T191110Z-right_crossing_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses right to left in front of approaching `ego`; `ego` brakes. | [MP4](visualizations/ped_cr-20261006T191110Z-right_crossing_brake.mp4) |
| [Left crossing continue](scenic/ped_cr-20261006T191110Z-left_crossing_continue.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses left to right in front of approaching `ego`; `ego` continues following the lane. | [MP4](visualizations/ped_cr-20261006T191110Z-left_crossing_continue.mp4) |
| [Paused in lane stop](scenic/ped_cr-20261006T191110Z-paused_in_lane_stop.scenic) | `agent1` | `ego` | Pedestrian `agent1` resumes a paused right-to-left crossing within the lane as `ego` approaches; `ego` stops. | [MP4](visualizations/ped_cr-20261006T191110Z-paused_in_lane_stop.mp4) |
| [Right diagonal brake](scenic/ped_cr-20261006T191110Z-right_diagonal_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses diagonally from the right toward the left and approaching `ego`; `ego` brakes. | [MP4](visualizations/ped_cr-20261006T191110Z-right_diagonal_brake.mp4) |
| [Acceleration toward far-side crossing](scenic/ped_cr-20261023T214105Z-far_side_acceleration_clearance.scenic) | `ego` | `agent1` | `ego` accelerates toward pedestrian `agent1`, who is already crossing from the opposite sidewalk toward the near side; the pedestrian speeds up to clear ego's lane. | [MP4](visualizations/ped_cr-20261023T214105Z-far_side_acceleration_clearance.mp4) |
| [Left turn with pedestrian clearance](scenic/ped_cr-20261023T214105Z-left_turn_crossing_clearance.scenic) | `ego` | `agent1` | `ego` commits to a left turn toward pedestrian `agent1` crossing the outgoing road from the far sidewalk; the pedestrian speeds up to clear the exit lane. | [MP4](visualizations/ped_cr-20261023T214105Z-left_turn_crossing_clearance.mp4) |
| [Acceleration toward near-side crossing](scenic/ped_cr-20261023T214105Z-near_side_acceleration_pause.scenic) | `ego` | `agent1` | `ego` accelerates toward pedestrian `agent1`, who is already crossing from the near sidewalk; the pedestrian pauses as ego approaches and resumes once it recedes. | [MP4](visualizations/ped_cr-20261023T214105Z-near_side_acceleration_pause.mp4) |
| [Right lane change with pedestrian clearance](scenic/ped_cr-20261023T214105Z-right_lane_change_crossing_clearance.scenic) | `ego` | `agent1` | `ego` changes right toward the path of pedestrian `agent1` crossing from the right sidewalk; the pedestrian speeds up to clear the vehicle's path. | [MP4](visualizations/ped_cr-20261023T214105Z-right_lane_change_crossing_clearance.mp4) |
| [Right turn with pedestrian pause](scenic/ped_cr-20261023T214105Z-right_turn_crossing_pause.scenic) | `ego` | `agent1` | `ego` turns right toward pedestrian `agent1` crossing the outgoing road from the right sidewalk; the pedestrian pauses once ego commits and resumes after ego moves away. | [MP4](visualizations/ped_cr-20261023T214105Z-right_turn_crossing_pause.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
