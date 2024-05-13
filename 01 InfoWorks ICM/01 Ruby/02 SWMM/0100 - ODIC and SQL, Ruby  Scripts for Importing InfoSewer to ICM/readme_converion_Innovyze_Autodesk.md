**Title: Converting an InfoSewer Model to an ICM InfoWorks Network using ODIC, SQL**

## Model Conversion
Converting InfoSewer Model to ICM InfoWorks Network.md: Documentation detailing the steps for converting an InfoSewer model to an ICM InfoWorks Network.

## Macros and Utilities
Excel_Macro_readme.md: Explains how to use Excel macros in the conversion process.
InfoSewer_InfoSWMM_VBA_DBF_CSV_Conversion.xlsm: Excel workbook with VBA macros for converting InfoSewer and InfoSWMM data to DBF and CSV formats.
SQL Scripts for Node and Link Attributes
SET Node Type = Break.sql: Sets node type to 'Break'.
Set node_id = subcatchment_id.sql: Matches node_id with subcatchment_id.
SET node_type = 'Outfall'.sql: Sets node type to 'Outfall'.
SQL number_of_barrels.sql: Calculates and sets the number of barrels for pipes.
SQL Area from InfoSewer.sql: Retrieves area information from InfoSewer.
SQL Inverts.sql: Manages invert levels of nodes.
SQL Set ground_level = chamber_roof.sql: Sets the ground level based on the chamber roof.
SQL_Find_Pumps.sql: Identifies pumps in the model.
SQL_FM_Roughness.sql: Sets the roughness coefficients.
SQL_InfoSewer_Manhole_Area.sql: Sets or calculates the manhole areas.
SQL_Make_Subcatchments.sql: Creates subcatchments in the model.
SQL_Population_Flow.sql: Sets or calculates flow rates based on population data.
SQL_Pump_On_Off.sql: Sets the on and off levels for pumps.
SQL_WW.sql: Related to wet  well attributes.

![Alt text](image-5.png)

## Configuration Files and Step-by-Step Guides

### Step 1: Node and Manhole Configuration
Step1_InfoSewer_Node_csv.cfg: Configuration settings for initializing nodes in the InfoSewer model.
Step1_readme.md: Provides detailed instructions and explanations for setting up nodes in Step 1.
Sub-Step 1a: Manhole-Specific Settings
Step1a_InfoSewer_Manhole_csv.cfg: Configuration for manhole-specific attributes in InfoSewer.
Step1a_readme.md: Documentation for configuring manholes, outlining parameters and how to apply them.
Sub-Step 1b: Subcatchment Boundaries
Step1b_Create_Dummy_Subcatchment_Boundaries: Likely a script or tool to create placeholder boundaries for subcatchments.
Step1b_readme.md: Instructions and guidelines for creating dummy subcatchment boundaries in the model.

### Step 2: Pipe and Link Configuration
Step2a_InfoSewer_Pipe_CSV.cfg: Configuration for pipe-specific attributes in InfoSewer.

Step2a_readme.md: Documentation explaining the parameters and settings for configuring pipes.

Step2_InfoSewer_Link_csv.cfg: Configuration for link attributes in the InfoSewer network.

Step2_readme.md: Provides instructions for configuring the links between nodes.

### Step 3: Manhole Hydraulics
Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg: Configuration for hydraulic calculations related to manholes.
Step3_readme.md: Documentation for setting up manhole hydraulic calculations.

### Step 4: Link Hydraulics
Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg: Configuration settings for hydraulic calculations related to pipes and links.
Step4_readme.md: Instructions for setting up hydraulic calculations for links.

### Step 5: Pump Curve Configuration
Step5_InfoSewer_pump_curve_pumphyd_csv.cfg: Configuration for defining pump curves.
Step5_readme.md: Documentation explaining how to set up pump curves in the model.

### Step 6: Pump Control
Step6_InfoSewer_pump_control_control_csv.cfg: Configuration for pump control logic.
Step6_readme.md: Instructions for implementing pump control settings.

### Step 7: Subcatchment Dry Weather Flow
Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg: Configuration for dry weather flow in subcatchments.
Step7_readme.md: Instructions for configuring dry weather flows.

### Step 8: Wet Well Hydraulics
Step8_Infosewer_wetwell_wwellhyd_csv.cfg: Configuration settings for the hydraulics of wet wells.
Step8_readme.md: Documentation for setting up wet well hydraulics.

### Step 9: RDII Hydrograph
Step9_rdii_hydrograph_csv.cfg: Configuration for Rainfall-Dependent Infiltration and Inflow (RDII) hydrographs.
Step9_readme.md: Provides guidelines and instructions for setting up RDII hydrographs.

## Miscellaneous
Step1b_Create_Duumy_Subcatchment_Boundaries: A guide to create dummy subcatchment boundaries.

This collection of files provides a comprehensive toolkit for working with wastewater network models, particularly for converting, modifying, and understanding InfoSewer and ICM InfoWorks models. It contains SQL scripts for data manipulation, CFG configuration files for modeling steps, and documentation to guide users through the process.


## Background Refinement

When transitioning from InfoSWMM to an ICM SWMM network, and eventually converting it to an ICM InfoWorks network, users may encounter discrepancies in flow data. This raises the question: **What could be causing these differences in flow readings?**

## Key Factors

- **DWF Allocator Tool in InfoSWMM**: InfoSWMM's DWF (Dry Weather Flow) Allocator tool leverages GIS data to estimate DWF from parcel information. This can lead to multiple DWF values per node in InfoSWMM, which is permissible and also supported in ICM SWMM.

- **Limitation in SWMM5**: Unlike InfoSWMM or ICM SWMM, SWMM5 allows only one DWF value per node. To address this in ICM SWMM, while maintaining fidelity to the original InfoSWMM data, we introduced an 'additional DWF' table. This table accommodates the extra DWF values from InfoSWMM that exceed the single-value limit of SWMM5.

- **Unit Conversion Challenges**: A notable aspect is the unit compatibility. ICM primarily operates in CMS, MGD, or CFS units. When InfoSWMM data is in these units, the conversion to ICM is straightforward. However, if InfoSWMM uses LPS (liters per second) or GPM (gallons per minute), manual conversion becomes necessary. For instance:
    - LPS data needs division by 1000.
    - GPM data requires multiplication by the factor 1440 / 1,000,000.

### Illustration

The accompanying image demonstrates how to adjust the baseline flow in SQL, considering these unit conversions. This step is crucial for ensuring accuracy when transferring DWF data from InfoSWMM to ICM.

## Conclusion

This process underscores the importance of careful data management and conversion when transitioning between different network models. Understanding the nuances of each system’s data handling capabilities is key to ensuring consistency and accuracy in flow data across various platforms.


## How about Steady State InfoSewer in ICM?

To effectively manage your ICM model simulations, you have a couple of options to consider:

- **Utilizing the Ending State of a Previous Simulation**:
    - **Run the ICM Model**: Start by running your ICM model as usual.
    - **Save the Ending State**: Once the simulation is complete, save the final state of the model. This captures all the relevant data and conditions at the end of the simulation.
    - **Use the Saved State for the Next Simulation**: When you're ready to run a new simulation, use this saved state as your starting point. This approach allows you to continue from where the last simulation left off, providing continuity in your model's progression.
    - **Turn Off Initialization**: Before running the new simulation, ensure that the initialization step is turned off. This prevents the model from resetting to its default starting conditions.
    - **Run for a Short Duration**: Execute the new simulation for a brief period, such as one minute. This can be particularly useful for observing short-term dynamics or changes that occur immediately after the previous simulation’s end.

- **Starting Fresh with Initialization**:
    - **Initial Setup**: Alternatively, you can choose to start a new simulation without using a saved state. This means the model will begin with its default or specified initial conditions.
    - **Run for a Brief Period**: Like the first option, run this simulation for a short duration, such as one minute. This approach is beneficial for analyzing the initial behavior of the network under specific conditions, without the influence of prior states.

Both methods offer unique insights and can be chosen based on the specific requirements of your study. The first option provides a seamless continuation from a previous state, ideal for studying ongoing processes or cumulative effects. The second option allows for a fresh start, useful for comparative studies or examining initial system responses.

# Introduction

We're on the move 🔄 from our legacy software like XPSWMM, InfoSewer, and InfoSWMM, to the advanced Autodesk ICM Standard and ICM Ultimate 🌐. To make this switch smooth for our users, we've enabled direct imports 🔄 from InfoSWMM to ICM SWMM networks and XPSWMM XPX files to both ICM InfoWorks and ICM SWMM 📁. For those transitioning from InfoSewer, we've got Ruby and ODIC CFG files on our Github, accessible via the ICM Technical Information Hub 🔗. Plus, there's a treasure trove of about 100 Knowledge Center Service (KCS) articles in the ICM Online help file 📚 - just search for 'InfoSewer', 'InfoSWMM', or 'XPSWMM' to find detailed guidance 💡. Our aim? A seamless, informed transition for all our users into the new era of Autodesk products 🚀🌟.

# Files Used for InfoSewer or InfoSWMM to ICM InfoWorks or ICM SWMM

## Markdown Files
- Excel\_Macro\_readme.md
- InfoSewer\_ODIC\_Ruby.md
- InfoSWMM\_Merge\_Models.md
- readme.md
- SET Node Type = Break.md
- SQL\_Make\_Subcatchments.md
- Step1a\_readme.md
- Step1b\_readme.md
- Step1\_readme.md
- Step20.md
- Step21.md
- Step22.md
- Step22a\_User\_123\_ICM\_mhhyd\_csv\_One\_Read.md
- Step22\_User\_123\_ICM\_mhhyd\_csv\_Folder\_Reader.md
- Step23.md
- Step24.md
- Step25.md
- Step2\_readme.md
- Step3\_readme.md
- Step4\_readme.md
- Step5\_readme.md
- Step6\_readme.md
- Step7\_readme.md
- Step8\_readme copy 2.md
- Step8\_readme copy.md
- Step8\_readme.md
- Step9\_readme.md

## Excel Files
- InfoSewer\_InfoSWMM\_VBA\_DBF\_CSV\_Conversion.xlsm

## Ruby Files
- InfoSewer\_ODIC\_Ruby.rb
- Move\_Copy\_Imported\_Pumps.rb
- Step10\_InfoSewer\_sub\_dwf\_mhhyd\_scenario\_ODIC.rb
- Step11\_InfoSewer\_pipehyd\_scenario\_ODIC.rb
- Step12\_Point\_Scenario\_csv.rb
- Step13\_Point\_Runopt\_csv.rb
- Step14\_Point\_Patterns\_csv.rb
- Step15\_Point\_Patndata\_csv.rb
- Step16\_Additional\_DWF\_ICM\_SWMM\_XLOAD\_csv.rb
- Step17\_User\_10\_ICM\_SWMM\_XLOAD\_csv.rb
- Step18\_User\_123\_ICM\_SWMM\_mhhyd\_csv.rb
- Step1a\_InfoSewer\_Manhole\_ODIC.rb
- Step1b\_InfoSewer\_Subcatchment\_Manhole\_ODIC.rb
- Step1\_InfoSewer\_Node\_ODIC.rb
- Step21\_User\_123\_ICM\_SWMM\_pipehyd\_csv .rb
- Step22a\_User\_123\_ICM\_mhhyd\_csv\_One\_Read.rb
- Step22\_User\_123\_ICM\_mhhyd\_csv\_\_Folder\_Reader.rb
- Step23a\_User\_123\_ICM\_pipehyd\_csv\_One\_Read.rb
- Step23\_User\_123\_ICM\_pipehyd\_csv\_Folder\_Reader.rb
- Step24\_User\_123\_ICM\_anode\_alink\_csv.rb
- Step25\_User\_123\_ICM\_Scenario\_csv.rb
- Step2\_InfoSewer\_Link\_ODIC.rb
- Step3a\_InfoSewer\_General\_Lines\_mhhyd\_csv.rb
- Step3\_InfoSewer\_manhole\_hydraulics\_ODIC..rb
- Step4\_InfoSewer\_link\_hydraulics\_ODIC.rb
- Step5\_InfoSewer\_pump\_curve\_ODIC.rb
- Step6\_InfoSewer\_pump\_control\_ODIC.rb
- Step7\_InfoSewer\_Subcatchment\_dwf\_ODIC.rb
- Step8\_InfoSewer\_wwellhyd\_ODIC.rb
- Step9\_InfoSewer\_rdii\_hydrograph\_ODIC.rb

## SQL Files
- SET Node Type = Break.sql
- Set node\_id = subcatchment\_id.sql
- SET node\_type = 'Outfall'.sql
- SQL number\_of\_barrels.sql
- SQL Area from InfoSewer.sql
- SQL Inverts.sql
- SQL Set ground\_level = chamber\_roof.sql
- SQL\_Find\_Pumps.sql
- SQL\_FM\_Roughness.sql
- SQL\_InfoSewer\_Manhole\_Area.sql
- SQL\_Make\_Subcatchments.sql
- SQL\_Population\_Flow.sql
- SQL\_Pump\_On\_Off.sql
- SQL\_WW.sql

## Configuration Files
- Step10\_InfoSewer\_sub\_dwf\_mhhyd\_scenario.cfg
- Step11\_InfoSewer\_pipehyd\_scenario.cfg
- Step12\_Point\_Scenario\_csv.cfg
- Step13\_Point\_Runopt\_csv.cfg
- Step14\_Point\_Patterns\_csv.cfg
- Step15\_Point\_Patndata\_csv.cfg
- Step16\_Additional\_DWF\_ICM\_SWMM\_XLOAD\_csv.cfg
- Step17\_User\_10\_ICM\_SWMM\_XLOAD\_csv.cfg
- Step18\_User\_123\_ICM\_SWMM\_mhhyd\_csv.cfg
- Step19\_Anode\_csv.cfg
- Step1a\_InfoSewer\_Manhole\_csv.cfg
- Step1b\_InfoSewer\_Subcatchment\_Manhole\_csv.cfg
- Step1\_InfoSewer\_Node\_csv.cfg
- Step20\_ALink\_csv.cfg
- Step21\_User\_123\_ICM\_SWMM\_pipehyd\_csv.cfg
- Step22\_User\_123\_ICM\_pipehyd\_csv.cfg
- Step2\_InfoSewer\_Link\_csv.cfg
- Step3a\_InfoSewer\_General\_Lines\_mhhyd\_csv.cfg
- Step3\_InfoSewer\_manhole\_hydraulics\_mhhyd\_csv.cfg
- Step4\_InfoSewer\_link\_hydraulics\_pipehyd\_csv.cfg
- Step5\_InfoSewer\_pump\_curve\_pumphyd\_csv.cfg
- Step6\_InfoSewer\_pump\_control\_control\_csv.cfg
- Step7\_InfoSewer\_subcatchment\_dwf\_mhhyd\_csv.cfg
- Step8\_Infosewer\_wetwell\_wwellhyd\_csv.cfg
- Step9\_rdii\_hydrograph\_csv.cfg

## Other Files
- make\_sub\_folders\_list.bat
- media

