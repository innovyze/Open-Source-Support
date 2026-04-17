
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
        - `8_LID_Example 8_Subs.inp`
        - `hw_UI_script_downstream_velocity.rb`
        - `hw_UI_script_downstream_flow.rb`
        - `hw_UI_script_downstream_depth.rb`
        - `hw_UI_script_groundwater_elevation.rb`
        - `hw_UI_script_node_flood_depth.rb`
        - `hw_UI_script_node_lateral_inflow.rb`
        - `hw_UI_script_node_level.rb`
        - `hw_UI_script_runoff.rb`
        - `hw_UI_script_upstream_low.rb`
        - `hw_UI_script_upstream_depth.rb`
        - `hw_UI_script_upstream_velocity.rb`
        - `hw_UI_script_groundwater_flow.rb`
        - `hw_UI_script.rb`
        - `README.md`

---

### Description

This section focuses on the **0015 - Export SWMM5 Calibration Files** directory under the `02 SWMM` folder, which contains Ruby scripts designed for exporting calibration files for SWMM5:

- **Example File:** `8_LID_Example 8_Subs.inp` is likely an example input file for SWMM5, possibly demonstrating LID (Low Impact Development) subcatchments.
- **Downstream Data:** 
  - `hw_UI_script_downstream_velocity.rb` exports downstream velocity data for calibration purposes.
  - `hw_UI_script_downstream_flow.rb` exports downstream flow data.
  - `hw_UI_script_downstream_depth.rb` deals with exporting downstream depth data.
- **Groundwater Data:** 
  - `hw_UI_script_groundwater_elevation.rb` exports groundwater elevation data.
  - `hw_UI_script_groundwater_flow.rb` exports groundwater flow data.
- **Node Data:** 
  - `hw_UI_script_node_flood_depth.rb` exports data related to flood depth at nodes.
  - `hw_UI_script_node_lateral_inflow.rb` handles lateral inflow data at nodes.
  - `hw_UI_script_node_level.rb` exports node level data.
- **Runoff and Upstream Data:** 
  - `hw_UI_script_runoff.rb` exports runoff data.
  - `hw_UI_script_upstream_low.rb`, `hw_UI_script_upstream_depth.rb`, and `hw_UI_script_upstream_velocity.rb` export various upstream conditions like flow, depth, and velocity.
- **General Script:** `hw_UI_script.rb` might be a general script or a placeholder for broader functionality related to calibration file exports.

### Usage

To use the scripts within the `0015 - Export SWMM5 Calibration Files` directory:

1. **Open InfoWorks ICM:** Open a relevant network in the UI.
2. **Run Script Dialog:** Navigate to **Network -> Run Ruby Script**.
3. **Select Script:** Choose the required `hw_UI_*.rb` script from this folder.

For example, to export downstream velocity data, choose:
`hw_UI_scrip_downstream_velocity.rb`.

Note
Always check for permissions before running scripts that might access or modify calibration files.
Backup your data before executing scripts that could alter or process datasets extensively.
The README.md file within this directory might contain specific instructions, notes, or prerequisites for running these export scripts.


This README now focuses exclusively on the `0015 - Export SWMM5 Calibration Files` folder, detailing its contents and usage.  