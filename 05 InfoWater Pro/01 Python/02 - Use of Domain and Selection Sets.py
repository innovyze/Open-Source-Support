# Prerequisites
import pandas as pd
from pathlib import Path
from infowater.output.manager import Manager as OutMan
import arcpy

# Define Project information
project_name = "Purpletown"
scenario1 = "Base"
vdb_folder = "IWVDB1" # You can find this by viewing the Data Source tab on properties of your map layers
iwp_working_folder = "C:\\ProgramData\\Innovyze\\Temp\\IWPR10VDB"


# Create list of Junction ID's in Domain

junction_table = iwp_working_folder + "\\" + vdb_folder + "\\Map\\Map.gdb\\Junction"

# Create a list of junction ID's in Domain
cursor = arcpy.da.SearchCursor(junction_table, ["MOID"], "MOTYPE=1")
domain_junctions = []
for row in cursor:
    domain_junctions.append(row[0])

print(domain_junctions)

# Create list of Junction ID's in Selection Set

# Input: Provide the name of the Selection Set
select_set = "TEST"

# Get table path. Note this applies to nodes only. Links requires the ALINK.DBF table.
anode_selection = vdb_path + "\\Select\\" +select_set+ "\\ANODE.DBF"

# Create a list of junction ID's in Selection Set
cursor = arcpy.da.SearchCursor(anode_selection, ["ID"])
sel_set_junctions = []
for row in cursor:
    sel_set_junctions.append(row[0])

print(sel_set_junctions)

# Use above selection list to generate custom output table

# Get Outputs
aprx = arcpy.mp.ArcGISProject("CURRENT")
project_path = Path(aprx.filePath).parent
out1_path = str(project_path) + "/" + project_name + ".OUT/SCENARIO/" + scenario1 + "/HYDQUA.OUT"
out1 = OutMan(out1_path)

# Get list of indices based on selected junction ID's
junctions = out1.get_element_list("Junction")
j_indices = [i for i, moid in enumerate(junctions) if moid in domain_junctions]

# Get remaining results to build table
p1min = out1.get_range_data("Junction", "Pressure", "min")
p1avg = out1.get_range_data("Junction", "Pressure", "avg")
dmd1avg = out1.get_range_data("Junction", "Demand", "avg")

# Generate table
df = pd.DataFrame(
{
    "Junction": [junctions[i] for i in j_indices],
    "Base Avg Demand (gpm)": [dmd1avg[i]*448.8 for i in j_indices],
    "Base Avg Pressure (psi)": [p1avg[i]*0.433 for i in j_indices],
    "Base min Pressure (psi)": [p1min[i]*0.433 for i in j_indices],
})

df.sort_values(by='Base Avg Demand (gpm)',ascending=False)
