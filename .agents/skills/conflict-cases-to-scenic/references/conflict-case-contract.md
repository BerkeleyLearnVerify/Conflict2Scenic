# Conflict-case input and realization output

## Input

The minimum supported input is:

```json
{
  "conflict_group": {
    "title": "front-to-rear",
    "property": "Involves one road user interacting with another road user in the same direction and same travel lane."
  },
  "conflict_partners": {
    "ego": {"type": "car", "role": "responder"},
    "agent1": {"type": "car", "role": "initiator"}
  }
}
```

- `conflict_group.title` names the conflict group; `conflict_group.property` describes its interaction constraints. Use the supplied property to plan realizations.
- `conflict_partners` maps stable partner IDs to their `type` and `role`.
- An `initiator` performs the event that creates the conflict. A `responder` is exposed to that event and follows the specified or chosen response policy. The role of a conflict is orthogonal to legal considerations of fault.

## Realization planning

Enumerate realizations as structured JSON before generating Scenic. Create and store one JSON object per distinct realization using this schema:

```json
{
  "agents": {
    "agent1": {
      "type": "car",
      "maneuver": "braking",
      "position": "in_front_of_ego",
      "order": 1
    }
  },
  "road": {
    "intersection": "no",
    "left_lane_exists": "no",
    "right_lane_exists": "no"
  },
  "comments": "The initiator is ahead of ego and brakes after a preparation period."
}
```

The fields are:

- `agents`: all non-ego agents in the realization. Preserve their IDs from `conflict_partners`. Each agent has:
  - `type`: `car`, `pedestrian`, or `cyclist`.
  - `maneuver`: `follow_lane`, `lane_change_left`, `lane_change_right`, `left_turn`, `right_turn`, `passing_intersection`, `braking`, `accelerating`, `stopping`, `reversing`, `crossing`, or `standing`. `crossing`, and `standing` apply only to pedestrians; the other maneuvers apply to cars and cyclists.
  - `position`: `in_front_of_ego`, `behind_ego`, `left_front_of_ego`, `left_of_ego`, `left_behind_of_ego`, `right_front_of_ego`, `right_of_ego`, `right_behind_of_ego`, `lateral_lane_at_intersection`, or `oncoming_lane`. For `pedestrians`, use all except `lateral_lane_at_intersection` and `oncoming_lane`.
  - `order`: a positive integer ranking agents that share a position. Order 1 is nearest to ego, order 2 is next, and so on. Use 1 when the position is unique.
- `road`: road conditions relative to ego. `intersection`, `left_lane_exists`, and `right_lane_exists` each use `yes` or `no`.
- `comments`: optional assumptions or causal notes. Do not place required geometry or behavior only in this field; generation is driven by the structured fields.

By default, ego is a car with maneuver `follow_lane` and is omitted from `agents`. Conflict cases can make ego the initiator or otherwise require another maneuver. In that case, add the optional top-level `ego` object:

```json
{
  "ego": {
    "type": "car",
    "maneuver": "braking"
  },
  "agents": {
    "agent1": {
      "type": "car",
      "maneuver": "follow_lane",
      "position": "behind_ego",
      "order": 1
    }
  },
  "road": {
    "intersection": "no",
    "left_lane_exists": "no",
    "right_lane_exists": "no"
  },
  "comments": "Ego is the lead initiator and agent1 is the following responder."
}
```

The optional `ego` object uses the same `type` and `maneuver` values as other agents but has no `position` or `order`, because all spatial relations are defined relative to ego. Generate ego's Scenic behavior from this object. Do not silently replace it with `follow_lane`.

The resolved-realization JSON is an intermediate representation derived from the conflict case. Do not copy `conflict_group` or `role` into it. Use those input fields to select the concrete geometry and maneuvers, then preserve the causal mapping in the chosen fields and, when useful, `comments`.

Choose the following planning details before encoding each resolved-realization JSON object. Use the stable ID as the output filename; express the partner geometry and maneuvers in the structured JSON fields, and place nonessential assumptions in `comments`:

| Item | Purpose |
| --- | --- |
| Stable ID | Group and causal mechanism, e.g. `f2r_lead_brakes` |
| Partner mapping | Original ID/type/role plus chosen leader/follower position |
| Initiating event | Actor, trigger, maneuver, and duration |
| Response policy | Controller or explicit reaction, including any delay |
| Geometry | Lane/direction properties and necessary map conditions |
| Parameters | Initial speed, spacing, trigger, controls, and horizon with units |
| Assumptions | Choices absent from the input, separate from supplied facts |
| Outcome intent | Conflict opportunity by default; collision only if requested |

Reject candidates that contradict explicit constraints. When the user does not request a specific count, perform a diversity pass before finalizing the set: vary the spatial arrangement, initiating maneuver or trigger, approach path/topology, and responder behavior wherever the group properties allow. Target at least three to five materially distinct realizations. Continue beyond when additional causal arrangements are clearly supported. Stop when further candidates would violate supplied constraints or differ only in sampled values, distances, speeds, timing, or seeds. If only one or two realizations remain compatible, keep them and record why additional diversity would violate the properties or input. If none remain, explain the conflict rather than weakening the input.

## Delivery

Unless the user specifies another format, store each intermediate realization at `<case-directory>/realizations/<conflict-group>-<time>-<realization-id>.json`, then write its program to `<case-directory>/scenic/<conflict-group>-<time>-<realization-id>.scenic`, where `<conflict-group>` is the conflict group identifier (e.g. `f2r`, all in lowercase), `<time>` is of the format `YYYYMMDDTHHMMSSZ`, and `<realization-id>` is the stable ID of the realization (e.g., `lead_brakes`). The filenames must use the same stable ID. Do not overwrite unrelated existing outputs; update only artifacts within the requested task. If returning results without a writable case directory, include one labeled realization JSON block immediately before its corresponding labeled Scenic code block. Keep realization/program pairs separate and include other explanatory prose only when the user requests it.

Each realization JSON file contains only one resolved-realization object. Each Scenic file contains only its corresponding complete program, with section titles (see references/examples.md) between logical sections; explanatory comments are optional unless the user forbids them. Never concatenate alternatives into one file or randomly choose the causal recipe inside a single program by default.

Map/model settings are generation configuration, not mandatory conflict-case fields. Use values explicitly supplied by the user. Otherwise, use these defaults:

```scenic
param map = localPath('../../maps/Town05.xodr')
model scenic.simulators.metadrive.model
```

Resolve a user-supplied relative map path as requested. Placeholders are appropriate only in reference templates. Generation ends after producing and reviewing the Scenic text: do not inspect a local Scenic repository, compile or sample the program, or run a simulation.
