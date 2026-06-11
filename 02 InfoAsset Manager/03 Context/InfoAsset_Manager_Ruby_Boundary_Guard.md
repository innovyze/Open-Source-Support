# InfoAsset Manager Ruby Boundary Guard

**Purpose:** Prevent cross-product, cross-runtime, and cross-language contamination when generating InfoAsset Manager Ruby.

**Load Priority:** CRITICAL
**Last Updated:** May 29, 2026

## Product Scope

This file applies to **InfoAsset Manager Ruby only**.

Allowed primary source types:

- IAM Ruby examples under `02 InfoAsset Manager/01 Ruby`
- IAM Ruby README files
- Official Autodesk Help for `INFOAMAN`

Not allowed as default sources:

- InfoWorks ICM Ruby examples
- InfoWorks WS Pro Ruby examples
- IAM SQL examples
- ICM SQL schema or syntax files

## Cross-Product Quarantine

Treat these as quarantined unless the task is explicitly interoperability work:

- `02 InfoAsset Manager/01 Ruby/0003 Import an InfoWorks ICM Model into InfoAsset Manager`

Reason:

- The workflow is intentionally mixed-product and can pollute normal IAM Ruby retrieval with ICM-specific assumptions.

## Cross-Language Guard

Do not place SQL syntax into IAM Ruby output. If the generated code contains SQL statements, SQL field-path navigation, or SQL-only functions, stop and re-route to the IAM SQL context instead.

Reject all of the following in Ruby generation:

- SQL statements and clauses (`SELECT`, `UPDATE`, `WHERE`, etc.)
- SQL field-path navigation
- SQL prompt headers
- SQL function syntax

IAM SQL examples are valid style references for IAM SQL only. They must not bleed into IAM Ruby output.

Ruby must use Ruby methods, row objects, model objects, hashes, arrays, and transactions appropriate to the runtime.

## Runtime Guard

The most common IAM Ruby failure is mixing UI-only methods into Exchange scripts, or Exchange-only setup into UI scripts.

### UI-only Signals

Safe only in UI scripts:

- `WSApplication.current_network`
- `WSApplication.prompt`
- `WSApplication.message_box`
- Folder or file dialogs triggered from the UI

### Exchange-only Signals

Safe only in Exchange scripts unless verified otherwise:

- `WSApplication.open(...)` to open databases explicitly
- Hard-coded database paths or model object IDs used to open networks
- Explicit database iteration and export loops designed for unattended execution

### Dual-mode Signals

Use dual-mode only when the script deliberately branches by runtime:

- `WSApplication.ui?`
- `UIIE-` filename examples

Do not start from a dual-mode example when a clean UI-only or Exchange-only example already exists.

### Wrong

- Starting an Exchange script from `WSApplication.current_network`
- Using prompts or message boxes as required logic in Exchange-only automation
- Copying explicit database open logic into a normal UI script

### Right

- UI scripts start from `WSApplication.current_network`
- Exchange scripts open the database explicitly with `WSApplication.open(...)`
- Dual-mode scripts branch early on `WSApplication.ui?`

### Filename Signals

- `UI-` = UI only
- `IE-` = Exchange only
- `UIIE-` = dual-mode / mixed UI and Exchange support

If the runtime mode is not clear, determine it from the filename prefix or the task wording before proceeding.

## Blocked Non-IAM Features

Reject or remove these unless official IAM Help proves a method is shared and valid for IAM:

- ICM/WS Pro simulation, scenario, and hydraulic features
- ICM/SWMM run management and result storage
- WS Pro-specific network and demand features
- ICM-only model group hierarchy logic

## Preferred IAM Themes

Prefer IAM-native examples involving:

- ODEC export
- ODIC import
- Callback classes
- PACP and MACP import/export
- BEFDSS or WSAA XML workflows
- Report generation
- Attachment and blob handling
- Database object inventory
- Asset and survey relationships

## Pre-Generation Checklist

- Product confirmed as InfoAsset Manager
- Runtime mode confirmed as UI, Exchange, or dual-mode
- Example source chosen from the matching IAM example index
- No ICM or WS Pro runtime assumptions carried over
- No SQL syntax or SQL field navigation in Ruby output
- Any unfamiliar method queued for Help verification

## Stop Conditions

Stop and re-route before generating code if any of the following appear:

- ICM/SWMM-only table prefixes or simulation result fields appear in generated output
- Scenario, rainfall, or run object workflows appear in generated output
- SQL statement syntax appears in a Ruby answer
- An example path from InfoWorks ICM or InfoWorks WS Pro is used as the primary source for a normal IAM script