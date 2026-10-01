# Export Node Connectivity CSV

**Script:** [UIIE-ExportNodeConnectivity_CSV.rb](./UIIE-ExportNodeConnectivity_CSV.rb)

## Purpose

For each **seed node**, trace the collection pipe network **upstream** and **downstream** and write a CSV of connected nodes whose `node_type` is in a configurable list (for example treatment works, pumping stations, overflows).

The script is **read-only** against the network (no `write`, commit, or reserve).

## Configuration

Edit the **User configuration** block at the top of the script before running:

| Setting | Description |
|---------|-------------|
| `NODE_TABLE` | Node table to trace (typically `cams_manhole`) |
| `REFERENCE_FIELD` | Field exported as **Reference** on each seed row |
| `NAME_FIELD` | Field exported as **Name**; also used when building upstream/downstream labels |
| `OPERATIONAL_STATUS_FIELD` | Field checked for operational eligibility |
| `OPERATIONAL_STATUS_TOKEN` | Required first comma-separated token in that field (case insensitive), e.g. `LIVE` in `LIVE,SWR,F,T2011` |
| `MAJOR_NODE_TYPES` | `node_type` values listed in **Upstream** / **Downstream** |
| `PIPE_STATUS_EXCLUDE` | Pipe `status` value that must not be traversed (commonly `AB`) |
| `APPEND_NODE_TYPE_TO_LABEL` | When true, list entries are `{NAME_FIELD}/{node_type}` |
| `LIST_SEPARATOR` | Character between multiple entries in one cell (default `;`) |
| `SKIP_INELIGIBLE_SEEDS` | Skip seed nodes that fail the operational status check |
| `CSV_COLUMNS` | Header row and column order |

Default values match a typical custom-field layout (`user_text_11`, `user_text_12`, `user_text_19`) and major types **STW**, **PST**, **CSO**, **DTK**. Change them to match your network.

## Trace behaviour

- Full upstream and full downstream from each seed (`us_links` / `ds_links`).
- **All** reachable nodes of the configured types on any path (not shortest-path only).
- Other node types are used for traversal only.
- List entries are sorted **alphabetically**.
- The seed node is not included in its own upstream/downstream lists.

## CSV output

Default columns: `Reference`, `Name`, `Node_ID`, `Node_Type`, `Upstream`, `Downstream`.

## UI usage

1. Open the target **Collection Network** on the GeoPlan.
2. Select seed **nodes** on the map, **or** note Selection List ID(s).
3. **Network → Run Ruby Script…** and choose `UIIE-ExportNodeConnectivity_CSV.rb`.
4. Set input source (current selection or Selection List ID(s)), output folder, and filename (default `Node_Connectivity_YYYYMMDD_HHMMSS.csv`).

## Exchange usage

Edit the **Exchange configuration** block at the top of the script:

| Setting | Description |
|---------|-------------|
| `exchange_database` | Workgroup database connection string |
| `collection_network_id` | Numeric Collection Network ID |
| `use_current_selection` | Use `false` and set Selection List ID(s) for batch runs |
| `selection_list_ids` | Comma-separated Selection List ID(s) |
| `output_folder` | Folder for the CSV file |
| `output_filename` | File name (blank = timestamped default) |

Run via InfoAsset Exchange (see [Ruby README](../../README.md)).

## Related examples

| Script | Notes |
|--------|--------|
| [UI-NodeTraceUpstream.rb](../UI-NodeTraceUpstream.rb) | Upstream trace → GeoPlan selection |
| [UI-NodeTraceUpDownstream_ExcludeBy_PipeStatus.rb](../UI-NodeTraceUpDownstream_ExcludeBy_PipeStatus.rb) | Up/down trace; skip pipe status AB |
| [UI-PipeTraceUpstream_SaveToSelectionList.rb](../UI-PipeTraceUpstream_SaveToSelectionList.rb) | Upstream trace → Selection List |

Other trace examples: [0014 Network Trace Readme](../Readme.md). SQL tracing: [02 SQL/0001 Network Tracing](../../../02%20SQL/0001%20Network%20Tracing/readme.md)
