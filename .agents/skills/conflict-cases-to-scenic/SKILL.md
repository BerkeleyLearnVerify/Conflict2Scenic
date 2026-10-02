---
name: conflict-cases-to-scenic
description: Expand conflict-case JSON with conflict_group and conflict_partners into distinct concrete Scenic scenarios while preserving partner types and initiator/responder roles. Use for conflict cases, rather than the agents/road format that already specifies maneuvers and positions.
---

# Conflict Cases to Scenic

Turn a conflict case into one or more concrete realizations, then generate a separate Scenic program for each. A conflict group constrains the interaction; it does not uniquely determine positions, maneuvers, or the outcome.

## Workflow

1. Read [the input and output contract](references/conflict-case-contract.md). Normalize the input and preserve partner identities, types, roles, and explicit user constraints.
2. Enumerate a diverse set of compatible realizations using the input `conflict_group.property`. Represent every realization as a separate resolved-realization JSON object using the schema in the input and output contract. Separate input facts from chosen assumptions. Honor a requested variant/count; otherwise do not stop after the first obvious realization or the first pair. Explore materially different longitudinal/lateral arrangements, initiating mechanisms, approach paths, and responder behaviors allowed by the group's property. Target at least three to five realizations when the property and supplied constraints support them. Do not count different numeric samples, timing values, or parameter ranges of the same causal arrangement as distinct realizations.
3. Store every resolved-realization JSON object before generating Scenic. Unless the user specifies another location, write it to `<case-directory>/realizations/<realization-id>-<time>.json`. Use the same stable ID for its Scenic program so the intermediate and final outputs have a one-to-one mapping.
4. Use the map and Scenic model named by the user. If either is omitted, default to `../../maps/Town05.xodr` and `scenic.simulators.metadrive.model`, respectively. Read [the shared Scenic guide](references/scenic-generation-guide.md) and [the general examples](references/examples.md) before emitting code.
5. Convert each stored resolved-realization JSON object into one self-contained Scenic program using the syntax guide and examples. Bind behavior to conflict role.
6. Review the generated text for input fidelity, role-to-event mapping, group geometry, behavior timing, defined names, and consistency with the syntax guide. Confirm that every stored realization has exactly one Scenic program and that the set is materially diverse. Then output the Scenic programs.

Use only this skill's contract, the input's group property, syntax guide, and examples. The skill is self-contained. Do not consult another skill or a locally installed Scenic source tree. Do not refer to previously generated outputs. Do not compile the programs, sample scenes, or run simulations.
