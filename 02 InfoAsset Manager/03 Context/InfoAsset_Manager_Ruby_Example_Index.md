# InfoAsset Manager Ruby Example Index

Use this file to route InfoAsset Manager Ruby tasks to the nearest relevant repository examples.

**Routing rule:** Determine the runtime mode first (UI, Exchange, or Dual-Mode), then use the matching section below.

---

## UI Examples

Use this section for **UI-only** tasks (scripts that run inside the InfoAsset Manager interface).

### Primary UI Example Folders

| Folder | Use For |
|--------|---------|
| `0040 Convert Coordinate Values` | UI prompts, selection-driven updates, object-type choices |
| `0020 Generate Individual Reports for a Selection of Objects` | UI report generation and folder-prompt variants |
| `0022 Rename Exported Image & Attachment Files` | UI file and attachment workflows |
| `0015 Export Choice List values` | UI metadata export |
| `0016 Update an object with values of another object through comparison` | UI prompts and object-to-object updates |
| `0038 Import INTERLIS survey details` | UI import flows tied to existing survey objects |
| `0033 Output the Array BLOB values as a clustered value` | UI blob/array output examples |

### UI Import/Export Examples

| Folder | Notes |
|--------|-------|
| `0001 ODEC Export` | Use only `UI-` examples for pure UI work |
| `0002 ODIC Import` | Use only `UI-` examples for pure UI work |
| `0006 Import-Export Snapshot file` | Use only `UI-` examples for pure UI work |

### UI Fast Routing Hints

- Need prompts or dialog boxes: start with `0040`, `0016`, or `0020`
- Need object selection driven UI logic: start with `0040` or `0036`
- Need UI import/export: start with the `UI-` files in `0001`, `0002`, or `0006`

---

## Exchange Examples

Use this section for **Exchange-only** tasks (scripts that run under InfoAsset Exchange).

### Primary Exchange Example Folders

| Folder | Use For |
|--------|---------|
| `0001 ODEC Export` | Exchange export flows, batch export, previous-version comparisons |
| `0002 ODIC Import` | Exchange import flows and options hashes |
| `0004 GIS Export` | Exchange GIS export |
| `0006 Import-Export Snapshot file` | Exchange snapshot export and bulk import |
| `0010 Import-Export BEFDSS XML` | Exchange-only BEFDSS workflows |
| `0025 Copy Network Attachments to Folder` | Exchange scanning and attachment export |
| `0029 List Database Objects Contents` | Database and network inventory |

### Exchange-Specific Signals

Start here when the task includes:

- Explicit database connection strings
- Unattended batch processing
- Bulk folder processing
- Commit/version comparison
- Exchange executable usage or `/ADSKASSET`

### Exchange Fast Routing Hints

- Need export automation: start with `0001` or `0004`
- Need import automation: start with `0002`, `0006`, or `0010`
- Need inventory or discovery: start with `0029`
- Need attachment extraction: start with `0025`

---

## Dual-Mode Examples

Use this section for tasks that explicitly need **one script to run in both UI and Exchange**.

### Primary Dual-Mode Example Folders

| Folder | Use For |
|--------|---------|
| `0001 ODEC Export` | `UIIE-` export examples that branch by runtime |
| `0009 Import-Export MACP-PACP Survey Data` | IAM-only survey methods available in UI and Exchange |
| `0029 List Database Objects Contents` | Database content and summary examples usable in both modes |
| `0035 Export CCTV Surveys to WSAA XML` | Dual-mode export workflow |

### Dual-Mode Entry Conditions

Use dual-mode sources only when the task explicitly needs one script to run:

- inside the InfoAsset Manager UI, **and**
- through InfoAsset Exchange

If the user needs only one runtime, prefer the UI or Exchange section instead.

### Dual-Mode Mandatory Checks

- Confirm the example actually uses `UIIE-` or a runtime branch such as `WSApplication.ui?`
- Keep UI-only prompts inside the UI branch
- Keep database opening logic inside the Exchange branch
- Do not merge the two paths into one unconditional flow

### Dual-Mode Fast Routing Hints

- Need one export script for both runtimes: start with `0001`
- Need PACP or MACP behavior in both runtimes: start with `0009`
- Need object inventory in both runtimes: start with `0029`

---

## Do Not Use First (All Modes)

- `UIIE-` examples when a clean `UI-` or `IE-` example exists for the specific mode
- `0003 Import an InfoWorks ICM Model into InfoAsset Manager` unless the task is explicitly cross-product import/export
