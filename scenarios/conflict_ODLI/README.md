# Opposite Direction Lateral Incursion

This conflict group occurs when a non-turning actor operating in the trafficway’s intended travel direction interacts with another actor that is operating opposite of the travel direction in the same trafficway.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Frontal approach with lane following](scenic/odli-20260930T225223Z-frontal_lane_following.scenic) | `agent1` | `ego` | `agent1` accelerates the wrong way toward `ego` in the same lane; `ego` continues following the lane in its intended direction. | [MP4](visualizations/odli-20260930T225223Z-frontal_lane_following.mp4) |
| [Frontal approach with braking](scenic/odli-20260930T225223Z-frontal_responder_brakes.scenic) | `agent1` | `ego` | `agent1` accelerates the wrong way toward `ego` in the same lane; `ego` brakes as separation decreases. | [MP4](visualizations/odli-20260930T225223Z-frontal_responder_brakes.mp4) |
| [Frontal approach with left evasion](scenic/odli-20260930T225223Z-frontal_responder_evades_left.scenic) | `agent1` | `ego` | `agent1` accelerates the wrong way toward `ego` in the same lane; `ego` changes into a clear lane to its left. | [MP4](visualizations/odli-20260930T225223Z-frontal_responder_evades_left.mp4) |
| [Frontal approach with right evasion](scenic/odli-20260930T225223Z-frontal_responder_evades_right.scenic) | `agent1` | `ego` | `agent1` accelerates the wrong way toward `ego` in the same lane; `ego` changes into a clear lane to its right. | [MP4](visualizations/odli-20260930T225223Z-frontal_responder_evades_right.mp4) |
| [Adjacent wrong-way close pass](scenic/odli-20260930T225223Z-adjacent_wrong_way_close_pass.scenic) | `agent1` | `ego` | `agent1` accelerates the wrong way in the adjacent left lane; `ego` follows its own lane in the intended direction as the cars pass closely. | [MP4](visualizations/odli-20260930T225223Z-adjacent_wrong_way_close_pass.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
