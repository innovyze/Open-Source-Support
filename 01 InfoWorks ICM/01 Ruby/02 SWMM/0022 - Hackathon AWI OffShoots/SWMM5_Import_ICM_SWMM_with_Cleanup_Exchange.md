# SWMM5 Import to ICM - Exchange Script Documentation

**Version:** 2.0  
**Purpose:** Backend processing script that executes the actual SWMM5 import operations via ICMExchange

---

## Overview

This Ruby script is the **worker component** of the SWMM5 Import system. It runs within the ICMExchange environment (headless/command-line mode) and performs the actual import of SWMM5 `.inp` files into ICM model groups.

The script is designed to be launched automatically by the companion UI script (`SWMM5_Import_ICM_SWMM_with_Cleanup_UI.rb`) and reads its configuration from a YAML file.

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Single & Batch Import** | Processes one or many files from configuration |
| **Two-Phase Processing** | Import phase followed by validation phase |
| **Empty Label Cleanup** | Removes empty visualization label lists created during import |
| **Connectivity Validation** | Checks for disconnected nodes and subcatchments |
| **Fault Tolerance** | Continues processing remaining files after individual failures |
| **Comprehensive Logging** | Detailed log files plus machine-readable summary |
| **Partial Import Cleanup** | Automatically removes model groups from failed imports |

---

## How It Works

The script is **not run directly** by users. Instead:

1. User runs the **UI script** in ICM
2. UI script generates a YAML configuration file
3. UI script launches **ICMExchange.exe** with this Exchange script
4. Exchange script reads configuration and performs imports
5. Exchange script writes summary file for UI script to display

```
┌─────────────────┐     YAML Config      ┌─────────────────┐
│   UI Script     │ ──────────────────── │ Exchange Script │
│  (ICM Ruby)     │                      │  (ICMExchange)  │
└─────────────────┘                      └─────────────────┘
        │                                        │
        │  Launches via command line             │
        └────────────────────────────────────────┘
                                                 │
                                                 ▼
                                    ┌─────────────────────┐
                                    │  batch_summary.txt  │
                                    │  (Results for UI)   │
                                    └─────────────────────┘
```

---

## Processing Workflow

For **each file** in the configuration, the script executes:

```
┌─────────────────────────────────────────────────────────────────┐
│  PRE-VALIDATION                                                 │
│  - Verify file exists                                           │
│  - Verify .inp extension                                        │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 1: IMPORT                                                │
│                                                                 │
│  Step 1: Create Model Group                                     │
│    - Create new model group with specified name                 │
│    - Handle duplicate name errors                               │
│                                                                 │
│  Step 2: Import Network                                         │
│    - Call import_all_sw_model_objects()                         │
│    - Generate per-file import log                               │
│    - Count imported objects                                     │
│                                                                 │
│  Step 3: Gather Statistics                                      │
│    - Open imported SWMM network                                 │
│    - Count nodes, links, subcatchments                          │
│    - Commit network with import message                         │
│                                                                 │
│  Step 4: Cleanup (if enabled)                                   │
│    - Find all Label List objects from import                    │
│    - Check each for empty 'labels' blob                         │
│    - Delete empty label lists                                   │
├─────────────────────────────────────────────────────────────────┤
│  PHASE 2: VALIDATION (if enabled)                               │
│                                                                 │
│  Check 1: Empty Network                                         │
│    - Warn if no nodes or links                                  │
│                                                                 │
│  Check 2: Disconnected Subcatchments                            │
│    - Find subcatchments with no outlet_id                       │
│                                                                 │
│  Check 3: Unconnected Nodes                                     │
│    - Find nodes not referenced by any link                      │
├─────────────────────────────────────────────────────────────────┤
│  ERROR HANDLING                                                 │
│  - On failure: delete partial model group                       │
│  - Record failure reason                                        │
│  - Continue to next file                                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Configuration File Format

The script reads a YAML configuration file (generated by UI script):

```yaml
import_mode: "Batch - Include Subdirectories"
base_directory: "C:/SWMM_Models"
file_type: "SWMM network"
cleanup_empty_label_lists: true
validate_after_import: true

file_configs:
  - file_path: "C:/SWMM_Models/site1.inp"
    model_group_name: "SWMM_Import_site1_20241205_1430"
    file_basename: "site1.inp"
    
  - file_path: "C:/SWMM_Models/sub/site2.inp"
    model_group_name: "SWMM_Import_sub_site2_20241205_1430"
    file_basename: "site2.inp"
```

### Required Configuration Keys

| Key | Type | Description |
|-----|------|-------------|
| `import_mode` | String | Display label for logging |
| `file_configs` | Array | List of file configurations |
| `file_type` | String | Target network type |
| `cleanup_empty_label_lists` | Boolean | Enable label cleanup |

### File Configuration Fields

| Field | Description |
|-------|-------------|
| `file_path` | Full path to the `.inp` file |
| `model_group_name` | Name for the new model group |
| `file_basename` | Filename for display purposes |

---

## Configuration File Discovery

The script locates the configuration file using this priority:

1. **Environment variable:** `ICM_IMPORT_CONFIG` (set by UI script)
2. **Search paths:** Looks for `import_config.yaml` in:
   - Script directory
   - Parent directory
   - Grandparent directory
   - Any `ICM Import Log Files` subfolder

When multiple config files are found, the **most recently modified** is selected.

---

## Output Files

All outputs are written to the `ICM Import Log Files` folder:

| File | Format | Purpose |
|------|--------|---------|
| `SWMM5_Batch_Import_YYYYMMDD_HHMMSS.log` | Text | Detailed processing log |
| `batch_summary.txt` | Key=Value | Machine-readable statistics for UI |
| `{filename}_YYYYMMDD_HHMMSS.txt` | Text | Per-file ICM import log |

### Summary File Format

```
BATCH_IMPORT_SUMMARY
files_processed=5
files_successful=4
files_failed=1
total_nodes=2847
total_links=3156
total_subcatchments=892
total_label_lists_deleted=8
```

---

## Aggregate Statistics Tracked

| Statistic | Description |
|-----------|-------------|
| `files_processed` | Total files attempted |
| `files_successful` | Files imported without errors |
| `files_failed` | Files that failed to import |
| `total_nodes` | Sum of all nodes across networks |
| `total_links` | Sum of all links across networks |
| `total_subcatchments` | Sum of all subcatchments |
| `total_label_lists_deleted` | Empty label lists removed |
| `failed_files` | Array of failure details |

---

## Validation Checks

When `validate_after_import` is enabled:

| Check | Condition | Severity |
|-------|-----------|----------|
| **Empty Network** | No nodes AND no links | Warning |
| **Disconnected Subcatchments** | `outlet_id` is nil or empty | Warning |
| **Unconnected Nodes** | Node not in any link's `us_node_id` or `ds_node_id` | Warning |

Validation warnings are logged but do **not** cause the import to fail.

---

## Empty Label List Cleanup

During SWMM5 import, ICM may create empty `Label List` objects that serve no purpose. The cleanup process:

1. Iterates through all imported objects
2. Identifies objects of type `'Label List'`
3. Checks if the `'labels'` blob is nil or empty
4. Deletes empty label lists
5. Preserves label lists that contain data

```ruby
def is_label_list_empty?(label_list, log_file = nil)
  begin
    labels_blob = label_list['labels']
    return labels_blob.nil? || labels_blob.empty?
  rescue => e
    log "  WARNING: Error checking label list: #{e.message}", log_file
    false  # Preserve on error (safe default)
  end
end
```

---

## Error Handling

The script implements robust error handling at multiple levels:

### File-Level Errors

| Error | Action |
|-------|--------|
| File not found | Skip file, log error, continue |
| Invalid extension | Skip file, log error, continue |
| Duplicate model group | Skip file, log error, continue |
| No objects imported | Delete empty model group, continue |
| Import exception | Delete partial model group, log backtrace, continue |

### Partial Import Cleanup

When an import fails mid-process, the script attempts to clean up:

```ruby
rescue => e
  # Clean up partial import
  if defined?(model_group) && model_group
    begin
      model_group.delete
      log "  Cleaned up partial import", log_file
    rescue => cleanup_error
      log "  Could not clean up: #{cleanup_error.message}", log_file
    end
  end
  
  aggregate_stats[:files_failed] += 1
  aggregate_stats[:failed_files] << { file: file_basename, reason: e.message }
end
```

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | All files imported successfully |
| `1` | One or more files failed (or configuration error) |

---

## Console Output

The script provides formatted console output for live monitoring:

```
+======================================================================+
|                       BATCH IMPORT PROCESSING                        |
+======================================================================+

----------------------------------------------------------------------
[1/5] Processing: model_site1.inp
----------------------------------------------------------------------
  Step 1: Creating model group...
          Model group created
  Step 2: Importing network...
          Import successful: 847 objects
          Nodes: 234, Links: 312, Subs: 89
  Step 3: Cleaning up artifacts...
          Removing 2 empty label list(s)
          Cleanup complete
  Step 4: Validating...
          Validation passed
  SUCCESS: Import complete

----------------------------------------------------------------------
[2/5] Processing: model_site2.inp
----------------------------------------------------------------------
  ...
```

---

## Version 2.0 Features

This version introduced several enhancements over the original:

| Feature | Description |
|---------|-------------|
| **Single File Support** | Works with one file, not just batches |
| **Batch Directory Import** | Process all `.inp` files in a folder |
| **Recursive Scanning** | Include files from subdirectories |
| **Progress Tracking** | `[N/Total]` progress indicators |
| **Aggregate Statistics** | Combined totals across all files |
| **Fault Tolerance** | Continue processing after failures |
| **Summary File** | Machine-readable output for UI integration |

---

## Dependencies

```ruby
require 'yaml'  # Configuration file parsing
```

The script also relies on ICMExchange-specific APIs:
- `WSApplication.open` - Open the database
- `db.new_model_object()` - Create model groups
- `model_group.import_all_sw_model_objects()` - Import SWMM files
- `imported_network.open` - Access network data
- `net.row_objects()` - Query network elements

---

## Related Files

| File | Purpose |
|------|---------|
| `SWMM5_Import_ICM_SWMM_with_Cleanup_UI.rb` | User interface script that launches this |
| `import_config.yaml` | Configuration file (input) |
| `batch_summary.txt` | Statistics file (output) |

---

## Technical Notes

- **Network Type:** Creates `'SWMM network'` objects (not InfoWorks networks)
- **Import Method:** Uses `import_all_sw_model_objects()` with `"inp"` format
- **Commit Message:** Each network is committed with `"Imported from SWMM5 - {filename}"`
- **Label Check:** Accesses the `'labels'` blob attribute directly

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "Configuration file not found" | Run UI script first to generate config |
| "Missing required keys" | Regenerate config with UI script |
| "Model group already exists" | Use timestamp option in UI script |
| "No objects imported" | Check import log for SWMM parsing errors |
| Empty network after import | Verify `.inp` file format and content |

---

## Author Notes

This script is designed to run unattended as part of an automated workflow. Key design principles:

- **Never fail silently** - All errors are logged with context
- **Clean up after failures** - No orphaned model groups left behind
- **Provide actionable feedback** - Summary statistics help identify issues
- **Support large batches** - Memory-efficient sequential processing

For debugging, check the detailed log file in the `ICM Import Log Files` folder.

Nano Banana Diagrams of the UI and EX Ruby Code

![alt text](<Gemini_Generated_Image_yugmv8yugmv8yugm (1)-1.jpeg>)

![alt text](Gemini_Generated_Image_gpznzggpznzggpzn.jpeg)