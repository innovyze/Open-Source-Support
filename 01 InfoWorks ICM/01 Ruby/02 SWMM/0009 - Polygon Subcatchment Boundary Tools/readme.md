

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
      - `diagram(4).png`
      - `Network Nodes.png`
      - `readme.md`
      - `UI_2DMesh_Result_Points.rb`
      - `UI_Other_2D_Generic_Sides copy.rb`
      - `UI_Polygon_Generic_Sides.rb`
      - `UI_script_Create nodes from polygon subcatchment boundary.rb`
      - `UI_script_Create Subs from polygon.rb`
      - `UI_script.rb`

---

### Description

This section focuses on the **0009 - Polygon Subcatchment Boundary Tools** directory under the `02 SWMM` folder, which contains Ruby scripts and images related to the manipulation and analysis of polygon subcatchment boundaries:

- **Visual Aids:** 
  - `diagram(4).png` and `Network Nodes.png` are likely diagrams or images illustrating the concepts or results related to polygon subcatchment boundaries.
- **Documentation:** `readme.md` provides documentation or instructions for the use of the tools within this directory.
- **Mesh and Result Points:** `UI_2DMesh_Result_Points.rb` might handle operations related to 2D mesh result points, possibly for visualization or analysis.
- **Generic Sides:** `UI_Other_2D_Generic_Sides copy.rb` and `UI_Polygon_Generic_Sides.rb` deal with creating or managing generic sides of 2D polygons.
- **Node and Subcatchment Creation:** 
  - `UI_script_Create nodes from polygon subcatchment boundary.rb` creates nodes from polygon subcatchment boundaries.
  - `UI_script_Create Subs from polygon.rb` generates subcatchments from polygons.
- **General Script:** `UI_script.rb` is a general script which might contain utility functions or be a placeholder for broader functionality.

### Usage

To use the scripts within the `0009 - Polygon Subcatchment Boundary Tools` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0009 - Polygon Subcatchment Boundary Tools` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for managing polygon subcatchment boundaries.

For example, to create nodes from a polygon subcatchment boundary:
```sh
ruby UI_script_Create nodes from polygon subcatchment boundary.rb

Note
Always check for permissions before running scripts that might modify data or create new elements.
Backup your data before executing scripts that could alter or process datasets extensively.
The readme.md file within this directory might contain specific instructions, notes, or prerequisites for running these polygon boundary tools.


This README now focuses exclusively on the `0009 - Polygon Subcatchment Boundary Tools` folder, detailing its contents and usage.  