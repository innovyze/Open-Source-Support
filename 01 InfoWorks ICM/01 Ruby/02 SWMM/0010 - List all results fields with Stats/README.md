
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
      - `hw_UI_script Find Time of Max DS Depth.rb`
      - `README.md`
      - `sw_UI_script_ Raingages_AllOutputParameters.rb`
      - `UI_script List all results fields in a simulation (ICM SWMM) and Show Link Res...`
      - `UI_script List all results fields in a simulation (ICM) and Show Subcatchment Res...`
      - `UI_script List all results fields in a simulation (ICM) and Show Flap Valve Results...`
      - `UI_script List all results fields in a simulation (ICM) and Show Link Results Stats...`
      - `UI_script List all results fields in a simulation (ICM) and Show Node Results Stats...`

---

### Description

This section focuses on the **0010 - List all results fields with Stats** directory under the `02 SWMM` folder, which contains Ruby scripts for listing and analyzing results fields with statistical data:

- **Max Depth Time:** `hw_UI_script Find Time of Max DS Depth.rb` finds the time of maximum downstream depth, which could be useful for flooding or flow analysis.
- **Documentation:** `README.md` provides documentation or instructions on how to use the scripts within this directory.
- **Rain gauges Output:** `sw_UI_script_ Raingages_AllOutputParameters.rb` lists all output parameters for raingages in SWMM.
- **Link Results:** `UI_script List all results fields in a simulation (ICM SWMM) and Show Link Res...` and `UI_script List all results fields in a simulation (ICM) and Show Link Results Stats...` list results fields for links in ICM SWMM and ICM simulations, respectively, providing statistics on link performance or conditions.
- **Subcatchment Results:** `UI_script List all results fields in a simulation (ICM) and Show Subcatchment Res...` lists results fields related to subcatchments in ICM, useful for understanding runoff and infiltration statistics.
- **Flap Valve Results:** `UI_script List all results fields in a simulation (ICM) and Show Flap Valve Results...` focuses on listing results related to flap valves in ICM simulations.
- **Node Results:** `UI_script List all results fields in a simulation (ICM) and Show Node Results Stats...` provides statistics on node results within an ICM simulation.

### Usage

To use the scripts within the `0010 - List all results fields with Stats` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0010 - List all results fields with Stats` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for listing and analyzing simulation results with statistics.

For example, to find the time of maximum downstream depth:
```sh
ruby hw_UI_script Find Time of Max DS Depth.rb

Note
Always ensure you have the necessary permissions to run these scripts.
Backup your data before running scripts that might process or alter datasets.
The README.md file within this directory might contain specific instructions, notes, or prerequisites for running these statistical analysis scripts.


This README now focuses exclusively on the `0010 - List all results fields with Stats` folder, detailing its contents and usage.  