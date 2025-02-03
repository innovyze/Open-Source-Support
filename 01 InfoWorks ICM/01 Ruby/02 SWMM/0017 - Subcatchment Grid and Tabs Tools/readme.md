
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
        - `diagram(2).png`
        - `hw_UIscript Connect subcatchment to nearest node.rb`
        - `hw_UI_Script_Land Use with Runoff Surface Table.rb`
        - `hw_UI_script_Copy selected subcatchments User Defined Times.rb`
        - `hw_UI_script_Copy selected subcatchments with user_suffix.rb`
        - `hw_UI_Script_InfoWorks Land Use Tables.rb`
        - `hw_UI_Script_Runoff Surface Tables.rb`
        - `hw_UI_Script_Sub_Land Use with Runoff Surfaces Table.rb`
        - `hw_UI_Script_Subcatchment Grid Area Table.rb`
        - `Move_Copy_Imported_Pumps.rb`
        - `Nearest Storage Node.rb`
        - `readme.md`
        - `Step1a_Create_Subcatchments.rb`
        - `Step7a_InfoSewer_subcatchment_copy_for_ten_loads.rb`
        - `sw_UI_script Connect subcatchment to nearest node.rb`
        - `sw_UI_script_Copy selected subcatchments User Defined Times.rb`
        - `sw_UI_script_Copy selected subcatchments with user_suffix.rb`
        - `UI_script Runoff surfaces from selected subcatchments.rb`

---

### Description

This section focuses on the **0017 - Subcatchment Grid and Tabs Tools** directory under the `02 SWMM` folder, which contains Ruby scripts and images related to managing subcatchments, their connections, and various data operations:

- **Visual Aid:** `diagram(2).png` is likely an image diagram illustrating some aspect of subcatchment management or the functionality of one of the scripts.
- **Scripts:**
  - `hw_UIscript Connect subcatchment to nearest node.rb` and `sw_UI_script Connect subcatchment to nearest node.rb` connect subcatchments to the nearest node in the network, tailored for HydroWorks (HW)