# Front To Rear

This conflict group involves one road user interacting with another road user in the same direction and same travel lane.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Lead brakes](scenic/f2r-20260930T012108Z-lead_brakes.scenic) | `agent1` | `ego` | `agent1` brakes ahead in the same lane; following `ego` brakes when the gap becomes short. | [MP4](visualizations/f2r-20260930T012108Z-lead_brakes.mp4) |
| [Lead stops at intersection](scenic/f2r-20260930T012108Z-lead_stops_intersection.scenic) | `agent1` | `ego` | `agent1` stops ahead as both cars approach an intersection; `ego` continues following the same lane. | [MP4](visualizations/f2r-20260930T012108Z-lead_stops_intersection.mp4) |
| [Trailing car accelerates](scenic/f2r-20260930T012108Z-trailing_accelerates.scenic) | `agent1` | `ego` | `agent1` accelerates from behind in the same lane; `ego` accelerates when the gap becomes short. | [MP4](visualizations/f2r-20260930T012108Z-trailing_accelerates.mp4) |
| [Lead brake pulse](scenic/f2r-20261023T191645Z-lead_brake_pulse.scenic) | `ego` | `agent1` | Leading `ego` briefly brakes, then resumes cruising in the same lane; following `agent1` reacts with a delayed brake pulse before resuming its cruise. | [MP4](visualizations/f2r-20261023T191645Z-lead_brake_pulse.mp4) |
| [Lead full stop](scenic/f2r-20261023T191645Z-lead_full_stop.scenic) | `ego` | `agent1` | Leading `ego` abruptly stops and remains in the lane; following `agent1` brakes after a reaction delay and then holds stopped. | [MP4](visualizations/f2r-20261023T191645Z-lead_full_stop.mp4) |
| [Lead right-turn slowdown](scenic/f2r-20261023T191645Z-lead_right_turn_slowdown.scenic) | `ego` | `agent1` | Leading `ego` slows for a right turn at an intersection; `agent1` follows the same turn path and reduces its target speed as the gap closes. | [MP4](visualizations/f2r-20261023T191645Z-lead_right_turn_slowdown.mp4) |
| [Rear acceleration toward leader](scenic/f2r-20261023T191645Z-rear_acceleration.scenic) | `ego` | `agent1` | Following `ego` accelerates toward `agent1` ahead in the same lane; the leading responder maintains its lane and original target speed. | [MP4](visualizations/f2r-20261023T191645Z-rear_acceleration.mp4) |
| [Rear late braking](scenic/f2r-20261023T191645Z-rear_late_braking.scenic) | `ego` | `agent1` | Faster `ego` closes on slower `agent1` in the same lane, delays braking until the gap is short, then targets the leader's speed; `agent1` maintains its lane and speed. | [MP4](visualizations/f2r-20261023T191645Z-rear_late_braking.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
