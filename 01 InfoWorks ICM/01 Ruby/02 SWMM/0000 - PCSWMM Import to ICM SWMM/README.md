# PCSWMM to InfoWorks ICM Import Tool

**Imports PCSWMM model (.pcz file) into InfoWorks ICM as a SWMM network**

**⚠️ IMPORTANT: An InfoWorks ICM Ultimate license is required to run this script.**

---

## Quick Start

1. **Download both scripts** (`PCSWMM_Import_UI.rb` and `PCSWMM_Import_Exchange.rb`) and save them to the same folder
2. **Open InfoWorks ICM**
3. **Create a new model group**
4. **Create a new SWMM network**
5. **Open the SWMM network**
6. **Network → Run Ruby Script**
7. **Select:** `PCSWMM_Import_UI.rb`
8. **Follow the dialogs:**
   - Choose your `.pcz` file
   - Enter a model group name
   - Confirm import
9. **Wait for completion** - Check console output for results

---

## What It Does

- Extracts .pcz file (ZIP format)
- Locates INP file in extracted contents
- Truncates overly long field values (ICM 100-character limit)
- Creates model group and imports SWMM network
- Cleans up URL-encoded names (%20 → spaces)
- Removes empty label lists
- Commits network to database

---

## Results

**Model Group** - Contains imported SWMM network with all objects

**Log Files** - Created in subfolder named after your .pcz file:
- `PCSWMM_Import_YYYYMMDD_HHMMSS.log` - Main import log
- `INP_Import_YYYYMMDD_HHMMSS.txt` - ICM's INP import log

**Imported Objects:**
- SWMM Network
- Nodes (junctions, outfalls, storage, dividers)
- Links (conduits, pumps, orifices, weirs, outlets)
- Subcatchments
- Rainfall Events
- Climatology
- Time Patterns

---

## Files

- `PCSWMM_Import_UI.rb` - **Run this** (user interface)
- `PCSWMM_Import_Exchange.rb` - Core logic (launched automatically)
- `README.md` - This guide

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| "No database is currently open" | Open an ICM database before running the script |
| "Model group already exists" | Delete or rename existing group, or choose a different name |
| "Cannot find ICMExchange.exe" | Install InfoWorks ICM 2024+ or contact support |
| No objects imported | Check logs for field value errors - truncation may have failed |
| Where are my log files? | `[PCZfileLocation]\[PCZfilename]\PCSWMM_Import_*.log` |

---

## Known Limitations

1. **PCSWMM Extensions** - Custom plugins and extensions don't transfer
2. **Field Length** - Values over 100 characters are automatically truncated
3. **Scenarios** - Each .pcz represents one model state; export multiple .pcz files for different scenarios
4. **PCZ Encryption** - Password-protected .pcz files are not supported

---

## Tips

- **Before Export:** Validate your PCSWMM model to catch geometry errors
- **Naming:** Use descriptive model group names (e.g., "Project - Scenario Name")
- **Multiple Models:** Import each .pcz separately with unique names
- **Validation:** Always run ICM's network validation after import
- **Log Files:** Keep logs with your project documentation

---

*Note: This documentation was AI-generated and reviewed by the script author.*
