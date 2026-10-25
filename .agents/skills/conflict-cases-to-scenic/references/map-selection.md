# Map selection

Read this reference after planning concrete realizations and before storing their final JSON or generating Scenic. Select one map per realization; different realizations of the same conflict case may use different maps. Map/model settings remain generation configuration, outside the realization schema.

## Available maps and configuration

For automatic selection, discover `maps/*.net.xml` in the project and retain only entries with a matching `<name>.xodr` file. Scenic uses the `.xodr`; the separate simulation runner reads the generated scene's `map` parameter and automatically uses the companion `.net.xml`. Its optional `map_path` and `xodr_map_path` arguments, or CLI `--map-path` and `--xodr-map-path`, allow explicit overrides. Generation does not run the runner.

The inspected candidate set is:

| Map | Scenic asset, relative to project root | Matching runner asset |
| --- | --- | --- |
| Town01 | `maps/Town01.xodr` | `maps/Town01.net.xml` |
| Town04 | `maps/Town04.xodr` | `maps/Town04.net.xml` |
| Town05 | `maps/Town05.xodr` | `maps/Town05.net.xml` |
| Town07 | `maps/Town07.xodr` | `maps/Town07.net.xml` |
| Town10HD | `maps/Town10HD.xodr` | `maps/Town10HD.net.xml` |

Town02, Town03, and Town06 have `.xodr` files but no matching `.net.xml` in this folder, so exclude them from automatic selection. Do not convert or create map assets during generation.

An explicit user-selected map takes precedence over automatic selection. Preserve that choice; if it is missing or incompatible, explain the issue instead of substituting another map. Report a missing companion asset when it is needed by the intended runner. Preserve explicit Scenic model settings; otherwise use `scenic.simulators.metadrive.model`.

An optional `available_maps` list restricts automatic selection to the supplied candidates. Accept it in the prompt or a separate generation-configuration JSON file, for example:

```json
{
  "available_maps": ["maps/Town01.xodr", "maps/Town04.xodr", "maps/Town05.xodr"]
}
```

Resolve configuration-relative paths against the configuration file's directory, or prompt paths against the user-specified base, otherwise the project root. Match normalized asset paths, not only filenames. If the list is omitted, use all eligible maps discovered above. An explicitly empty list, missing assets, or no compatible candidates must not trigger a fallback to Town05 or an unlisted map.

## Evidence and interpretation

The profiles below come from static inspection of the local OpenDRIVE and SUMO XML files. They are not compilation, sampling, or simulation results. Refresh the affected profile if an asset changes or a new eligible map appears; inspect the supplied XML rather than inferring capabilities from town names. Unknown capabilities are not confirmed support.

- A regular lane section belongs to an OpenDRIVE road whose `junction` is `-1`. Directional lane counts count `type="driving"` lanes on each side of the road reference line. Verify width and travel direction at the chosen location, particularly for tapers.
- A four-approach candidate is a SUMO junction with four distinct incoming external edges, cross-checked against four distinct OpenDRIVE `incomingRoad` IDs. These are source-topology candidates for the guide's `is4Way` filter, not verified Scenic intersection objects. Connection directions `s`, `l`, and `r` provide evidence of straight, left-turn, and right-turn movements; they do not prove Scenic's maneuver/conflict classification.
- Lengths are OpenDRIVE reference-line lengths rounded to two decimal places. Usable lane length, spawn clearance, and connected route length can differ. A road containing arcs is not necessarily curved throughout.
- Sidewalk counts indicate that a section contains at least one sidewalk, not necessarily on the required side. Crosswalk counts are OpenDRIVE objects of `type="crosswalk"`; their presence does not establish a Scenic walkable region or a usable crossing trajectory. The SUMO files primarily encode driving lanes, so use OpenDRIVE for pedestrian geometry.
- Source road, lane, and junction IDs below locate evidence in the XML. Do not assume these IDs are Scenic object IDs or hard-code them into generated programs without a documented mapping.

## Capability overview

| Map | Maximum driving lanes in one direction | Regular sections with 2+ lanes in one direction | Regular sections with sidewalks | Four-approach candidates | Crosswalk objects |
| --- | ---: | ---: | ---: | ---: | ---: |
| Town01 | 1 | 0 of 26 | 26 of 26 | 0 | 0 |
| Town04 | 4 | 18 of 53 | 25 of 53 | 9 | 27 |
| Town05 | 3 | 50 of 53 | 53 of 53 | 13 | 66 |
| Town07 | 2, only on a short tapering segment | 1 of 68 | 36 of 68 | 3 | 7 |
| Town10HD | 2 | 20 of 23 | 23 of 23 | 1 | 16 |

All five contain opposing-direction traffic and straight/left/right connections somewhere in the network. None declares a dedicated bicycle lane (`type="biking"`). Cyclist conflicts may use driving lanes when allowed by the input, but do not claim bicycle infrastructure. Opposing traffic on the same road does not imply an unobstructed path across the center: check shoulders, medians, and separation at the actual conflict location.

### Town01: single-lane roads and simple roadside interactions

- All 26 regular sections have one driving lane in each direction and sidewalks. There are no same-direction adjacent driving lanes, so reject realizations requiring lane changes or same-direction vehicles abreast in separate lanes.
- Straight road `12` is 224.25 m long with driving lanes `1` and `-1`, each 4 m wide, and 4 m sidewalks on both sides. Road `4` is another straight section, 224.22 m long. These are evidence for same-lane following, braking, reversing, opposing traffic, and roadside pedestrian arrangements without extra lane requirements.
- Roads `8` (308.69 m) and `15` (307.64 m) include arcs, but road `8` has only tiny, low-curvature arcs; do not use the longest-road metric as evidence of a substantial bend.
- All 12 junctions have three incoming external edges. Junction `26`, for example, has straight, left, and right connections, but no four-approach junction exists in these assets. Under the current guide's `is4Way` template, reject Town01 for intersection realizations. Supporting T-junction scenarios requires a separate syntax-guide extension.
- No explicit parking lane or crosswalk object was found. Pedestrian crossing need not imply a marked crosswalk unless the input requires one.

### Town04: wide roads, long curves, and single-lane intersections

- Eighteen regular sections have multiple driving lanes in one direction; sixteen have at least three. Road `45` is a 585.40 m curved section with four driving lanes per direction, each 3.5 m wide. Roads `35` (285.58 m) and `38` (245.69 m) also have four per direction. Interior lanes can support same-direction neighbors on both sides.
- Road `45` has wide shoulders separating the directional carriageways and no sidewalks. It is evidence for prolonged multilane interactions and curves, not an undivided head-on conflict or a sidewalk crossing. Road `22` is a 468.09 m, two-lane one-way curved road with no sidewalks.
- Nine four-approach candidates exist. Junction `1452` connects roads `10`, `17`, `18`, and `9`, whose reference lengths are 36.32, 57.15, 71.97, and 49.91 m. Junction `335` has straight/left/right connections from each approach, but road `2` is only 5.68 m long. Prefer a candidate with sufficient approach length for every partner.
- Sidewalks occur on only 25 of 53 regular sections; do not assume the wide-road locations also provide pedestrian space. There are 27 crosswalk objects, including objects on connector roads at junction `53`. No explicit parking lane was found.

### Town05: extensive multilane roads, intersections, and parking lanes

- Fifty of 53 regular sections have multiple driving lanes in one direction; six have at least three. Road `0` is a straight 53.56 m section with two 3.5 m driving lanes in each direction and sidewalks on both sides. It demonstrates that adjacent lanes and roadside pedestrian space coexist.
- Road `37` is an 814.84 m section containing substantial curves with three driving lanes per direction and sidewalks on both sides. Roads `38` (300.24 m) and `34` (276.20 m) also have three per direction. These are candidates for longer multilane arrangements or a middle ego lane with neighbors on both sides. Road `37` has an inner shoulder separating directions; do not assume an unobstructed opposing-lane incursion.
- Thirteen four-approach candidates exist. Junction `1427` has straight/left/right connections and two-lane straight movements, but its approaches include road `17` at only 11.21 m. Junction `1126` connects roads `46`, `47`, `6`, and `7`, with reference lengths 73.36, 51.82, 54.36, and 45.47 m; inspect maneuver availability on the chosen incoming lanes.
- Every regular section has at least one sidewalk; there are 66 crosswalk objects. Nine regular roads contain explicit parking lanes: `4`, `5`, `19`, `20`, `48`, `49`, `50`, `51`, and `52`. Roads `19` (215.43 m) and `20` (214.63 m) are useful starting points when the realization specifically needs parked-roadside geometry. A parking lane alone does not establish a parking bay or a complete reverse-merge route.

### Town07: curved two-way roads with limited extra-lane capacity

- Most roads offer one driving lane per direction. Road `20` is a 256.42 m winding section with 3.2 m lanes, opposing traffic, and no sidewalks. Its arcs include curvature about 0.04664 per meter (radius about 21.44 m). Roads `62` (197.00 m) and `21` (190.71 m) are additional curved two-way candidates.
- The only regular section with a second same-direction driving lane is road `26` (25.54 m). Lane `-2` begins at zero width and becomes 3.5 m wide at reference offset 12.12 m. It is not evidence for a long lane-change corridor; reject ordinary sustained multilane arrangements unless their full geometry fits the usable segment. There is no three-lane direction for neighbors on both sides of ego.
- Three four-approach candidates exist: junctions `68`, `169`, and `725`. Junction `68` connects roads `0`, `44`, `45`, and `55` (33.80, 35.40, 46.75, and 77.62 m); junction `169` is another single-lane option. At junction `725`, road `27` is only 0.29 m long, so do not assume arbitrary approach distances fit.
- Sidewalks occur on 36 of 68 regular sections, with seven crosswalk objects. Parking lanes occur on roads `5`, `6`, and `7`; these roads are only 13.28, 8.59, and 56.50 m long. Verify the chosen side and usable length for pedestrian or parked-vehicle interactions.

### Town10HD: compact two-lane roads and broad sidewalks

- Twenty of 23 regular sections have two driving lanes in a direction; none has three. This supports an adjacent lane on one side, but not simultaneous same-direction neighbors on both sides of ego.
- Road `10` is 120.40 m long with two 3.5 m driving lanes per direction, 6 m sidewalks on both sides, and a substantial curved portion. Road `1` (119.93 m) and road `5` (106.75 m) are further two-lane candidates. Road `20` is a straight 55.13 m section, but has a central median: do not use it as evidence for an unobstructed oncoming intrusion.
- The only four-approach candidate is junction `189`. Straight/left/right connections exist, including two-lane straight movements. Its incoming roads `14`, `15`, `19`, and `20` are 9.17, 3.11, 11.24, and 55.13 m long. Long approaches would require inspection of connected predecessor roads; the junction alone does not support them.
- Every regular section has a sidewalk; there are 16 crosswalk objects. No explicit parking lane was found. Prefer this map when compact two-lane geometry and broad sidewalks meet the required distances, rather than assuming all urban interactions fit.

## Matching and selection

1. Derive requirements from the input constraints, realization `road`, all agent positions and maneuvers, optional `ego`, and planned distances/timing. Distinguish required geometry from optional preferences. A `no` lane-existence flag does not prohibit additional lanes unless their absence is essential, consistent with the generation guide.
2. Require a same-direction adjacent lane on the appropriate side for lane changes and lane-relative placements. Simultaneous same-direction neighbors on both sides of ego need at least three coexisting driving lanes with ego in an interior lane. Apply these checks to each actor's actual lane, not only ego's. Reversing alone does not require a parking lane.
3. For intersection realizations under the current guide, require a four-approach candidate, appropriate turning/straight connections, and compatible opposing or crossing approaches. Check that all required movements coexist at the same junction and that distances fit their approaches. Do not count a merge with several incoming edges as a proven four-way crossing.
4. For pedestrian, cyclist, opposing-lane, or curve requirements, inspect the relevant side, widths, separators, and geometry. In particular, a sidewalk elsewhere in the map, a crosswalk on another connector, or opposing traffic beyond a median does not establish the requested interaction.
5. Exclude incompatible candidates and candidates whose required capabilities remain unknown after focused static XML inspection. Prefer maps with directly supported, coexisting geometry and enough usable length, then fewer unnecessary lanes or topology complications. For otherwise equivalent candidates use the user list order; with no list use map name order. Do not randomly select a map in Scenic.
6. Select independently for each realization while preserving partner types, roles, conflict geometry, and material diversity. Do not change a causal arrangement merely to fit a preferred map. If a realization cannot be supported, identify the missing capability and try other materially distinct arrangements permitted by the conflict property. Report any remaining requested-count shortfall; if none fit, explain why instead of emitting an unsupported program.

Useful starting points, subject to those checks:

| Required arrangement | First maps to inspect |
| --- | --- |
| Same-lane interaction or simple roadside pedestrian placement, no intersection | Town01 |
| Sustained adjacent-lane interaction | Town05 or Town10HD |
| Same-direction neighbors on both sides of ego | Town05 or Town04 |
| Four-way intersection with single-lane approaches | Town04 or Town07 |
| Four-way intersection with multilane approaches | Town05; Town10HD only if its short approaches suffice |
| Winding two-way road without a sidewalk requirement | Town07 |
| Long curved multilane section | Town04 or Town05 |
| Explicit parking-lane geometry | Town05; Town07 for short arrangements |
| Explicit marked-crosswalk requirement | Town04, Town05, Town07, or Town10HD; inspect the actual crossing |

These are search hints, not a replacement for matching constraints or deterministic tie-breaking.

## Emission and review

Resolve the selected `.xodr` to an actual asset and compute `localPath(...)` relative to the emitted `.scenic` file's directory. For the standard `scenarios/conflict_<ID>/scenic/` output directory, the path is `../../../maps/<name>.xodr`. Recompute for other output locations; do not copy the old fixed `../../maps/Town05.xodr` default. When returning code without files, establish the intended program directory before computing a relative path, or use the resolved absolute asset path.

Include a map-selection comment in the map section naming the selected map and the decisive capability, unless comments are forbidden. The entire map-selection comment must occupy at most one line in the generated Scenic program; do not split or expand it across multiple comment lines. Keep this outside the realization JSON. Emit one fixed map per program. Retain the guide's intersection, maneuver, and lane-adjacency constructions and requirements so the generated scene is constrained to compatible topology; selecting a capable map does not make every lane suitable. Do not invent Scenic IDs or unsupported syntax to pin source XML examples.

Review that every stored realization has exactly one program, every selected map respects configuration, each emitted path resolves to the intended asset, and the combined geometry is supported. The runner automatically binds to the scene's map and requires its matching `.net.xml`, so no additional binding fields are needed in generated programs. End generation after static text review; do not inspect Scenic source, compile, sample, or simulate.
