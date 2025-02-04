
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
        - *(Content omitted for brevity)*
      - **0014 - InfoSewer to ICM Comparison Tools**
        - *(Content omitted for brevity)*
      - **0015 - Export SWMM5 Calibration Files**
        - *(Content omitted for brevity)*
      - **0016 - InfoSWMM and SWMM5 Tools in Ruby**
        - `read_swmm5_rpt.rb`
        - `README.md`
        - `sw_UI_script_Make an Inflows File from User Fields.rb`
        - `UI_script InfoSWMM Subcatchment Manager Tools.rb`

---

### Description

This section focuses on the **0016 - InfoSWMM and SWMM5 Tools in Ruby** directory under the `02 SWMM` folder, which contains Ruby scripts for managing and interacting with InfoSWMM and SWMM5 models:

- **Report Reading:** `read_swmm5_rpt.rb` is a script designed to read and possibly parse SWMM5 report files, which could be useful for analyzing simulation results or extracting data for further processing.
- **Documentation:** `README.md` provides instructions or information on how to use the tools within this directory.
- **Inflows Creation:** `sw_UI_script_Make an Inflows File from User Fields.rb` generates an inflows file based on user-defined fields, which might be used for setting up specific scenarios or data inputs in SWMM models.
- **Subcatchment Management:** `UI_script InfoSWMM Subcatchment Manager Tools.rb` offers tools or functionalities for managing subcatchments within the InfoSWMM environment, possibly including creation, modification, or analysis of subcatchment data.

### Usage

To use the scripts within the `0016 - InfoSWMM and SWMM5 Tools in Ruby` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0016 - InfoSWMM and SWMM5 Tools in Ruby` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for managing SWMM models.

For example, to read a SWMM5 report:
```sh
ruby read_swmm5_rpt.rb

Note
Always check for permissions before running scripts that might modify or interact with your model files.
Backup your data before executing scripts that could alter or process datasets extensively.
Review the README.md file for any specific instructions, notes, or prerequisites for using these InfoSWMM and SWMM5 tools.


This README now focuses exclusively on the `0016 - InfoSWMM and SWMM5 Tools in Ruby` folder, detailing its contents and usage. If there's anything else you need