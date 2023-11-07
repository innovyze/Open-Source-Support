
# InfoWorks to SWMM5 Calibration File Generator

This Ruby script is designed to assist in generating SWMM5 calibration files from InfoWorks ICM output data.

## Requirements

- Ruby
- Access to an InfoWorks ICM model

## Usage

1. Ensure you have the `date` library available in Ruby.
2. Obtain the current network object from InfoWorks ICM.
3. Define your asset mapping for the network.
4. Run the script within the context of your InfoWorks ICM network with the necessary data loaded.

## Script

```ruby
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table
asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  # ... (additional mappings)
}

# Get the list of timesteps
ts = net.list_timesteps

# Check for sufficient timesteps
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval
time_interval = (ts[1] - ts[0]) * 24 * 60 * 60

# Define the result field name
res_field_name = 'ds_flow'

# Output headers for the calibration file
puts ";Flows for Selected Conduits"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Process each selected link in the network
net.each_selected do |sel|
  # ... (rest of the processing logic)
end
```

## Note

The script assumes that the time steps are evenly spaced and that the result field name corresponds to the upstream flow of the links.

---

Generated with the assistance of GPT-4.
