# Select Objects

InfoAsset Manager **UI** Ruby scripts for making GeoPlan selections from object data.

**Run from:** Network → Run Ruby Script… (Collection Network open on the GeoPlan)

---

## [UI-SelectAssetsBySharedFieldValue.rb](./UI-SelectAssetsBySharedFieldValue.rb)

Selects objects across multiple CAMS asset tables where a named field matches a value entered at runtime. Useful when the same identifier or shared value appears on more than one asset type (for example a custom `user_text_n` field, `node_id`, or `location`).

### Asset tables searched

The script can search any of these tables that exist in the open network:

`cams_channel`, `cams_connection_node`, `cams_connection_pipe`, `cams_data_logger`, `cams_defence_area`, `cams_defence_structure`, `cams_flume`, `cams_general_asset`, `cams_general_line`, `cams_generator`, `cams_manhole`, `cams_orifice`, `cams_outlet`, `cams_pipe`, `cams_pump`, `cams_pump_station`, `cams_screen`, `cams_siphon`, `cams_sluice`, `cams_storage`, `cams_wtw`, `cams_ancillary`, `cams_valve`, `cams_vortex`, `cams_weir`

Tables not present in the current network are listed in the Ruby console and are not shown in the first prompt.

### Prompts

| Step | Dialog | Options |
|------|--------|---------|
| 1 | **Select Asset Tables** | Checkboxes for each available asset table shown as **Display Name (tablename)**, sorted alphabetically by display name, plus **Select / deselect all asset tables**. |
| 2 | **Search Criteria** | **Field name**, **Value to match**, **Use wildcard search (*, ?)?**, readonly wildcard note, **Append to existing selection?** |

### Behaviour

- Only **top-level** object fields are searched (not blob sub-table fields such as `details`).
- Field names are matched case-insensitively on each table. If the field does not exist on a selected table, that table is skipped and reported in the Ruby console log.
- **String fields:** exact match, case-insensitive (for example `ABC` matches `abc`).
- **Numeric fields** (`Double`, `Long`, `Integer`, `Float`): compares the underlying numeric value, so `1` matches `1.0`, `1.00`, and so on. Display precision in the grid does not affect matching.
- **Use wildcard search?** unchecked (default): exact match as above.
- **Use wildcard search?** checked: glob-style matching — `*` matches any characters, `?` matches one character (case-insensitive).
- **Append to existing selection?** unchecked (default): clears the current selection, then selects matching objects.
- **Append to existing selection?** checked: keeps the current selection and adds matching objects.
- Leaving **Value to match** empty selects objects where the field is blank or null.

### Example wildcard values

| Value to match | Matches |
|----------------|---------|
| `MAIN*` | Values starting with `MAIN` |
| `*STREET*` | Values containing `STREET` |
| `MH?01` | Values such as `MH101`, `MHA01` |
| `MH?0*` | Values such as `MH102`, `MHA0211` |
| `1.*` | Values such as `1.0`, `1.5`|

### Console output

The script logs how many objects were selected per table, a summary total, and any tables skipped because the field was not found.

---

## [UI-SelectNetworkObjectsBySharedFieldValue.rb](./UI-SelectNetworkObjectsBySharedFieldValue.rb)

Same selection behaviour as [UI-SelectAssetsBySharedFieldValue.rb](./UI-SelectAssetsBySharedFieldValue.rb), but the first prompt lists **every object table** in the open network (sorted alphabetically) instead of a fixed CAMS asset list.

Use this script when the shared value may appear on assets, surveys, incidents, repairs, zones, or other object types.

### Prompts

| Step | Dialog | Options |
|------|--------|---------|
| 1 | **Select Object Tables** | Checkboxes for each table in the open network shown as **Display Name (tablename)**, sorted alphabetically by display name, plus **Select / deselect all object tables**. |
| 2 | **Search Criteria** | Same options as the asset-only script above. |

All other behaviour (field matching, wildcard search, append option, skipped tables, and console logging) is the same.

---

## [UI-CCTVSurveyDetails.rb](./UI-CCTVSurveyDetails.rb)

Selects `cams_cctv_survey` objects where the `details` blob contains at least one row with:

- `code` starting with `T` (case-insensitive), and
- `remarks` containing `X` anywhere (case-insensitive).

No prompt dialog — run the script directly. Matching surveys are selected on the GeoPlan; the existing selection is not cleared first.
