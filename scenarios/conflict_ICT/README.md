# Intersection Cross Traffic

This conflict group occurs when both roadway actors change or cross trafficways at an intersection and their paths cross one another.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Perpendicular straight](scenic/ict-20260930T010110Z-perpendicular_straight.scenic) | `agent1` | `ego` | Both cars proceed straight from conflicting lateral approaches. | [MP4](visualizations/ict-20260930T010110Z-perpendicular_straight.mp4) |
| [Oncoming left turn](scenic/ict-20260930T010110Z-oncoming_left_turn.scenic) | `agent1` | `ego` | `agent1` turns left across the path of oncoming `ego`, which proceeds straight. | [MP4](visualizations/ict-20260930T010110Z-oncoming_left_turn.mp4) |
| [Ego left turn](scenic/ict-20260930T010110Z-ego_left_turn.scenic) | `agent1` | `ego` | `ego` turns left across the path of oncoming `agent1`, which proceeds straight. | [MP4](visualizations/ict-20260930T010110Z-ego_left_turn.mp4) |
| [Left turn across left-side turning traffic](scenic/ict-20261023T211728Z-left_turn_across_left_left_turn.scenic) | `ego` | `agent1` | `ego` turns left across the left-turn path of `agent1` approaching from the left; `agent1` brakes after a reaction delay, yields until ego clears, then resumes its turn. | [MP4](visualizations/ict-20261023T211728Z-left_turn_across_left_left_turn.mp4) |
| [Left turn across left-side through traffic](scenic/ict-20261023T211728Z-left_turn_across_left_traffic.scenic) | `ego` | `agent1` | `ego` turns left across the straight path of `agent1` approaching from the left; `agent1` brakes when ego enters the junction, then resumes its crossing after ego clears. | [MP4](visualizations/ict-20261023T211728Z-left_turn_across_left_traffic.mp4) |
| [Left turn across right-side turning traffic](scenic/ict-20261023T211728Z-left_turn_across_right_left_turn.scenic) | `ego` | `agent1` | `ego` turns left across the left-turn path of `agent1` approaching from the right; `agent1` continues its planned turn without an added evasive brake. | [MP4](visualizations/ict-20261023T211728Z-left_turn_across_right_left_turn.mp4) |
| [Straight across left-side through traffic](scenic/ict-20261023T211728Z-straight_across_left_traffic.scenic) | `ego` | `agent1` | `ego` crosses straight into the path of `agent1` approaching from the left; `agent1` brakes after a reaction delay, then resumes its straight crossing after ego clears. | [MP4](visualizations/ict-20261023T211728Z-straight_across_left_traffic.mp4) |
| [Straight across right-side turning traffic](scenic/ict-20261023T211728Z-straight_across_right_left_turn.scenic) | `ego` | `agent1` | `ego` crosses straight through the left-turn path of `agent1` approaching from the right; `agent1` continues its planned turn without an added evasive brake. | [MP4](visualizations/ict-20261023T211728Z-straight_across_right_left_turn.mp4) |
| [Straight across right-side through traffic](scenic/ict-20261023T211728Z-straight_across_right_traffic.scenic) | `ego` | `agent1` | `ego` crosses straight into the path of `agent1` approaching from the right; `agent1` brakes when ego enters the junction, then resumes its straight crossing after ego clears. | [MP4](visualizations/ict-20261023T211728Z-straight_across_right_traffic.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
