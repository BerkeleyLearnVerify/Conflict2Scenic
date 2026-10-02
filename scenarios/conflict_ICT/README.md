# Intersection Cross Traffic

This conflict group occurs when both roadway actors change or cross trafficways at an intersection and their paths cross one another.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Perpendicular straight](scenic/ict-20260930T010110Z-perpendicular_straight.scenic) | `agent1` | `ego` | Both cars proceed straight from conflicting lateral approaches. | [MP4](visualizations/ict-20260930T010110Z-perpendicular_straight.mp4) |
| [Oncoming left turn](scenic/ict-20260930T010110Z-oncoming_left_turn.scenic) | `agent1` | `ego` | `agent1` turns left across the path of oncoming `ego`, which proceeds straight. | [MP4](visualizations/ict-20260930T010110Z-oncoming_left_turn.mp4) |
| [Ego left turn](scenic/ict-20260930T010110Z-ego_left_turn.scenic) | `agent1` | `ego` | `ego` turns left across the path of oncoming `agent1`, which proceeds straight. | [MP4](visualizations/ict-20260930T010110Z-ego_left_turn.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
