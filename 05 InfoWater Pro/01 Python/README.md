# InfoWater Pro open source scripts

This repository hosts open source Python scripts for **InfoWater Pro 2025.0 or later**.

Scripts use the [`infowater.output.manager`](https://help.autodesk.com/cloudhelp/ENU/INFWP-UserGuide/files/GUID-4E37DBD2-3ED6-4527-8F3D-18C1893799AF.htm) API to read hydraulic simulation results from **HYDQUA.OUT** files.

## Before you start

- Run scripts from the **ArcGIS Pro Python window** (or a script tool) with your InfoWater project open and initialized.
- A **simulation must have been run** for the scenario you want to read. The Output Manager opens result files on disk; it does not run the model.
- Official API reference: [How to leverage Python scripting within InfoWater Pro](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/How-to-leverage-Python-scripting-within-InfoWater-Pro.html)

## Project folders (quick reference)

An InfoWater Pro project lives next to your `.aprx` file. These folders come up often in scripts:

| Path | What it is |
|------|------------|
| `MyProject.aprx` | ArcGIS Pro project file |
| `MyProject.IWDB/` | Saved model database (persisted with the project) |
| `.../IWVDB##/` | **Live working copy** of the model while editing (temporary path; number varies) |
| `MyProject.OUT/SCENARIO/{name}/HYDQUA.OUT` | Hydraulic results for scenario `{name}` |

**IWVDB** is the folder InfoWater Pro uses during an editing session. It holds live model tables (`Project.ini`, `DMNODE.DBF`, etc.) and reflects the scenario currently loaded in the application. Scripts that need “what scenario is active right now?” should read **`Project.ini`** inside the IWVDB folder:

```ini
Active Model Scenario ID=BASE
```

**HYDQUA.OUT** is the binary results file passed to the Output Manager. Scenario folder names are **case-sensitive** (`BASE` ≠ `Base`).

Typical layout:

```
MyProject/
  MyProject.aprx
  MyProject.IWDB/
  MyProject.OUT/
    SCENARIO/
      BASE/
        HYDQUA.OUT
      BREAK/
        HYDQUA.OUT
```

## Sample getting started

Start with **`output_manager_quickstart.py`**. It resolves paths from the open project so you do not hard-code example paths like Net1.

The script:

1. Finds the **IWVDB** folder from map layer data sources
2. Reads the **active scenario** from `Project.ini` (or uses a scenario you specify)
3. Opens **`{ProjectName}.OUT/SCENARIO/{scenario}/HYDQUA.OUT`**
4. Calls `get_range_data` for average junction pressure

Run it from the ArcGIS Pro Python window with your project open:

```python
# Paste or run output_manager_quickstart.py
```

Or adapt the core pattern in your own script:

```python
import arcpy
from pathlib import Path
from infowater.output.manager import Manager

# *Active* = currently loaded scenario (InfoWater Pro convention); or e.g. "BASE"
SCENARIO = "*Active*"

aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
project_name = Path(aprx.filePath).stem

# ... find iwvdb_dir, resolve scenario from Project.ini when SCENARIO is *Active* ...

hydqua_path = project_path / f"{project_name}.OUT" / "SCENARIO" / "BASE" / "HYDQUA.OUT"
outman = Manager(str(hydqua_path))

# Range stats for all junctions (Min, Max, Avg, etc. also available)
pressure_avg = outman.get_range_data("Junction", "Pressure", "Avg")
```

See **`output_manager_quickstart.py`** for the full working version with IWVDB lookup, scenario resolution, and clear errors when output is missing.

### Scenario selection

| `SCENARIO` value | Behavior |
|------------------|----------|
| `"*Active*"` | Use `Active Model Scenario ID` from `Project.ini` in the IWVDB folder |
| `"BASE"` (or any name) | Use that scenario folder under `.OUT/SCENARIO/` |

If the chosen scenario has no **HYDQUA.OUT**, the starter script stops with an error listing scenarios that do have results.

### What you can do next

Once you have an `outman` object:

```python
times = outman.get_time_list()
junctions = outman.get_element_list("Junction")
series = outman.get_time_data("Junction", "21", "Pressure")
```

Element types include `Junction`, `Pipe`, `Pump`, `Tank`, `Reservoir`, and `Valve`. Field names are case-sensitive.

## Copy examples to your project

Download any included `.ipynb` or `.py` files and add them to your ArcGIS Pro catalog (**Catalog → Notebooks → Add Notebook**, or copy `.py` scripts into your project folder).

Most examples assume an open `.aprx` project. Prefer **`output_manager_quickstart.py`** as the template for path and scenario handling; older examples may use hard-coded paths that you will need to update.
