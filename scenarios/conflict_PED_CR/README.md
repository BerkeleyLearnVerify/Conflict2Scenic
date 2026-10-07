# Pedestrian Crossing Road

This conflict group involves an actor traveling along a trafficway interacting with a pedestrian crossing that trafficway without traveling along or onto another trafficway.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Right crossing brake](scenic/ped_cr-20261006T191110Z-right_crossing_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses right to left in front of approaching `ego`; `ego` brakes. | [MP4](visualizations/ped_cr-20261006T191110Z-right_crossing_brake.mp4) |
| [Left crossing continue](scenic/ped_cr-20261006T191110Z-left_crossing_continue.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses left to right in front of approaching `ego`; `ego` continues following the lane. | [MP4](visualizations/ped_cr-20261006T191110Z-left_crossing_continue.mp4) |
| [Paused in lane stop](scenic/ped_cr-20261006T191110Z-paused_in_lane_stop.scenic) | `agent1` | `ego` | Pedestrian `agent1` resumes a paused right-to-left crossing within the lane as `ego` approaches; `ego` stops. | [MP4](visualizations/ped_cr-20261006T191110Z-paused_in_lane_stop.mp4) |
| [Right diagonal brake](scenic/ped_cr-20261006T191110Z-right_diagonal_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses diagonally from the right toward the left and approaching `ego`; `ego` brakes. | [MP4](visualizations/ped_cr-20261006T191110Z-right_diagonal_brake.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
