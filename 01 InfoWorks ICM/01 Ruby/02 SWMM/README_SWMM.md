# ICM SWMM Networks
In InfoWorks SWMM, the data representing the stormwater network (such as pipes, nodes, and subcatchments) is organized into tables. These tables often have names beginning with sw_, for example sw_pipe, sw_node, etc. The different attributes of these elements (such as their dimensions, materials, and locations) are represented as fields within these tables.

The comment suggests that while these Ruby scripts are intended for use with InfoWorks SWMM, they may also work with Autodesk Innovyze's InfoWorks ICM (Integrated Catchment Modeling) to some extent, because the code structure is often very similar. However, there are important differences to be aware of.

In particular, the naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.

This means that if you're trying to use these Ruby scripts with Autodesk Innovyze's InfoWorks ICM, you may need to modify the code to account for these differences in table and field names. Without such modifications, the scripts might not work as intended or might produce errors.

In conclusion, while these Ruby scripts are designed to work specifically with Autodesk In | Network Data  |novyze's InfoWorks SWMM, they might be adaptable for use with InfoWorks ICM or other similar software packages, but such adaptation would likely require some adjustments to the code.

## ICM SWMM Ruby Folders

- 0001 - Pipe Length Statistics
- 0002 - Quick Trace
- 0003 - Scenario Maker
- 0004 - New ICM Scenarios
- 0005 - Change All Subcatchment, Node and Link IDs
- 0006 - Add Total Area for Subs
- 0007 - Count Objects In the Database
- 0008 - Select Upstream Subcatchments from a Node with Multilinks
- 0009 - ICM Binary Results Export
- 0010 - List all results fields in a simulation (SWMM or ICM)
- 0011 - Pipe Length Histogram
- 0012 - ODEC Export Node and Conduit tables to CSV and MIF
- 0013 - Depression Storage Statistics
- 0014 - Find all flags in all objects of a network model
- 0015 - Pipe Diameter Statistics
- 0016 - All Link Parameter Statistics
- 0017 - All Node Parameter Statistics
- 0018 - All Subcatchment Parameter Statistics
- 0019 - Distribute attachment details by a shared value
- 0020 - Generate Individual Reports for a Selection of Objects
- 0021 - Create nodes from polygon, subcatchment boundary
- 0022 - Output CSV of calcs based on Subcatchment Data
- 0023 - Rename Nodes & Links using Name Generation pattern
- 0024 - Change Subcatchment Boundaries
- 0025 - Get Minimum X, Y for All Nodes
- 0026 - Make Subcatchments From Imported InfoSewer Manholes
- 0027 - Copy selected subcatchments five times
- 0028 - Percentage change in runoff surfaces upstream node into new scenario
- 0029 - Runoff surfaces from selected subcatchments
- 0030 - Connect subcatchment to nearest node
- 0031 - List all results fields in a Simulation
- 0032 - List Network Fields-Structure
- 0033 - Make an Inflows File from User Fields
- 0034 - Display Export geometries
- 0035 - List Complete Database Objects Contents
- 0036 - Create Selection List
- 0037 - Select Isolated Nodes
- 0038 - Remove rows from a blob field
- 0039 - Calculate subcatchment areas in all nodes upstream a node
- 0040 - Create a new selection list using a SQL query
- 0041 - Get results from all timesteps for Links, US Flow, DS Flow
- 0042 - Get results from all timesteps for Subcatchments, All Params
- 0043 - Get results from all timesteps for Manholes, Qnode
- 0044 - Get results from all timesteps for Manholes, All Params
- 0045 - Get results from all timesteps for Links, All Params
- 0046 - Output SUDS control as CSV
- 0047 - Select links sharing the same us and ds node ids
- 0048 - Delete all scenarios except Base
- 0049 - Clear SUDS from subcatchments
- 0050 - Assign Subcatchment to nearest 'Storage' type Node
- 0051 - Additional DWF Node IDs
- 0052 - Stats for ICM Network Tables
- 0053 - Scenario Counter
- 0054 - Flow Survey
- 0055 - Scenario Maker - Specific
- 0056 - Listview of the currently selected network objects
- 0057 - Bifurcation Nodes
- 0058 - Header Nodes
- 0059 - Dry Pipes
- 0060 - Compare ICM Headloss in Ruby Script
- 0060 - Find All Network Elements
- 0061 - Compare ICM Inlets to HEC22 Inlets
- 0063 - ICM SWMM All Tables
- 0064 - ICM SWMM Network Overview
- 0065 - Get and Put Run Dialog Parameters
- 0066 - ICM results against measured data within the UI
- 0067 - ICM Ruby Tutorials
- 0068 - ICM InfoWorks All Table Names
- 0069 - Make an Overview of All Network Elements
- 0070 - Upstream Subcatchments from an Outfall
- 0071 - Raingages, All Output Parameters
- 0072 - Find Root Model Group
- 0073 - Rename Exported Image & Attachment Files
- 0074 - Capacity Assurance White Paper
- 0075 - Sandbox Instance Evaluation and Class Scope
- 0076 - InfoWorks vs SWMM CSV Comparison
- 0077 - ICM InfoWorks UX Tables
- 0078 - ICM SWMM UX Tables
- 0079 - ICM SWMM IWR Tables
- 0080 - ICM InfoWorks IWR Tables
- 0081 - Export Compare Network Versions to CSV
- 0082 - Create SuDS for All Subcatchments
- 0083 - Find Time of Max DS Depth
- 0084 - Change All Node, Subs and Link IDs
- 0085 - Export SWMM5 Calibration Files - Node Flooding
- 0086 - Export SWMM5 Calibration Files - Groundwater Elev
- 0087 - Export SWMM5 Calibration Files - Groundwater Flow
- 0088 - Export SWMM5 Calibration Files - Runoff
- 0089 - Export SWMM5 Calibration Files - Node Flood Depth
- 0090 - Export SWMM5 Calibration Files - Node Level
- 0091 - Export SWMM5 Calibration Files - Node Lateral Inflow
- 0092 - Export SWMM5 Calibration Files - Downstream Velocity
- 0093 - Export SWMM5 Calibration Files - Upstream Velocity
- 0094 - Export SWMM5 Calibration Files - Upstream Depth
- 0095 - Export SWMM5 Calibration Files - Downstream Depth
- 0096 - Export SWMM5 Calibration Files - Downstream Flow
- 0097 - Export SWMM5 Calibration Files - Upstream Flow
- 0099 - Common Operations
- 0100 - ODIC and SQL, Ruby Scripts for Importing InfoSewer to ICM
- 0101 - ODIC. SQL and Ruby for InfoSWMM Scenario Import
- 0102 - ICM InfoWorks Results to SWMM5 Node Inflows Summary Table
- 0103 - ICM InfoWorks Results to SWMM5 Node Depths Summary Table
- 0104 - ICM InfoWorks Results to SWMM5 Node Surcharging Table
- 0105 - ICM InfoWorks Results to SWMM5 Conduit Surcharging Summary Table
- 0106 - ICM InfoWorks Results to SWMM5 Link Flows Summary Table
- 0107 - ICM InfoWorks Results to SWMM5 Subcatchment Runoff Summary
- 0108 - Spatial Scripts
- 0109 - Statistics for Node User Numbers
- 0110 - Statistics for Link User Numbers
- 0111 - All Node and Link URL Stats
- 0112 - Add Nine 1D Results Points
- 0114 - GIS Export of Data Tables
- 0116 - Export Choice List values
- 0117 - Import-Export Snapshot file
- 0118 - Bulk Data Import
- 0119 - Export to CSV
- 0120 - Import-Export XML
- 0121 - Find Duplicate Link IDs
- 0122 - Update from external CSV
- 0123 - Update an object with values of another object through comparison
- 0124 - Network Trace
- 0125 - Tracing
- 0126 - Copy selected subcatchments with user suffix
- 0127 - Kutter Sql for ICM SWMM
- 0128 - InfoSewer Gravity Main Report, from ICM InfoWorks
- 0129 - ICM Information Hub Finder
- 0130 - InfoSewer Peaking Factors
- 0131 - Complete RB Files
- 0134 - Input Message Box
- 0135 - Create Subs from polygon
- 0136 - InfoWorks Sub, Land Use with Runoff Surfaces Table
- 0137 - Creates Subs from Polygons
- 0138 - Input Message Box
- 0139 - InfoWorks 2D Parameter Statistics
- 0140 - List all results fields in a simulation ICM and Show Node Results Stats
- 0141 - List all results fields in a simulation ICM and Show Subcatchment Results Stats
- 0142 - Create nodes from polygon subcatchment boundary
- 0143 - List all results fields in a simulation ICM and Show Flap Valve Results Stats
- 0144 - Create nodes from polygon subcatchment boundary
- 0145 - Change 2D Polygon Boundaries
- 0146 - Add 2D Results Points in a Polygon
- 0147 - 
- 0148 - 
- 0149 - 
- 0150 - 


## SWMM5 Versions

| Release Date | Versions   | Developers     | FEMA Approval | LID Controls | Major Release |
|--------------|------------|----------------|---------------|--------------|---------------|
| 08/07/2023   | SWMM 5.2.4 | EPA            | Yes           | Yes          |               |
| 03/03/2023   | SWMM 5.2.3 | EPA            | Yes           | Yes          |               |
| 12/01/2022   | SWMM 5.2.2 | EPA            | Yes           | Yes          |               |
| 08/11/2022   | SWMM 5.2.1 | EPA            | Yes           | Yes          |               |
| 02/01/2022   | SWMM 5.2   | EPA            | Yes           | Yes          | Yes           |
| 07/20/2020   | SWMM 5.1.015 | EPA          | Yes           | Yes          |               |
| 02/18/2020   | SWMM 5.1.014 | EPA          | Yes           | Yes          | Yes           |
| 08/09/2018   | SWMM 5.1.013 | EPA          | Yes           | Yes          | Yes           |
| 03/14/2017   | SWMM 5.1.012 | EPA          | Yes           | Yes          | Yes           |
| 08/22/2016   | SWMM 5.1.011 | EPA          | Yes           | Yes          | Yes           |
| 08/20/2015   | SWMM 5.1.010 | EPA          | Yes           | Yes          | Yes           |
| 04/30/2015   | SWMM 5.1.009 | EPA          | Yes           | Yes          | Yes           |
| 04/17/2015   | SWMM 5.1.008 | EPA          | Yes           | Yes          |               |
| 10/09/2014   | SWMM 5.1.007 | EPA          | Yes           | Yes          |               |
| 06/02/2014   | SWMM 5.1.006 | EPA          | Yes           | Yes          |               |
| 03/27/2014   | SWMM 5.1.001 | EPA          | Yes           | Yes          |               |
| 04/21/2011   | SWMM 5.0.022 | EPA          | Yes           | Yes          |               |
| 08/20/2010   | SWMM 5.0.019 | EPA          | Yes           | Yes          |               |
| 03/19/2008   | SWMM 5.0.013 | EPA          | Yes           | Yes          |               |
| 08/17/2005   | SWMM 5.0.005 | EPA, CDM     | Yes           | No           |               |
| 11/30/2004   | SWMM 5.0.004 | EPA, CDM     | No            | No           |               |
| 11/25/2004   | SWMM 5.0.003 | EPA, CDM     | No            | No           |               |
| 10/26/2004   | SWMM 5.0.001 | EPA, CDM     | No            | No           |               |
| 2001–2004    | SWMM5        | EPA, CDM     | No            | No           |               |
| 1988–2004    | SWMM4        | UF, OSU, CDM | No            | No           |               |
| 1981–1988    | SWMM3        | UF, CDM      | No            | No           |               |
| 1975–1981    | SWMM2        | UF           | No            | No           |               |
| 1969–1971    | SWMM1        | UF, CDM, M&E | No            | No           |               |

## Name notes on the meaning of the prefixes

* The Ruby script says "hw_Upstream Subcatchments from an Outfall.rb" is designed to work specifically with ICM InfoWorks, indicated by the "hw_" prefix in its name. It focuses on identifying and managing upstream subcatchments from an outfall point within the ICM InfoWorks environment. Similarly, when you see a "sw_" prefix in a Ruby script's name, it means that script is intended for use with ICM SWMM only.

* However, for scripts with the "hw_sw" prefix, it means they are versatile and can be applied to both ICM InfoWorks (hw) and ICM SWMM (sw) modeling environments. These versatile scripts provide flexibility and convenience, allowing users to work seamlessly across both platforms to perform various tasks related to water management, drainage, and modeling.

* By using appropriate prefixes in the script names, users can easily identify which scripts are compatible with their specific modeling software, ensuring a smooth and efficient workflow when working with ICM InfoWorks or ICM SWMM projects.

### Descriptions

* Field `Type`:
    * `UI & EX` - Script can be ran in either UI or ICM Exchange
    * `UI` - Script is designed to run in the UI only
    * `EX` - Script is designed to run in the ICM Exchange only
    * `TBC` - Requires assessment from a maintainer
* Field `Category`:
    * `Network Data Bin`      - Reading raw binary data from the network. Makes no attempt to parse data.
    * `Network Data Get`      - Reading useful data from a network
    * `Network Data Set`      - Writing data to a network
    * `Network Data Export`   - Export network data to a file
    * `Network Data Import`   - Import network data from a file
    * `Network Data Analysis` - Related to tracing through a network or checking for specific conditions. These examples are more like final products.
    * `Database Data Bin`     - Reading raw binary data from the database. Makes no attempt to parse data.
    * `Database Data Get`     - Reading useful data from a database
    * `Database Data Set`     - Writing data to a database
    * `Database Data Export`  - Export database data to a file
    * `Database Data Import`  - Import database data from a file
    * `Network RTC Bin`       - Reading raw binary data from the network RTC data. Makes no attempt to parse data.
    * `Network RTC Get`       - Reading useful data from the network RTC data
    * `Network RTC Set`       - Writing data to the network RTC data
    * `Simulations Run`       - Creating and Running simulations
    * `Simulations Data Get`  - Obtaining simulation data
    * `System Automation`     - Misc system tasks
    * `Developer Tools`       - Tools that can help you make / learn how to make Ruby scripts.

    # InfoWorks ICM Ruby Integration: Exchange vs UI

InfoWorks ICM provides two main ways to integrate with Ruby: Exchange and UI. Each of these has its own strengths and limitations, and they are intended for different use cases.

## Exchange

Exchange is a powerful tool for manipulating tree objects 🗂, creating and opening databases 💽, running simulations 🏁, and more. It provides a lower-level access to the database, allowing you to control and manipulate the data directly.

However, Exchange does not have access to UI elements like graphs 📊 and dialogs 💬. This means that you cannot use Exchange to interact with the user interface of InfoWorks ICM. Exchange scripts are typically run from the command line and do not require the InfoWorks ICM user interface to be open.

## UI

UI, on the other hand, allows you to manipulate the currently open network(s) 🌐. You can import and export data 💾, select objects 👉, and run scripts that produce output in the UI 💻.

However, the UI integration does not allow you to open or close databases, access tree objects directly, or run simulations. It is limited to working on the current open network 🌐.

## Summary

In summary, Exchange gives you more low-level database control 🤓 but no UI access 🚫💻, while UI allows you to manipulate the current network with some UI interactions 💻 but with less low-level control ⚙️.

The Exchange products are intended for command line or automated tasks ⚙️, while the UI Ruby integration allows some scripting on open networks with UI interaction 💻. So they provide different levels of access tailored to their intended use cases.

