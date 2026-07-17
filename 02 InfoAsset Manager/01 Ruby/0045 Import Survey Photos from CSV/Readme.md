# Import Manhole Survey Photos from CSV

## Script

[UI-ImportManholeSurveyPhotosFromCSV.rb](./UI-ImportManholeSurveyPhotosFromCSV.rb)

## Purpose

Reads a PHOTO_Node-style CSV export and:

1. Splits it into two ODIC CSV files in the **image folder**
2. Writes matching ODIC `.cfg` mapping files
3. Runs ODIC import for header images and attachments on `cams_manhole_survey`

Designed for workflows where `OBS_SortOrder` identifies the target image field and column **A** holds the image filename.

## Source CSV columns

| Column | Use |
|--------|-----|
| `OBJ_Key` | Manhole survey ID |
| `A` | Image filename (must exist in the image folder) |
| `OBS_SortOrder` | Target field selector |
| `B` | Description / reference text |

## SortOrder mapping

| OBS_SortOrder | Target field |
|---------------|--------------|
| 1 | `internal_image` |
| 2 | `location_sketch` |
| 3 | `location_image` |
| 4 | `plan_sketch` |
| 5+ | `attachments` blob (`purpose` = **Other Image**) |

## Usage

1. Open the relevant Collection Network in InfoAsset Manager.
2. Place all image files in one folder.
3. Run via **Network → Run Ruby Script…** and select `UI-ImportManholeSurveyPhotosFromCSV.rb`.

### Prompt options

| Field | Description |
|-------|-------------|
| **Source PHOTO_Node CSV** | The merged PHOTO export CSV |
| **Image folder** | Folder containing the `.jpg` files; ODIC output files are also written here |
| **Update existing surveys only** | ODIC `Update Only` (recommended) |
| **Run ODIC import after generating CSVs** | Untick to only generate CSV/cfg files |

Attachments import uses ODIC **Duplication Behaviour = Merge** (not Blob Merge) so each CSV row appends to the survey's attachments blob. Blob Merge stays off — when enabled it collapses multiple rows for the same survey into a single attachment (last row wins).

## Generated files (in image folder)

| File | Contents |
|------|----------|
| `ODIC_Header_Images.csv` | One row per survey, SortOrder 1–4 pivoted to header image fields |
| `ODIC_Attachments.csv` | One row per SortOrder 5+ image |
| `ODIC_Header_Images.cfg` | ODIC mapping for header import (`DBI002` header, table registry from open network) |
| `ODIC_Attachments.cfg` | ODIC mapping on `cams_manhole_survey:attachments` with `attachments.*` CSV columns |
| `ODIC_HeaderImport_Errors.txt` | ODIC error log for header import (if errors occur) |
| `ODIC_AttachmentsImport_Errors.txt` | ODIC error log for attachments import (if errors occur) |

## ODIC behaviour

- **Image Folder** is set to the selected image folder.
- **Import Images** is enabled.
- **Duplication Behaviour** is `Merge` (appends attachment rows; required for SortOrder 5+).
- **Blob Merge** is `false` for both imports.
- Header import uses ODIC table **`ManholeSurvey`**; attachments import uses **`ManholeSurveyAttachments`** (parent UI table name + blob sub-table name).
- Header import runs first, then attachments.
- Generated `.cfg` files follow the ODIC import layout: `DBI002`, then `table,{{"InfoAsset field","CSV field","","",""},...}` (one outer `{...}` wrapper), then separate registry lines for every table and `table:blob` sub-table in the open network.

## Notes

- Survey IDs in `OBJ_Key` must already exist in the network when **Update Only** is enabled.
- Missing image files are reported in the Ruby console and summary dialog; import still proceeds.
- If a survey has more than one row for the same SortOrder (1–4), the last row wins and a warning is written to the console.

## Related

- [0002 ODIC Import](../0002%20ODIC%20Import/)
- [0022 Rename Exported Image & Attachment Files](../0022%20Rename%20Exported%20Image%20&%20Attachment%20Files/) (manhole survey image field examples)
- [0044 HTML Report](../0044%20HTML%20Report/)
