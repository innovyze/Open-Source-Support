
markdown
# Folder Structure

## OPEN-SOURCE-SUPPORT
- **01 InfoWorks ICM**
  - **01 Ruby**
  - **01 InfoWorks**
  - **02 SWMM**
    - **0001 - Element and Field Statistics**
      - *(Content omitted for brevity)*
    - **0002 - Tracing Tools**
      - *(Content omitted for brevity)*
    - **0003 - Scenario Tools**
      - *(Content omitted for brevity)*
    - **0004 - Scenario Sensitivity - InfoWorks**
      - *(Content omitted for brevity)*
    - **0005 - Import Export of Data Tables**
      - *(Content omitted for brevity)*
    - **0006 - ICM SWMM vs ICM InfoWorks All Tables**
      - *(Content omitted for brevity)*
    - **0007 - Hydraulic Comparison Tools for ICM InfoWorks and SWMM**
      - *(Content omitted for brevity)*
    - **0008 - Database Field Tools for Elements and Results**
      - *(Content omitted for brevity)*
    - **0009 - Polygon Subcatchment Boundary Tools**
      - *(Content omitted for brevity)*
    - **0010 - List all results fields with Stats**
      - *(Content omitted for brevity)*
    - **0011 - Get results from all timesteps in the IWR File**
      - *(Content omitted for brevity)*
    - **0012 - ICM InfoWorks Results to SWMM5 Summary Tables**
      - *(Content omitted for brevity)*
    - **0013 - SUDS or LID Tools**
      - `hw_UI_Script.rb`
      - `Network Modification Script.png`
      - `readme.md`
      - `UI_Script_Create SuDS for All Subcatchments.rb`
      - `UI_Script_output_suds_control_as_csv.rb`
      - `UI_Script.rb`

---

### Description

This section focuses on the **0013 - SUDS or LID Tools** directory under the `02 SWMM` folder, which contains Ruby scripts and images for handling Sustainable Urban Drainage Systems (SUDS) or Low Impact Development (LID) tools:

- **General Script:** `hw_UI_Script.rb` might be a general script for handling UI interactions or managing other scripts related to SUDS or LID.
- **Visual Aid:** `Network Modification Script.png` is likely an image illustrating the modifications or configurations related to network changes for SUDS or LID.
- **Documentation:** `readme.md` provides documentation or instructions for the use of the tools within this directory.
- **SUDS Creation:** `UI_Script_Create SuDS for All Subcatchments.rb` is a script designed to create SUDS for all subcatchments in the model, facilitating the implementation of sustainable drainage solutions.
- **SUDS Output:** `UI_Script_output_suds_control_as_csv.rb` outputs the control details of SUDS into a CSV format, which can be useful for data analysis or reporting.
- **General UI Script:** `UI_Script.rb` could be a general utility script or a placeholder for broader functionality related to SUDS or LID tools.

### Usage

To use the scripts within the `0013 - SUDS or LID Tools` directory:

1. **Open InfoWorks ICM:** Open a relevant network in the UI.
2. **Run Script Dialog:** Navigate to **Network -> Run Ruby Script**.
3. **Select Script:** Choose the required `UI_*.rb` or `hw_UI_*.rb` script from this folder.

For example, to create SuDS for all subcatchments, choose:
`UI_Script_Create SuDS for All Subcatchments.rb`.

Note
Always check for permissions before running scripts that might modify your model or data.
Backup your data before executing scripts that could alter or process datasets extensively.
The readme.md file within this directory might contain specific instructions, notes, or prerequisites for running these SUDS or LID tools.


This README now focuses exclusively on the `0013 - SUDS or LID Tools` folder, detailing its contents and usage.  