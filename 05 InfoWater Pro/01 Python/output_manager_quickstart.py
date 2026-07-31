"""
InfoWater Pro — Output Manager quick start
==========================================
Run from the ArcGIS Pro Python window with an InfoWater project open.

Resolves paths from the current .aprx, locates the live model folder (IWVDB*),
reads the active scenario from Project.ini, and opens HYDQUA.OUT for that scenario.

SCENARIO: use "*Active*" for the loaded scenario (InfoWater Pro convention), or a
specific scenario folder name (case-sensitive).
"""

import arcpy
from pathlib import Path
from infowater.output.manager import Manager

# InfoWater Pro uses *Active* for the currently loaded scenario; or set e.g. "BASE"
SCENARIO = "*Active*"

aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
project_name = Path(aprx.filePath).stem


def find_iwvdb_dir() -> Path:
    """Live model folder while editing (contains Project.ini, DMNODE.DBF, etc.)."""
    for m in aprx.listMaps():
        for lyr in m.listLayers():
            ds = getattr(lyr, "dataSource", None)
            if not ds or "IWVDB" not in ds.upper():
                continue
            parts = Path(ds).parts
            for i, part in enumerate(parts):
                if part.upper().startswith("IWVDB"):
                    candidate = Path(*parts[: i + 1])
                    if candidate.is_dir() and (candidate / "Project.ini").is_file():
                        return candidate
    raise FileNotFoundError(
        "Could not find an IWVDB folder from map layer data sources.\n"
        "Initialize InfoWater Pro and ensure model layers are loaded."
    )


def read_active_scenario(ini_path: Path) -> str:
    prefix = "Active Model Scenario ID="
    for line in ini_path.read_text(encoding="utf-8", errors="replace").splitlines():
        s = line.strip()
        if s.lower().startswith(prefix.lower()):
            val = s.split("=", 1)[1].strip().strip('"').strip("'")
            if val:
                return val
    raise ValueError(f"No 'Active Model Scenario ID' found in:\n  {ini_path}")


def list_scenarios_with_results(out_scenario_root: Path) -> list[str]:
    if not out_scenario_root.is_dir():
        return []
    return sorted(
        d.name for d in out_scenario_root.iterdir()
        if d.is_dir() and (d / "HYDQUA.OUT").is_file()
    )


def match_scenario(name: str, available: list[str]) -> str | None:
    if name in available:
        return name
    return {s.lower(): s for s in available}.get(name.lower())


def resolve_scenario_name(scenario: str, ini_path: Path) -> str:
    """Map *Active* to Project.ini; otherwise return the given folder name."""
    if scenario.strip().lower() == "*active*":
        return read_active_scenario(ini_path)
    return scenario


# --- Resolve model folder and active scenario ---
iwvdb_dir = find_iwvdb_dir()
scenario_name = resolve_scenario_name(SCENARIO, iwvdb_dir / "Project.ini")

# --- Build path to hydraulic results for that scenario ---
scenario_root = project_path / f"{project_name}.OUT" / "SCENARIO"
available = list_scenarios_with_results(scenario_root)

matched = match_scenario(scenario_name, available)
if not matched:
    if available:
        hint = f"\nScenarios with HYDQUA.OUT: {', '.join(available)}"
    else:
        hint = f"\nNo HYDQUA.OUT files found under:\n  {scenario_root}"
    raise FileNotFoundError(
        f"Scenario {scenario_name!r} has no hydraulic output (HYDQUA.OUT).{hint}\n"
        "Run a simulation for that scenario first."
    )

hydqua_path = scenario_root / matched / "HYDQUA.OUT"

# --- Read results ---
outman = Manager(str(hydqua_path))
pressure_avg = outman.get_range_data("Junction", "Pressure", "Avg")

print(f"IWVDB folder : {iwvdb_dir}")
print(f"Active scenario : {matched}")
print(f"HYDQUA.OUT : {hydqua_path}")
print(f"Junction count : {len(pressure_avg)}")
