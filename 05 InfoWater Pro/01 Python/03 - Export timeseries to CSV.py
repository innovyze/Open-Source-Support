from infowater.output.manager import Manager as OutMan
import arcpy
from pathlib import Path
import csv

# Define Project information
project_name = "Sample"
scenario = "Base"

# Prepare output
aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
out_path = str(project_path) + "/" + project_name + ".OUT/SCENARIO/" + scenario + "/HYDQUA.OUT"
outman = OutMan(out_path)


# Get List of objects to export.
junctions = outman.get_element_list("junction");

# Apply filtering if needed and review list. See "Use of Domain and Selection Sets" script for examples.
print(junctions)

# Export results to CSV
# This example includes Time, Demand, Pressure, and Head for all Junctions.
# Check the units and convert as needed.

Junction_timeseries = str(project_path) + "/Junction_timeseries.csv"

time = outman.get_time_list()

with open(Junction_timeseries, 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['ID', 'Time (hrs)', 'Demand (gpm)', 'Pressure (psi)', 'Head (ft)'])
    for id in junctions:
        demand = outman.get_time_data("junction", id, "demand")*448.8
        pressure = outman.get_time_data("junction", id, "pressure")*0.433
        head = outman.get_time_data("junction", id, "head")
        for i in range(len(time)):
            writer.writerow([id, str(time[i]), str(demand[i]), str(pressure[i]), str(head[i])])
