#sys.path.append("C:\Program Files\Autodesk\InfoWater Pro\Bin\Python")
import arcpy
import matplotlib.pyplot as plt
from pathlib import Path
import pandas as pd
import csv

from infowater.output.manager import Manager as OutMan

# Define User Inputs:
project_name = "Purpletown"
scenario1 = "Base"
scenario2 = "Break"

# Get Outputs
aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
out1_path = str(project_path) + "/" + project_name + ".OUT/SCENARIO/" + scenario1 + "/HYDQUA.OUT"
out2_path = str(project_path) + "/" + project_name + ".OUT/SCENARIO/" + scenario2 + "/HYDQUA.OUT"
out1 = OutMan(out1_path)
out2 = OutMan(out2_path)

# Generate custom graph from multiple Scenarios
times = out1.get_time_list()
tank_vol_1 = out1.get_time_data("Tank","T5004","% Volume")
tank_vol_2 = out2.get_time_data("Tank","T5004","% Volume")

%matplotlib inline
plt.plot(times, tank_vol_1)
plt.plot(times, tank_vol_2)
plt.xlabel("Time (hrs)")
plt.ylabel("Volume (%)")
plt.legend(["Baseline","Break"])
plt.annotate('Pipe Break', xy=(10.25, 33), xytext=(2, 10),
             arrowprops=dict(facecolor='black', width=1, shrink=0.05))

plt.show()

# Generate view of multiple objects in one graph
fig2, axs = plt.subplots(2)
fig2.suptitle('Pump flowrate Summary')
  
for i in out1.get_element_list("pump"):
    axs[0].plot(times, out1.get_time_data("Pump",i,"Flow"))
    axs[1].plot(times, out2.get_time_data("Pump",i,"Flow"))
    
axs[0].set_title('Base Scenario')
axs[1].set_title('Break Scenario')
axs[0].legend(out1.get_element_list("pump"),bbox_to_anchor=(1.1,1.05))

for ax in axs.flat:
    ax.set(xlabel='Time (hrs)', ylabel='Flowrate (CFS)')
    ax.label_outer()


# Summarize Pump average flows
df = pd.DataFrame(
{
    "pump": out1.get_element_list("pump"),
    "Base Avg Flow": out1.get_range_data("pump", "Flow", "Avg"),
    "Break Avg Flow": out2.get_range_data("pump", "Flow", "Avg"),
})
df

p1min = out1.get_range_data("Junction", "Pressure", "min")
p2min = out2.get_range_data("Junction", "Pressure", "min")
junctions = out1.get_element_list("Junction")

#Get list of junctions with minimum pressure below 20 psi and also a notable difference from baseline simulation.
selection = [i for i, (x, y) in enumerate(zip(p1min, p2min)) if abs(x-y)>10 and y<20]

p1avg = out1.get_range_data("Junction", "Pressure", "avg")
dmd1avg = out1.get_range_data("Junction", "Demand", "avg")

df = pd.DataFrame(
{
    "Impacted Junctions": [junctions[i] for i in selection],
    "Base Avg Demand (gpm)": [dmd1avg[i]*448.8 for i in selection],
    "Base Avg Pressure (psi)": [p1avg[i]*0.433 for i in selection],
    "Base min Pressure (psi)": [p1min[i]*0.433 for i in selection],
    "Break min Pressure (psi)": [p2min[i]*0.433 for i in selection],
})

df.sort_values(by='Base Avg Demand (gpm)',ascending=False)

#Export Table report to Excel

Junction_report = str(project_path) + "/" + "Junction_report.xlsx"

df.to_excel(Junction_report)

# Export full timeseries to CSV for selected objects
Junction_timeseries = str(project_path) + "/" + "Junction_timeseries.csv"
selected_junctions = [junctions[i] for i in selection]

with open(Junction_timeseries, 'w', newline='') as file:
    writer = csv.writer(file)
    writer.writerow(['ID', 'Time (hrs)', 'Demand (gpm)', 'Pressure (psi)'])
    for id in selected_junctions:
        demand = out2.get_time_data("junction", id, "demand")
        pressure = out2.get_time_data("junction", id, "pressure")
        for i in range(len(times)):
            writer.writerow([id, str(times[i]), str(demand[i]), str(pressure[i])])

# Quick Tips:

help(OutMan) # Get in-line help
help(out1.get_range_data) # Get help for individual functions

# Get detailed output of output metadata for lists of types, outputs, indices, etc.
import json
metadata = out1.get_metadata() 
print(json.dumps(vars(metadata), indent=4))
