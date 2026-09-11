# Import Photos and Attachments

Ruby scripts for importing **manhole survey photos** into InfoAsset Manager on `cams_manhole_survey`. Each workflow builds ODIC CSV and `.cfg` mapping files, then runs ODIC import for header image fields and the `attachments` blob.

Target surveys must already exist in the open network when **Update Only** is enabled (recommended).

## Manhole Survey from Folder

**Script:** [UI-ImportManholeSurveyPhotosFromFolder.rb](./Manhole%20Survey%20from%20folder/UI-ImportManholeSurveyPhotosFromFolder.rb)

Import images from a single folder using a **filename convention** — no source CSV required. The filename stem matches a survey ID or node ID; an optional bracket index (e.g. `(2)`, `(3)`) selects the target header field or attachments blob.

| Index | Target |
|-------|--------|
| (none) / `(2)` | Location view → `location_image` |
| `(3)` | Internal view → `internal_image` |
| `(4)+` | Attachments blob (`purpose` = **Location Photo**) |

Full details: [Manhole Survey from folder/Readme.md](./Manhole%20Survey%20from%20folder/Readme.md)

## Manhole Survey from WinCan PHOTO_Node CSV

**Script:** [UI-ImportManholeSurveyPhotosFromCSV.rb](./Manhole%20Survey%20from%20WinCan%20PHOTO_Node%20CSV/UI-ImportManholeSurveyPhotosFromCSV.rb)

Import images using a **WinCan PHOTO_Node-style CSV** export. Column `OBJ_Key` holds the survey ID, column `A` the image filename, and `OBS_SortOrder` selects the target field:

| OBS_SortOrder | Target field |
|---------------|--------------|
| 1 | `internal_image` |
| 2 | `location_sketch` |
| 3 | `location_image` |
| 4 | `plan_sketch` |
| 5+ | `attachments` blob (`purpose` = **Other Image**) |

Full details: [Manhole Survey from WinCan PHOTO_Node CSV/Readme.md](./Manhole%20Survey%20from%20WinCan%20PHOTO_Node%20CSV/Readme.md)

## Choosing a workflow

| Scenario | Use |
|----------|-----|
| Images named by survey or node ID with optional index in brackets | [Manhole Survey from folder](./Manhole%20Survey%20from%20folder/) |
| WinCan export with `PHOTO_Node` CSV and `OBS_SortOrder` | [Manhole Survey from WinCan PHOTO_Node CSV](./Manhole%20Survey%20from%20WinCan%20PHOTO_Node%20CSV/) |

Both scripts write the same ODIC output files to the selected image folder:

| File | Purpose |
|------|---------|
| `ODIC_Header_Images.csv` / `.cfg` | Header image fields (index 1–3 or SortOrder 1–4) |
| `ODIC_Attachments.csv` / `.cfg` | Additional images into the attachments blob |
| `ODIC_*Import_Errors.txt` | ODIC error logs (if import errors occur) |

Shared ODIC settings: **Import Images** enabled, **Duplication Behaviour** = `Merge`, **Blob Merge** = `false`, header import on **`ManholeSurvey`** then attachments on **`ManholeSurveyAttachments`**.

## Usage (both scripts)

1. Open the relevant Collection Network in InfoAsset Manager.
2. Place all image files in one folder (and, for the CSV workflow, have the PHOTO_Node export ready).
3. Run via **Network → Run Ruby Script…** and select the script from the appropriate subfolder.

Untick **Run ODIC import after generating CSVs** to review or edit the generated CSV/cfg files before importing manually.

## Related

- [0002 ODIC Import](../0002%20ODIC%20Import/)
- [0022 Rename Exported Image & Attachment Files](../0022%20Rename%20Exported%20Image%20&%20Attachment%20Files/)
- [0044 Reports](../0044%20Reports/) — HTML report listing attachment and video references
