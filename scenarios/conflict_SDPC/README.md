# Same Direction Prior Circumstances

This conflict group involves two roadway actors operating on the same trafficway in the same direction when one actor performs a lateral evasive action, loses control, or experiences a prior collision that results in an interaction with the other actor.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Front evasion brake](scenic/sdpc-20261005T191502Z-front_evasion_brake.scenic) | `agent1` | `ego` | `agent1` evades right from the left lane ahead into the lane of `ego`, which brakes. | [MP4](visualizations/sdpc-20261005T191502Z-front_evasion_brake.mp4) |
| [Front evasion escape left](scenic/sdpc-20261005T191502Z-front_evasion_escape_left.scenic) | `agent1` | `ego` | `agent1` evades left from the right lane ahead into the lane of `ego`, which escapes to the left lane. | [MP4](visualizations/sdpc-20261005T191502Z-front_evasion_escape_left.mp4) |
| [Rear evasion closing](scenic/sdpc-20261005T191502Z-rear_evasion_closing.scenic) | `agent1` | `ego` | Faster `agent1` approaches from behind in the right lane and evades left into the lane of `ego`, which continues following its lane. | [MP4](visualizations/sdpc-20261005T191502Z-rear_evasion_closing.mp4) |
| [Alongside evasion escape right](scenic/sdpc-20261005T191502Z-alongside_evasion_escape_right.scenic) | `agent1` | `ego` | Alongside `agent1` evades right from the left lane into the lane of `ego`, which escapes to the right lane. | [MP4](visualizations/sdpc-20261005T191502Z-alongside_evasion_escape_right.mp4) |
| [Late left evasion behind slower car](scenic/sdpc-20261023T215751Z-late_left_evasion_behind_slower_car.scenic) | `ego` | `agent1` | `ego` closes on slower `agent1` ahead in the same lane, then initiates a late left evasion into an empty adjacent lane; `agent1` maintains its lane and target speed. | [MP4](visualizations/sdpc-20261023T215751Z-late_left_evasion_behind_slower_car.mp4) |
| [Lead left evasion with follower escaping right](scenic/sdpc-20261023T215751Z-lead_left_evasion_follower_escapes_right.scenic) | `ego` | `agent1` | Leading `ego` initiates a left evasion from the middle lane; faster `agent1` following in the same lane responds by escaping into the clear lane to its right. | [MP4](visualizations/sdpc-20261023T215751Z-lead_left_evasion_follower_escapes_right.mp4) |
| [Left evasion ahead of faster car](scenic/sdpc-20261023T215751Z-left_evasion_ahead_of_faster_car.scenic) | `ego` | `agent1` | `ego` initiates a left evasion into the path of faster `agent1` approaching from behind in the target lane; `agent1` brakes after detecting the incursion and a reaction delay. | [MP4](visualizations/sdpc-20261023T215751Z-left_evasion_ahead_of_faster_car.mp4) |
| [Left evasion with adjacent car escaping left](scenic/sdpc-20261023T215751Z-left_evasion_beside_car_escape_left.scenic) | `ego` | `agent1` | `ego` initiates a left evasion toward approximately abreast `agent1` in the adjacent lane; `agent1` responds by escaping into a clear third lane farther left. | [MP4](visualizations/sdpc-20261023T215751Z-left_evasion_beside_car_escape_left.mp4) |
| [Right evasion toward leading car](scenic/sdpc-20261023T215751Z-right_evasion_toward_leading_car.scenic) | `ego` | `agent1` | `ego` initiates a right evasion toward the rear quarter of slower `agent1` ahead in the target lane; `agent1` maintains its lane and target speed. | [MP4](visualizations/sdpc-20261023T215751Z-right_evasion_toward_leading_car.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
