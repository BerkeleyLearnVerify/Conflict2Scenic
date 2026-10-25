import argparse
import re
import random
import tempfile
from contextlib import contextmanager
from pathlib import Path

import matplotlib.pyplot as plt
import scenic
from matplotlib.animation import FFMpegWriter, FuncAnimation
from matplotlib.lines import Line2D
from matplotlib.patches import Polygon
from scenic.simulators.metadrive import MetaDriveSimulator
from shapely.geometry import Polygon as ShapelyPolygon


_AGENT_DECLARATION_RE = re.compile(
    r"^[ \t]*(?P<name>[A-Za-z_]\w*)[ \t]*=[ \t]*new[ \t]+"
    r"(?:Car|Vehicle|Pedestrian|Bicycle|Motorcycle|Truck|Bus)\b",
    re.MULTILINE,
)
_RECORD_ID_RE = re.compile(
    r"^[ \t]*record\b.*?\bas[ \t]+(?P<id>[A-Za-z_]\w*)[ \t]*(?:#.*)?$",
    re.MULTILINE,
)


def _agent_names(scenic_source):
    """Return simulated-agent variable names in their source declaration order."""
    names = []
    for match in _AGENT_DECLARATION_RE.finditer(scenic_source):
        name = match.group("name")
        if name not in names:
            names.append(name)
    return names


@contextmanager
def recorded_polygon_program(file_path):
    """Create a temporary copy of a Scenic program recording agent/lane polygons.

    Yields ``(temporary_path, record_ids)`` and removes the temporary program on
    exit. Keeping the copy beside the input program preserves Scenic's relative
    path resolution.
    """
    source_path = Path(file_path).resolve()
    source = source_path.read_text(encoding="utf-8")
    agents = _agent_names(source)
    if not agents:
        raise ValueError(f"No agent declarations found in Scenic program: {file_path}")

    existing_record_ids = {
        match.group("id") for match in _RECORD_ID_RE.finditer(source)
    }
    record_ids = []
    extra_lines = []
    for agent in agents:
        agent_polygon_id = f"{agent}Poly"
        lane_polygon_id = f"{agent}LanePoly"
        record_ids.extend((agent_polygon_id, lane_polygon_id))
        if agent_polygon_id not in existing_record_ids:
            extra_lines.append(
                f"record {agent}._boundingPolygon as {agent_polygon_id}"
            )
        if lane_polygon_id not in existing_record_ids:
            # Crossing pedestrians may legitimately be outside every traffic lane.
            extra_lines.append(
                f"record ({agent}._lane.polygon if {agent}._lane is not None "
                f"else None) as {lane_polygon_id}"
            )

    suffix = "\n\n# Automatically added polygon records\n" + "\n".join(extra_lines) + "\n"
    temporary_path = None
    try:
        with tempfile.NamedTemporaryFile(
            mode="w",
            encoding="utf-8",
            prefix=f".{source_path.stem}_recorded_",
            suffix=source_path.suffix,
            dir=source_path.parent,
            delete=False,
        ) as temporary_file:
            temporary_file.write(source)
            if extra_lines:
                temporary_file.write(suffix)
            temporary_path = temporary_file.name
        yield temporary_path, record_ids
    finally:
        if temporary_path is not None:
            Path(temporary_path).unlink(missing_ok=True)


def _resolve_map_paths(scene, map_path=None):
    """Resolve simulator assets from the sampled Scenic map and a SUMO override."""
    try:
        xodr_path = Path(scene.params["map"]).expanduser().resolve()
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError(
            "The Scenic program must define a 'map' parameter pointing to an "
            "OpenDRIVE file, or an xodr_map_path override must be supplied."
        ) from exc
    if xodr_path.suffix.lower() != ".xodr":
        raise ValueError(f"Expected an OpenDRIVE .xodr map, got: {xodr_path}")
    if not xodr_path.is_file():
        raise FileNotFoundError(f"OpenDRIVE map not found: {xodr_path}")

    sumo_path = (
        Path(map_path).expanduser().resolve()
        if map_path is not None
        else xodr_path.with_suffix(".net.xml")
    )
    if not sumo_path.is_file():
        raise FileNotFoundError(
            f"SUMO map not found: {sumo_path}. Provide the matching .net.xml "
            "using map_path or --map-path."
        )
    return sumo_path, xodr_path


def run_metadrive_scenario(
    file_path,
    max_steps=100,
    seed=None,
    maxIterations=10,
    map_path=None,
    xodr_map_path=None,
):
    """Use the program's map unless explicit simulator assets are supplied."""
    if seed is not None:
        random.seed(seed)
    params = {}
    if xodr_map_path is not None:
        xodr_override = Path(xodr_map_path).expanduser().resolve()
        if not xodr_override.is_file():
            raise FileNotFoundError(f"OpenDRIVE map not found: {xodr_override}")
        # Scenic must build its geometry from the same map used by MetaDrive.
        params["map"] = str(xodr_override)
    scenic.setDebuggingOptions(
        verbosity=1, fullBacktrace=True, debugExceptions=False, debugRejections=False
    )
    with recorded_polygon_program(file_path) as (run_file_path, polygon_record_ids):
        scenario = scenic.scenarioFromFile(
            run_file_path,
            params=params,
            model="scenic.simulators.metadrive.model",
            mode2D=True,
        )
        scene, _ = scenario.generate()
        sumo_path, xodr_path = _resolve_map_paths(scene, map_path)
        simulator = MetaDriveSimulator(
            sumo_map=str(sumo_path),
            xodr_map=str(xodr_path),
        )
        simulation = simulator.simulate(
            scene, maxSteps=max_steps, maxIterations=maxIterations
        )
    if not simulation:
        raise RuntimeError("Simulation failed.")
    simulation.polygon_record_ids = polygon_record_ids
    return simulation


def visualize_simulation(
    simulation,
    ids=None,
    violated_rules=None,
    save_path="trajectory.mp4",
    fps=10,
    trail_length=15,
    truncate=0,
):
    if ids is None:
        ids = getattr(simulation, "polygon_record_ids", None)
    if ids is None:
        ids = [
            record_id
            for record_id in simulation.records
            if record_id.endswith("Poly")
        ]
    if not ids:
        raise ValueError("No polygon record IDs were supplied or found in the simulation.")
    if violated_rules is None:
        violated_rules = []

    trajectories = {}
    for id in ids:
        if id not in simulation.records:
            print(f"ID {id} not found in simulation records.")
            return
        trajectories[id] = simulation.records[id]
        trajectories[id] = trajectories[id][truncate:]

    # Number of frames = max length across vehicles
    num_frames = max(len(traj) for traj in trajectories.values())

    fig, ax = plt.subplots(figsize=(8, 8))
    ax.set_aspect("equal", "box")

    # Print violated rules on the plot
    rules_text = "\n".join(violated_rules)
    rules_display = ax.text(
        1.1,
        1.1,
        rules_text,
        fontsize=12,
        color="red",  # weight='bold',
        ha="right",
        va="top",
        transform=ax.transAxes,
        bbox=dict(facecolor="white", alpha=0.7, edgecolor="none"),
        animated=True,
    )

    # Create polygon patches and text labels for each vehicle
    vehicle_patches = {}
    vehicle_labels = {}
    for i, vid in enumerate(trajectories):
        poly = trajectories[vid][0][1]

        if "Lane" in str(vid):  # Lane polygon
            facecolor = plt.cm.Pastel1(i % 9)  # softer colormap
            alpha = 0.2  # more transparent
        else:  # Vehicle polygon
            facecolor = plt.cm.tab10(i % 10)  # bold colormap
            alpha = 0.5

        patch = Polygon(
            list(poly.exterior.coords) if poly is not None else [(0, 0)],
            closed=True,
            facecolor=facecolor,
            alpha=alpha,
            edgecolor="black",
            visible=poly is not None,
        )
        ax.add_patch(patch)
        vehicle_patches[vid] = patch

        if "Lane" not in str(vid):
            label = ax.text(
                poly.centroid.x,
                poly.centroid.y,
                str(vid).split("Poly")[0],
                fontsize=10,
                ha="center",
                va="center",
                color="black",
                weight="bold",
            )
            vehicle_labels[vid] = label
        else:
            vehicle_labels[vid] = ax.text(
                poly.centroid.x if poly is not None else 0,
                poly.centroid.y if poly is not None else 0,
                "",
                fontsize=10,
                ha="center",
                va="center",
                color="black",
                weight="bold",
            )

    # Determine global plot limits
    all_x, all_y = [], []
    for vid, traj in trajectories.items():
        if "Lane" in str(vid):  # Lane polygon
            continue
        for poly in traj:
            poly = poly[1]
            x, y = poly.exterior.xy
            all_x.extend(x)
            all_y.extend(y)
    ax.set_xlim(min(all_x) - 5, max(all_x) + 5)
    ax.set_ylim(min(all_y) - 5, max(all_y) + 5)

    # For fading trails: store line objects per vehicle
    vehicle_trails = {vid: [] for vid in trajectories}

    def update(frame):
        artists = []
        artists.append(rules_display)

        for i, (vid, traj) in enumerate(trajectories.items()):
            if frame < len(traj):
                poly: ShapelyPolygon = traj[frame][1]
                vehicle_patches[vid].set_visible(poly is not None)
                vehicle_labels[vid].set_visible(poly is not None)
                if poly is None:
                    artists.extend((vehicle_patches[vid], vehicle_labels[vid]))
                    continue
                # Update polygon
                vehicle_patches[vid].set_xy(list(poly.exterior.coords))
                artists.append(vehicle_patches[vid])

                # Update label
                centroid = poly.centroid
                vehicle_labels[vid].set_position((centroid.x, centroid.y))
                artists.append(vehicle_labels[vid])

                # Add trail segment (centroid path)
                if frame > 0 and "Lane" not in str(vid):  # Skip lane markings
                    prev = traj[frame - 1][1].centroid
                    curr = centroid
                    (line,) = ax.plot(
                        [prev.x, curr.x],
                        [prev.y, curr.y],
                        color=plt.cm.tab10(i % 10),
                        alpha=0.6,
                        linewidth=2,
                    )
                    vehicle_trails[vid].append(line)

                    # Keep only the last `trail_length` segments
                    if len(vehicle_trails[vid]) > trail_length:
                        old_line = vehicle_trails[vid].pop(0)
                        old_line.remove()

                    # Update fading alpha
                    for j, l in enumerate(vehicle_trails[vid]):
                        l.set_alpha((j + 1) / trail_length)

                    artists.extend(vehicle_trails[vid])
        return artists

    ani = FuncAnimation(
        fig, update, frames=num_frames, blit=True, interval=1000 / fps, repeat=False
    )

    # Save as mp4 using ffmpeg
    writer = FFMpegWriter(
        fps=fps, codec="libx264", bitrate=-1, extra_args=["-pix_fmt", "yuv420p"]
    )
    ani.save(save_path, writer=writer)
    plt.close(fig)
    print(f"Video saved to {save_path}")


def visualize_simulation_figure(
    simulation,
    save_path="trajectory.png",
    sample_interval=10,
    *,
    ids=None,
    violated_rules=None,
    truncate=0,
):
    """Draw sampled agent footprints, centroid paths, and occupied lanes.

    Adapted from Mosaic's visualize_simulation_figure for this runner's named
    polygon records. Always include the final frame, even between intervals.
    """
    if sample_interval < 1 or int(sample_interval) != sample_interval:
        raise ValueError("sample_interval must be a positive integer")
    sample_interval = int(sample_interval)
    if ids is None:
        ids = getattr(simulation, "polygon_record_ids", None)
    if ids is None:
        ids = [key for key in simulation.records if key.endswith("Poly")]
    trajectories = {}
    for record_id in ids:
        if record_id not in simulation.records:
            raise ValueError(f"ID {record_id} not found in simulation records.")
        trajectories[record_id] = simulation.records[record_id][truncate:]
    agents = {
        key: trajectory
        for key, trajectory in trajectories.items()
        if "Lane" not in key and any(poly is not None for _, poly in trajectory)
    }
    if not agents:
        raise ValueError("No agent polygon samples found for the trajectory figure.")

    def sampled_indices(trajectory):
        indices = list(range(0, len(trajectory), sample_interval))
        if indices and indices[-1] != len(trajectory) - 1:
            indices.append(len(trajectory) - 1)
        return indices

    fig, ax = plt.subplots(figsize=(10, 10))
    try:
        ax.set_aspect("equal", "box")
        seen_lanes = set()
        for record_id, trajectory in trajectories.items():
            if "Lane" not in record_id:
                continue
            for frame in sampled_indices(trajectory):
                lane = trajectory[frame][1]
                if lane is None or lane.wkb in seen_lanes:
                    continue
                seen_lanes.add(lane.wkb)
                ax.add_patch(
                    Polygon(
                        list(lane.exterior.coords), closed=True,
                        facecolor="lightgray", edgecolor="gray",
                        linewidth=0.8, alpha=0.18, zorder=0,
                    )
                )

        all_x, all_y = [], []
        legend_handles = []
        for index, (record_id, trajectory) in enumerate(agents.items()):
            color = plt.cm.tab10(index % 10)
            samples = [
                trajectory[frame][1]
                for frame in sampled_indices(trajectory)
                if trajectory[frame][1] is not None
            ]
            if not samples:
                continue
            centroids = [polygon.centroid for polygon in samples]
            is_ego = record_id == "egoPoly"
            line_width = 2.6 if is_ego else 1.8
            ax.plot(
                [point.x for point in centroids],
                [point.y for point in centroids],
                color=color, linewidth=line_width, alpha=0.85, zorder=2,
            )
            for sample_index, polygon in enumerate(samples):
                x_coords, y_coords = polygon.exterior.xy
                all_x.extend(x_coords)
                all_y.extend(y_coords)
                progress = sample_index / max(len(samples) - 1, 1)
                ax.add_patch(
                    Polygon(
                        list(polygon.exterior.coords), closed=True,
                        facecolor=color, edgecolor=color,
                        linewidth=1.5 if is_ego else 1.0,
                        alpha=0.15 + 0.4 * progress, zorder=3,
                    )
                )
                centroid = polygon.centroid
                ax.annotate(
                    str(sample_index + 1), (centroid.x, centroid.y),
                    xytext=(4, -9), textcoords="offset points",
                    fontsize=7, ha="left", va="top", color=color,
                    bbox={
                        "boxstyle": "round,pad=0.12", "facecolor": "white",
                        "edgecolor": color, "linewidth": 0.5, "alpha": 0.85,
                    },
                    zorder=5,
                )
            start, end = centroids[0], centroids[-1]
            ax.scatter(start.x, start.y, color=color, marker="o", s=45, zorder=4)
            ax.scatter(end.x, end.y, color=color, marker="*", s=110, zorder=4)
            legend_handles.append(
                Line2D([0], [0], color=color, linewidth=line_width,
                       label=record_id[:-4])
            )

        if not all_x:
            raise ValueError("No agent polygon samples found at the selected frames.")
        # Frame the agents rather than entire lanes, which can be very long.
        span = max(max(all_x) - min(all_x), max(all_y) - min(all_y)) + 20
        center_x = (min(all_x) + max(all_x)) / 2
        center_y = (min(all_y) + max(all_y)) / 2
        ax.set_xlim(center_x - span / 2, center_x + span / 2)
        ax.set_ylim(center_y - span / 2, center_y + span / 2)
        marker_handles = [
            Line2D([0], [0], color="black", marker="o", linestyle="None",
                   label="start point"),
            Line2D([0], [0], color="black", marker="*", markersize=10,
                   linestyle="None", label="end point"),
        ]
        ax.legend(handles=legend_handles + marker_handles, loc="best")
        ax.set_xlabel("x (m)")
        ax.set_ylabel("y (m)")
        ax.set_title("Agent trajectories")
        ax.grid(alpha=0.2)
        if violated_rules:
            ax.text(
                0.02, 0.98, "\n".join(violated_rules), transform=ax.transAxes,
                ha="left", va="top", color="red",
                bbox=dict(facecolor="white", alpha=0.7, edgecolor="none"),
            )
        output_path = Path(save_path)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        fig.savefig(str(output_path), dpi=200, bbox_inches="tight")
    finally:
        plt.close(fig)
    print(f"Trajectory figure saved to {output_path}")


def default_visualization_path(file_path):
    """Place the video beside the directory containing the Scenic program."""
    scenario_path = Path(file_path)
    return (
        scenario_path.parent.parent
        / "visualizations"
        / scenario_path.with_suffix(".mp4").name
    )


def run_and_visualize_scenario(
    file_path,
    *,
    max_steps=100,
    seed=None,
    maxIterations=10,
    map_path=None,
    xodr_map_path=None,
    violated_rules=None,
    save_path=None,
    fps=10,
    trail_length=15,
    truncate=0,
    sample_interval=10,
    video=True,
    png=False,
):
    """Run once and optionally save an MP4 (default on) and PNG (default off)."""
    if png and (sample_interval < 1 or int(sample_interval) != sample_interval):
        raise ValueError("sample_interval must be a positive integer")
    output_path = (
        Path(save_path) if save_path is not None else default_visualization_path(file_path)
    )
    simulation = run_metadrive_scenario(
        file_path,
        max_steps=max_steps,
        seed=seed,
        maxIterations=maxIterations,
        map_path=map_path,
        xodr_map_path=xodr_map_path,
    )
    if video or png:
        output_path.parent.mkdir(parents=True, exist_ok=True)
    if video:
        visualize_simulation(
            simulation,
            violated_rules=violated_rules,
            save_path=str(output_path),
            fps=fps,
            trail_length=trail_length,
            truncate=truncate,
        )
    if png:
        visualize_simulation_figure(
            simulation,
            save_path=str(output_path.with_suffix(".png")),
            sample_interval=sample_interval,
            violated_rules=violated_rules,
            truncate=truncate,
        )
    return simulation


def _parse_bool(value):
    value = value.lower()
    if value not in ("true", "false"):
        raise argparse.ArgumentTypeError("expected true or false")
    return value == "true"


def main():
    parser = argparse.ArgumentParser(
        description="Run a Scenic scenario in MetaDrive with optional MP4 and trajectory PNG output."
    )
    parser.add_argument("scenario", help="Path to the input Scenic program")
    parser.add_argument(
        "--save-path",
        help="Output visualizations path (default: visualizations/ beside the scenario directory)",
    )
    parser.add_argument(
        "--video", type=_parse_bool, default=True, metavar="{true,false}",
        help="Save an MP4 visualization (default: true)",
    )
    parser.add_argument(
        "--png", type=_parse_bool, default=False, metavar="{true,false}",
        help="Save a static trajectory figure (default: false)",
    )
    parser.add_argument(
        "--sample-interval", type=int, default=10,
        help="Frames between agent footprints in the trajectory figure (default: 10)",
    )
    parser.add_argument(
        "--map-path",
        help="SUMO .net.xml override (default: companion of the Scenic map)",
    )
    parser.add_argument(
        "--xodr-map-path",
        help="OpenDRIVE .xodr override for both Scenic and MetaDrive",
    )
    args = parser.parse_args()

    run_and_visualize_scenario(
        args.scenario,
        save_path=args.save_path,
        map_path=args.map_path,
        xodr_map_path=args.xodr_map_path,
        sample_interval=args.sample_interval,
        video=args.video,
        png=args.png,
        max_steps=120,
        seed=0,
    )


if __name__ == "__main__":
    main()
