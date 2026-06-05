# Reschedule Survey from Asset Selection

## Script

[UI-RescheduleSurveyFromAssetSelection.rb](./UI-RescheduleSurveyFromAssetSelection.rb)

## Purpose

For each **selected asset object**, finds the **most recent completed survey** of a chosen survey type (ranked by the recency fields described below — not `date_completed` alone), copies **all fields** (including blob sub-tables such as `details`, `attachments`, `pipes_in`, etc.), and creates a new planned survey with:

- **ID:** `{asset_id}-{date_planned}` (for example `MH001-20260605`)
- **`date_planned`:** the date chosen in the prompt dialog

Network field structure is discovered at runtime from the open Collection Network, so standard CAMS tables and **user-defined** object/survey types are supported when they exist in the network.

Survey tables are discovered from:

- A built-in list of standard CAMS survey tables present in the network
- Any other table whose name ends with `_survey`
- User-defined tables whose internal name starts with `cams__` and where either the **table name** or **display name** contains **survey** (case-insensitive)

## Usage

1. Open the relevant Collection Network in InfoAsset Manager.
2. Select one or more asset objects on the GeoPlan (manholes, pipes, general assets, user-defined objects, etc.).
3. Run the script via **Network → Run Ruby Script…** and select `UI-RescheduleSurveyFromAssetSelection.rb`.
4. When prompted:
   - Choose the **asset object type** (only types with a current selection are listed; display name and internal table name, e.g. `Manhole (cams_manhole)`; sorted alphabetically by display label).
   - Choose the **survey type** to copy (display name and internal table name, e.g. `Manhole Survey (cams_manhole_survey)`; sorted alphabetically by display label).
   - Choose the **date planned** for the new survey(s).
5. Review the Ruby console output for recency ranking, per-asset results, blank-`asset_type` review suggestions, and summary counts.

## How source surveys are matched to assets

Matching runs in two passes; results are merged per asset.

### Pass 1 — Asset relationship (standard survey tables only)

For standard survey tables (not `cams__*` user-defined), linked surveys are collected via the network relationship (e.g. `manhole_surveys` on a node, `cctv_surveys` on a pipe).

### Pass 2 — Field-based matching

Each survey in the chosen survey table is tested against each selected asset. A match requires **one** of the following (only rules whose fields exist on the survey table are used):

| Rule | Match condition |
|------|-----------------|
| **`asset_id` + `asset_type`** | Primary rule for most survey types. Survey `asset_type` must match the selected asset table (internal name, display name, or known display-name alias) **and** survey `asset_id` must match the asset `id`, `asset_id`, or `node_id`. Both fields are required — `asset_id` alone is not used. |
| **Pipe link** | Selected asset is `cams_pipe` and survey `us_node_id` / `ds_node_id` / `link_suffix` match `{us}.{ds}.{suffix}`. |
| **Flood defence** | On `cams_flood_defence_survey`: `user_text_39` (asset ID) and `user_text_40` (asset type) match the asset. |

The script does **not** match on survey `id` prefix or `asset_id` without a matching `asset_type`, to avoid incorrect links from duplicate or inconsistent IDs across asset tables.

Surveys with a matching `asset_id` but **blank `asset_type`** are listed in the Ruby console as review suggestions (they are not matched on `asset_type` alone). If such a survey was still included via an asset relationship, that is noted in the output.

User-defined survey tables (`cams__*`) use pass 2 only; they rely on `asset_id` + `asset_type` when those fields exist on the table.

## Most recent survey selection

The copy source is the **most recent completed** related survey, ranked using whichever of these apply on the survey table (in order):

1. `when_surveyed`
2. Custom **Date** fields whose field name or display description contains **inspection date**
3. `survey_date`
4. Custom **Date** fields whose field name or display description contains **survey date**
5. `date_completed`

Standard and user-defined survey tables are handled the same way — custom fields are discovered from the network schema at runtime. When more than one field is present, earlier fields take precedence and later fields break ties.

**Blank date fields:** If a ranked field (such as a user-defined Inspection Date) is blank on both surveys being compared, that field is skipped and the next field in the order is used. Surveys with a value in an earlier-ranked field rank above surveys where that field is blank. If all ranked fields are blank or tied, `date_completed` is used, then survey `id` as a final tie-breaker.

A survey counts as **completed** when `date_completed` is populated. The `completed` checkbox is **not** required — if `date_completed` has a value, a blank or false `completed` flag is ignored.

Incomplete surveys (blank `date_completed`) are **never** used as the copy source.

If any selected asset has incomplete related survey(s), the script lists them in the Ruby console. A **Yes/No prompt** is shown **only** when the asset also has a **completed** survey to copy from — i.e. there is something to reschedule despite open/incomplete work. Assets with **only** incomplete surveys are logged and skipped without a prompt (nothing to copy).

When prompted:

- **Yes** — a new planned survey is created from the latest completed survey.
- **No** — those assets are skipped.

The survey table must include `id` and `date_completed` fields; the script exits if either is missing.

## Field copy behaviour

- All top-level scalar fields are copied from the source survey except `id`, system-managed fields, cleared fields, and `estimated_duration` / `estimated_cost` (those are set from the source `actual_*` values instead).
- All **WSStructure** (blob) fields are copied row-by-row. **Resource** and **materials** blobs are then adjusted on each row: matching `actual*` values are copied to their `estimated*` counterparts and **all `actual*` fields** are left blank.
- On the main survey object, `estimated_duration` and `estimated_cost` are set from the source survey’s `actual_duration` and `actual_cost` when those fields exist.
- `date_planned` on the new survey is set to the prompted value.
- If one or more target IDs already exist, an upfront **Duplicate Survey IDs** prompt shows how many are affected and offers three choices: **skip all duplicates**, **create suffixed IDs for all** (`_1`, `_2`, … — first free suffix per asset), or **ask for each duplicate** individually. Assets whose base ID is free are unaffected and still use `{asset_id}-{date_planned}`.

### Fields left blank on the new survey

Only applied when the field exists on the survey table in the current network:

`date_started`, `completed`, `date_completed`, `closed`, `date_closed`, `actual_duration`, `actual_cost`, `estimated_completion_date`, `task_status`, `task_phase`, and each corresponding `*_flag` field.

`estimated_duration` and `estimated_cost` are **not** cleared — they are populated from the source survey’s actual values (see above).

### System-managed fields (not copied)

`date_opened`, `date_opened_flag`, `mobile_uid`, `uid`

## Notes

- All writes are wrapped in a single transaction.
- At startup the script prints the recency field order used for the chosen survey table.
- If `date_planned` is not present on the chosen survey table, the script warns and asks for confirmation before continuing (new surveys are still created, but `date_planned` cannot be set).
- For field structure listing on any network type, see [0030 List Network Fields-Structure](../0030%20List%20Network%20Fields-Structure/ReadMe.md).
