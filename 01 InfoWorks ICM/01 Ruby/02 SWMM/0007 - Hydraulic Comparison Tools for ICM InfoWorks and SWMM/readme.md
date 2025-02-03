
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
      - `hw_UI_script_compare_icm_headloss.rb`
      - `hw_UI_script_compare_icm_inlets_hec22_inlets.rb`
      - `hw_UI_scriptsCompare ICM Headloss.rb`
      - `kutter_tm Kutter Sql for ICM SWMM.rb`
      - `kutter_tm Kutter Sql for ICM SWMM.sql`
      - `kutter_tm.rb`
      - `kutter_tm.sql`
      - `tau_shear_stress.rb`
      - `UI_script Tau or Shear Stress non QM Calculations.rb`

---

### Description

This section focuses on the **0007 - Hydraulic Comparison Tools for ICM InfoWorks and SWMM** directory under the `02 SWMM` folder, which contains scripts for comparing hydraulic parameters between ICM InfoWorks and SWMM:

- **Headloss Comparison:** `hw_UI_script_compare_icm_headloss.rb` and `hw_UI_scriptsCompare ICM Headloss.rb` are scripts for comparing headloss calculations between the two models.
- **Inlet Comparison:** `hw_UI_script_compare_icm_inlets_hec22_inlets.rb` compares inlets, likely following HEC-22 standards or methodologies.
- **Kutter's Formula:** `kutter_tm Kutter Sql for ICM SWMM.rb` and `kutter_tm Kutter Sql for ICM SWMM.sql` along with `kutter_tm.rb` and `kutter_tm.sql` deal with implementing or comparing Kutter's formula for flow calculations in both ICM SWMM and InfoWorks.
- **Shear Stress:** `tau_shear_stress.rb` and `UI_script Tau or Shear Stress non QM Calculations.rb` handle calculations and comparisons of shear stress or tau, which are crucial for understanding erosion or sediment transport in hydraulic models.

### Usage

To use the scripts within the `0007 - Hydraulic Comparison Tools for ICM InfoWorks and SWMM` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system. SQL scripts might require an appropriate SQL environment or tool for execution.
2. **Navigation:** Navigate to the `0007 - Hydraulic Comparison Tools for ICM InfoWorks and SWMM` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for comparing hydraulic parameters. For SQL scripts, use an SQL environment to execute them.

For example, to compare headloss:
```sh
ruby hw_UI_script_compare_icm_headloss.rb

Note
Always check for permissions before running scripts that might access or modify data.
Backup your data before executing scripts that could alter or process datasets extensively.
The SQL scripts (kutter_tm Kutter Sql for ICM SWMM.sql, kutter_tm.sql) should be run in an SQL environment, not through Ruby directly.
The readme.md file within this directory might contain specific instructions, notes, or prerequisites for running these comparison tools.


This README now focuses exclusively on the `0007 - Hydraulic Comparison Tools for ICM InfoWorks and SWMM` folder, detailing its contents and usage. 