# ARR Climate Change Adjustment Tool

The `ICM_ARRv4p2_CC.py` script applies climate change factors to Australian Rainfall and Runoff (ARR) version 4.2 rainfall data files. This tool adjusts rainfall intensities and loss parameters based on selected Shared Socioeconomic Pathway (SSP) scenarios and design years, enabling climate change impact assessments for InfoWorks ICM models.

For detailed instruction please download and view [ICM_ARR_ClimateChange.mp4](https://github.com/trannguyen9911/Open-Source-Support/blob/main/01%20InfoWorks%20ICM/03%20Python/0006%20ARR%20climate%20change/ICM_ARR_ClimateChange.mp4)

## Overview

This script processes ARR rainfall data ZIP files (`.arr.zip`) by:

- Applying rainfall Climate Change Factors (CCFs) to adjust rainfall depths for different durations
- Adjusting initial and continuing loss parameters based on climate change projections
- Extracting temperature change information for the selected scenario
- Creating a new adjusted ZIP file with original files preserved as backups


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

### Step 1: Generate a design storm in InfoWorks ICM 

An ARR design storm can be generated using ARR Storm Generator tool in InfoWorks ICM. Please take a look [here](https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=GUID-4C08EAE3-4163-49C8-B91A-789CFF763457) for more details of how to create an ARR design storm.

<img width="1925" height="955" alt="image" src="https://github.com/user-attachments/assets/99d1055d-719b-4253-945f-425a5d4e7fb3" />

Navigate to the location of the ARR design storm data, these following files can be found in _.arr.zip_:
   - BomIfds.csv file that contains IFD curves
   - ArrDataHub.txt file that includes Climate Change Factors for different Shared Socioeconomic Pathway (SSP), Initial Loss and (IL), and Continuous Loss (CL)

### Step 2: Run the Script

Execute the script:
```bash
python ICM_ARRv4p2_CC.py
```

### Step 3: Select Input File

A file dialog will appear. Select your ARR rainfall data ZIP file (`.arr.zip` format).

### Step 4: Choose Climate Change Scenario

A dialog window will appear with two dropdown menus:

1. **Select Shared Socioeconomic Pathway (SSP)**:
   - SSP1-2.6 (Low emissions scenario)
   - SSP2-4.5 (Intermediate emissions scenario)
   - SSP3-7.0 (High emissions scenario)
   - SSP5-8.5 (Very high emissions scenario)

2. **Select Design Year**:
   - Available years: 2030, 2040, 2050, 2060, 2070, 2080, 2090, 2100

Click "Submit" to proceed.

### Step 5: Review Output

The script will:
- Create a new ZIP file named `[original_name]_[SSP]_[year].arr.zip`
- If a file with the same name exists, it will append `_v2`, `_v3`, etc.
- Extract the contents to a folder with the same name (without `.zip` extension)

### Step 6: Update the design rainfall in InfoWorks ICM.

  <img width="1697" height="922" alt="image" src="https://github.com/user-attachments/assets/68143282-f658-43c4-aa52-b2a6c28cf578" />
  
- In InfoWorks ICM, open the design rainfall and select _ARR Storm Generator_
- Select the new .arr.zip folder (with climate change factors updated) and click _Edit_
- Select _Add from file..._ to update _ARR Data Hub Text File_ and _BOM Design Raifall_
- Select _OK_ to save the changes

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

