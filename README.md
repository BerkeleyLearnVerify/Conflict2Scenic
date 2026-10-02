# Conflict_Cases_to_Scenic

Converting Waymo's conflict cases to Scenic programs.

## Project checklist

This project is a work in progress. The following items are planned:
- [ ] Add conflict cases involving pedestrians and cyclists.
- [ ] Introduce automatic selection of maps.
- [ ] Integrate MPCC controllers.

## Installation

The project requires Python `>=3.8,<3.12`. From the repository root:

```bash
python -m venv .venv
source .venv/bin/activate
python -m pip install --upgrade pip
python -m pip install -e .
```

This installs Scenic with MetaDrive support, VerifAI, Matplotlib, Shapely, and the `run-scenic-scenarios` command. Install FFmpeg separately and make it available on `PATH` to export MP4 videos. Generation also requires the Codex CLI.

## The conflict cases to Scenic conversion

The [conflict-cases-to-scenic skill](.agents/skills/conflict-cases-to-scenic/SKILL.md) expands each conflict case into distinct concrete realizations, preserving partner identities, types, and initiator/responder roles. It stores each realization as JSON, then produces one Scenic program per realization. When constraints allow, it targets at least three to five materially different interactions.

The [input/output contract](.agents/skills/conflict-cases-to-scenic/references/conflict-case-contract.md) defines:

- **Input:** `conflict_group` with `title` and `property`, plus `conflict_partners` mapping IDs (including `ego`) to `type` and `role`.
- **Realization JSON:** `agents` with type, maneuver, relative position, and order; `road` with intersection and neighboring-lane flags; optional `ego` behavior and `comments`.
- **Scenic output:** a complete program for each realization, with a matching filename stem.

The [generation guide](.agents/skills/conflict-cases-to-scenic/references/scenic-generation-guide.md) covers map/model setup, placement, behaviors, and requirements. The [examples](.agents/skills/conflict-cases-to-scenic/references/examples.md) show lane changes and intersection conflicts. Generation ends after reviewing the Scenic text; simulation is a separate step.

## Creating a new conflict case

Create `scenarios/conflict_<ID>/input.txt` containing JSON. Copy an existing case, such as [conflict_F2R/input.txt](scenarios/conflict_F2R/input.txt), and edit the group title/property and partner types/roles. Use `car`, `pedestrian`, or `cyclist` for types and `initiator` or `responder` for roles.

## Generating Scenic scenarios from a conflict case

Edit [prompts/single_scenario.txt](prompts/single_scenario.txt) to point to your case, then run from the repository root:

```bash
codex exec "$(cat prompts/single_scenario.txt)"
```

The prompt selects the skill and Town05 map. Keep the map path `../../../maps/Town05.xodr` relative to generated programs in `scenarios/conflict_<ID>/scenic/`.

Outputs are stored in `scenarios/conflict_<ID>/realizations/*.json` and `scenarios/conflict_<ID>/scenic/*.scenic`. Each pair shares a stem: `<group>-<YYYYMMDDTHHMMSSZ>-<realization-id>`.

## Running and visualizing the generated Scenic scenarios

From the repository root, pass one generated program to the runner:

```bash
run-scenic-scenarios scenarios/conflict_TIPOD/scenic/tipod-20261001T012059Z-left_turn_wrong_way_stop.scenic
```

The runner uses MetaDrive with the Town05 maps, records agent and lane polygons, and saves an MP4 to `scenarios/conflict_<ID>/visualizations/<program-stem>.mp4`. Use `--save-path path/to/video.mp4` to choose another output location.
