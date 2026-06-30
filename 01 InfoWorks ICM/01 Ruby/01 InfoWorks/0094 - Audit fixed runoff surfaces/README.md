# Audit Fixed Runoff Surfaces (Exchange)

Read-only Exchange script that scans all InfoWorks model networks in a cloud (or other) database and reports runoff surfaces referenced by subcatchment land uses where:

- `runoff_volume_type` = **fixed** (case-insensitive)
- `runoff_coefficient` **< 0.7**

Results are written to an HTML report with per-network summary tables.

## Lookup chain

1. Collect distinct `land_use_id` values from `hw_subcatchment`
2. Look up each land use in `hw_land_use`
3. Read `runoff_index_1` and `runoff_index_2` only
4. Match each index to `hw_runoff_surface.runoff_index`
5. Flag surfaces meeting the audit condition

## Configuration

Edit constants at the top of [EX_script.rb](EX_script.rb):

| Constant | Purpose |
|----------|---------|
| `DATABASE_PATH` | Cloud or local database path (required unless passed on command line) |
| `SCENARIO` | Scenario for grid data (default: `Base`) |
| `COEFFICIENT_THRESHOLD` | Upper bound for flagging (default: `0.7`, strict less-than) |
| `OUTPUT_PATH` | HTML output file; `nil` = timestamped file next to script |
| `USE_PROCESS_ISOLATION` | When `true` (default), each network is audited in a separate ICMExchange process to avoid native crashes |
| `ICM_EXCHANGE_PATH` | Path to `ICMExchange.exe` when process isolation is enabled |

### Cloud database path

Create and connect to the cloud database in ICM first, then copy the path from:

**Help > About InfoWorks > Additional Information > Database**

Format: `cloud://DatabaseName@orgId/region`

Example:

```ruby
DATABASE_PATH = 'cloud://My Database ICM@abc123def456/namer'
```

## HTML report

The report includes:

- **Database summary** — networks found, scanned, skipped, flagged surface references, subcatchments breaching threshold, data issues
- **Per-network summary** — subcatchment count, land uses in use, breaching subcatchment count, flagged surface count, issue count
- **Flagged runoff surfaces** — land use ID, runoff slot, runoff surface ID, volume type, coefficient, and count of subcatchments using that land use (no individual subcatchment IDs)
- **Data issues** — missing land uses, missing runoff surfaces, empty `land_use_id` counts

Default output: `Runoff_Surface_Audit_YYYYMMDD_HHMMSS.html` in this folder.

Runtime files (safe to delete after a successful run):

- `Runoff_Surface_Audit.log` — step log
- `Runoff_Surface_Audit_PROGRESS.html` — partial report while running
- `audit_results_YYYYMMDD_HHMMSS/` — temporary JSON from isolated network runs

## Limitations

- InfoWorks networks only (`hw_subcatchment` required); SWMM networks are skipped
- Uses top-level `land_use_id` on subcatchments only; `swmm_coverage` land uses are not checked
- Checks runoff slots 1 and 2 only (`runoff_index_1`, `runoff_index_2`)
- Empty, blank, or zero runoff index values are skipped
- Read-only: no network or database modifications
- With process isolation enabled, a failed network is recorded in the report and the audit continues with remaining networks
