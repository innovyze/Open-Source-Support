
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
      - `hw_UI_script_swmm5_conduit_surcharge_summary_table.rb`
      - `hw_UI_script_swmm5_node_depths_summary_table.rb`
      - `hw_UI_script_swmm5_node_inflows_summary_table.rb`
      - `hw_UI_script_swmm5_node_surcharge_summary_table.rb`
      - `hw_UI_script_swmm5_runoff_summary_table.rb`
      - `hw_UI_script_swmm5_link_flows_summary_table.rb`
      - `README.md`

---

### Description

This section focuses on the **0012 - ICM InfoWorks Results to SWMM5 Summary Tables** directory under the `02 SWMM` folder, which contains Ruby scripts for converting or summarizing results from ICM InfoWorks into SWMM5 compatible summary tables:

- **Conduit Surcharge:** `hw_UI_script_swmm5_conduit_surcharge_summary_table.rb` generates a summary table for conduit surcharge data.
- **Node Depths:** `hw_UI_script_swmm5_node_depths_summary_table.rb` creates a summary table for node depth results.
- **Node Inflows:** `hw_UI_script_swmm5_node_inflows_summary_table.rb` provides a summary table for node inflows.
- **Node Surcharge:** `hw_UI_script_swmm5_node_surcharge_summary_table.rb` summarizes node surcharge information.
- **Runoff:** `hw_UI_script_swmm5_runoff_summary_table.rb` deals with creating a summary table for runoff data.
- **Link Flows:** `hw_UI_script_swmm5_link_flows_summary_table.rb` generates a summary table for link flows.

### Usage

To use the scripts within the `0012 - ICM InfoWorks Results to SWMM5 Summary Tables` directory:

1. **Open InfoWorks ICM:** Open a relevant network in the UI.
2. **Run Script Dialog:** Navigate to **Network -> Run Ruby Script**.
3. **Select Script:** Choose the required `hw_UI_*.rb` script from this folder.

For example, to generate a summary table for conduit surcharge, choose:
`hw_UI_script_swmm5_conduit_surcharge_summary_table.rb`.

Note
Always ensure you have the necessary permissions to run these scripts, especially since they might involve reading or writing result data.
Backup your data before executing scripts that could alter or process datasets extensively.
The README.md file within this directory might contain specific instructions, notes, or prerequisites for running these conversion scripts.


This README now focuses exclusively on the `0012 - ICM InfoWorks Results to SWMM5 Summary Tables` folder, detailing its contents and usage.  