# UI-GeojsonExporter_Selection_List_Group.rb

InfoAsset Manager **UI** Ruby script that exports **one Selection List** (by numeric ID) to CSV (WGS84), then builds GeoJSON for **`cams_pipe`** and **`cams_manhole`**.

**Script file:** `UI-GeojsonExporter_Selection_List_Group.rb`  
**Run from:** Network → Run Ruby Script (Collection Network must be open on the GeoPlan)

---

## When to use this script

Use this script when you know the **Selection List ID** and only want that list exported.

Use **`UI-GeojsonExporter_selections.rb`** instead when you want to export **every** Selection List under an **Asset Group** in one run.

---

## Prerequisites

- Autodesk **InfoAsset Manager** with Ruby Exchange enabled.
- An open **Collection Network** on the GeoPlan (`cams_*` tables present).
- A valid **Selection List** in the same database (numeric ID from the database tree).

---

## How to run

1. Open your `.isfc` database and the target **Collection Network** on the GeoPlan.
2. In the database tree, find the **Selection List** you want and note its **numeric ID** (this is **not** the Asset Group ID).
3. Go to **Network → Run Ruby Script**.
4. Select **`UI-GeojsonExporter_Selection_List_Group.rb`**.
5. Enter the **Selection List ID** when prompted.
6. A **folder browser dialog** opens — select the folder where output should be saved.

The script validates the ID, loads the list onto the network, exports CSV, converts to GeoJSON, then clears the selection.

---

## What you are prompted for

| Step | Prompt | Notes |
|------|--------|--------|
| 1 | **Selection List ID** | Positive integer only (e.g. `1778`). |
| 2 | **Output folder** | Folder browser dialog — `CSV` and `geoJSON` subfolders are created inside. Closing or cancelling the dialog aborts the export. |

The script checks that the ID exists as a **Selection List** object in the current database and prints the list name in the Ruby console when available.

---

## Output files

For network identifier `{nw}` and Selection List ID `{id}`:

```
{output folder}/
  CSV/
    {nw}-{id}-WGS84_cams_pipe.csv
    {nw}-{id}-WGS84_cams_manhole.csv
  geoJSON/
    cams_pipe-{id}.geoJSON
    cams_manhole-{id}.geoJSON
```

- **`{nw}`** — Collection Network model object ID when available, otherwise a sanitised network name.
- Coordinates are **WGS84** (CRS84 in the GeoJSON header).

---

## Export settings

CSV export uses the same options as the other GeoJSON exporters in this folder:

- Selection only (objects in the loaded Selection List)
- WGS84 coordinates
- Packed coordinate arrays
- Separate files per object type (`cams_pipe`, `cams_manhole`)

---

## GeoJSON content

### `cams_pipe`

- Properties: owner, materials, system type, dimensions, inverts, asset/plr identifiers, and related fields (see script for full mapping).
- Geometry: **MultiLineString** from packed `point_array` (two-vertex segments only; longer lines are truncated by design).
- Rows are skipped when: missing `asset_id`, duplicate `asset_id`, null/zero length, or degenerate line.

### `cams_manhole`

- Properties: node id, type, status, access, chamber/cover fields, etc.
- Geometry: **Point** from exported `x` / `y`.

---

## Troubleshooting

### Selection List not found

- Enter the **Selection List** object ID, not the parent **Asset Group** ID.
- Confirm the list belongs to the database you currently have open.

### Invalid ID

The prompt must be a positive integer. Text or decimals are rejected.

### `CSV::InvalidEncodingError`

The script decodes IAM CSV exports as UTF-8, Windows-1252, or ISO-8859-1 before parsing. If encoding errors persist, report your IAM version and locale.

### Empty GeoJSON

- Confirm the Selection List selects pipes and/or manholes when loaded on the GeoPlan.
- Check the Ruby console for per-row skip messages.
- Verify the `CSV\*_cams_pipe.csv` file exists in the output folder.

### No network open / not a Collection Network

Open the correct Collection Network before running the script.

