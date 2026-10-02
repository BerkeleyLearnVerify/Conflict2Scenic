import argparse
import re
import random
import tempfile
from contextlib import contextmanager
from pathlib import Path

import matplotlib.pyplot as plt
import scenic
from matplotlib.animation import FFMpegWriter, FuncAnimation
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
            extra_lines.append(f"record {agent}.lane.polygon as {lane_polygon_id}")

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


def run_metadrive_scenario(
    file_path,
    max_steps=100,
    seed=None,
    maxIterations=10,
    map_path="maps/Town05.net.xml",
    xodr_map_path="maps/Town05.xodr",
):
    if seed is not None:
        random.seed(seed)
    scenic.setDebuggingOptions(
        verbosity=1, fullBacktrace=True, debugExceptions=False, debugRejections=False
    )
    with recorded_polygon_program(file_path) as (run_file_path, polygon_record_ids):
        scenario = scenic.scenarioFromFile(
            run_file_path, model="scenic.simulators.metadrive.model", mode2D=True
        )
        scene, _ = scenario.generate()
        simulator = MetaDriveSimulator(
            sumo_map=map_path,
            xodr_map=xodr_map_path,
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
            list(poly.exterior.coords),
            closed=True,
            facecolor=facecolor,
            alpha=alpha,
            edgecolor="black",
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
                poly.centroid.x,
                poly.centroid.y,
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
    map_path="maps/Town05.net.xml",
    xodr_map_path="maps/Town05.xodr",
    violated_rules=None,
    save_path=None,
    fps=10,
    trail_length=15,
    truncate=0,
):
    """Run a Scenic program and visualize every recorded agent/lane polygon."""
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
    output_path.parent.mkdir(parents=True, exist_ok=True)
    visualize_simulation(
        simulation,
        violated_rules=violated_rules,
        save_path=str(output_path),
        fps=fps,
        trail_length=trail_length,
        truncate=truncate,
    )
    return simulation


def main():
    parser = argparse.ArgumentParser(
        description="Run a Scenic scenario in MetaDrive and save its visualization."
    )
    parser.add_argument("scenario", help="Path to the input Scenic program")
    parser.add_argument(
        "--save-path",
        help="Output MP4 path (default: visualizations/ beside the scenario directory)",
    )
    args = parser.parse_args()

    run_and_visualize_scenario(
        args.scenario,
        save_path=args.save_path,
        max_steps=120,
        seed=0,
    )


if __name__ == "__main__":
    main()
