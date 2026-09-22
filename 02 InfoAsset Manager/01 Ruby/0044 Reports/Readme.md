# Reports

Ruby export scripts for InfoAsset Manager (CSV and HTML). Each group lives in its own subfolder.

## CSV CCTV Survey Defects

One row per CCTV **detail** (defect) with survey, pipe, and filter prompts.

**Folder:** [CSV CCTV Survey Defects](./CSV%20CCTV%20Survey%20Defects/)

| Script | Summary |
|--------|---------|
| [UI-CSVReport-CCTVSurveyDefectCodes.rb](./CSV%20CCTV%20Survey%20Defects/UI-CSVReport-CCTVSurveyDefectCodes.rb) | Gravity sewer / rising main defect CSV export |

Full usage and columns: [CSV CCTV Survey Defects/Readme.md](./CSV%20CCTV%20Survey%20Defects/Readme.md).

---

## HTML Attachment Links

HTML reports for attachment, video, and image references (hyperlinks and optional single-file embedded media).

**Folder:** [HTML Attachment Links](./HTML%20Attachment%20Links/)

| Script | Summary |
|--------|---------|
| [UI-HTMLReport-AttachmentLinks.rb](./HTML%20Attachment%20Links/UI-HTMLReport-AttachmentLinks.rb) | All eligible tables |
| [UI-HTMLReport-AttachmentLinks-SelectTables.rb](./HTML%20Attachment%20Links/UI-HTMLReport-AttachmentLinks-SelectTables.rb) | Prompt to pick tables |
| [UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb](./HTML%20Attachment%20Links/UI-HTMLReport-AttachmentLinks-ConfiguredTables.rb) | Config-driven columns per object |
| [UI-HTMLReport-AttachmentLinks-ConfiguredTables-Embedded.rb](./HTML%20Attachment%20Links/UI-HTMLReport-AttachmentLinks-ConfiguredTables-Embedded.rb) | Config-driven + embedded files |

Full usage, `EXPORT_CONFIG`, troubleshooting: [HTML Attachment Links/Readme.md](./HTML%20Attachment%20Links/Readme.md).
