# Front To Rear

This conflict group involves one road user interacting with another road user in the same direction and same travel lane.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Lead brakes](scenic/f2r-20260930T012108Z-lead_brakes.scenic) | `agent1` | `ego` | `agent1` brakes ahead in the same lane; following `ego` brakes when the gap becomes short. | [MP4](visualizations/f2r-20260930T012108Z-lead_brakes.mp4) |
| [Lead stops at intersection](scenic/f2r-20260930T012108Z-lead_stops_intersection.scenic) | `agent1` | `ego` | `agent1` stops ahead as both cars approach an intersection; `ego` continues following the same lane. | [MP4](visualizations/f2r-20260930T012108Z-lead_stops_intersection.mp4) |
| [Trailing car accelerates](scenic/f2r-20260930T012108Z-trailing_accelerates.scenic) | `agent1` | `ego` | `agent1` accelerates from behind in the same lane; `ego` accelerates when the gap becomes short. | [MP4](visualizations/f2r-20260930T012108Z-trailing_accelerates.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
