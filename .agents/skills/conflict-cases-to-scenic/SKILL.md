---
name: conflict-cases-to-scenic
description: Expand conflict-case JSON with conflict_group and conflict_partners into distinct concrete Scenic scenarios while preserving partner types and initiator/responder roles. Use for conflict cases, rather than the agents/road format that already specifies maneuvers and positions.
---

# Conflict Cases to Scenic

Turn a conflict case into one or more concrete realizations, then generate a separate Scenic program for each. A conflict group constrains the interaction; it does not uniquely determine positions, maneuvers, or the outcome.

## Workflow

1. Read [the input and output contract](references/conflict-case-contract.md). Normalize the input and preserve partner identities, types, roles, and explicit user constraints.
2. Enumerate a diverse set of compatible realizations using the input `conflict_group.property`. Represent every realization as a separate resolved-realization JSON object using the schema in the input and output contract. Separate input facts from chosen assumptions. Honor a requested variant/count; otherwise do not stop after the first obvious realization or the first pair. Explore materially different longitudinal/lateral arrangements, initiating mechanisms, approach paths, and responder behaviors allowed by the group's property. Target at least three to five realizations when the property and supplied constraints support them. Do not count different numeric samples, timing values, or parameter ranges of the same causal arrangement as distinct realizations.
3. Read [map selection and the local map capabilities](references/map-selection.md). Honor an explicitly selected map; otherwise choose a suitable map independently for each realization from `maps/` entries with both `.xodr` and `.net.xml` assets, restricted by any user-supplied `available_maps` list. Match all required geometry at a usable location, preserve material diversity, and explain unsupported realizations or requested-count shortfalls rather than silently substituting an incompatible map. Keep map settings outside the realization schema.
4. Store every supported resolved-realization JSON object before generating Scenic, using the paths and filename convention in the input and output contract. Use the same stable ID for its Scenic program so the intermediate and final outputs have a one-to-one mapping.
5. Read [the shared Scenic guide](references/scenic-generation-guide.md) and [the general examples](references/examples.md). Convert each stored JSON object into one self-contained Scenic program using its selected map, with the map path resolved relative to the program's output directory. Use the Scenic model named by the user, otherwise `scenic.simulators.metadrive.model`. Bind behavior to conflict role.
6. Review the generated text for input fidelity, role-to-event mapping, map compatibility and path resolution, group geometry, behavior timing, defined names, and consistency with the syntax guide. Confirm that every stored realization has exactly one Scenic program and that the set is materially diverse. Then output the Scenic programs.

Use only this skill's contract, the input's group property and constraints, map-selection reference and supplied map/configuration assets, syntax guide, and examples. Static map XML inspection is allowed. The skill is self-contained. Do not consult another skill or a locally installed Scenic source tree. Do not refer to previously generated outputs. Do not compile the programs, sample scenes, or run simulations.
