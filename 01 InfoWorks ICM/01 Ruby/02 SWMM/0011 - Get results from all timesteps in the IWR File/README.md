

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
      - `hw_UI_script Get results from all timesteps for Manholes QNODE.rb`
      - `hw_UI_script Get results from all timesteps for Links All Params.rb`
      - `hw_UI_script Get results from all timesteps for Links_US Flow DS Flow.rb`
      - `hw_UI_script Get results from all timesteps for Subcatchments All Params.rb`
      - `hw_UI_script Get results from all timesteps for Manholes All Params.rb`
      - `hw_UI_script_All Node and Link URL Stats.md`
      - `hw_UI_script_All Node and Link URL Stats.rb`
      - `hw_UI_script_links.rb`
      - `hw_UI_script_nodes.rb`
      - `png001.png`
      - `README.md`
      - `sw_UI_script Get results from all timesteps for Manholes All Params.rb`
      - `sw_UI_script Get results from all timesteps for Subcatchments All Params.rb`
      - `sw_UI_script Get results from all timesteps for Links All Params.rb`

---

### Description

This section focuses on the **0011 - Get results from all timesteps in the IWR File** directory under the `02 SWMM` folder, which contains Ruby scripts designed to retrieve results from all timesteps in the IWR (InfoWorks Results) file:

- **Manhole Results:** 
  - `hw_UI_script Get results from all timesteps for Manholes QNODE.rb` retrieves results for manholes focusing on QNODE (flow node).
  - `hw_UI_script Get results from all timesteps for Manholes All Params.rb` and `sw_UI_script Get results from all timesteps for Manholes All Params.rb` get all parameters for manholes in HW (HydroWorks) and SW (SWMM) respectively.
- **Link Results:** 
  - `hw_UI_script Get results from all timesteps for Links All Params.rb` and `sw_UI_script Get results from all timesteps for Links All Params.rb` retrieve all parameters for links in HW and SW.
  - `hw_UI_script Get results from all timesteps for Links_US Flow DS Flow.rb` retrieves upstream and downstream flow data for links in HW.
- **Subcatchment Results:** 
  - `hw_UI_script Get results from all timesteps for Subcatchments All Params.rb` and `sw_UI_script Get results from all timesteps for Subcatchments All Params.rb` gather all parameters for subcatchments in HW and SW.
- **Node and Link URL Stats:** 
  - `hw_UI_script_All Node and Link URL Stats.md` and `hw_UI_script_All Node and Link URL Stats.rb` provide statistics or analysis related to URLs for nodes and links in HW.
- **General Link and Node Scripts:** 
  - `hw_UI_script_links.rb` and `hw_UI_script_nodes.rb` are scripts likely for managing or analyzing links and nodes in HW.

### Usage

To use the scripts within the `0011 - Get results from all timesteps in the IWR File` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0011 - Get results from all timesteps in the IWR File` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your workflow to retrieve results from all timesteps in the IWR file.

For example, to get results for manholes:
```sh
ruby hw_UI_script Get results from all timesteps for Manholes All Params.rb

Note
Always check for permissions before running scripts that might access or modify result files.
Backup your data before executing scripts that could process large datasets or alter results.
The README.md file within this directory might contain specific instructions, notes, or prerequisites for running these result retrieval scripts.


This README now focuses exclusively on the `0011 - Get results from all timesteps in the IWR File` folder, detailing its contents and usage. 