# InfoWorks SWMM Networks
In InfoWorks SWMM, the data representing the stormwater network (such as pipes, nodes, and subcatchments) is organized into tables. These tables often have names beginning with sw_, for example sw_pipe, sw_node, etc. The different attributes of these elements (such as their dimensions, materials, and locations) are represented as fields within these tables.

The comment suggests that while these SQL scripts are intended for use with InfoWorks SWMM, they may also work with Autodesk Innovyze's InfoWorks ICM (Integrated Catchment Modeling) to some extent, because the code structure is often very similar. However, there are important differences to be aware of.

In particular, the naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.

This means that if you're trying to use these SQL scripts with Autodesk Innovyze's InfoWorks ICM, you may need to modify the code to account for these differences in table and field names. Without such modifications, the scripts might not work as intended or might produce errors.

In conclusion, while these SQL scripts are designed to work specifically with Autodesk Innovyze's InfoWorks SWMM, they might be adaptable for use with InfoWorks ICM or other similar software packages, but such adaptation would likely require some adjustments to the code.

|------|------|---------------------------------------------------------|
|------|------|---------------------------------------------------------|
| ID   | Type | Name                                                    |
|------|------|---------------------------------------------------------|
| 0001 | UI   | Pipe Length Statistics                                  |
| 0002 | UI   | Quick Trace                                             |
| 0003 | UI   | Scenario Maker                                          |
| 0004 | UI   | New ICM InfoWorks and ICM SWMM Scenarios                |
| 0005 | UI   | Change All Node and Link IDs                            |
| 0006 | UI   | Add Total Area for Subcatchments                        |
| 0007 | UI   | Count Objects In the Database                           |
| 0008 | UI   | Select Upstream Subcatchments from a Node Multilinks    |
| 0009 | UI   | ICM Binary Results Export                               |
| 0010 | UI   | List all results fields in a simulation                 |
| 0011 | UI   | Pipe Length Selection                                   |
| 0012 | UI   | ODEC Export Node and Conduit tables to CSV and MIF      |
| 0013 | UI   | Depression Storage Statistics                           |
| 0014 | UI   | Find all flags in all objects of a network model        |
| 0015 | UI   | Pipe Diameter Statistics                                |
| 0016 | UI   | All Link Parameter Statistics                           |
| 0017 | UI   | All Node Parameter Statistics                           |
| 0018 | UI   | All Subcatchment Parameter Statistics                   |
| 0019 | UI   | Distribute attachment details by a shared value         |
| 0020 | UI   | Generate Individual Reports for a Selection of Objects  |
| 0021 | UI   | Create a node from polygon boundary                     |
| 0022 | UI   | Output CSV of calcs based on Subcatchment Data          |
| 0023 | UI   | Rename Nodes & Links using Name Generation pattern      |
| 0024 | UI   | Input Message Box                                       |
| 0025 | UI   | Get Minimum X, Y for All Nodes                          |
| 0026 | UI   | Make_Subcatchments_From_Imported_InfoSewer_Manholes     |
| 0027 | UI   | Copy a subcatchment and rename it                       |
| 0028 | UI   | Percent change in runoff surfaces upstream              |
| 0029 | UI   | Runoff surfaces from selected subcatchments             |
| 0030 | UI   | Connect subcatchment to nearest node                    |
| 0031 | UI   | List all results fields in a Simulation                 |
| 0032 | UI   | List Network Fields-Structure                           |
| 0033 | UI   | Output the Array BLOB values as a clustered value       |
| 0034 | UI   | Display Export geometries                               |
| 0035 | UI   | List Master Database Objects Contents                   |
| 0036 | UI   | Create Selection List                                   |
| 0037 | UI   | Select Isolated Nodes                                   |
| 0038 | UI   | Remove rows from a blob field                           |
| 0039 | UI   | Calculate subcatchment areas in all nodes upstream a    |
| 0040 | UI   | Create a new selection list using a SQL query           |
| 0041 | UI   | Get results from all timesteps for Links, US_FLOW       |
| 0042 | UI   | Get results from all timesteps for Subcatchments, All   |
| 0043 | UI   | Get results from all timesteps for Manholes, Qnode      |
| 0044 | UI   | Get results from all timesteps for Manholes, All Param  |
| 0045 | UI   | Get results from all timesteps for Links, All Params    |
| 0046 | UI   | Output SUDS control as CSV                              |
| 0047 | UI   | Select links sharing the same us and ds node ids        |
| 0048 | UI   | Delete all scenarios except Base                        |
| 0049 | UI   | Clear SUDS from subcatchments                           |
| 0050 | UI   | Assign Subcatchment to nearest 'Storage' type Node      |
| 0051 | UI   | Additional DWF Node IDs                                 |
| 0052 | UI   | Make a Table of the Run Parameters in ICM               |
| 0053 | UI   | Scenario Counter                              b         |
| 0054 | UI   |                                                         |
| 0055 | UI   |                                                         |
| 0056 | UI   | Listview of the currently selected network objects      |
| 0057 | UI   | Scenario Maker                                          |
| 0058 | UI   | Bifurcation Nodes                                       |
| 0059 | UI   | Dry Pipes                                               |
| 0060 | UI   | Find All Network Elements                               |
| 0061 | UI   | Flow Survey                                             |
| 0062 | UI   | Header Nodes                                            |
| 0063 | UI   | ICM SWMM All Tables                                     |
| 0064 | UI   | ICM SWMM Network Overview                               |
| 0065 | UI   | Get and Put Run Dialog Parameters                       |
| 0066 | UI   | ICM results against measured data within the UI         |
| 0067 | UI   | ICM Ruby Tutorials                                      |
| 0068 | UI   | ICM InfoWorks All Table Names                           |
| 0069 | UI   | Make an Overview of All Network Elements                |
| 0070 | UI   | Upstream Subcatchments from an Outfall                  |
| 0071 | UI   | Raingages, All Output Parameters                        |
| 0072 | UI   | Find Root Model Group                                   |
| 0073 | UI   | Rename Exported Image & Attachment Files                |
| 0074 | UI   | Capacity Assurance White Paper (InfoNet)                |
| 0075 | UI   | Sandbox Instance Evaluation and Class Scope             |
| 0076 | UI   | InfoWorks vs SWMM CSV Comparison                        |
| 0077 | UI   | ICM InfoWorks UX Tables                                 |
| 0078 | UI   | ICM SWMM UX Tables                                      |
| 0079 | UI   | ICM SWMM IWR Tables                                     |
| 0080 | UI   | ICM InfoWorks IWR Tables                                |
| 0081 | UI   | Export Compare Network Versions to CSV                  |
| 0082 | UI   | Create SuDS for All Subcatchments                       |
| 0083 | UI   | Find the Time of Max DS Depth in all Selected Links     |
| 0084 | UI   | Change All Node, Subs and Link IDs                      |
| 0085 | UI   | Export SWMM5 Calibration Files - Node Runoff            |
| 0086 | UI   | Export SWMM5 Calibration Files - Groundwater Elev       |
| 0087 | UI   | Export SWMM5 Calibration Files - Groundwater Flow       |
| 0088 | UI   | Export SWMM5 Calibration Files - Node Flooding          |
| 0089 | UI   | Export SWMM5 Calibration Files - Node Flood Depth       |
| 0090 | UI   | Export SWMM5 Calibration Files - Node Level             |
| 0091 | UI   | Export SWMM5 Calibration Files - Node Lateral Inflow    |
| 0092 | UI   | Export SWMM5 Calibration Files - Downstream Velocity    |
| 0093 | UI   | Export SWMM5 Calibration Files - Upstream Velocity      |
| 0094 | UI   | Export SWMM5 Calibration Files - Upstream Depth         |
| 0095 | UI   | Export SWMM5 Calibration Files - Downstream Depth       |
| 0096 | UI   | Export SWMM5 Calibration Files - Downstream Flow        |
| 0097 | UI   | Export SWMM5 Calibration Files - Upstream Flow          |
| 0098 | UI   | Compare ICM Inlets to HEC22 Inlets                      |
| 0099 | UI   | Compare ICM Headloss in Ruby Script                     |
| 0100 | UI   | ODIC and SQL Scripts for Importing InfoSewer to ICM     |
| 0101 | UI   | Common Operations                                       |
| 0102 | UI   | ICM IWR Results to SWMM5 Node Inflows Summary Table     |
| 0103 | UI   | ICM IWR Results to SWMM5 Node Depths Summary            |
| 0104 | UI   | ICM IWR Results to SWMM5 Node Surcharging               |
| 0105 | UI   | ICM IWR Results to SWMM5 Link Flows Summary             |
| 0106 | UI   | ICM IWR Results to SWMM5 Link Flows Summary             |
| 0107 | UI   | ICM IWR Results to SWMM5 to Subcatchment Runoff Summary |
| 0108 | UI   | Locate Missing Attachments on a Standalone Database     |
| 0109 | UI   | 1A ODEC Callback Examples                               |
| 0110 | UI   | ODIC Export                                             |   
| 0111 | UI   | ODIC Import                                             |
| 0112 | UI   | 2A ODIC Callback Examples                               |
| 0113 | UI   | Import an InfoWorks ICM SWMM Model InfoAsset Manager    |
| 0114 | UI   | GIS Export                                              |
| 0115 | UI   | Export Dashboard                                        |
| 0116 | UI   | Export Choice List values                               |
| 0117 | UI   | Import-Export Snapshot file                             |
| 0118 | UI   | Bulk Data Import                                        |
| 0119 | UI   | Export to CSV                                           |
| 0120 | UI   | ODIC and SQL Scripts for Importing InfoSewer to ICM     |
| 0121 | UI   | ODIC and SQL Scripts for Importing InfoSewer to ICM     |
| 0122 | UI   | Update from external CSV                                |
| 0123 | UI   | Update an object with values through comparison         |
| 0124 | UI   | Network Tracing                                         |
| 0125 | UI   | Tracing                                                 |
| 0126 | UI   | Copy selected subcatchments with user suffix            |
| 0127 | UI   | Kutter Sql for ICM SWMM                                 |
| 0128 | UI   | Spatial Scripts                                         |
| 0129 | UI   |                                                         |
| 0130 | UI   | ICM Information Hub Finder                              |
|------|------|---------------------------------------------------------|

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

