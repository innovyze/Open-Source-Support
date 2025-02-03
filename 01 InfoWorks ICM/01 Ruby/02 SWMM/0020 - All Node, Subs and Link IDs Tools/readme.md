
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
        - *(Content omitted for brevity)*
      - **0017 - Subcatchment Grid and Tabs Tools**
        - *(Content omitted for brevity)*
      - **0018 - Create Selection list using a SQL query**
        - *(Content omitted for brevity)*
      - **0019 - Node Connection Tools**
        - *(Content omitted for brevity)*
      - **0020 - All Node, Subs and Link IDs Tools**
        - `DuplicateLinkIDs.rb`
        - `hw_change All Node and Sub ID.rb`
        - `hw_change All Node, Subs and Link ID.rb`
        - `readme.md`
        - `sw_change All Node, Link and Subs ID.rb`
        - `sw_change All Node, Subs and Link ID.rb`

---

### Description

This section focuses on the **0020 - All Node, Subs and Link IDs Tools** directory under the `02 SWMM` folder, which contains Ruby scripts for managing and modifying IDs of nodes, subcatchments, and links within SWMM models:

- **Duplicate Link IDs:** `DuplicateLinkIDs.rb` is likely a script for handling or resolving duplicate link IDs, which can occur during model integration or data cleanup.
- **Change Node and Subcatchment IDs:**
  - `hw_change All Node and Sub ID.rb` changes IDs for nodes and subcatchments, tailored for HW (HydroWorks).
  - `sw_change All Node, Link and Subs ID.rb` modifies IDs for nodes, links, and subcatchments, focused on SW (SWMM).
  - `sw_change All Node, Subs and Link ID.rb` similar to the above but might have a different approach or additional functionality.
  - `hw_change All Node, Subs and Link ID.rb` changes IDs for all nodes, subcatchments, and links in HW models.
- **Documentation:** `readme.md` provides documentation or instructions for the use of the tools within this directory.

### Usage

To use the scripts within the `0020 - All Node, Subs and Link IDs Tools` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0020 - All Node, Subs and Link IDs Tools` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for managing or changing IDs.

For example, to change all node and subcatchment IDs in a HydroWorks model:
```sh
ruby hw_change All Node and Sub ID.rb

Note
Always check for permissions before running scripts that might modify your model data.
Backup your data before executing scripts that could alter or process datasets extensively.
The readme.md file within this directory might contain specific instructions, notes, or prerequisites for running these ID management tools.


This README now focuses exclusively on the `0020 - All Node, Subs and Link IDs Tools` folder, detailing its contents and usage.  