
markdown
# Folder Structure

## OPEN-SOURCE-SUPPORT
- **01 InfoWorks ICM**
  - **01 Ruby**
  - **02 SWMM**
    - **0001 - Element and Field Statistics**
      - *(Content omitted for brevity)*
    - **0002 - Tracing Tools**
      - `1_shortest_path_dijkstra.rb`
      - `2_boundary_trace.rb`
      - `hw_QuickTrace_NG.rb`
      - `hw_QuickTrace.rb`
      - `hw_Sum_Selected_Total_Area.rb`
      - `hw_Upstream Subcatchments from an Outfall.rb`
      - `image.png`
      - `readme.md`
      - `Select Upstream Subcatchments from a Node with Multilinks.rb`
      - `Sum_Selected_Total_Area_SWMM.rb`
      - `Sum_Selected_Total_Area.rb`
      - `sw_QuickTrace_SWMM.rb`
      - `sw_QuickTrace.rb`
      - `sw_Sum_Selected_Total_Area.rb`
      - `sw_Upstream Subcatchments from an Outfall.rb`
      - `UI_Script_Calculate subcatchment areas in all nodes upstream a node.rb`
      - `UI-IncidentTraceUpstream-Incident.rb`
      - `UI-NodeTraceUpDownstream_ExcludeBy_InvertLevel.rb`
      - `UI-NodeTraceUpDownstream_ExcludeBy_PipeStatus.rb`
      - `UI-NodeTraceUpDownstream_ExcludeBy_SumPipeLength.rb`
      - `UI-NodeTraceUpstream.rb`
      - `UI-PipesTraceUpstream_SumPipeLengths_WriteToFile.rb`
      - `UI-PipesTraceUpstream_SumPipeLengths.rb`
      - `UI-PipeTraceUpstream_SaveToSelectionList.rb`

---

### Description

This section focuses on the **0002 - Tracing Tools** directory under the `02 SWMM` folder, which contains Ruby scripts designed for various tracing and analysis tasks within the SWMM (Storm Water Management Model) environment:

- **Path Finding:** `1_shortest_path_dijkstra.rb` uses Dijkstra's algorithm to find the shortest path.
- **Boundary Tracing:** `2_boundary_trace.rb` traces boundaries within the network.
- **Quick Tracing:** Scripts like `hw_QuickTrace_NG.rb`, `hw_QuickTrace.rb`, `sw_QuickTrace_SWMM.rb`, and `sw_QuickTrace.rb` provide quick tracing functionalities for different parts of the model.
- **Area Summation:** `hw_Sum_Selected_Total_Area.rb`, `Sum_Selected_Total_Area_SWMM.rb`, `Sum_Selected_Total_Area.rb`, and `sw_Sum_Selected_Total_Area.rb` sum up the total area of selected elements.
- **Subcatchment Analysis:** `hw_Upstream Subcatchments from an Outfall.rb` and `sw_Upstream Subcatchments from an Outfall.rb` help in analyzing upstream subcatchments from outfalls.
- **Node and Pipe Tracing:** Various scripts like `UI_Script_Calculate subcatchment areas in all nodes upstream a node.rb`, `UI-IncidentTraceUpstream-Incident.rb`, `UI-NodeTraceUpDownstream_ExcludeBy_InvertLevel.rb`, `UI-NodeTraceUpDownstream_ExcludeBy_PipeStatus.rb`, `UI-NodeTraceUpDownstream_ExcludeBy_SumPipeLength.rb`, `UI-NodeTraceUpstream.rb`, `UI-PipesTraceUpstream_SumPipeLengths_WriteToFile.rb`, `UI-PipesTraceUpstream_SumPipeLengths.rb`, and `UI-PipeTraceUpstream_SaveToSelectionList.rb` are designed for detailed node and pipe tracing with different exclusion criteria.

### Usage

To use the scripts within the `0002 - Tracing Tools` directory:

1. **Environment Setup:** Ensure Ruby is installed on your system.
2. **Navigation:** Navigate to the `0002 - Tracing Tools` subdirectory under `02 SWMM`.
3. **Execution:** Run the Ruby scripts from the command line or integrate them into your SWMM workflow.

For example, to find the shortest path:
```sh
ruby 1_shortest_path_dijkstra.rb

Note
Always check for permissions before running scripts that modify data.
Backup your work before executing scripts that could alter your project significantly.
The readme.md file within this directory might contain specific instructions or notes relevant to these tracing tools.


This README now focuses exclusively on the `0002 - Tracing Tools` folder, detailing its contents and usage.  