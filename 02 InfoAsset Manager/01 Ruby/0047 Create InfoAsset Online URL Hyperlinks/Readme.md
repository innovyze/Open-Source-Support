# Create InfoAsset Online URL Hyperlinks

## Script

[UI-CreateInfoAssetOnlineURLHyperlinks.rb](./UI-CreateInfoAssetOnlineURLHyperlinks.rb)

## Purpose

Generates **InfoAsset Online (IAO)** deep-link URLs for `cams_*` objects in the active Collection Network (all objects, or GeoPlan selection only). For each object the script:

1. Computes a representative map centre (point, line midpoint, or polygon centroid).
2. Converts coordinates from the chosen source CRS to WGS84 latitude/longitude.
3. Builds an IAO URL that opens the map at that location and selects the object.
4. Writes the URL to an **IAO url Link** hyperlink on the object.
5. Optionally writes a single combined HTML report when an output folder is provided.

## Prerequisites

- Open the target **Collection Network** in InfoAsset Manager before running the script.
- Know your IAO server hostname (without `https://`) and workspace ID.
- Object `x`/`y` or geometry must be stored in the coordinate system selected in the prompt.

## Usage

1. Open the Collection Network in InfoAsset Manager.
2. Run via **Network → Run Ruby Script…** and select `UI-CreateInfoAssetOnlineURLHyperlinks.rb`.
3. Enter IAO server, workspace ID, and coordinate system.
4. Optionally tick **Process SELECTION only?** and select objects on the GeoPlan first.
5. Optionally choose an **HTML output folder** to write a combined report.
6. Test links in InfoAsset Online.

### Prompt options

| Field | Description |
|---|---|
| **The IAO Server Address** | Hostname only (for example `localhost` or your organisation's IAO host) |
| **The IAO Workspace ID** | Numeric workspace ID from the IAO URL (`webwsp.{id}`) |
| **Coordinate System** | Source CRS of stored coordinates |
| **HTML output folder (optional)** | Leave blank to update hyperlinks only; set a folder to write one combined HTML file |
| **Process SELECTION only?** | When ticked, only GeoPlan-selected objects are processed in each `cams_*` table |

## Output

When an HTML output folder is provided, the script writes a single tabbed HTML file:

- `{Network}_ALL_IAO({workspace}){timestamp}.html`

Columns in each table tab: `object_id`, `center_x`, `center_y`, `latitude`, `longitude`, `url`.

When the output folder is left blank, hyperlinks are still updated on network objects and no HTML file is created. Links in the HTML report open in a new browser tab.

When **Process SELECTION only?** is ticked but no objects are selected, the script completes without changes and reports that no selected objects were found.

## Supported coordinate systems

| EPSG | Description |
|---|---|
| 31370 | Belge 1972 / Belgian Lambert 72 |
| 29902 | Irish Grid (TM65) |
| 27700 | British National Grid (OSGB36) |
| 3857 | Web Mercator |
| 4326 | WGS84 (x = longitude, y = latitude) |

When the optional EPSG reference CSV is not present, the built-in list above is used. The default selection prefers EPSG:31370 when available, then EPSG:29902.

An optional EPSG reference CSV can be placed at `C:/temp/ESPG.csv` with columns `epsg_code` and `name` to extend or replace the built-in list.

## URL format

URLs follow the InfoAsset Online pattern:

```
https://{server}:30303/InfoAssetOnline/en-us/workspaces/webwsp.{workspace}#map;zoom=17.5;lat={lat};lon={lon}/activeObject;uri=mo%252Fcnn%252Fcnn.{network_id}%252Fro%253Ftable%253D{table}&id%253D{object_id}
```

Latitude and longitude are formatted to five decimal places in the URL. Object IDs containing characters such as `|` or `=` are double URL-encoded in the `id` portion (for example `asset|123|u=ABC` becomes `asset%25257C123%25257Cu%25253DABC`).

For link objects (pipes, etc.), the object ID in the URL uses the `us_node_id.ds_node_id.link_suffix` form when available.

## Notes

- Existing hyperlinks named **IAO url Link** (case-insensitive) are updated in place; otherwise a new hyperlink is appended.
- Conversion is calculated in Ruby — no external libraries are required.
