

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
      - `All Input Variables.rb`
      - `All_Results.rb`
      - `All_Variables.rb`
      - `Area-Methods-UIOnly-Working.rb`
      - `Change All Node and Link IDs.rb`
      - `count_objects_in_db.rb`
      - `Find All Network Elements.rb`
      - `Flow_Survey.rb`
      - `hash_sw_hw_tables.rb`
      - `hw_UI_Script Find All Network Elements.rb`
      - `hw_UI_Script Stats for ICM Network Tables.rb`
      - `image.png`
      - `Make an Overview of All Network Elements.rb`
      - `png001.png`
      - `README.md`
      - `sw_UI_Script Find All Network Elements.rb`
      - `sw_UI_Script Make a Table of the Run Parameters in ICM.rb`
      - `UI_script Find Root Model Group.rb`
      - `UI_script List all results fields in a simulation (SWMM or ICM).rb`
      - `UI_script List all results fields in a Simulation.rb`
      - `UI-script.rb`
      - `UI-CountConnections.rb`
      - `UI-CountRepairs.rb`
      - `UI-DeleteRowsFromAttachmentsBlob.rb`
      - `UI-ListCurrentNetworkFields_No_User_OR_Flags.rb`
      - `UI-ListCurrentNetworkFields.rb`
      - `UI-ListCurrentNetworkFieldStructure.rb`
      - `UI-UpdateBlockagePropertyID.rb`
      - `UI-UpdateObjectFromObject_ByPrompt_3.rb`
      - `UIE-DatabaseContents.rb`
      - `UIE-DatabaseSummary.rb`

---

### Description

This section focuses on the **0008 - Database Field Tools for Elements and Results** directory under the `02 SWMM` folder, which contains Ruby scripts for managing and analyzing database fields related to elements and results in SWMM and ICM:

- **Variable Management:** 
  - `All Input Variables.rb`, `All_Results.rb`, and `All_Variables.rb` handle listing or managing all input variables, results, and general variables within the models.
- **Area Methods:** `Area-Methods-UIOnly-Working.rb` might deal with area-related methods or calculations, possibly for user interface purposes.
- **ID Management:** `Change All Node and Link IDs.rb` allows for changing the IDs of nodes and links in the network.
- **Object Counting:** `count_objects_in_db.rb` counts objects within the database.
- **Network Element Finding:** `Find All Network Elements.rb`, `hw_UI_Script Find All Network Elements.rb`, and `sw_UI_Script Find All Network Elements.rb` are scripts to find all network elements, tailored for different contexts or models.
- **Flow Survey:** `Flow_Survey.rb` likely deals with surveying or analyzing flow data.
- **Table Hashing:** `hash_sw_hw_tables.rb` might be used for creating or managing hash tables for SWMM and HW (HydroWorks).
- **Network Stats:** `hw_UI_Script Stats for ICM Network Tables.rb` provides statistics on ICM network tables.
- **Network Overview:** `Make an Overview of All Network Elements.rb` creates an overview of all network elements.
- **Run Parameters:** `sw_UI_Script Make a Table of the Run Parameters in ICM.rb` makes a table of run parameters specifically for ICM.
- **Model Group Finding:** `UI_script Find Root Model Group.rb` finds the root model group.
- **Result Fields Listing:** `UI_script List all results fields in a simulation (SWMM or ICM).rb` and `UI_script List all results fields in a Simulation.rb` list all result fields in simulations.
- **Connection and Repair Counting:** `UI-CountConnections.rb` and `UI-CountRepairs.rb` count connections and repairs respectively.
- **Attachment Management:** `UI-DeleteRowsFromAttachmentsBlob.rb` manages deletion of rows from attachment blobs.
- **Field Listing:** Scripts like `UI-ListCurrentNetworkFields_No_User_OR_Flags.rb`, `UI-ListCurrentNetworkFields.rb`, and `UI-ListCurrentNetworkFieldStructure.rb` list current network fields with various criteria.
- **Property Update:** `UI-UpdateBlockagePropertyID.rb` updates blockage property IDs.
- **Object Update:** `UI-UpdateObjectFromObject_ByPrompt_3.rb` updates objects from other objects by prompt.
- **Database Overview:** `UIE-DatabaseContents.rb` and `UIE-DatabaseSummary.rb` provide contents and summary of the database.

### Usage

To use the scripts within the `0008 - Database Field Tools for Elements and Results` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0008 - Database Field Tools for Elements and Results` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow for managing and analyzing database fields.

For example, to count objects in the database:
```sh
ruby count_objects_in_db.rb

Note
Always check for permissions before running scripts that might access or modify database fields.
Backup your data before executing scripts that could alter or process datasets extensively.
The README.md file within this directory might contain specific instructions, notes, or prerequisites for running these database management scripts.


This README now focuses exclusively on the `0008 - Database Field Tools for Elements and Results` folder, detailing its contents and usage.  