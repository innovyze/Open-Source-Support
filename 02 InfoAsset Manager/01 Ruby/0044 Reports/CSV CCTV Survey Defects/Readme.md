# CSV CCTV Survey Defects

Export gravity sewer and rising main CCTV survey **defect observations** to CSV (one row per detail record).

Parent folder: [0044 Reports](../Readme.md)

## Script

[UI-CSVReport-CCTVSurveyDefectCodes.rb](./UI-CSVReport-CCTVSurveyDefectCodes.rb)

## Purpose

Exports **gravity sewer and rising main** CCTV survey defect observations to CSV with **one row per detail record**, for review of CCTV coverage, condition grades, defect codes, and video/report references where stored on the survey.

Key behaviour:

- **Latest survey per pipe** (default) — one current CCTV record per parent pipe/asset, by `when_surveyed`
- **Survey date filter** — defaults to surveys from 2000-01-01 onward (change in the prompt)
- **One row per defect** — survey and pipe header fields repeat on each `details` row
- **Parent pipe attributes** — linked pipe fields exported with a `pipe_` prefix (e.g. `pipe_asset_id`)
- **Asset class column** — `asset_class` flags Gravity Sewer, Rising Main, or Other from survey/pipe type fields

## Usage

1. Open the relevant Collection Network in InfoAsset Manager.
2. Optionally select CCTV Survey or Pipe objects first (selection-only mode).
3. Run via **Network → Run Ruby Script…** and select `UI-CSVReport-CCTVSurveyDefectCodes.rb`.

Out-of-the-box prompts favour a common workflow: latest survey per pipe, require `pipe_type`, exclude split surveys, export all defect rows. Adjust dates and filters for your network.

## Prompt options

| Field | Description |
|-------|-------------|
| **Process SELECTION only?** | Tick to export selected surveys only |
| **Survey date from** | Include surveys with `when_surveyed` on or after this date (default: 2000-01-01) |
| **Latest survey per pipe only?** | Keep only the most recent survey per linked pipe/asset (default: ticked) |
| **Require pipe type on survey?** | Skip surveys with blank `pipe_type` (default: ticked) |
| **Minimum survey structural grade (0 = all)** | Filter to surveys where `hard_wired_structural_grade` is at least this value |
| **Minimum defect structural score (0 = all)** | Filter to defect rows where `details.structural_score` is at least this value |
| **Exclude split surveys?** | Skip surveys where `splitsurvey` is true |
| **Include surveys with no defect rows?** | Write one row with blank defect columns when a survey passes filters but has no `details` records |
| **Output folder / filename** | Defaults to `CCTV_Survey_Defects.csv` |

## CSV columns (where present in the network)

**Survey:** `survey_id`, `start_manhole`, `finish_manhole`, `plr`, `when_surveyed`, `pipe_type`, `use`, `material`, `size_1`, lengths, structural/service grades and scores, location fields, `purpose`, `job_number`, `contract_no`, `surveyed_by`, `contractor`, `method`, `video_file_in`, `video_file_out`, task/status fields, etc.

**Computed:** `asset_class`, `pipe_asset_key`

**Parent pipe (`pipe_` prefix):** `pipe_asset_id`, `pipe_us_node_id`, `pipe_ds_node_id`, `pipe_link_suffix`, `pipe_pipe_type`, `pipe_system_type`, `pipe_length`, `pipe_material`, etc.

**Defect (one row each):** `defect_row`, `distance`, `code`, `characterisation1`, `characterisation2`, `structural_score`, `service_score`, `remarks`, `joint`, `cd`, clock/quantity fields, `video_file`, `detail_image`, etc.

Fields not present in the open network schema are omitted automatically.

## Typical workflows

**Broad export (defaults):**

Latest survey per pipe, date from 2000-01-01, require pipe type ticked, split surveys excluded.

**Grade 5 structural review:**

Set **Minimum survey structural grade** to `5` and **Minimum defect structural score** to `5`.

**All surveys (not just latest per pipe):**

Untick **Latest survey per pipe only?**

## Notes

- Read-only — no network data is modified.
- Rising main surveys are identified in `asset_class`; review that column to highlight rising main CCTV.
- Work-order linkage and attachment/report BLOBs are not summarised here; survey-level video fields and detail image/video references are included where stored on the survey.
- Related SQL: [CCTVSurvey-ByGrade-WithinDates.sql](../../../02%20SQL/0003%20Selecting%20most%20recent%20Survey-Incident%20for%20Assets/CCTVSurvey-ByGrade-WithinDates.sql), [CCTVSurvey_FromPipe.sql](../../../02%20SQL/0003%20Selecting%20most%20recent%20Survey-Incident%20for%20Assets/CCTVSurvey_FromPipe.sql).
