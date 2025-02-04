

markdown
#  Folder Structure

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
      - `hw_UI_script_infoSewer_Gravity_Main_Report_from_ICM_InfoWorks.rb`
      - `hw_UI_script_infoSewer_Peaking_Factors.rb`
      - `hw_UI_script_MakeSubcatchmentsFrom_Imported_InfoSewer_Manholes.md`
      - `hw_UI_script_MakeSubcatchmentsFrom_Imported_InfoSewer_Manholes.rb`
      - `png001.png`
      - `readme_steady_state.rb`
      - `README.md`
      - `sw_UI_script_MakeSubcatchments_From_Imported_InfoSewer_Manholes.rb`
      - `ui_script_Read_infoSewer_Steady_State_Report_File.rb`

---

### Description

This section focuses on the **0014 - InfoSewer to ICM Comparison Tools** directory under the `01 InfoWorks` folder within `01 Ruby`, which contains scripts and files for comparing or importing data from InfoSewer to InfoWorks ICM:

- **Gravity Main Report:** `hw_UI_script_infoSewer_Gravity_Main_Report_from_ICM_InfoWorks.rb` generates or compares gravity main reports from ICM InfoWorks based on InfoSewer data.
- **Peaking Factors:** `hw_UI_script_infoSewer_Peaking_Factors.rb` deals with peaking factors, possibly for flow analysis or comparison between InfoSewer and ICM.
- **Subcatchments Creation:** 
  - `hw_UI_script_MakeSubcatchmentsFrom_Imported_InfoSewer_Manholes.md` and `hw_UI_script_MakeSubcatchmentsFrom_Imported_InfoSewer_Manholes.rb` are scripts for creating subcatchments from manholes imported from InfoSewer into ICM.
  - `sw_UI_script_MakeSubcatchments_From_Imported_InfoSewer_Manholes.rb` is similar but tailored for SWMM, suggesting a process for integrating InfoSewer data into SWMM via ICM.
- **Visual Aid:** `png001.png` might be an image illustrating the process or results of the comparison or import tools.
- **Steady State Report:** `readme_steady_state.rb` and `ui_script_Read_infoSewer_Steady_State_Report_File.rb` handle reading or processing steady state reports from InfoSewer, useful for static
