# InfoWorks ICM Graph Syntax Reference

## Overview
This script demonstrates the `WSApplication.graph()` method syntax in InfoWorks ICM. It provides a complete working example of how to create custom graphs with time-series data, including proper formatting, styling, and axis configuration.

## Purpose
The script showcases how to:
- Create and format time-series data for graphing
- Define custom traces with specific colors and line styles
- Configure graph properties (titles, axis labels, markers)
- Use the `WSApplication.graph()` method with all available options
- Handle DateTime objects for time-based X-axis data

## Script Details
The example generates a graph showing:
- **Title**: "Flow vs Time"
- **Data**: Predicted downstream flow (l/s) over a series of time intervals
- **Styling**: Dark blue solid line with no markers
- **Time Range**: September 21, 2025 from 06:48 to 07:10

## Key Components

### Data Arrays
- **XArray**: Time values using `DateTime.strptime()` for proper date/time formatting
- **YArray**: Corresponding flow values in liters per second (l/s)

### Graph Configuration
The `WSApplication.graph()` method accepts a hash with the following options:
- `WindowTitle`: Title for the graph window
- `GraphTitle`: Main title displayed on the graph
- `XAxisLabel`: Label for the X-axis
- `YAxisLabel`: Label for the Y-axis  
- `IsTime`: Boolean flag indicating time-based X-axis values
- `Traces`: Array of trace definitions

### Trace Properties
Each trace in the traces array includes:
- `Title`: Name of the trace (shown in legend)
- `XArray`: Array of X-axis values
- `YArray`: Array of Y-axis values
- `LineType`: Style of line ("Solid", "Dashed", etc.)
- `Marker`: Marker style ("None", "Circle", "Square", etc.)
- `TraceColour`: RGB color created using `WSApplication.colour(red, green, blue)`

## Author & Credit
**Original Author**: [Sebasmadridmx](https://github.com/Sebasmadridmx)

**Source**: [InfoWorks-ICM-Ruby-Scripting Repository](https://github.com/Sebasmadridmx/InfoWorks-ICM-Ruby-Scripting-/blob/main/03%20Graphs%20Syntax.rb)

We gratefully acknowledge and thank Sebasmadridmx for creating this excellent reference script and for granting permission to include it in this repository. This contribution helps the InfoWorks ICM community better understand the graphing capabilities available through Ruby scripting.

## Example Output
Running this script will produce a graph window showing a time-series plot of flow data with:
- Professional formatting suitable for reports
- Clear axis labels and units
- Customizable colors and styling
- Time-based X-axis formatting

## Modifications
You can easily adapt this script by:
- Replacing XArray and YArray with your own data
- Changing colors using different RGB values
- Adding multiple traces to compare datasets
- Modifying line types and markers for different visual styles
- Adjusting axis labels and titles for your specific use case

## License
This script is provided as-is for educational and practical use within the InfoWorks ICM community.
