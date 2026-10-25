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
| [Legal left merge toward wrong-way responder](scenic/odli-20261023T212150Z-legal_left_merge_wrongway_responder.scenic) | `ego` | `agent1` | `ego` changes left into a mapped same-direction lane already occupied by wrong-way `agent1`; the oncoming responder brakes after a reaction delay. | [MP4](visualizations/odli-20261023T212150Z-legal_left_merge_wrongway_responder.mp4) |
| [Reverse toward following car](scenic/odli-20261023T212150Z-reverse_toward_following_car.scenic) | `ego` | `agent1` | `ego` starts stopped, then reverses against the intended lane direction toward following `agent1`; the legally moving responder brakes after a reaction delay. | [MP4](visualizations/odli-20261023T212150Z-reverse_toward_following_car.mp4) |
| [Wrong-way approach with right evasion](scenic/odli-20261023T212150Z-wrongway_approach_right_evasion.scenic) | `ego` | `agent1` | `ego` accelerates against the intended travel direction toward legally moving `agent1` in the same lane; `agent1` reacts by changing into a clear lane to its right. | [MP4](visualizations/odli-20261023T212150Z-wrongway_approach_right_evasion.mp4) |
| [Wrong-way launch with head-on braking](scenic/odli-20261023T212150Z-wrongway_launch_head_on_braking.scenic) | `ego` | `agent1` | `ego` accelerates against the intended travel direction toward legally moving `agent1` in the same lane; `agent1` brakes after a reaction delay. | [MP4](visualizations/odli-20261023T212150Z-wrongway_launch_head_on_braking.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
