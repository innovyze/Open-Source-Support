

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
        - `2021.4.1 Transportable.icmt`
        - `gif001.gif`
        - `Readme.md`
        - `UI_Script_Select links sharing the same us and ds node ids.rb`
        - `UI_Script.rb`
        - `UI_CreateSelectionList.rb`
        - `UI_Reports-CreateIndividualForSelection_folder.rb`
        - `UI_Reports-CreateIndividualForSelection.rb`
        - `UI_SelectIsolatedNodes.rb`

---

### Description

This section focuses on the **0018 - Create Selection list using a SQL query** directory under the `02 SWMM` folder, which contains scripts and files for creating selection lists using SQL queries within SWMM:

- **Transportable File:** `2021.4.1 Transportable.icmt` is likely a transportable file for InfoWorks ICM, possibly used for testing or demonstration purposes in the context of SQL query operations.
- **Visual Aid:** `gif001.gif` might be a GIF animation showing how to use one of the scripts or the result of a SQL query selection.
- **Documentation:** `Readme.md` provides documentation or instructions for the tools within this directory.
- **Scripts:**
  - `UI_Script_Select links sharing the same us and ds node ids.rb` is a script designed to select links that share the same upstream (us) and downstream (ds) node IDs, which can be useful for network analysis or data cleanup.
  - `UI_Script.rb` could be a general UI script or a base script for user interface interactions related to SQL query operations.
  - `UI_CreateSelectionList.rb` is specifically for creating selection lists using SQL queries, facilitating the extraction or management of data based on specific criteria.
  - `UI_Reports-CreateIndividualForSelection_folder.rb` and `UI_Reports-CreateIndividualForSelection.rb` are scripts for generating individual reports for selections, with one possibly handling folder operations.
  - `UI_SelectIsolatedNodes.rb` is used to select nodes that are isolated in the network, which might be useful for identifying errors or for specific analysis in network topology.

### Usage

To use the scripts within the `0018 - Create Selection list using a SQL query` directory:

1. **Open InfoWorks ICM:** Open a relevant network in the UI.
2. **Run Script Dialog:** Navigate to **Network -> Run Ruby Script**.
3. **Select Script:** Choose the required `UI_*.rb` script from this folder.

For example, to select links sharing the same upstream and downstream node IDs, choose:
`UI_Script_Select links sharing the same us and ds node ids.rb`.

Note
Always check for permissions before running scripts that might access or modify your model data.
Backup your data before executing scripts that could alter or process datasets extensively.
The Readme.md file within this directory might contain specific instructions, notes, or prerequisites for running these SQL query tools.


This README now focuses exclusively on the `0018 - Create Selection list using a SQL query` folder, detailing its contents and usage.  