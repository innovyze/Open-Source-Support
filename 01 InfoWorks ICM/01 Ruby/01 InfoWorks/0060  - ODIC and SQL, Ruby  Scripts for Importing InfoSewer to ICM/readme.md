# Model Conversion from InfoSewer to InfoWorks ICM

This repository contains scripts and supporting files to assist in the model conversion from InfoSewer to InfoWorks ICM (InfoWorks network)

## DBF to CSV File Conversion: Excel Macro
DBF_to_CSV.xlsm: Excel macro-enabled workbook to convert InfoSewer and InfoSWMM tabular data from DBF to CSV format. Used prior to beginning the model conversion process.

## InfoWorks Configuration Files and Step-by-Step Guides

### Step 1: Node and Manhole Configuration
Step01_InfoSewer_Node_csv.cfg: Configuration settings for initializing nodes in the InfoSewer model.\
Step01a_InfoSewer_Manhole_csv.cfg: Configuration for manhole-specific attributes in InfoSewer.\

### Step 2: Pipe and Link Configuration
Step02_InfoSewer_Link_csv.cfg: Configuration for link attributes in the InfoSewer network.\

### Step 3: Manhole Hydraulics
Step03_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg: Configuration for hydraulic calculations related to manholes.\

### Step 4: Link Hydraulics
Step04_InfoSewer_link_hydraulics_pipehyd_csv.cfg: Configuration settings for hydraulic calculations related to pipes and links.\

### Step 5: Pump Curve Configuration
Step05_InfoSewer_pump_curve_pumphyd_csv.cfg: Configuration for defining pump curves.\

### Step 6: Pump Control
Step06_InfoSewer_pump_control_control_csv.cfg: Configuration for pump control logic.\

### Step 7: Subcatchment Dry Weather Flow
Step07_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg: Configuration for dry weather flow in subcatchments.\

### Step 8: Wet Well Hydraulics
Step08_Infosewer_wetwell_wwellhyd_csv.cfg: Configuration settings for the hydraulics of wet wells.\

### Step 9: RDII Hydrograph
Step09_rdii_hydrograph_csv.cfg: Configuration for Rainfall-Dependent Infiltration and Inflow (RDII) hydrographs.\

## SQL
Scripts to modify Node, Link, and Subcatchment attributes:

**Nodes**
- SET node_type = 'Outfall'.sql: Sets node type to 'Outfall'
- SET calculate manhole area.sql: Calculates area information from diameters imported from InfoSewer
- SET calculate wet well area.sql: Calculates area information from diameters imported from InfoSewer

**Links**
- Find_Pumps.sql: Identifies pumps in the model
- SET pump on and off.sql: Calculates and sets the on and off levels for pumps
- SET number_of_barrels.sql: Calculates and sets the number of barrels for pipes
- SET FM roughness.sql: Sets the roughness coefficients for forcemains

**Subcatchments**
- Create_Subcatchments.sql: Creates subcatchments in the model

## How about Steady State InfoSewer in ICM?

There are a couple of options to consider:

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