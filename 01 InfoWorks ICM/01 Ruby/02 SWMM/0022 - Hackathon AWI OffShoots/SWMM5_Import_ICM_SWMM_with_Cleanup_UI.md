# SWMM5 Import to ICM - UI Script Documentation

**Version:** 3.1  
**Purpose:** User-facing script to configure and launch the import of SWMM5 `.inp` file(s) into ICM SWMM Networks

---

## Overview

This Ruby script provides a graphical user interface for importing EPA SWMM5 input files (`.inp`) into Autodesk InfoWorks ICM. It serves as a front-end configuration tool that prepares import settings and then launches the actual import process via ICMExchange.

The script handles everything from single-file imports to large batch operations with hundreds of files, including automatic network naming, duplicate detection, and post-import cleanup.

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Multiple Import Modes** | Single file, batch (directory only), or recursive batch (include subdirectories) |
| **Automatic Network Naming** | Configurable naming conventions with optional prefixes and timestamps |
| **Duplicate Detection** | Pre-validates network names against existing database objects |
| **Empty Label Cleanup** | Automatically removes empty visualization labels after import |
| **Connectivity Validation** | Post-import validation of network connectivity |
| **Live Progress Streaming** | Real-time output display during import operations |
| **Time Estimation** | Heuristic-based import duration estimates |

---

## Prerequisites

1. **InfoWorks ICM** must be installed (2025.2 or later recommended)
2. An **ICM database must be open** before running the script
3. The companion **Exchange script** (`SWMM5_Import_ICM_InfoWorks_with_Cleanup_Exchange.rb`) must be in the same directory

---

## How to Use

1. Open your ICM database
2. Navigate to **Network menu → Run Ruby Script**
3. Select this script file
4. Follow the interactive prompts:
   - Choose import mode (single/batch/recursive)
   - Select file(s) or directory
   - Configure naming options
   - Confirm and launch import

---

## Script Workflow

The script operates in 10 sequential steps:

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: Initialization                                         │
│  - Verify database is open                                      │
│  - Display welcome message with feature summary                 │
├─────────────────────────────────────────────────────────────────┤
│  STEP 2: Import Mode Selection                                  │
│  - Single File                                                  │
│  - Batch - Directory Only                                       │
│  - Batch - Include Subdirectories                               │
├─────────────────────────────────────────────────────────────────┤
│  STEP 3: File/Directory Selection                               │
│  - File dialog for single file or directory selection           │
│  - Automatic .inp file discovery for batch modes                │
├─────────────────────────────────────────────────────────────────┤
│  STEP 4: Size Check & Time Estimation                           │
│  - Calculate total file size                                    │
│  - Estimate import duration using heuristics                    │
│  - Warn user if estimated time exceeds 10 minutes               │
├─────────────────────────────────────────────────────────────────┤
│  STEP 5: Naming Configuration                                   │
│  - Single: Custom name with optional timestamp                  │
│  - Batch: Naming convention, prefix, and timestamp options      │
├─────────────────────────────────────────────────────────────────┤
│  STEP 6: Pre-Validation                                         │
│  - Check for duplicate network names in database                │
│  - Check for self-duplicates in generated names                 │
├─────────────────────────────────────────────────────────────────┤
│  STEP 7: Configuration File Generation                          │
│  - Create YAML config file with all import settings             │
│  - Store in "ICM Import Log Files" subfolder                    │
├─────────────────────────────────────────────────────────────────┤
│  STEP 8: Final Confirmation                                     │
│  - Display summary and request user confirmation                │
├─────────────────────────────────────────────────────────────────┤
│  STEP 9: Launch ICMExchange                                     │
│  - Locate ICMExchange.exe automatically                         │
│  - Execute with live output streaming                           │
├─────────────────────────────────────────────────────────────────┤
│  STEP 10: Results Summary                                       │
│  - Parse batch_summary.txt from Exchange script                 │
│  - Display import statistics and element counts                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Naming Conventions (Batch Mode)

When importing multiple files, three naming conventions are available:

| Option | Example Input | Example Output |
|--------|---------------|----------------|
| **Filename Only** | `C:/Models/Site1/model.inp` | `model` |
| **Directory + Filename** | `C:/Models/Site1/model.inp` | `Site1_model` |
| **Relative Path** | `C:/Models/Site1/Sub/model.inp` | `Site1_Sub_model` |

Additional options:
- **Prefix:** Prepended to all names (e.g., `SWMM_Import_`)
- **Timestamp:** Appends `_YYYYMMDD_HHMM` to prevent duplicates

---

## ICMExchange Discovery

The script automatically locates `ICMExchange.exe` using this priority:

1. **Hardcoded paths** for known ICM versions (2025.2–2027)
2. **Dynamic search** in `Program Files\Autodesk\` and `Program Files\Innovyze\`
3. **User fallback** dialog if automatic detection fails

---

## Time Estimation Heuristic

```
Estimated Time = (Number of Files × 0.5 min) + (Total Size MB ÷ 25)
```

This accounts for:
- Fixed overhead per file (~30 seconds)
- Processing time proportional to file size (~1 minute per 25 MB)

---

## Configuration File Structure

The script generates a YAML configuration file (`import_config.yaml`) with this structure:

```yaml
import_mode: "Batch - Include Subdirectories"
base_directory: "C:/SWMM_Models"
cleanup_empty_label_lists: true
validate_after_import: true
file_configs:
  - file_path: "C:/SWMM_Models/site1.inp"
    network_name: "SWMM_Import_site1_20241205_1430"
    file_basename: "site1.inp"
  - file_path: "C:/SWMM_Models/sub/site2.inp"
    network_name: "SWMM_Import_sub_site2_20241205_1430"
    file_basename: "site2.inp"
```

---

## Output Files

All outputs are stored in an `ICM Import Log Files` folder within the base directory:

| File | Description |
|------|-------------|
| `import_config.yaml` | Configuration passed to Exchange script |
| `batch_summary.txt` | Machine-readable import statistics |
| Individual log files | Per-file import details (generated by Exchange script) |

---

## Summary Statistics

After import, the script displays:

- **Duration** (formatted as seconds)
- **Files processed/successful/failed** (batch mode)
- **Total elements imported:**
  - Nodes
  - Links
  - Subcatchments
- **Empty labels cleaned** (if any)

---

## Version 3.1 Changes

This version includes several important fixes and improvements:

1. **Fixed WSApplication.prompt RuntimeError**
   - Implemented robust 4-element format `[Label, Type, Attributes, DefaultValue]` for all prompt definitions
   - Resolved "attributes parameter item 0 invalid type" errors

2. **Improved Relative Path Naming**
   - Better handling of files in root directories
   - Cleaner path separator replacement

3. **Enhanced Duration Formatting**
   - Proper float parsing for accurate time display
   - Improved summary report formatting

---

## Error Handling

| Scenario | Behavior |
|----------|----------|
| No database open | Displays error and exits |
| No `.inp` files found | Displays warning and exits |
| Duplicate network names in DB | Lists conflicts and exits |
| Duplicate names generated | Lists duplicates, suggests timestamp, exits |
| ICMExchange not found | Prompts user to locate manually |
| Exchange script missing | Displays error and exits |

---

## Dependencies

```ruby
require 'yaml'       # Configuration file serialization
require 'open3'      # Process execution with live streaming
require 'fileutils'  # Directory creation
```

---

## Related Files

| File | Purpose |
|------|---------|
| `SWMM5_Import_ICM_InfoWorks_with_Cleanup_Exchange.rb` | Companion Exchange script that performs the actual import |
| `import_config.yaml` | Generated configuration file |
| `batch_summary.txt` | Generated results file |

---

## Technical Notes

- **Target Network Type:** `SWMM network` (not InfoWorks network)
- **File Pattern Matching:** Case-insensitive (`.inp`, `.INP`, `.Inp`)
- **Character Sanitization:** Invalid characters replaced with underscores
- **Path Normalization:** Windows backslashes converted to forward slashes

---

## Author Notes

This script is designed for water/wastewater engineers working with SWMM5 models who need to migrate or import data into InfoWorks ICM. It emphasizes:

- **User-friendly prompts** with sensible defaults
- **Robust error handling** to prevent partial imports
- **Transparency** through live progress streaming
- **Automation** of repetitive cleanup tasks

For questions or issues, check the Ruby output window for detailed diagnostic messages.

Nano Banana Diagrams of the UI and EX Ruby Code

![alt text](<Gemini_Generated_Image_yugmv8yugmv8yugm (1)-1.jpeg>)

![alt text](Gemini_Generated_Image_gpznzggpznzggpzn.jpeg)