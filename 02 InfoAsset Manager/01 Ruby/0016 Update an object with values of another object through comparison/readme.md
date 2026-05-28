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
| `notes` | Appended: existing notes + survey date (yyyy-mm-dd hh:mm) + survey notes |

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
Copies attachments from General Surveys (where `asset_type = cams_property`) to their linked Property objects, matching on `asset_id`. Skips attachments already present on the Property (matched by `db_ref`). Can be run on the whole network or on a selection of surveys.
