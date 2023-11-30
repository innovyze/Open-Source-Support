# Integrating InfoWorks with SWMM5 Summary Tables Using Ruby Scripts

## Overview
This Ruby script automates the generation of a SWMM5 Runoff Summary table from ICM InfoWorks engine output. It handles data extraction, comparison with SWMM5 RPT files, and converts the ICM InfoWorks network to ICM SWMM for further analysis.

## Script Workflow
1. **Initialization**: The script starts by requiring the 'date' library and initializing an array to store all statistics.
2. **Network Object Retrieval**: It fetches the current network object from InfoWorks and obtains the list and count of timesteps.
3. **Data Extraction**: A predefined list of result field names is used to fetch results for all selected Subcatchments.
4. **Data Processing**: For each selected object in the network, the script iterates through the results, calculating totals and maintaining minimum and maximum values.
5. **Time Interval Handling**: The script assumes time steps are evenly spaced, calculating the time interval for integration over time.
6. **Statistics Aggregation**: It saves statistical data, like sum, mean, max, and min, into an array.
7. **Summary Display**: The script outputs a formatted header for the Runoff Summary, followed by aggregated data for each subcatchment.

## Features
- **Field Customization**: Field names can be customized to include a variety of results like rainfall, evaporation rate, and different surface runoff components.
- **Dynamic Time Calculation**: Adjusts for varying lengths of time steps.
- **Efficient Data Aggregation**: Collects and summarizes data effectively across different fields.
- **Flexibility**: Can be modified to add or remove fields as needed.

## Usage
To execute the script, users must have the Ruby runtime installed and have access to an ICM InfoWorks network with the necessary data.

## Output
The output is a Runoff Summary table in the console, formatted with headers and data rows for each subcatchment, similar to SWMM5's RPT file format.

---

## Enhancements
- The script could be enhanced to output data directly to a CSV or Excel file for easier analysis.
- Additional error handling could be implemented for robustness.
