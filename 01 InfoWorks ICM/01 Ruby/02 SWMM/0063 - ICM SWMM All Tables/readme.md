## Code Summary: Counting Tables in an ICM SWMM Network

### Purpose
This Ruby script is designed to count all the tables in an ICM SWMM (Stormwater Management Model) Network.

### Process Flow

1. **Begin Block**
   - The script starts with a `begin` block to handle any exceptions that might occur.

2. **Accessing the Current Network**
   - `net = WSApplication.current_network`: Retrieves the current network.
   - The script raises an error if no current network is found.

3. **Defining Table Names**
   - A list of table names related to the ICM SWMM network is defined. This includes tables like `sw_conduit`, `sw_node`, `sw_weir`, etc.

4. **Counting Rows in Each Table**
   - The script iterates through each table name.
   - For each table, it accesses the row objects.
   - Counts the number of rows (elements) in each table.
   - Prints the table name along with the count of its rows.

5. **Error Handling**
   - If a table is not found, an error message is raised.
   - Any other exceptions are caught and their message is printed.

### Notes
- The script is useful for getting an overview of the elements present in an ICM SWMM network.
- It provides a count of elements for each specified table, which can be essential for data analysis and network management.
- Exception handling is implemented to ensure the script does not fail silently.

=======================================================================
Knowledge Acquisition and Training Environment (KATE)
=======================================================================
SWMM5's nonlinear hydrology offers several key advantages over both the Rational Method and SCS Unit Hydrograph approaches:

## Comprehensive Modeling Capabilities

**Distributed Analysis**
SWMM5 uses kinematic wave routing which allows separate modeling of both impervious and pervious areas within a single subbasin, providing more accurate representation of urban runoff characteristics[1]. This distributed approach better captures the different responses from various surface types compared to the lumped parameters used in SCS method.

**Hydrologic Processes**
SWMM5 accounts for multiple hydrologic processes including:
- Time-varying rainfall patterns
- Evaporation from surface water
- Infiltration into unsaturated soil layers
- Interflow between groundwater and drainage systems
- Surface ponding and routing[5]

## Technical Advantages

**Nonlinear Response**
The kinematic wave technique produces a nonlinear response to rainfall excess, unlike the linear response of unit hydrographs[1]. This better represents the actual physical behavior of urban runoff.

**Urban Applications**
SWMM5 is particularly effective for urban areas because:
- It generates sharp runoff responses that match observed urban drainage patterns[1]
- It can simulate complex drainage networks including pipes, channels, storage devices, and various control structures[5]
- It provides detailed results beyond just peak flows, including full runoff hydrographs and routing calculations[4]

## Limitations of Other Methods

**Rational Method Limitations**
- Only provides peak discharge estimates, not complete hydrographs[6]
- Uses simplified assumptions about rainfall intensity and timing[6]
- Best suited only for small watersheds and preliminary screening[6]

**SCS Method Limitations**
- Uses averaged runoff characteristics that can underestimate peak flows in urban areas[1]
- Less accurate for small storm events[2]
- Provides less detailed results compared to SWMM's comprehensive output[4]

Citations:
[1] https://www.openswmm.org/Topic/3206/swmm5-hydrology-and-the-scs-method
[2] https://www.dep.state.pa.us/dep/subject/advcoun/stormwater/Manual_DraftJan05/Section09-jan-rev.pdf
[3] https://learn.hydrologystudio.com/hydrology-studio/knowledge-base/rational-method-vs-scs-method/
[4] https://www.openswmm.org/Topic/4199/swmm-versus-rational-method-for-calculating-the-surface-water
[5] https://en.wikipedia.org/wiki/Storm_Water_Management_Model
[6] https://www.openswmm.org/Topic/6525/swmm-vs-rational-method
[7] https://www.semswa.org/files/047af3e3d/Chapter-6-Hydrology.pdf
[8] https://www.openswmm.org/Topic/16652/advantages-of-swmm
