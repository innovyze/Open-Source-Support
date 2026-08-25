# Introduction
InfoAsset Manager has an asset-centric relational object structure, in most instances assets have a relationship based on the Object ID to multiple other objects (asset-asset [Node-Pipe, Pipe-Property], asset-survey [Pipe-CCTV Survey] etc.).  
Using InfoAsset Manager Executive Suite it is possible to also define custom relationships, using a User_Text_n field to relate to the Object ID of the related object.  
By the script examples in this repository relationships are used against any two fields.  

## [UI-UpdateBlockagePropertyID.rb](./UI-UpdateBlockagePropertyID.rb)
Query: Is it possible to look-up the property ID within the Property grid based upon the location and assign it to the property ID in the Blockage incident with a query?  
Request to Update the property_id field of a Blockage Incident with the Property ID form the Property table by comparing the location field on the Blockage Incident to the property_address on the Property object.  

## [UI-UpdateObjectFromObject_ByPrompt_3.rb](./UI-UpdateObjectFromObject_ByPrompt_3.rb)
This script essentially runs the same action as UI-UpdateBlockagePropertyID.rb but at runtime a prompt dialog is displayed to the user to enter the source & destination fields for the comparison and which fields to extract from & update to.  
Options for Source & Destination are: Tables, Fields for comparison, Fields to pull from/to.  

V2 Adds in support for overwriting existing values in destination.  
V3 Adds in support for Flags.  

## [UI-CountConnections.rb](./UI-CountConnections.rb)
In the user's scenario, each Connection Pipe has the Asset_ID of the related Pipe it connects to.  Count the number of Connection Pipes per Pipe and write the count to the User_Text_5 field.  

## [UI-CountRepairs.rb](./UI-CountRepairs.rb)
In the user's scenario, each Pipe Repair has a classification in User_Text_8 and the Asset ID of the related Pipe in User_Text_10. Count the number of 'reactive network' repairs to the User_Text_6 of the Pipe object.  

## [UI-UpdateAssetsFromLatestNotUsedFloodDefenceSurvey.rb](./UI-UpdateAssetsFromLatestNotUsedFloodDefenceSurvey.rb)
For each of the 8 flood defence asset types (Channel, Defence Structure, General Asset, Node, Outlet, Screen, Storage Area, Weir), finds the latest `cams_flood_defence_survey` linked to each asset and copies the survey results back to the asset object, then marks the survey as `used_in_network = true`.

The link between survey and asset is stored on the survey itself: `user_text_39` holds the asset ID and `user_text_40` holds the asset type. Both the `cams_` table name format and common display-name variants are recognised (see `ASSET_TYPE_MAP` in the script).

**Field mappings applied to the asset:**

| Asset field | Source (survey field) |
|---|---|
| `survey_date` | `survey_date` |
| `material` | `user_text_4` |
| `user_text_1` | `user_text_1` |
| `user_text_4` | `repeat_period` |
| `user_text_5` | `user_text_5` |
| `user_text_6` | `user_text_6` |
| `user_text_7` | `user_text_3` |
| `user_text_9` | `user_text_9` |
| `user_text_10` | `user_text_11` |
| `user_number_1` | `user_number_1` |
| `location` | `location` |
| `name` | `user_text_8` |
| `condition_grade` | `condition_grading_score` |
| `notes` | Appended: existing notes + survey date (yyyy-mm-dd hh:mm) + survey notes. Skipped entirely if the survey notes field is blank. |

**Fields updated on the survey itself:**

| Survey field | Value |
|---|---|
| `contractor` | Copied from `surveyed_by` |
| `used_in_network` | Set to `true` |

**Latest-survey logic:** the script finds the chronologically latest survey per asset (by `survey_date`) before checking `used_in_network`. If the latest survey is already marked `used_in_network = true`, the asset is skipped entirely rather than falling back to an older unprocessed survey, which would risk writing stale data.

## [UI-UpdateFloodDefenceSurveyFromAsset_Selection.rb](./UI-UpdateFloodDefenceSurveyFromAsset_Selection.rb)
The reverse of `UI-UpdateAssetsFromLatestNotUsedFloodDefenceSurvey.rb`. For each **selected** `cams_flood_defence_survey`, looks up the linked asset via `user_text_39` (asset ID) and `user_text_40` (asset type), then copies asset fields back onto the survey.

**Field mappings applied to the survey:**

| Survey field | Source (asset field) |
|---|---|
| `user_text_15` | `user_text_12` |
| `priority` | `user_text_16` |
| `user_text_14` | `owner` |
| `user_text_7` | `maintained_by` |

Surveys with a blank `user_text_39` or `user_text_40`, or an unrecognised asset type, are skipped with a warning. The script exits early if no surveys are selected.

## [UI-CopyGeneralSurveyAttachmentsToProperty.rb](./UI-CopyGeneralSurveyAttachmentsToProperty.rb)
Copies attachments from General Surveys (where `asset_type = cams_property`) to their linked Property objects, matching on `asset_id`. Skips attachments already present on the Property (matched by `db_ref`). Can be run on the whole network or on a selection of surveys. Renames copied attachments for Property display (`Location view` purpose and a postcode/name-based filename).

## [UI-UpdateCCTVSurveyContractNoFromProjectWorkPackage.rb](./UI-UpdateCCTVSurveyContractNoFromProjectWorkPackage.rb)
Sets `contract_no` on `cams_cctv_survey` objects by matching `project` and `work_package` against a comma-separated mapping list defined at the top of the script.

**Mapping format (one line per match):**

```
project,work_package,contract_no
```

Example:

```
proj1,wp1,con101
proj1,wp2,con102
proj2,wp1,con201
```

Project and work package values are compared case-insensitively. Surveys with a blank `project` or `work_package` are skipped. By default, surveys that already have a `contract_no` are left unchanged; use the prompt option to overwrite existing values.

**Prompt options:**

| Option | Default | Notes |
|---|---|---|
| Process SELECTION only? | false | When checked, only selected CCTV surveys are processed |
| Overwrite existing contract_no values? | false | When unchecked, surveys with a non-blank `contract_no` are skipped |
| Verbose logging? | false | When checked, writes one line per survey to the Ruby output (updated, skipped, and reason) |
| Asset Group ID (optional) | blank | When entered, creates one Selection List per outcome in that Asset Group (updated and each skip reason). Lists are named with a run timestamp prefix including seconds, for example `CCTV contract_no 2026-08-24 13:05:42 - Updated`. If a name already exists, a numeric suffix is added automatically. Empty outcome groups are skipped. |

## [UI-CopyCCTVDefectImagesToPipeRepair.rb](./UI-CopyCCTVDefectImagesToPipeRepair.rb)
Copies CCTV survey defect images onto **pipe repair** attachments by matching:

| Pipe repair field | Match |
|---|---|
| `cctv_survey_id` | Identifies the pre-repair CCTV survey |
| `defect_type` | Mapped to one or more CCTV defect `code` values (see `DEFECT_TYPE_MAPPINGS` in the script) |
| `start_length` | CCTV defect `distance` within a configurable buffer (default 0.5 m) |

When a matching defect row has a `detail_image`, the image UID is appended to the pipe repair `attachments` blob (same file reference — no duplicate on disk). Duplicate `db_ref` values on the repair are skipped.

**Defect type mapping format (one line per repair defect type):**

```
repair_defect_type,cctv_code[,cctv_code...]
```

Example:

```
BREAK,B,H,CR
JOINT,J,JNT
ROOTS,R,ROOT
```

Matching is case-insensitive for both repair defect type and CCTV codes.

**Prompt options:**

| Option | Default | Notes |
|---|---|---|
| Process SELECTION only? | true | When checked, only selected pipe repairs are processed |
| Distance buffer (m) | 0.5 | Defect `distance` must be within this tolerance of repair `start_length` |
| Verbose logging? | false | When checked, writes one CSV-formatted line per pipe repair to the Ruby output (same columns as the log file) |
| CSV log file folder (optional) | blank | Enter a folder path to write a timestamped CSV log; leave blank to skip the file |

**Log file columns:** `status`, `reason`, `pipe_repair_id`, `cctv_survey_id`, `defect_type`, `start_length`, matched defect details, and image reference.

**Status values:** `TRANSFERRED`, `ALREADY_PRESENT`, `FAILED` (with reason — survey not found, no mapping, no matching defect, no image, etc.).

## [UI-CopySurveyAttachmentsToAsset.rb](./UI-CopySurveyAttachmentsToAsset.rb)
Copies **attachment blob metadata** from **selected** survey objects to their associated asset object (any survey type that links to an asset with an `attachments` blob). Duplicate attachments on the asset (matched by `db_ref`, case-insensitive) are skipped. Files on disk are not duplicated — asset rows reference the same `db_ref` as the survey.

**Asset resolution** (first match with an `attachments` field wins): `asset_id` + `asset_type`; flood-defence `user_text_39` / `user_text_40`; pipe link fields; `node_id`; then `navigate('property')`, `navigate('node')`, or `navigate('pipe')`. Asset lookup uses `row_object`, `row_objects_from_asset_id`, then a table scan on `id`, `asset_id`, `node_id`, and `property_id`.

**Usage:** select survey object(s) on the GeoPlan, then run via **Network → Run Ruby Script…**. If `db_ref` is blank on a survey attachment row, the script falls back to `filename` as the file reference.
