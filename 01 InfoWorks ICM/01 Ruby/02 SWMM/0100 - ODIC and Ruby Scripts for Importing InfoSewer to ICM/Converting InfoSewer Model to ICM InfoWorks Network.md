**Title: Converting an InfoSewer Model to an ICM InfoWorks Network using ODIC and Ruby**

**Step 1: Convert DBF Files using Excel Macro**

Use the Excel macro InfoSewer_VBA_DBF_CSV_Conversion.xlsm to convert all DBF files in InfoSewer.

**Step 2: Import InfoSewer Elements to InfoWorks Network using ICM ODIC**

Use the ICM ODIC to import InfoSewer Elements to an InfoWorks Network. Import the Geodatabase layer using the following files:

Step1_InfoSewer_Manhole_Geodatabase_map_folder.cfg

Step1a_Make_Subcatchments_From_Imported_InfoSewer_Manholes.rb

Step1b_Create_Duumy_Subcatchment_Boundaries_ICMMenu_Model_Subcatchment

Step2_InfoSewer_Outlet_Geodatabase_map_folder.cfg

Step3_InfoSewer_Chamber_Geodatabase_map_folder.cfg

Step4_InfoSewer_WetWell_Geodatabase_map_folder.cfg

Step5_6\_InfoSewer_GM_FM_Geodatabase_map_folder.cfg

Step7_InfoSewer_Pump_Geodatabase_map_folder.cfg

**Step 3: Import Node and Link Data from CSV Files**

Switch to CSV files and import node and link data. Import the CSV files using the following files:

Step8_InfoSewer\_\_manhole_hydraulics_mhhyd_csv.cfg

Step9_InfoSewer_link_hydraulics_pipehyd_csv.cfg

Step10_InfoSewer_pump_control_control_csv.cfg

Step11_InfoSewer_pump_curve_pumphyd.cfg

Step14_Infosewer_wetwell_wwellhyd_csv.cfg

**Step 4: Create Subcatchments for Loading Data from InfoSewer**

Create subcatchments for the loading data from InfoSewer. Use the following files:

Step12_InfoSewer_subcatchment_copy_for_ten_loads.rb

Step13_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg

Step17_InfoSewer_rdii_hydrograph_csv.cfg

**Step 5: Read InfoSewer Information Tables**

Learn how to read the InfoSewer Information tables (similar to user-defined columns in ICM). Use the following files:

Step15_Infosewer_manhole_csv.cfg

Step16_Infosewer_pipe_csv.cfg

Overall, this revised version uses clearer headings and descriptions to help the reader understand the steps more easily.
