
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
        - *(Content omitted for brevity)*
      - **0021 - Change the Geometry or Rename IDs**
        - `1_split_link_into_chunks.rb`
        - `2_split_links_around_node.rb`
        - `Get Minimum X,Y for All Nodes.md`
        - `Get Minimum X,Y for All Nodes.rb`
        - `hw_UI_script_Add Nine 1D Results Points.rb`
        - `image-1.png`
        - `readme_Change Subcatchment Boundaries.md`
        - `readme.md`
        - `spatial.rb`
        - `swmm_UI_script_Change Subcatchment Boundaries.rb`
        - `UI_4_Sides_script_Change Subcatchment Boundaries.rb`
        - `UI_5_Sides_script_Change Subcatchment Boundaries.rb`
        - `UI_Generic_Sides_Change Subcatchment Boundaries.md`
        - `UI_Generic_Sides_Change Subcatchment Boundaries.rb`
        - `UI_script_Change Subcatchment Boundaries.rb`
        - `UI-RenameNodeLinks.rb`

---

### Description

This section focuses on the **0021 - Change the Geometry or Rename IDs** directory under the `02 SWMM` folder, which contains Ruby scripts and documentation for modifying network geometries or renaming IDs within SWMM models:

- **Link Splitting:**
  - `1_split_link_into_chunks.rb` splits a link into multiple chunks, useful for detailed analysis or modification.
  - `2_split_links_around_node.rb` handles splitting links around a specified node, aiding in network restructuring.

- **Node Coordinates:**
  - `Get Minimum X,Y for All Nodes.md` and `Get Minimum X,Y for All Nodes.rb` provide documentation and a script to find the minimum X,Y coordinates for all nodes, which could be useful for spatial analysis or data normalization.

- **Results Points Addition:**
  - `hw_UI_script_Add Nine 1D Results Points.rb` adds nine 1D results points to the network, possibly for enhanced data collection or analysis.

- **Visual Aids:**
  - `image-1.png` might be a visual representation or diagram related to one of the scripts or concepts in this directory.

- **Subcatchment Boundary Changes:**
  - `readme_Change Subcatchment Boundaries.md` offers guidance on changing subcatchment boundaries.
  - `swmm_UI_script_Change Subcatchment Boundaries.rb`, `UI_4_Sides_script_Change Subcatchment Boundaries.rb`, `UI_5_Sides_script_Change Subcatchment Boundaries.rb`, `UI_Generic_Sides_Change Subcatchment Boundaries.md`, `UI_Generic_Sides_Change Subcatchment Boundaries.rb`, and `UI_script_Change Subcatchment Boundaries.rb` are scripts with different approaches to modifying subcatchment boundaries, tailored for different scenarios or user interfaces.
  
- **Spatial Analysis:**
  - `spatial.rb` likely deals with spatial operations or analysis within the network.

- **Renaming:**
  - `UI-RenameNodeLinks.rb` provides functionality to rename nodes and links, which can be crucial for standardization or merging models.

### Usage

To use the scripts within the `0021 - Change the Geometry or Rename IDs` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0021 - Change the Geometry or Rename IDs` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for modifying network geometries or renaming IDs.

For example, to split a link into chunks:
```sh
ruby 1_split_link_into_chunks.rb

Note
Always check for permissions before running scripts that might modify your model.
Backup your data before executing scripts that could alter or process datasets extensively.
Review readme.md and readme_Change Subcatchment Boundaries.md for specific instructions or notes related to running these scripts for geometry changes or ID renaming.


This README now focuses exclusively on the `0021 - Change the Geometry or Rename IDs` folder, detailing its contents and usage.  