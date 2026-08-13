# Storage and Pond Node Audit and Correction

InfoWorks (`hw_*`) UI scripts to audit and correct engine-derived flood behaviour for **storage** and **pond** nodes. The simulation engine assigns flood type from the relationship between **ground level** and the **last level in the storage array** — not from the hidden `flood_type` field on storage nodes.

## Overview

Two companion scripts:

1. **[UI_audit_script.rb](UI_audit_script.rb)** — read-only HTML report of current flood type per node
2. **[UI_fix_script.rb](UI_fix_script.rb)** — adjust ground level or the last storage-array level to reach a target flood type

## Engine rule

For storage and pond nodes, Autodesk documents the following behaviour:

| Last storage-array level vs ground | Engine flood type |
|------------------------------------|-------------------|
| Above ground | stored |
| Equal to ground | lost |
| Below ground | sealed |

The audit uses the **last row** in the storage array (the engine key level). See [Storage tank flood behavior in ICM](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Storage-tank-flood-behavior-in-ICM.html) and [Which node flood type should I use in InfoWorks ICM?](https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Which-node-flood-type-should-I-use-in-InfoWorks-ICM.html) (storage nodes or ponds).

## Prerequisites

- InfoWorks network open in the ICM UI
- Storage or pond nodes with a defined storage array and ground level (for meaningful results)

## Audit usage

1. Open an InfoWorks network.
2. Optionally select storage/pond nodes on the GeoPlan (otherwise all storage and pond nodes are scanned).
3. Run [UI_audit_script.rb](UI_audit_script.rb) from the ICM UI script menu.
4. Choose an output folder when prompted.
5. Open the HTML report in a browser.

Default output filename: `storage_flood_type_audit_YYYYMMDD_HHMMSS.html`

## HTML report

The report includes:

- **Summary** — counts for storage nodes, pond nodes, flood-type breakdown, and data issues
- **Storage nodes** table — node ID, ground level, last array level, delta, flood type, status, notes
- **Pond nodes** table — same columns, listed separately below storage nodes

### Status values

| Status | Meaning |
|--------|---------|
| OK | Valid data; flood type derived from levels |
| Data issue | Missing storage array, blank levels, or last array level differs from maximum level |

Rows with data issues are highlighted in the report.

## Correction usage

1. Run the audit and identify nodes to change.
2. Select storage/pond nodes on the GeoPlan.
3. Run [UI_fix_script.rb](UI_fix_script.rb).
4. Choose:
   - **Target flood type** — stored, lost, or sealed
   - **Adjust field** — ground level or top storage-array level
   - **Stored/sealed separation margin** — default 0.01 m; keeps levels strictly above/below for stored and sealed targets
5. Review the preview and confirm to apply.

Re-run the audit after corrections to verify.

### Adjustment behaviour

When adjusting **top storage-array level** (default):

- **stored** — last array level set to ground + margin
- **lost** — last array level set equal to ground level
- **sealed** — last array level set to ground − margin

When adjusting **ground level** (top fixed):

- **stored** — ground level lowered below top
- **lost** — ground level set equal to top
- **sealed** — ground level raised above top

Only nodes that do not already match the target flood type are updated. Changes are applied inside a network transaction.

## Selection behaviour

| Script | Selection |
|--------|-----------|
| Audit | Optional. Empty selection scans all storage and pond nodes. Non-storage/pond selections are ignored. |
| Fix | Required. Select one or more storage or pond nodes before running. |

## Notes

- InfoWorks networks only (`hw_*` tables).
- The `flood_type` field is not used for storage nodes in the audit; engine behaviour is level-driven.
- Comparison is exact (no user tolerance). Stored and sealed corrections use a configurable separation margin only when writing new levels.
- Related example: [0073 - Populate storage array data](../0073%20-%20Populate%20storage%20array%20data/) for storage-array read/write patterns.
