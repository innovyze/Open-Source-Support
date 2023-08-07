# InfoWorks SWMM Networks
In InfoWorks SWMM, the data representing the stormwater network (such as pipes, nodes, and subcatchments) is organized into tables. These tables often have names beginning with sw_, for example sw_pipe, sw_node, etc. The different attributes of these elements (such as their dimensions, materials, and locations) are represented as fields within these tables.

The comment suggests that while these Ruby scripts are intended for use with InfoWorks SWMM, they may also work with Autodesk Innovyze's InfoWorks ICM (Integrated Catchment Modeling) to some extent, because the code structure is often very similar. However, there are important differences to be aware of.

In particular, the naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.

This means that if you're trying to use these Ruby scripts with Autodesk Innovyze's InfoWorks ICM, you may need to modify the code to account for these differences in table and field names. Without such modifications, the scripts might not work as intended or might produce errors.

In conclusion, while these Ruby scripts are designed to work specifically with Autodesk Innovyze's InfoWorks SWMM, they might be adaptable for use with InfoWorks ICM or other similar software packages, but such adaptation would likely require some adjustments to the code.

|------|----------|---------------------------------------------------------------------|-----------------------|
|------|----------|---------------------------------------------------------------------|-----------------------|
| ID   | Type     | Name                                                                | Category              |
|------|----------|---------------------------------------------------------------------|-----------------------|
| 0001 | UI       | Pipe Length Statistics                                              | Network Data          |
| 0002 | UI       | Quick Trace                                                         | Network Data          |
| 0003 | UI       | Scenario Maker                                                      | Network Data          |
| 0004 | UI       | New ICM InfoWorks and ICM SWMM Scenarios                            | Network Data          |
| 0005 | UI       | Change All Node and Link IDs                                        | Network Data          |
| 0006 | UI       | Add Total Area for Subcatchments                                    | Network Data          |
| 0007 | UI       | Kutter Sql for ICM SWMM                                             | Network Data          |
| 0008 | UI       | Select Upstream Subcatchments from a Node with Multilinks           | Network Data          |
| 0009 | UI       | ICM Binary Results Export                                           | Network Data          |
| 0010 | UI       | List all results fields in a simulation                             | Network Data          |
| 0011 | UI       | Pipe Length Selection                                               | Network Data          |
| 0012 | UI       | ODEC Export Node and Conduit tables to CSV and MIF                  | Network Data          |
| 0013 | UI       | Depression Storage Statistics                                       | Network Data          |
| 0014 | UI       | Find all flags in all objects of a network model                    | Network Data          |
| 0015 | UI       | Pipe Diameter Statistics                                            | Network Data          |
| 0016 | UI       | All Link Parameter Statistics                                       | Network Data          |
| 0017 | UI       | All Node Parameter Statistics                                       | Network Data          |
| 0018 | UI       | All Subcatchment Parameter Statistics                               | Network Data          |
| 0019 | UI       |                                                                     | Network Data          |
| 0020 | UI       |                                                                     | Network Data          |
| 0021 | UI       | Create a node from polygon boundary                                 | Network Data          |
| 0022 | UI       | Output CSV of calcs based on Subcatchment Data                      | Network Data          |
| 0023 | UI       |                                                                     | Network Data          |
| 0024 | UI       | Input Message Box                                                   | Network Data          |
| 0025 | UI       | Get Minimum X, Y for All Nodes                                      | Network Data          |
| 0026 | UI       | Make_Subcatchments_From_Imported_InfoSewer_Manholes                 | Network Data          |
| 0027 | UI       | Copy a subcatchment and rename it                                   | Network Data          |
| 0028 | UI       | Percentage change in runoff surfaces upstream node into new scenario| Network Data          |
| 0029 | UI       | Runoff surfaces from selected subcatchments                         | Network Data          |
| 0030 | UI       | Connect subcatchment to nearest node                                | Network Data          |
| 0031 | UI       | List all results fields in a simulation                             | Network Data          |
| 0032 | UI       |                                                                     | Network Data          |
| 0033 | UI       |                                                                     | Network Data          |
| 0034 | UI       |                                                                     | Network Data          |
| 0035 | UI       |                                                                     | Network Data          |
| 0036 | UI       |                                                                     | Network Data          |
| 0037 | UI       |                                                                     | Network Data          |
| 0038 | UI       |                                                                     | Network Data          |
| 0039 | UI       | Calculate subcatchment areas in all nodes upstream a node           | Network Data          |
| 0040 | UI       | Create a new selection list using a SQL query                       | Network Data          |
| 0041 | UI       | Get results from all timesteps for Links, US_FLOW                   | Network Data          |
| 0042 | UI       | Get results from all timesteps for Subcatchments, All Params        | Network Data          |
| 0043 | UI       | Get results from all timesteps for Manholes, Qnode                  | Network Data          |
| 0044 | UI       | Get results from all timesteps for Manholes, All Params             | Network Data          |
| 0045 | UI       | Get results from all timesteps for Links, All Params                | Network Data          |
| 0046 | UI       | Output SUDS control as CSV                                          | Network Data          |
| 0047 | UI       | Select links sharing the same us and ds node ids                    | Network Data          |
| 0048 | UI       | Delete all scenarios except Base                                    | Network Data          |
| 0049 | UI       | Clear SUDS from subcatchments                                       | Network Data          |
| 0050 | UI       | Assign Subcatchment to nearest 'Storage' type Node                  | Network Data          |
| 0051 | UI       |                                                                     | Network Data          |
| 0052 | UI       |                                                                     | Network Data          |
| 0053 | UI       |                                                                     | Network Data          |
| 0054 | UI       |                                                                     | Network Data          |
| 0055 | UI       |                                                                     | Network Data          |
| 0056 | UI       | Listview of the currently selected network objects                  | Network Data          |
| 0057 | UI       | Scenario Maker                                                      | UI Specific           |
| 0058 | UI       | Bifurcation Nodes                                                   | Network Data          |
| 0059 | UI       | Dry Pipes                                                           | Network Data          |
| 0060 | UI       | Find All Network Elements                                           | Network Data          |
| 0061 | UI       | Flow Survey                                                         | Network Data          |
| 0062 | UI       | Header Nodes                                                        | Network Data          |
| 0063 | UI       | ICM SWMM All Tables                                                 | Network Data          |
| 0064 | UI       | ICM SWMM Network Overview                                           | Network Data          |
| 0065 | UI       | Put Run Parameters                                                  | Network Data          |
| 0066 | UI       | Get Run Parameters                                                  | Network Data          |
| 0067 | UI       | ICM Ruby Tutorials                                                  | Network Data          |
| 0068 | UI       | ICM InfoWorks All Table Names                                       | Network Data          |
| 0069 | UI       | Make an Overview of All Network Elements                            | Network Data          |
| 0070 | UI       | Upstream Subcatchments from an Outfall                              | Network Data          |
| 0071 | UI       |                                                                     | Network Data          |
| 0072 | UI       |                                                                     | Network Data          |
| 0073 | UI       |                                                                     | Network Data          |
| 0074 | UI       |                                                                     | Network Data          |
| 0075 | UI       |                                                                     | Network Data          |
| 0076 | UI       |                                                                     | Network Data          |
| 0077 | UI       |                                                                     | Network Data          |
| 0078 | UI       |                                                                     | Network Data          |
| 0079 | UI       |                                                                     | Network Data          |
| 0080 | UI       |                                                                     | Network Data          |
| 0081 | UI       |                                                                     | Network Data          |
| 0082 | UI       |                                                                     | Network Data          |
| 0083 | UI       |                                                                     | Network Data          |
| 0084 | UI       | Change All Node and Link IDs                                        | Network Data          |
| 0085 | UI       |                                                                     | Network Data          |
| 0086 | UI       |                                                                     | Network Data          |
| 0087 | UI       |                                                                     | Network Data          |
| 0088 | UI       |                                                                     | Network Data          |
| 0089 | UI       |                                                                     | Network Data          |
| 0090 | UI       |                                                                     | Network Data          |
| 0091 | UI       |                                                                     | Network Data          |
| 0092 | UI       |                                                                     | Network Data          |
| 0093 | UI       |                                                                     | Network Data          |
| 0094 | UI       |                                                                     | Network Data          |
| 0095 | UI       |                                                                     | Network Data          |
| 0096 | UI       |                                                                     | Network Data          |
| 0097 | UI       |                                                                     | Network Data          |
| 0098 | UI       |                                                                     | Network Data          |
| 0099 | UI       |                                                                     | Network Data          |
| 0100 | UI       |                                                                     | Network Data          |
|------|----------|---------------------------------------------------------------------|-----------------------|

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