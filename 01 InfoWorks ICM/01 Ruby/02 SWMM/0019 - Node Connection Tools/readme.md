
markdown
# Folder Structure

Based on your instruction to focus only on the 0019 - Node Connection Tools folder, here's the updated markdown README file:

markdown
# Project Structure

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
        - *(Content omitted for brevity)*
      - **0017 - Subcatchment Grid and Tabs Tools**
        - *(Content omitted for brevity)*
      - **0018 - Create Selection list using a SQL query**
        - *(Content omitted for brevity)*
      - **0019 - Node Connection Tools**
        - `hw_dry_pipes.rb`
        - `hw_sw_Bifurcation Nodes.rb`
        - `hw_sw_Header Nodes.rb`
        - `readme.md`
        - `sw_dry_pipes.rb`

---

### Description

This section focuses on the **0019 - Node Connection Tools** directory under the `02 SWMM` folder, which contains Ruby scripts for managing and analyzing different types of node connections in SWMM models:

- **Dry Pipes:**
  - `hw_dry_pipes.rb` and `sw_dry_pipes.rb` are scripts likely used for identifying or managing dry pipes in HydroWorks (HW) and SWMM (SW) models respectively. Dry pipes could refer to pipes that do not carry flow under certain conditions or are part of a specific analysis.

- **Bifurcation Nodes:**
  - `hw_sw_Bifurcation Nodes.rb` deals with bifurcation nodes, which are nodes where the flow splits into two or more directions. This script might help in setting up, analyzing, or modifying these nodes in both HW and SWMM.

- **Header Nodes:**
  - `hw_sw_Header Nodes.rb` focuses on header nodes, which could be the starting nodes of a network or significant junction nodes. This script might assist in managing or analyzing these critical points.

- **Documentation:** `readme.md` provides documentation or instructions related to the usage of these node connection tools.

### Usage

To use the scripts within the `0019 - Node Connection Tools` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0019 - Node Connection Tools` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for node connection analysis or management.

For example, to manage dry pipes in a SWMM model:
```sh
ruby sw_dry_pipes.rb

Note
Always ensure you have the necessary permissions before running scripts that might modify your model.
Backup your data before executing scripts that could alter or process datasets extensively.
Review readme.md for any specific instructions, notes, or prerequisites for running these node connection tools.


This README now focuses exclusively on the `0019 - Node Connection Tools` folder, detailing its contents and usage. If there's anything else you need or any further adjustments, please let me know!