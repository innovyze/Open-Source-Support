# InfoSewer to InfoWorks ICM Conversion Tools

This repository contains scripts and supporting files to assist in the model conversion from InfoSewer to InfoWorks ICM (InfoWorks network). The contents of this repository can be downloaded directly using this [link](https://download-directory.github.io/?url=https%3A%2F%2Fgithub.com%2Finnovyze%2FOpen-Source-Support%2Ftree%2Fmain%2F01%2520InfoWorks%2520ICM%2F01%2520Ruby%2F01%2520InfoWorks%2F0060%2520-%2520InfoSewer%2520to%2520InfoWorks%2520ICM%2520Conversion%2520Tools).

Instructions for use of these files are provided here: https://www.autodesk.com/support/technical/article/caas/sfdcarticles/sfdcarticles/Knowledge-Importing-InfoSewer-to-InfoWorks-ICM-Overview-of-all-Import-Steps.html

## DBF to CSV File Conversion: Excel Macro
DBF_to_CSV.xlsm: This macro automates the conversion of InfoSewer tabular data from DBF to CSV format. Used prior to beginning the model conversion process.

## Configuration (CFG) Files

Step 1: Manhole/Node Configuration

Step 2: Pipe/Link Configuration

Step 3: Manhole Hydraulics

Step 4: Link Hydraulics

Step 5: Pump Hydraulics

Step 6: Pump Controls

Step 7: Subcatchment Loadings

Step 8: Wet Well Hydraulics

Step 9: RDII Hydrographs

## SQL Scripts
Scripts to modify Node, Link, and Subcatchment attributes:

**Nodes**
- SET node_type = 'Outfall'.sql: Sets node type to 'Outfall'
- SET calculate wet well area.sql: Calculates area information from diameters imported from InfoSewer

**Links**
- Find_Pumps.sql: Converts conduits to pumps in the model
- SET pump on and off.sql: Calculates and sets the on and off levels for pumps
- SET number_of_barrels.sql: Calculates and sets the number of barrels for pipes
- Use full solution for forcemains.sql: Sets parameters to use full solution
- Use forcemain solution for forcemains.sql: Sets parameters to use forcemain solution
- Insert pump curves.sql: Inserts pump curve data for 1-point (design point) and 3-point (exponential) pump curves

**Subcatchments**
- Create_Subcatchments.sql: Creates subcatchments in the model

## Ruby Import BASE
- InfoSewer_to_InfoWorks_Base.rb: This companion ruby script automates the documented 9-step process in a single script. 

## Scenario Tools
- Create Scenarios from InfoSewer.rb: This ruby script utilizes the SCENARIO.CSV to create scenarios from InfoSewer model. Created scenarios are a copy of the Base network in InfoWorks ICM. Scenario data will not be populated.
- InfoWorks Selection Lists from Scenarios or Selection Set.rb: This ruby script utilizes the ANODE.CSV and ALINK.CSV located within either the Scenario folder or the SS (Selection Set) folder to create selection lists. The ANODE and ALINK files within the Scenario folder indicate which nodes and links are active in that scenario, while the ANODE and ALINK files within the SS folder indicate nodes and links which should be selected. 

## Pattern Tools
- Patterns_to_ICM_CSV.xlsm: This macro automates the conversion of diurnal pattern data into a format that InfoWorks ICM can recognize and use.

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