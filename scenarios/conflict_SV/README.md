# Single Vehicle

This conflict group includes actions or omissions where `ego` travels in a trafficway and experiences an interaction within it or leaves it, without a conflict partner.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Curve steering omission](scenic/sv-20261007T000119Z-curve_steering_omission.scenic) | `ego` | None | `ego` accelerates along its initial tangent without steering to follow a curved lane, creating a road-departure opportunity. | [MP4](visualizations/sv-20261007T000119Z-curve_steering_omission.mp4) |
| [Right oblique departure](scenic/sv-20261007T000119Z-right_oblique_departure.scenic) | `ego` | None | `ego` starts angled right of the lane direction and accelerates without correcting its heading, creating a lateral road-departure opportunity. | [MP4](visualizations/sv-20261007T000119Z-right_oblique_departure.mp4) |
| [Intersection missed left turn](scenic/sv-20261007T000119Z-intersection_missed_left_turn.scenic) | `ego` | None | `ego` omits an intended left turn at an intersection and continues accelerating along its initial heading, creating a road-departure opportunity. | [MP4](visualizations/sv-20261007T000119Z-intersection_missed_left_turn.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
