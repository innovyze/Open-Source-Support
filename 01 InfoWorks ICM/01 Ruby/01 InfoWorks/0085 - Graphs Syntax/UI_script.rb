# InfoWorks ICM WSApplication.Graph(options) syntax reference
require 'date'

# Define the XArray with 10 time values parsed using DateTime.strptime
# Each time value represents a 2-minute interval starting from "21/09/2025 06:48"
XArray = [
  DateTime.strptime("21/09/2025 06:48", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 06:50", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 06:52", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 06:54", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 07:00", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 07:02", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 07:04", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 07:06", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 07:08", "%d/%m/%Y %H:%M"),
  DateTime.strptime("21/09/2025 07:10", "%d/%m/%Y %H:%M")
]

# Define the YArray with corresponding flow values in l/s
# These values represent synthetic flow data that fluctuates but never reaches zero
YArray = [26.9, 26.7, 26.9, 26.5, 27.0, 25.6, 25.3, 25.6, 26.1, 26.3]

# Initialize an array to store trace data
traces = []

# Define the RGB values for the trace color (dark blue)
red = 0
green = 0
blue = 139  # Dark blue color

# Add a trace to the traces array
# The trace includes the title, XArray, YArray, line type, marker type, and trace color
traces << {
      "Title" => "Flow Data",  # Title of the trace
      "XArray" => XArray,      # X-axis values (time)
      "YArray" => YArray,      # Y-axis values (flow)
      "LineType" => "Solid",  # Line type for the trace
      "Marker" => "None",     # No markers on the trace
      "TraceColour" => WSApplication.colour(red, green, blue)  # Dark blue color for the trace
    }

# Generate the graph using WSApplication.graph
# The graph includes window title, graph title, axis labels, and trace data
WSApplication.graph({
"WindowTitle" => "Flow vs Time",  # Title of the graph window
    "GraphTitle" => "Predicted DS Flow (l/s)",  # Title of the graph
    "XAxisLabel" => "Time",  # Label for the X-axis
    "YAxisLabel" => "Flow (l/s)",  # Label for the Y-axis
    "IsTime" => true,  # Indicates that the X-axis values are time values
    "Traces" => traces  # Array of traces to be plotted
})