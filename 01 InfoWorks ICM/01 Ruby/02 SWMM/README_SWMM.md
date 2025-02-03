# ICM SWMM Networks

In InfoWorks SWMM, the data representing the stormwater network (such as pipes, nodes, and subcatchments) is organized into tables. These tables often have names beginning with `sw_`, for example `sw_pipe`, `sw_node`, etc. The different attributes of these elements (such as their dimensions, materials, and locations) are represented as fields within these tables.

The comment suggests that while these Ruby scripts are intended for use with InfoWorks SWMM, they may also work with Autodesk Innovyze's InfoWorks ICM (Integrated Catchment Modeling) to some extent, because the code structure is often very similar. However, there are important differences to be aware of.

In particular, the naming convention for tables in InfoWorks ICM is different. Instead of starting with `sw_`, tables in ICM usually start with `hw_` (for "HydroWorks", a predecessor of InfoWorks ICM). The field names within these tables can also be different between SWMM and InfoWorks.

This means that if you're trying to use these Ruby scripts with Autodesk Innovyze's InfoWorks ICM, you may need to modify the code to account for these differences in table and field names. Without such modifications, the scripts might not work as intended or might produce errors.

## ICM SWMM Ruby Folders (Composite 2025)

- **0001 - Element and Field Statistics**
- **0002 - Tracing Tools**
- **0003 - Scenario Tools**
- **0004 - Scenario Sensitivity - InfoWorks**
- **0005 - Import Export of Data Tables**
- **0006 - ICM SWMM vs ICM InfoWorks All Tables**
- **0007 - Hydraulic Comparison Tools for ICM InfoWorks and SWMM**
- **0008 - Database Field Tools for Elements and Results**
- **0009 - Polygon Subcatchment Boundary Tools**
- **0010 - List all results fields with Stats**
- **0011 - Get results from all timesteps in the IWR File**
- **0012 - ICM InfoWorks Results to SWMM5 Summary Tables**
- **0013 - SUDS or LID Tools**
- **0014 - InfoSewer to ICM Comparison Tools**
- **0015 - Export SWMM5 Calibration Files**
- **0016 - InfoSWMM and SWMM5 Tools in Ruby**
- **0017 - Subcatchment Grid and Tabs Tools**
- **0018 - Create Selection list using a SQL query**
- **0019 - Node Connection Tools**
- **0020 - All Node, Subs and Link IDs Tools**
- **0021 - Change the Geometry or Rename IDs**
- **0022 - TBA**
- **0023 - TBA**
- **0024 - Utilities**
- **0025 - Miscellaneous**


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