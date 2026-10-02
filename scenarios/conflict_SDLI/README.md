# Same Direction Lateral Incursion

This conflict group occurs when two roadway actors are traveling in the same trafficway but in initially different travel lanes at the time of the initial interaction due to lateral incursion by some actor.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Lead left cut-in with braking](scenic/sdli-20261001T010323Z-lead_left_cut_in_braking_response.scenic) | `agent1` | `ego` | `agent1` cuts into the lane ahead of `ego` from the left at a lower speed; `ego` brakes as separation decreases. | [MP4](visualizations/sdli-20261001T010323Z-lead_left_cut_in_braking_response.mp4) |
| [Lead right cut-in with lane following](scenic/sdli-20261001T010323Z-lead_right_cut_in_lane_following_response.scenic) | `agent1` | `ego` | `agent1` cuts into the lane ahead of `ego` from the right; `ego` continues following its lane. | [MP4](visualizations/sdli-20261001T010323Z-lead_right_cut_in_lane_following_response.mp4) |
| [Abreast right incursion with braking](scenic/sdli-20261001T010323Z-abreast_right_incursion_braking_response.scenic) | `agent1` | `ego` | `agent1` starts alongside `ego` in the right lane and changes left toward its lane; `ego` brakes when the incursion comes close. | [MP4](visualizations/sdli-20261001T010323Z-abreast_right_incursion_braking_response.mp4) |
| [Abreast left incursion with right evasion](scenic/sdli-20261001T010323Z-abreast_left_incursion_evasive_right_response.scenic) | `agent1` | `ego` | `agent1` starts alongside `ego` in the left lane and changes right toward its lane; `ego` changes into a clear lane to its right. | [MP4](visualizations/sdli-20261001T010323Z-abreast_left_incursion_evasive_right_response.mp4) |
| [Rear left approach and cut-in](scenic/sdli-20261001T010323Z-rear_left_accelerated_approach_cut_in.scenic) | `agent1` | `ego` | `agent1` approaches faster from behind in the left lane, then changes right toward the lane occupied by `ego`; `ego` continues following its lane. | [MP4](visualizations/sdli-20261001T010323Z-rear_left_accelerated_approach_cut_in.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
