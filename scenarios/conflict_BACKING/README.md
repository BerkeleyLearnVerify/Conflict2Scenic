# Backing

This conflict group includes interactions where at least one road user is moving in reverse.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Lead reverse brake](scenic/backing-20261007T003235Z-lead_reverse_brake.scenic) | `agent1` | `ego` | `agent1` reverses toward approaching `ego` from ahead in the same lane; `ego` brakes. | [MP4](visualizations/backing-20261007T003235Z-lead_reverse_brake.mp4) |
| [Rear reverse follow](scenic/backing-20261007T003235Z-rear_reverse_follow.scenic) | `agent1` | `ego` | `agent1` faces opposite the traffic direction and reverses toward `ego` from behind; `ego` continues following the lane. | [MP4](visualizations/backing-20261007T003235Z-rear_reverse_follow.mp4) |
| [Right reverse merge brake](scenic/backing-20261007T003235Z-right_reverse_merge_brake.scenic) | `agent1` | `ego` | `agent1` backs laterally from the right lane into the path of approaching `ego`; `ego` brakes. | [MP4](visualizations/backing-20261007T003235Z-right_reverse_merge_brake.mp4) |
| [Pedestrian crossing reverse brake](scenic/backing-20261007T003235Z-pedestrian_crossing_reverse_brake.scenic) | `agent1` | `ego` | Pedestrian `agent1` crosses right to left behind reversing `ego`; `ego` brakes as the pedestrian enters its path. | [MP4](visualizations/backing-20261007T003235Z-pedestrian_crossing_reverse_brake.mp4) |
| [Reverse across pedestrian path](scenic/backing-20261023T211145Z-reverse_across_pedestrian_path.scenic) | `ego` | `agent1` | `ego` reverses across the path of pedestrian `agent1`, who is already crossing behind it from right to left; the pedestrian stops when ego comes close. | [MP4](visualizations/backing-20261023T211145Z-reverse_across_pedestrian_path.mp4) |
| [Reverse into crossing traffic](scenic/backing-20261023T211145Z-reverse_into_crossing_traffic.scenic) | `ego` | `agent1` | `ego` faces against its approach lane and reverses into an intersection; `agent1` approaches straight on a crossing roadway and brakes after a reaction delay. | [MP4](visualizations/backing-20261023T211145Z-reverse_into_crossing_traffic.mp4) |
| [Reverse toward braking follower](scenic/backing-20261023T211145Z-reverse_toward_braking_follower.scenic) | `ego` | `agent1` | `ego` reverses toward `agent1`, which is approaching from behind in the same lane; the follower brakes after a reaction delay. | [MP4](visualizations/backing-20261023T211145Z-reverse_toward_braking_follower.mp4) |
| [Reverse toward standing pedestrian](scenic/backing-20261023T211145Z-reverse_toward_standing_pedestrian.scenic) | `ego` | `agent1` | `ego` reverses toward pedestrian `agent1` standing behind it in the travel lane; the pedestrian remains stationary. | [MP4](visualizations/backing-20261023T211145Z-reverse_toward_standing_pedestrian.mp4) |
| [Reverse toward stopped car](scenic/backing-20261023T211145Z-reverse_toward_stopped_car.scenic) | `ego` | `agent1` | `ego` reverses toward `agent1` stopped behind it in the same lane; the responder holds its position. | [MP4](visualizations/backing-20261023T211145Z-reverse_toward_stopped_car.mp4) |
| [Reverse with follower left evasion](scenic/backing-20261023T211145Z-reverse_with_follower_left_evasion.scenic) | `ego` | `agent1` | `ego` reverses toward an approaching follower in the same lane; `agent1` changes into a clear same-direction lane to its left. | [MP4](visualizations/backing-20261023T211145Z-reverse_with_follower_left_evasion.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
