# Import Patterns to Profiles

**Convert InfoSewer diurnal patterns to InfoWorks ICM CSV format**

**Last Updated**: February 2026

---

## About This Tool

This tool converts InfoSewer diurnal pattern data (PATNDATA.DBF) into properly formatted CSV files for InfoWorks ICM. 

**⚠️ IMPORTANT:** This script **generates CSV files only** - it does NOT import them into ICM. You must manually import the generated CSV files through the InfoWorks ICM user interface.

**Why?** Wastewater and Trade Waste profiles are Model Group objects that cannot be created via UI Ruby scripts (Network → Run Ruby Script). They require either Exchange scripts or CSV import through the UI. This tool uses CSV generation to avoid Exchange complexity.

---

## Quick Start

### ⚠️ Required Folder Structure

```
0060 - InfoSewer to InfoWorks ICM Conversion Tools/
├── lib/
│   └── dbf_reader.rb          ← REQUIRED
└── Pattern Import/
    └── Import_Patterns_to_Profiles.rb
```

### Instructions

1. **Open InfoWorks ICM** and any network
2. **Network → Run Ruby Script** → Select `Import_Patterns_to_Profiles.rb`
3. **Follow the dialogs:**
   - Choose your `.IEDB` folder
   - Choose output folder for CSV files
   - Select profile types to generate (Wastewater, Trade Waste, or both)
4. **Script completes** - CSV files generated in your output folder
5. **Import CSVs manually into ICM:**
   - Right-click **Model Group** → **Import InfoWorks**
   - For Wastewater: **Waste water → from InfoWorks format CSV file...**
   - For Trade Waste: **Trade waste → from InfoWorks format CSV file...**

---

## What It Does

- Reads `PATNDATA.DBF` directly from InfoSewer model (24 hourly factors, SEQ 0-23)
- Converts patterns to InfoWorks CSV event format
- Generates `Wastewater_Profiles.csv` and `Trade_Waste_Profiles.csv`
- Populates calibration weekday, weekend, and design profiles with pattern data
- Sets monthly calibration factors to 1.0 (no monthly variation)
- Includes all 16 standard pollutant definitions (concentrations set to 0)

### Data Quality Handling

| Issue | How It's Handled |
|-------|------------------|
| Pattern with >24 values | Uses first 24 values (SEQ 0-23), ignores extras, warns user |
| Pattern with <24 values | Fills missing values with 1.0, warns user |
| Pattern IDs with dots | Dots replaced with underscores (ICM compatibility) |

**All corrections are clearly reported in console output.**

---

## Files

- `Import_Patterns_to_Profiles.rb` - Main script
- `../lib/dbf_reader.rb` - **DBF file parser** (REQUIRED - in parent folder)

---

## Output File Format

### CSV Structure

The generated CSV files follow InfoWorks event format specification:

```
!Version=1,type=WWG,encoding=UTF8
TITLE,POLLUTANT_COUNT
InfoSewer Patterns - Wastewater Profiles,16
Units_Concentration,Units_Salt_Concentration,Units_Temperature,Units_Average_Flow
mg/l,kg/m3,degC,l/day
PROFILE_NUMBER,PROFILE_DESCRIPTION,FLOW
1,RESIDENTIAL,0
SEDIMENT,AVERAGE_CONCENTRATION
SF1,0
SF2,0
POLLUTANT,DISSOLVED,SF1,SF2
BOD,0,0,0
COD,0,0,0
...
CALIBRATION_WEEKDAY
TIME,FLOW,POLLUTANT
00:00,0.618,1
01:00,0.484,1
...
CALIBRATION_WEEKEND
TIME,FLOW,POLLUTANT
...
CALIBRATION_MONTHLY
MONTH,FLOW,POLLUTANT
JANUARY,1,1
...
DESIGN_PROFILES
TIME,FLOW,POLLUTANT
...
```

### Profile Sections

| Section | Description |
|---------|-------------|
| PROFILE_NUMBER | Pattern ID from InfoSewer |
| FLOW | Per capita flow (wastewater=0) or flow scaling factor (trade waste=1) |
| SEDIMENT | Sediment fractions (all 0) |
| POLLUTANT | Base pollutant concentrations (all 0) |
| CALIBRATION_WEEKDAY | 24 hourly multipliers from PATNDATA (00:00 to 23:00) |
| CALIBRATION_WEEKEND | Same as weekday |
| CALIBRATION_MONTHLY | 12 monthly multipliers (all 1.0) |
| DESIGN_PROFILES | Same as weekday |

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **Script fails immediately** | Check that `../lib/dbf_reader.rb` exists in parent folder |
| "Could not find PATNDATA.DBF" | Verify file exists in `.IEDB` folder root |
| "No pattern data found" | Check that PATNDATA.DBF is not empty or corrupted |
| Profiles not showing in model | Profiles must be manually linked to subcatchments after import |

---

## Assumptions

1. Pattern format: Hourly increments, 24 hours of data (SEQ 0-23)
2. Calibration weekday, weekend, and design profiles all use same pattern data

---

## Related Tools

- **InfoSewer_Import_UI.rb** - Main import tool (geometry, scenarios, hydraulics) - in parent folder

---

*Note: This documentation was AI-generated and reviewed by the script author.*
