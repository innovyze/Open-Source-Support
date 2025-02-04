
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
      - `compare_icm_swmm_icm_files.rb`
      - `EX Run Parameters.rb`
      - `ICM InfoWorks All Table Names.rb`
      - `ICM SWMM All Tables.rb`
      - `ICM SWMM Network Overview.rb`
      - `readme.md`
      - `Sensor_Comparison.rb`
      - `sw_hw_UI_Set_Script_CN_BN.rb`
      - `sw_UI_Get_script_CN_BN.rb`
      - `sw_UI_Script_additional_dwf_nodes_icm_swmm.rb`
      - `sw_UI_Script_Calculate statistics for baseline data.rb`

---

### Description

This section focuses on the **0006 - ICM SWMM vs ICM InfoWorks All Tables** directory under the `02 SWMM` folder, which contains Ruby scripts for comparing and analyzing data between ICM SWMM and ICM InfoWorks:

- **File Comparison:** `compare_icm_swmm_icm_files.rb` is designed to compare files between ICM SWMM and ICM InfoWorks.
- **Run Parameters:** `EX Run Parameters.rb` likely deals with setting or extracting run parameters for simulations or analyses.
- **Table Names:** `ICM InfoWorks All Table Names.rb` retrieves or lists all table names within ICM InfoWorks.
- **All Tables:** `ICM SWMM All Tables.rb` provides functionality to work with all tables in ICM SWMM.
- **Network Overview:** `ICM SWMM Network Overview.rb` offers an overview of the network in ICM SWMM, useful for understanding the structure or connectivity.
- **Sensor Comparison:** `Sensor_Comparison.rb` might compare sensor data or configurations between different models or scenarios.
- **Script Setting:** `sw_hw_UI_Set_Script_CN_BN.rb` and `sw_UI_Get_script_CN_BN.rb` are scripts for setting and getting certain script parameters or data (possibly related to Curve Numbers or Building Numbers).
- **Dry Weather Flow Nodes:** `sw_UI_Script_additional_dwf_nodes_icm_swmm.rb` handles additional dry weather flow nodes in ICM SWMM.
- **Baseline Data Statistics:** `sw_UI_Script_Calculate statistics for baseline data.rb` calculates statistics for baseline data, providing a base for comparison or analysis.

### Usage

To use the scripts within the `0006 - ICM SWMM vs ICM InfoWorks All Tables` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0006 - ICM SWMM vs ICM InfoWorks All Tables` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for comparing or analyzing data between ICM SWMM and ICM InfoWorks.

For example, to compare files:
```sh
ruby compare_icm_swmm_icm_files.rb

Note
Always check for permissions before running scripts that might access or modify files.
Backup your data before executing scripts that could alter or process data extensively.
The readme.md file within this directory might contain specific instructions, notes, or prerequisites for running these comparison scripts.


This README now focuses exclusively on the `0006 - ICM SWMM vs ICM InfoWorks All Tables` folder, detailing its contents and usage. 