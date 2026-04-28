# Export Network Schema to CSV

This folder contains two scripts — one for the static network data schema, one for simulation results fields.

| Script | Purpose | Requires simulation? |
|--------|---------|----------------------|
| `Export Network Schema to CSV.rb` | All tables and their data fields | No |
| `Export Results Schema to CSV.rb` | All tables and their results fields | **Yes** — drag a simulation onto the network first |

---

## Export Network Schema to CSV

### Purpose

Introspects the currently open InfoWorks ICM network and exports a complete list of all tables and their data fields to a single CSV file. Useful for discovering available field names before writing SQL queries or Ruby scripts, and for documenting schema differences between InfoWorks and SWMM networks.

## Key Features

- Works in both **UI** and **Exchange** (headless) modes
- Enumerates every table and field via `net.tables` / `WSTableInfo`
- Tables are sorted alphabetically in the output
- In Exchange mode, set the output path in the configuration block at the top of the script

## Output CSV Columns

| Column | Description |
|--------|-------------|
| `table_name` | Database table name (e.g. `hw_node`, `sw_conduit`) |
| `field_name` | Field/column name used in Ruby `ro['field_name']` or SQL `field_name` |
| `data_type` | Data type string (e.g. `String`, `Double`, `Long`, `Boolean`) |

## Notes

- **InfoWorks networks** expose `hw_*` tables; **SWMM networks** expose `sw_*` tables. Run the script against each network type to compare their schemas.
- Results fields (simulation outputs) are not included — use `net.list_result_field_names` or `WSSimObject#results_fields` for those.
- Custom user fields (`user_number_1`…`user_number_10`, `user_text_1`…`user_text_10`) will appear in the output alongside built-in fields.

## API Used

| Method | Class | Notes |
|--------|-------|-------|
| `net.tables` | `WSOpenNetwork` | Returns Array of `WSTableInfo` objects |
| `table.name` | `WSTableInfo` | Table name string |
| `table.fields` | `WSTableInfo` | Array of `WSFieldInfo` objects |
| `f.name` | `WSFieldInfo` | Field name string |
| `f.data_type` | `WSFieldInfo` | Data type string |

---

## Export Results Schema to CSV

### Purpose

Exports a complete list of all tables that carry simulation results fields, along with every result field code available in those tables. Useful for knowing exactly which field codes to pass to `ro.results('field_code')` in Ruby scripts.

### Requirement

**A simulation must be loaded (dragged) onto the network before running this script.** Results fields are only populated once a simulation is associated with the open network and the table has objects present in the network.

**Important:** Tables whose object type does not exist in this particular network will be absent from the output — even if that object type theoretically supports results. The script returns all result fields for all object types that *exist* in this network, not a global catalogue of every possible result field across all object types.

### Output CSV Columns

| Column | Description |
|--------|-------------|
| `table_name` | Table name (e.g. `hw_1d_results_point`) |
| `field_name` | Results field code passed to `ro.results('field_code')` (e.g. `depnod`, `qlink`) |

### Notes

- Tables with no results fields, or whose object type has no objects in this network, are automatically skipped.
- Results field codes are case-sensitive when used in `ro.results('code')`.

### API Used

| Method | Class | Notes |
|--------|-------|-------|
| `net.tables` | `WSOpenNetwork` | Returns Array of `WSTableInfo` objects |
| `table.results_fields` | `WSTableInfo` | Array of `WSFieldInfo` for results; `nil` if table has none |
| `f.name` | `WSFieldInfo` | Results field code string |
