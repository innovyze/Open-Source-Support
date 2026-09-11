# Complete Parent from Related Records

Part of [0016 Update objects through relationships or comparison](../readme.md).

InfoAsset Manager Ruby script to automatically complete a **parent** work order, case, order, task, or incident when all configured **related** records are finished.

## Script

[UIIE-CompleteParentFromRelatedRecords.rb](./UIIE-CompleteParentFromRelatedRecords.rb)

## Overview

Use this script when a parent object should only be marked complete after every linked child record is done — for example:

- A **case** that stays open until all related repairs and maintenance tasks are completed
- An **order** or **work package** that completes when all linked maintenance or incident records are finished
- A **parent work order** that depends on multiple related tasks, inspections, or incidents

For each configured parent table, the script:

1. Finds related work orders, tasks, maintenance records, or incidents (via `navigate` and/or a link field)
2. Checks each related record's `completed` or `resolved` status (configurable per related type)
3. Marks the parent **completed** when every related record is done
4. Sets the parent completion date from the **latest** related completed/resolved date

Parents already marked complete are skipped. Parents with no related records are not completed.

## Supported object types

Works with both **default IAM objects** and **user-defined custom objects**:

| Type | Table naming | Examples |
|---|---|---|
| Default IAM (Distribution) | `wams_*` (single underscore) | `wams_order`, `wams_general_maintenance`, `wams_hydrant_maintenance`, `wams_incident_general` |
| User-defined custom objects | `wams__*` (double underscore) | `wams__case`, `wams__works`, `wams__waterstationrepair` |
| Default IAM (Collection) | `cams_*` | Adapt table names in the config if using a Collection network |
| User-defined (Collection) | `cams__*` | Same pattern as Distribution |

Parent and related entries can be mixed in one configuration — for example a user-defined Case parent linked to both custom child tables and a standard `wams_general_maintenance` table.

## When to use this script

- You need to replace batch SQL that counts related records and updates a parent in multiple passes
- Parent completion depends on **all** related children being complete, not just one
- Related records span multiple object types (maintenance, repairs, incidents, custom tables)
- You want a **dry run** and **verbose** logging to verify relationships before writing changes
- You run from the **InfoAsset Manager UI** or **InfoAsset Exchange** (UIIE script)

## Configuration note

The bundled `PARENT_OBJECT_CONFIGS` in the script is an **internal testing example only**. Replace it before use in another database.

Update for your network:

- Parent and child **table** names
- **navigate** relationship names (verify with verbose output)
- **link_field** on child records (field storing the parent ID)
- **completed_field**, **completed_date_field**, **status_field**, and **date_field** names

## Configuration

Edit `PARENT_OBJECT_CONFIGS` at the top of the script:

```ruby
PARENT_OBJECT_CONFIGS = [
  {
    label: 'Case',
    table: 'wams__case',
    completed_field: 'completed',
    completed_date_field: 'date_completed',
    related_types: [
      { label: 'Water Station Repair', navigate: 'waterstationrepair', table: 'wams__waterstationrepair', link_field: 'srmcase_', status_field: 'completed', date_field: 'date_completed' },
      { label: 'Water Meter Repair', navigate: 'watermeterreplace', table: 'wams__watermeterrepair', link_field: 'srmcase_', status_field: 'completed', date_field: 'date_completed' },
      { label: 'General Maintenance', navigate: 'generalmaintenance', table: 'wams_general_maintenance', link_field: 'work_package', status_field: 'completed', date_field: 'date_completed' }
    ]
  }
]
```

| Parent setting | Description |
|---|---|
| `label` | Name shown in logs and summary output |
| `table` | Parent object table |
| `completed_field` | Boolean field set when all related records are done |
| `completed_date_field` | Date field set from the latest related date |
| `related_types` | List of related tables/relationships for this parent |

| Related type setting | Description |
|---|---|
| `label` | Optional label for verbose output |
| `navigate` | Primary relationship name from parent to child |
| `table` | Fallback child table for link-field scan |
| `link_field` | Field on child that stores the parent ID |
| `status_field` | `completed` or `resolved` (or similar boolean field) |
| `date_field` | Date field to read when status is done |

### Object types in the bundled example

| Item | Example value | Type |
|---|---|---|
| `wams__case` | Parent table | User-defined custom object |
| `wams__waterstationrepair`, `wams__watermeterrepair` | Child tables | User-defined custom objects |
| `wams_general_maintenance` | Child table | Default IAM Distribution table |
| `srmcase_`, `work_package` | Link fields | Network-specific (verify in your database) |
| `waterstationrepair`, `watermeterreplace`, `generalmaintenance` | navigate names | Network-specific (verify in your database) |

## Usage (UI)

1. Open a **Distribution** network in InfoAsset Manager (or adapt config for Collection).
2. Optional: select parent records on the GeoPlan to limit scope.
3. Run via **Network → Run Ruby Script…** and choose `UIIE-CompleteParentFromRelatedRecords.rb`.

### Prompt options

| Field | Description |
|---|---|
| **Process selection only?** | Only selected records in each configured parent table are scanned |
| **Dry run (report only, no writes)?** | Reports what would update without writing changes — use this first |
| **Verbose output?** | Per-record detail: related IDs, status/date values, navigate vs link-field matches |

## Exchange

Edit `distribution_network_id` and `commit_message` in the `EXCHANGE CONFIG` block at the top of the script.

Example:

```bat
"C:\Program Files\Autodesk\InfoAsset Manager 2026\iexchange.exe" "C:\path\to\UIIE-CompleteParentFromRelatedRecords.rb" /ADSKASSET
```

## Behaviour summary

- Multiple parent sections can run in one execution
- Summary output includes totals for all sections, plus a per-section breakdown
- Intermediate counts are not stored on parent records
- Related records are found by `navigate` first, then by scanning the child table on `link_field`

## Keywords

InfoAsset Manager, IAM, Ruby, UIIE, Distribution network, Collection network, parent object, related records, work order, task, case, order, incident, maintenance, completed, resolved, navigate, user-defined objects, `wams_*`, `wams__*`, `cams_*`, `cams__*`, dry run, InfoAsset Exchange
