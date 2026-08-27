# Update — Set Field Values

InfoAsset Manager **UI** Ruby scripts for writing a text value to selected objects on the GeoPlan.

**Run from:** Network → Run Ruby Script… (with a network open on the GeoPlan), or save the script as a Ruby script database item.

Works on Collection (CAMS), Distribution (WAMS), and Asset (AMS) networks.

---

## [UI-SetNotesOnSelection.rb](./UI-SetNotesOnSelection.rb)

Sets a text field on the current GeoPlan selection. The default use case is populating a notes template on the `notes` field, but any top-level text field name can be entered at runtime.

Use this script when you need to apply the same text to selected objects across one or more object tables — for example after selecting valve maintenance records manually, or when an ODIC callback Script File cannot be used (see [0002A ODIC Callback Examples](../0002A%20ODIC%20Callback%20Examples/) for import-time alternatives).

### Prerequisites

1. A network open on the GeoPlan.
2. One or more objects selected.
3. The target field must exist as a **top-level** field on each chosen table (blob sub-table fields are not supported).

### Prompts

| Step | Dialog | Options |
|------|--------|---------|
| 1 | **Set Field Value - Select Object Tables** | Checkboxes for each table that has a current selection, shown as **Display Name (tablename) [n selected]**. All listed tables are checked by default. Uncheck any table to skip it. |
| 2 | **Set Field Value - Options** | **Field to update** (default `notes`), **Value to set** (pre-filled notes template, editable), **Update mode** dropdown. Readonly notes in the dialog describe Fill blanks only and Append to existing. |

### Customising the script

Edit these constants at the top of the script for site-specific defaults:

| Constant | Purpose |
|----------|---------|
| `DEFAULT_FIELD_NAME` | Field written by default (default `notes`) |
| `DEFAULT_NOTES_TEXT` | Pre-filled text in the **Value to set** prompt |

| Mode | Behaviour |
|------|-----------|
| **Fill blanks only** | Updates only blank or null field values. Objects that already have text are skipped. |
| **Overwrite existing** | Replaces the entire field value with the entered text. |
| **Append to existing** | Adds the entered text after any existing value, separated by a blank line. If the field is blank, the entered text is written as-is. |

### Default notes template

The **Value to set** field is pre-filled with:

```
Operator 1:
Date/Time:
Notes:

Operator 2:
Date/Time:
Notes:

Operator 3:
Date/Time:
Notes:
```

Edit this text in the prompt before continuing, or change `DEFAULT_NOTES_TEXT` in the script. The stored template uses `\r\n` line breaks.

### Update modes

- Only tables with at least one selected object appear in the first prompt.
- Field names are matched case-insensitively on each table. If the field does not exist on a chosen table, that table is skipped and reported in the Ruby console log.
- Objects are not written when the computed value is unchanged (for example, Append to existing with blank text to append).
- Changes are applied inside a single transaction (`transaction_begin` / `transaction_commit`).
- A summary message box reports how many objects were updated.

### Console output

The script logs:

- Detected network profile (Collection, Distribution, or Asset)
- Number of tables with a current selection
- Per-table update counts
- Tables skipped because the field was not found
- Objects skipped because they already had a value (Fill blanks only mode)

### Example workflow

1. Open a Collection network and select valve maintenance records on the GeoPlan.
2. Run **Network → Run Ruby Script…** and choose this script.
3. In prompt 1, confirm the table(s) to update (for example `Valve Maintenance (valve_maintenance_cov) [3 selected]`).
4. In prompt 2, leave **Field to update** as `notes`, edit the template if needed, and choose an update mode.
5. Review the summary message and console log.
