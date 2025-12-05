# ARR Climate Change Adjustment Tool

The `INFD_ARRv4p2_CC.py` script applies climate change factors to Australian Rainfall and Runoff (ARR) version 4.2 rainfall data files. This tool adjusts rainfall intensities and loss parameters based on selected Shared Socioeconomic Pathway (SSP) scenarios and design years, enabling climate change impact assessments for InfoWorks ICM models.

For detailed instruction please download and view [INFD_ARR_ClimateChange.mp4]

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

### Step 1: Generate a design storm in InfoDrainage

An ARR design storm can be generated using ARR Storm Generator tool in InfoDrainage. Please take a look [here](https://help.autodesk.com/view/INFDS/ENU/?guid=GUID-2BC3BB13-3736-4FAF-A67F-80C2BB08B826) for more details of how to create an ARR design storm.

<img width="1605" height="1075" alt="image" src="https://github.com/user-attachments/assets/03adf695-7a09-4eed-9844-9bab21a3e8bf" />


Design rainfall data downloaded includes:
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

### Step 6: Update the design rainfall in InfoDrainage.

<img width="1653" height="1072" alt="image" src="https://github.com/user-attachments/assets/0adf62ae-6d27-419f-936b-d48387d5cbb6" />

- In InfoDrainage, open _Rainfall Manager_ and select the ARR design rainfall
- Select the icons under _Add from file_ to update _ARR Data Hub Text File_ and _BOM Design Raifall_
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

