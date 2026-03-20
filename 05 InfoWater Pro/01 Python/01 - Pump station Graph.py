import matplotlib.pyplot as plt
from infowater.output.manager import Manager as OutMan
%matplotlib inline # this command keeps graphs inline within the notebook

path = "C:/Examples/SAMPLE.OUT/SCENARIO/BASE/HYDQUA.OUT"
outman = OutMan(path)

# Create simple graph of Tank Level and Pump flowrate for two related pumps at a pump station.

# Define relevant ID's
tank_id = '103'
pump_ids = ['200','210']

# Get x-axis list of times
times = outman.get_time_list()

# Create two subplots
fig, axes = plt.subplots(2, 1, figsize=(10, 6))
axes[0].plot(times, outman.get_time_data("Tank",tank_id,"Level"))
for pump in pump_ids:
    axes[1].plot(times, outman.get_time_data("Pump",pump,"Flow"));

axes[1].legend(pump_ids,bbox_to_anchor=(1.1,1.0))
axes[0].set(ylabel='Tank Level (ft)')
axes[1].set(xlabel='Time (hrs)', ylabel='Flowrate (CFS)')

