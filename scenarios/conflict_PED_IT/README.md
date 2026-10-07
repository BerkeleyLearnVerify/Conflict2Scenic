# Pedestrian Interacting in Trafficway

This conflict group occurs when a vehicle traveling forward interacts with a pedestrian in the trafficway who is moving around, entering, exiting, or interacting with an immediately adjacent vehicle or object.

## Generated Scenarios

| Scenario | Initiator | Responder | Interaction | Visualization |
| --- | --- | --- | --- | --- |
| [Exit right vehicle](scenic/ped_it-20261006T223530Z-exit_right_vehicle.scenic) | `agent1` | `ego`, `agentStatic` | Pedestrian `agent1` walks from beside stopped `agentStatic` in the right lane into `ego`'s lane; `ego` brakes and `agentStatic` stays stopped. | [MP4](visualizations/ped_it-20261006T223530Z-exit_right_vehicle.mp4) |
| [Enter left vehicle](scenic/ped_it-20261006T223530Z-enter_left_vehicle.scenic) | `agent1` | `ego`, `agentStatic` | Pedestrian `agent1` approaches and stops beside `agentStatic` in the left lane to represent entering it; `ego` brakes and `agentStatic` stays stopped. | [MP4](visualizations/ped_it-20261006T223530Z-enter_left_vehicle.mp4) |
| [Rear vehicle bypass](scenic/ped_it-20261006T223530Z-rear_vehicle_bypass.scenic) | `agent1` | `ego`, `agentStatic` | Pedestrian `agent1` walks left to right around the rear of stopped `agentStatic`, crossing `ego`'s path; `ego` brakes and `agentStatic` stays stopped. | [MP4](visualizations/ped_it-20261006T223530Z-rear_vehicle_bypass.mp4) |
| [Walk along vehicle toward ego](scenic/ped_it-20261006T223530Z-walk_along_vehicle_toward_ego.scenic) | `agent1` | `ego`, `agentStatic` | Pedestrian `agent1` walks rearward along the right side of stopped `agentStatic` toward approaching `ego`; `ego` brakes and `agentStatic` stays stopped. | [MP4](visualizations/ped_it-20261006T223530Z-walk_along_vehicle_toward_ego.mp4) |

The corresponding JSON plans are in [realizations/](realizations/), with matching filenames. See the [project README](../../README.md) for installation and running instructions.
