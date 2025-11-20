# ARR Climate Change Adjustment Tool

The `ICM_ARRv4p2_CC.py` script applies climate change factors to Australian Rainfall and Runoff (ARR) version 4.2 rainfall data files. This tool adjusts rainfall intensities and loss parameters based on selected Shared Socioeconomic Pathway (SSP) scenarios and design years, enabling climate change impact assessments for InfoWorks ICM models.

## Overview

This script processes ARR rainfall data ZIP files (`.arr.zip`) by:

- Applying rainfall Climate Change Factors (CCFs) to adjust rainfall depths for different durations
- Adjusting initial and continuing loss parameters based on climate change projections
- Extracting temperature change information for the selected scenario
- Creating a new adjusted ZIP file with original files preserved as backups

## Features

- **Interactive GUI**: User-friendly interface for selecting SSP scenarios and design years
- **Automatic Versioning**: Prevents overwriting existing files by appending version numbers
- **Backup Preservation**: Original files are saved as `old_BomIfds.csv` and `old_ArrDataHub.txt`
- **Adjustment Documentation**: Creates an `adjustment_info.txt` file documenting all applied changes
- **Automatic Extraction**: Extracts the adjusted ZIP file contents to a folder for easy access

## Requirements

- Python 3.x
- Required packages:
  - `pandas`
  - `tkinter` (usually included with Python)
  - Standard library: `shutil`, `os`, `zipfile`, `io`, `re`

Install dependencies using:
```bash
pip install pandas
```

## Usage

### Step 1: Run the Script

Execute the script:
```bash
python ICM_ARRv4p2_CC.py
```

### Step 2: Select Input File

A file dialog will appear. Select your ARR rainfall data ZIP file (`.arr.zip` format).

### Step 3: Choose Climate Change Scenario

A dialog window will appear with two dropdown menus:

1. **Select Shared Socioeconomic Pathway (SSP)**:
   - SSP1-2.6 (Low emissions scenario)
   - SSP2-4.5 (Intermediate emissions scenario)
   - SSP3-7.0 (High emissions scenario)
   - SSP5-8.5 (Very high emissions scenario)

2. **Select Design Year**:
   - Available years: 2030, 2040, 2050, 2060, 2070, 2080, 2090, 2100

Click "Submit" to proceed.

### Step 4: Review Output

The script will:
- Create a new ZIP file named `[original_name]_[SSP]_[year].arr.zip`
- If a file with the same name exists, it will append `_v2`, `_v3`, etc.
- Extract the contents to a folder with the same name (without `.zip` extension)

## Output Files

The adjusted ZIP file contains:

- **BomIfds.csv**: Updated rainfall depths with climate change factors applied
- **ArrDataHub.txt**: Updated loss parameters (initial and continuing losses)
- **old_BomIfds.csv**: Backup of original rainfall data
- **old_ArrDataHub.txt**: Backup of original ARR data hub file
- **adjustment_info.txt**: Summary of applied adjustments including:
  - Selected SSP scenario
  - Design year
  - Number of rainfall CCFs applied
  - Initial loss factor
  - Continuing loss factor
  - Temperature change (°C)

## How It Works

### Rainfall Adjustment

The script applies duration-specific Climate Change Factors (CCFs) to rainfall depths in `BomIfds.csv`:

- **10 CCF values** correspond to durations: ≤1h, 1.5h, 2h, 3h, 4.5h, 6h, 9h, 12h, 18h, ≥24h
- For durations between these values, linear interpolation is used
- All rainfall depth columns (except Duration columns) are multiplied by the appropriate factor

### Loss Parameter Adjustment

Initial and continuing loss values in the `[LOSSES]` section of `ArrDataHub.txt` are adjusted by:
- **Initial Loss Factor**: Multiplies "Storm initial losses" values
- **Continuing Loss Factor**: Multiplies "Storm continuing losses" values

### Data Source

The script reads climate change factors from the `ArrDataHub.txt` file within the ZIP, which contains:
- `[SSP1-2.6]`, `[SSP2-4.5]`, `[SSP3-7.0]`, `[SSP5-8.5]` sections with rainfall CCFs
- `[Climate_Change_INITIAL_LOSS]` table
- `[Climate_Change_CONTINUING_LOSS]` table
- `[TEMPERATURE_CHANGES]` table

## Console Output

The script provides console feedback including:
- Confirmation of file copy location
- Parsed factor counts and values
- Updated loss parameter values
- Temperature change information
- Extraction folder location

## Error Handling

The script will display error messages if:
- No file is selected
- `ArrDataHub.txt` is not found in the ZIP file
- `BomIfds.csv` is not found in the ZIP file
- Rainfall CCFs are not found for the selected SSP/year combination (warning only, file still created)

## Notes

- The script preserves all other files in the original ZIP
- Original files are always backed up before modification
- The adjusted ZIP maintains the same structure as the original
- Temperature change values are extracted but not directly applied to the model (for reference only)

## Example

If you select a file named `Sydney_ARR.arr.zip` with SSP2-4.5 and year 2050:
- Output file: `Sydney_ARR_SSP2-4.5_2050.arr.zip`
- Extraction folder: `Sydney_ARR_SSP2-4.5_2050.arr`

## References

This tool is designed to work with ARR v4.2 climate change data. For more information on ARR climate change factors, refer to the Australian Rainfall and Runoff guidelines.

