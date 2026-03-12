# Run Mesh Job

Runs a 2D mesh generation job on a network in InfoWorks ICM via ICMExchange, targeting a specified scenario and ground model.

**IMPORTANT:** This script must be run from **ICMExchange** — it cannot be run from the InfoWorks ICM UI.

## Usage

```
ICMExchange.exe EX_Script.rb <database_path> <network_id> <scenario_name> <ground_model_id>
```

### Arguments

| Argument           | Description                                                                 |
|--------------------|-----------------------------------------------------------------------------|
| `database_path`    | Path to the database (e.g. `cloud://...` or a local `.icmm` path)          |
| `network_id`       | Integer ID of the Model Network to mesh                                     |
| `scenario_name`    | Scenario to set before meshing (e.g. `Base`)                                |
| `ground_model_id`  | Ground model ID — positive integer for a grid, negative integer for a TIN   |

> ICMExchange automatically injects `ARGV[0]="ADSK"` before your arguments, so your first argument begins at `ARGV[1]`.

## What It Does

1. Opens the database and locates the network by ID
2. Sets the active scenario
3. Configures mesh options (ground model, all 2D zones, no lower element ground levels)
4. Calls `net.mesh()` and reports per-zone success/failure
5. Commits the network if at least one zone succeeded
6. Exits with a raised error if any zone failed, so ICMExchange reports a non-zero exit code

## Notes

- All 2D zones in the network are meshed. To target specific zones, set `'2DZones'` to an array of zone names in `mesh_options`.
- To use building polygons as mesh voids, uncomment the `'VoidsCategory'` line and set the appropriate polygon category name.
- The script runs the mesh job locally (`'RunOn' => '.'`). Change this to a server name to offload the job.
