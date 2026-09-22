# HTML Attachment Links

HTML reports that list attachment, video, and image file references (with hyperlinks or optional embedded media). Run from **Network → Run Ruby Script…** on the open network.

Parent folder: [0044 Reports](../Readme.md)

## Scripts

| Script | Use when |
|--------|----------|
| [UI-HTMLReport-AttachmentLinks.rb](./UI-HTMLReport-AttachmentLinks.rb) | Export **all** eligible tables in one run |
| [UI-HTMLReport-AttachmentLinks-SelectTables.rb](./UI-HTMLReport-AttachmentLinks-SelectTables.rb) | Choose **which tables** to include via a second prompt (dynamic list from the open network) |
| [UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb](./UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb) | **One row per object** with columns you define in `EXPORT_CONFIG`; attachment and file links on the same line |
| [UI-HTMLReport-AttachmentLinks-ConfiguredTables-Embedded.rb](./UI-HTMLReport-AttachmentLinks-ConfiguredTables-Embedded.rb) | Same as ConfiguredTables, but **inlines** local images/files into one HTML file (optional video embed) |

## Purpose

Exports HTML listing **attachment, video, and image file references** in the open network. Each row includes object details and a hyperlink to open the file in a new browser tab (read-only), unless using the embedded variant.

The HTML layout uses one data table per exported IAM table. When more than one table is included, the report shows **tabs** at the top (label and reference count per table); the first tab is active on open. A single-table export is one table with no tabs. Columns: object ID, type, purpose/field, filename, description, DB ref, file exists, and link.

## What is reported

| Source | Type column |
|--------|-------------|
| `attachments` BLOB | Attachment |
| `video_file_in` / `video_file_out` | Video |
| Individual image UID fields (`photo`, `detail_image`, etc.) | Image |

## Network types

The script uses `WSApplication.current_network` and scans **whatever network is open**. It does not hard-code Collection-only tables.

| Network type | Typical content in the report |
|--------------|-------------------------------|
| **Collection Network** (`cams_*`) | CCTV/MACP surveys (`attachments`, `video_file_in` / `video_file_out`), manhole images, pipe attachments |
| **Distribution Network** (`wams_*`) | Hydrant and water asset attachments and image reference fields |
| **Asset Network** (`ams_*` / user-defined) | Any table in that network that has `attachments`, video fields, or image UID fields |

Tables are discovered at runtime via `net.tables`; only tables with at least one of those field types are processed.

## Usage

1. Open the relevant **Collection, Distribution, or Asset** network in InfoAsset Manager.
2. Optionally select objects on the GeoPlan (if using selection-only mode).
3. Run via **Network → Run Ruby Script…** and select the script you need (see table above).

### Prompt options (link-based scripts)

| Field | Description |
|-------|-------------|
| **Process SELECTION only?** | Tick to report selected objects only |
| **SNumbatData root** | Parent folder containing `Attachments\` and `Videos\` (not the `Attachments` folder itself). For UNC paths use forward slashes, e.g. `//fileserver/InfoWorks/Workgroups/Your_Workgroup` |
| **Output folder** | Where to save the HTML file |
| **Output filename** | Defaults to `IAM_AttachmentLinks_Report.html` |

### Table selection script only (`-SelectTables`)

After the options prompt, a second dialog lists every table in the open network that has attachment, video, or image file fields. The first row is **Include all eligible tables** (off by default). Tick it to export every listed table, or leave it off and tick individual tables only. Each table row shows the display name, internal table name, and field types found (`Att`, `Vid`, `Img`); individual rows are off by default.

## URL / path construction

```
{SNumbatData root}\Attachments\{database-guid}\{uid}
{SNumbatData root}\Videos\{database-guid}\{uid}
```

The database GUID is read from `WSApplication.current_database.guid`. The script scans the store folders when accessible to verify file existence and resolve exact paths.

## Troubleshooting

### `undefined method 'attachments' for nil:NilClass`

Caused by calling `.attachments` on a nil row object, or using `net.row_objects` on an IAM build that only supports `row_object_collection`. The repo script uses `row_object_collection`, skips nil rows, and checks `ro.respond_to?(:attachments)` before reading the blob.

### `undefined method 'row_objects'`

Use the repo script — it prefers `row_object_collection` / `row_object_collection_selection`.

### `undefined method 'size' for WSRowObjectCollection` (selection only)

Fixed in repo scripts: selection mode must not call `.size` on `row_object_collection_selection` (IAM 2027+). Re-copy the latest script from this folder.

### Path / SNumbatData

- Set the **parent** folder (contains `Attachments` and `Videos`), not `\Attachments` itself.
- If auto-detect fails, enter your UNC path in the prompt.
- Optional defaults can be set in `SNUMBATDATA_CANDIDATES` at the top of each script.

## Configured tables export (one row per object)

### Script

[UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb](./UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb)

Edit **`EXPORT_CONFIG`** at the top of the script before running. Each entry sets an IAM **table name** and an ordered **`fields`** list (column order in the HTML). Optional **`headers`** override column titles.

The script ships with example blocks for **`cams_manhole`** (nodes), **`cams_manhole_survey`**, and **`cams_cctv_survey`** — remove or comment out any you do not need; all configured tables appear as HTML tabs.

| Config pattern | Meaning |
|----------------|---------|
| `survey_id`, `when_surveyed`, … | Scalar field value (dates formatted as `YYYY-MM-DD`) |
| `video_file_in:link` | Hyperlink to the video file in SNumbatData |
| `photo:link` | Hyperlink for an image UID field |
| `video_file_in:exists` | `Yes` / `No` if the file is on disk |
| `attachments` or `attachments:links` | All **attachments** BLOB files as links in one cell (`<br>` between links) |
| `attachments:count` | Number of attachment records with a `db_ref` |
| `attachments:filenames` | Filenames only, separated by `; ` |
| `attachments:text` | Plain-text list of purpose, filename, and `db_ref` |
| `details:count` | Number of records in a nested BLOB (e.g. CCTV **details**) |
| `details:links` | Links for `detail_image`, `video_file`, and other image/video fields on each detail row |
| `details:distance,code,remarks` | Each defect as `distance; code; remarks` in one cell; multiple defects separated by line breaks in HTML |
| `attachments:purpose,filename,db_ref` | Same pattern for **attachments** BLOB sub-fields |
| Header `details:Distance,Code,Remarks` | Column title labels (comma or `blob:…` form), shown joined with `; ` |

Prompts match the other HTML reports (selection scope, SNumbatData root, output path). Multiple tables in `EXPORT_CONFIG` produce **tabs** in the HTML.

### Handling BLOB fields in configuration

A BLOB is not a single scalar, so listing `attachments` or `details` alone cannot export “the whole blob” in one column. Recommended approach (used in this script):

1. **`attachments` BLOB** — use virtual tokens (`attachments:links`, `:count`, `:filenames`, `:text`) so one object row gets a **summary column** you choose, with links aggregated in that cell when needed.
2. **Other nested BLOBs** (e.g. `details` on surveys) — use **`details:field1,field2,…`** to pack each blob row into `field1; field2; …` inside one object column (semicolons within a defect, line breaks between defects). Use **`:count`** or **`:links`** for summaries only.
3. For **one CSV row per defect** (not one row per survey), use [UI-CSVReport-CCTVSurveyDefectCodes.rb](../CSV%20CCTV%20Survey%20Defects/UI-CSVReport-CCTVSurveyDefectCodes.rb).

### Single-file HTML with embedded media (`-ConfiguredTables-Embedded`)

Uses the same **`EXPORT_CONFIG`** as [UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb](./UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb). Local files referenced by `:link`, `attachments:links`, and `details:links` are read from SNumbatData (or absolute paths) and stored as **base64 data URLs** inside the HTML so you can share one `.html` file.

| Prompt | Default | Behaviour |
|--------|---------|-----------|
| **Embed local images in HTML?** | Yes | Inlines image bytes in the HTML (required for offline viewing) |
| **Embedded image display** | Inline + click → new tab | **Inline thumbnail only**, **link only** (opens data URL in new tab), or **thumbnail wrapped in link** (default) |
| **Embed other local files (e.g. PDF)?** | No | PDFs become download links inside the HTML |
| **Embed local video files in HTML?** | No | Off by default (large); `<video>` when on |
| **Max embed size per file (MB)** | 8 | Larger or missing files fall back to normal hyperlinks |

**http(s)** URLs are not downloaded — they stay external links. The report header summarises embedded vs linked vs skipped counts. Duplicate paths are embedded once (shared cache).

Embedded image links use a small **JavaScript** helper (`openEmbeddedMedia`) so left-click opens the image in a new tab reliably (browsers often show a blank tab for direct `target="_blank"` navigation to long `data:` URLs).

**Caution:** embedding many CCTV videos or large attachments can produce very large HTML files and slow browsers; keep video embed off unless you need offline playback for a small set.

## Notes

- Read-only — no network data is modified.
- Related: [0025 Copy Network Attachments to Folder](../../0025%20Copy%20Network%20Attachments%20to%20Folder/), [0018 Identify OrphanedMissing AttachmentsVideos](../../0018%20Identify%20OrphanedMissing%20AttachmentsVideos/).
