# ODIC delta import from multiple shapefiles (one IAM table)

Example of importing **several ESRI shapefiles** into the **same node table** when GIS supplies a **delta** column (`NEW`, `UPDATED`, `DELETED`). Rows are filtered in an ODIC callback; deletions are applied after all imports complete.

| Script | Purpose |
|--------|---------|
| [UI-odic_delta_import_multiple_shp.rb](./UI-odic_delta_import_multiple_shp.rb) | UI script — run with the target network open |

Related: [0002 ODIC Import](../Readme.md), [0002A ODIC Callback Examples](../../0002A%20ODIC%20Callback%20Examples/).

---

## Pattern

1. **NEW / UPDATED** — record is imported via `odic_import_ex` (create or update using your `.cfg` and `Update Based On Asset ID` / primary-key behaviour).
2. **DELETED** — record is skipped during import; its ID is queued and removed with `row_object` + `delete` in a transaction after all layers run.
3. **Multiple shapefiles** — repeat import with different `.cfg` files and optional callback classes; all target the same ODIC table (e.g. `Node` → `cams_manhole`).

This avoids **Delete missing objects** on partial delta files, which would remove assets not present in the extract.

---

## Setup

1. Copy this folder (or the script) to a short path on your PC.
2. Create subfolders next to the script (defaults in the script):
   - `delta_import_data/` — shapefiles (`.shp`, `.shx`, `.dbf`, `.prj`, …)
   - `delta_import_configs/` — ODIC import configs (`.cfg`)
3. Edit **`IMPORT_SOURCES`** in the script: shapefile names, config names, labels.
4. Edit **`IMPORT_DELTA_VALUES`**, **`DELETE_DELTA_VALUES`**, and **`DELTA_FIELD_NAMES`** if your GIS uses different field names or codes.
5. Save one `.cfg` per shapefile. Start from [example_manhole_delta_import.cfg](./example_manhole_delta_import.cfg):
   - First line must be **`DBI002`** (import), not `DBX002`.
   - Save **without UTF-8 BOM** (BOM breaks the header in some builds).
   - Add registry lines for your network if ODIC requires them (save a full config from the ODIC UI for your database and keep only the mapped line you need, or copy registry lines from that file).
6. Map **`node_id`** (or your primary key) in the `.cfg`. Do not map source fields that are not on the shapefile. Set **`node_type`** in a custom `onEndRecordNode` callback if needed (see commented example in the script).
7. Open the **Collection network** → **Network → Run Ruby Script…** → select the `.rb` file.

---

## Configuration reference (top of script)

| Setting | Meaning |
|---------|---------|
| `IMPORT_DELTA_VALUES` | Import these delta codes (after uppercasing) |
| `DELETE_DELTA_VALUES` | Queue delete by ID for these codes |
| `IMPORT_WHEN_DELTA_BLANK` | If true, rows with no delta value still import |
| `DELETE_ID_SOURCE_FIELDS` | Shapefile column(s) used to find IAM rows to delete |
| `DELETE_NODE_TABLE` | IAM table for deletes (e.g. `cams_manhole`) |
| `ODIC_OPTIONS['Update Based On Asset ID']` | `false` = match on `node_id` from `.cfg`; `true` = match on asset id |

For **pipes** or a second object type, duplicate the pattern with `OnBeginRecordPipe`, a pipe `.cfg`, and `row_objects_from_asset_id('cams_pipe', …)` for deletes.

---

## Customising delta codes

Change the arrays at the top of the script (not each callback):

```ruby
IMPORT_DELTA_VALUES = ['NEW', 'UPDATED', 'INSERT'].freeze
DELETE_DELTA_VALUES = ['DELETED', 'REMOVED'].freeze
```

All listed `IMPORT_SOURCES` share the same `DeltaNodeImporter` unless you assign a different `callback_class`.

---

## Exchange / automation

This example uses `WSApplication.current_network` (UI). For scheduled runs, open the database and model object as in [IE-odic_import_ex-SHP.rb](../IE-odic_import_ex-SHP.rb), call `odic_import_ex` on the **model object**, and `commit` when finished. Keep the same delta helpers and delete pass on `net.open`.

---

## Test data

You can build small point shapefiles with `DELTA_TYPE` and `node_id` using QGIS or `ogr2ogr`. Test on a **copy** of a network before production use.
