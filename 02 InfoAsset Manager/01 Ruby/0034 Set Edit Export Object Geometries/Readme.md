# Set, Edit, and Export Object Geometries

InfoAsset Manager **UI** Ruby examples for **reading, updating, or exporting** geometry stored on network objects — polyline bend vertices (`point_array`), point **X/Y** fields, and coordinates derived from related assets.

**Run from:** **Network → Run Ruby Script…** (with a network open on the GeoPlan), unless noted otherwise.

Works primarily on **Collection (CAMS)** networks in the examples below; the same Ruby patterns apply to other profiles where equivalent tables and fields exist.

---

## Folder name

This folder was previously named `0034 Display Export geometries`. The current title **Set Edit Export Geometries** reflects three activities covered here:

| Activity | Examples in this folder |
|----------|-------------------------|
| **Set** | Write coordinates or geometry-related values onto objects |
| **Edit** | Transform or populate geometry fields from other network data |
| **Export** | Write geometry to the console, CSV, or other external formats |

---

## Related folders (not duplicates)

| Folder | Focus |
|--------|--------|
| [0040 Convert Coordinate Values](../0040%20Convert%20Coordinate%20Values/ReadMe.md) | **Reproject** existing X/Y between CRS (for example WGS84 → UTM) |
| [0041 Export to GeoJSON](../0041%20Export%20to%20GeoJSON/ReadMe.md) | **Bulk export** of nodes and links to GeoJSON via Selection Lists |
| [0017 Update-Set Field Values](../0017%20Update-Set%20Field%20Values/Readme.md) | Generic **non-geometry** field updates (notes, user text, and so on) |

Use **0034** when the task is about **where** something is on the map (vertices, centroids, polyline shape), not datum conversion or full-network GIS export.

---

## Geometry concepts in InfoAsset Manager

### Pipe polylines (`cams_pipe`)

- Straight links are defined by **upstream** and **downstream** nodes (`us_node` / `ds_node` and their X/Y).
- **Bends** and intermediate vertices are stored in the **`point_array`** blob (a sequence of x/y pairs).
- Pipe identity in scripts is usually `us_node_id`, `ds_node_id`, and `link_suffix`.

### Point objects (for example `cams_general_survey`, manholes)

- **X coordinate** / **Y coordinate** map to fields `x` and `y`.
- Point surveys may relate to a pipe via the product relationship (`navigate1('pipe')`), **`asset_type`** / **`asset_id`**, or pipe link fields on the survey.

### Typical Ruby access

```ruby
net = WSApplication.current_network
pipe = net.row_object('cams_pipe', 'US.DS. ')
pa   = pipe.point_array          # bend vertices
x    = survey.x                  # point coordinates
pipe = survey.navigate1('pipe')  # related pipe when linked in the UI
```

See also [`03 Context/InfoAsset_Manager_Ruby_Patterns.md`](../../03%20Context/InfoAsset_Manager_Ruby_Patterns.md) (navigation from surveys to pipes) and [`UI-CreateInfoAssetOnlineURLHyperlinks.rb`](../0047%20Create%20InfoAsset%20Online%20URL%20Hyperlinks/UI-CreateInfoAssetOnlineURLHyperlinks.rb) for shared `point_array` parsing helpers used elsewhere in this repository.

---

## Scripts

### [UI-SetGeneralSurveyXYFromPipeCentroid.rb](./UI-SetGeneralSurveyXYFromPipeCentroid.rb)

Sets **X** and **Y** on **General Survey** (`cams_general_survey`) point objects from the **centroid** of a related **Pipe** polyline.

**When to use:** General Surveys are linked to a pipe but X/Y were not filled automatically (common for point geometry with an asset relationship only).

**Pipe resolution** (first match wins):

1. `navigate1('pipe')`
2. `asset_type` = pipe and `asset_id` = pipe ID
3. Survey link fields: `us_node_id`, `ds_node_id`, `link_suffix`

**Centroid:** Point at **half the total arc length** along the pipe, using `point_array` vertices. If `point_array` is empty, uses the midpoint of upstream and downstream node coordinates.

**Prompts:**

| Option | Description |
|--------|-------------|
| **Run on** | **Selected General Surveys** (default) or whole network |
| **Update mode** | **Fill blanks only** (default) or **Overwrite existing** |

Outputs per-object lines to the Ruby console and a summary message box (updated / skipped / errors). Changes run inside one transaction.

---

### [UI-ExportPipeArrayCSV.rb](./UI-ExportPipeArrayCSV.rb)

**Displays** each selected pipe’s `point_array` in the console and **exports** upstream node ID, downstream node ID, link suffix, and `point_array` to a CSV file.

**When to use:** Inspect or archive bend vertices for pipes already selected on the GeoPlan (QA, hand-off to GIS, or debugging geometry).

**Before running:**

1. Select pipes on the GeoPlan.
2. Edit the output path in the script (default `c:\temp\pipes.csv` on line 5).

**Scope:** `row_objects_selection('cams_pipe')` only — remove `_selection` in the script to process all pipes (use with care on large networks).

**Console:** One line per pipe (with or without `point_array`).

---

### [UI-SetFieldWithPipePointArray.rb](./UI-SetFieldWithPipePointArray.rb)

Copies each pipe’s **`point_array`** into **`user_text_33`** (as text) for all pipes in the network, and prints ID plus `point_array` to the console.

**When to use:** Quick visibility of bend data in a user text field (reports, ad hoc review). Site-specific — change the target field name if `user_text_33` is not available on your schema.

**Scope:** All `cams_pipe` objects (no selection filter).

**Caution:** Overwrites `user_text_33` on every pipe. Wrap in a transaction; adjust the field name before production use.

---

## Suggested workflows

### Place General Surveys on pipe centroids

1. Ensure surveys are related to pipes (relationship or asset/link fields).
2. Run **UI-SetGeneralSurveyXYFromPipeCentroid.rb** on selection or whole network with **Fill blanks only**.
3. Refresh the GeoPlan and confirm point positions.

### Audit pipe bend geometry

1. Select pipes of interest.
2. Run **UI-ExportPipeArrayCSV.rb** (after setting the CSV path).
3. Compare CSV with map or external GIS.

### Expose bends in a text field for reporting

1. Confirm **`user_text_33`** (or edit script to another free user text field).
2. Run **UI-SetFieldWithPipePointArray.rb** on a test network first.
3. Use the field in lists or exports as needed.

---

## Adding scripts to this folder

Place new **UI** scripts here when they:

- Read or write **`point_array`**, **x/y**, or other geometry stored on row objects;
- Derive coordinates from network geometry (centroid, midpoint, intersection, and so on);
- Export or log geometry to files or the console for inspection.

Prefer **prompts**, **selection** options, and **transaction** boundaries for anything that modifies the network. Document hardcoded paths or field names in the script header and in this readme.

For CRS conversion, use **0040**. For GeoJSON bulk export, use **0041**. For arbitrary field bulk edit (notes, flags), use **0017**.
