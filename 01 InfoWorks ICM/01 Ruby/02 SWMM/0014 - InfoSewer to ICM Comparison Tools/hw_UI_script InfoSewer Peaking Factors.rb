#peak_gpm = val * 2.6/ (val*1.547)**0.16

# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
cn = WSApplication.current_network

# Prompt the user for various parameters
parameters = WSApplication.prompt "Making ICM InfoWorks Approximate InfoSewer Peaking Factors\n" \
  "Note: Unpeakable flow should be in the base flow column, peakable load in trade flow, and coverage population in the additional foul flow column.",
[
  ['Use USA Units (GPM)', 'Boolean', false],
  ['Use SI Units (L/s)', 'Boolean', true],
  ['Save Peak Flow (Calc) to Inflow Conduit Field', 'Boolean', true],
  ['Include Peak Flow Calculation', 'Boolean', true],
  ['Unpeakable Flow as Base Flow', 'Boolean', true],
  ['Peakable Point Flow as Trade Flow', 'Boolean', true],
  ['Peakable Coverage as Additional Foul Flow', 'Boolean', true],
  ['Enter value for k (Peaking Factor)', 'String', '1.0'],
  ['Enter value for p (Exponent)', 'String', '2.0'],
  ['Use Peakable Coverage Load', 'Boolean', true],
  ['Enter value for peakable coverage load', 'String', '0.0'],
  ['Enter value for a', 'String', '0.0'],
  ['Enter value for b', 'String', '0.0'],
  ['Enter value for c', 'String', '0.0'],
  ['Enter value for d', 'String', '0.0'],
  ['Enter value for e', 'String', '0.0'],
  ['Alternative Peaking Curve', 'Boolean', true],
  ['X Coverage', 'NUMBER', 23, nil, 'LIST', [0,1,5,10,50]],
  ['Y Peaking Multiplier', 'NUMBER', 23, nil, 'LIST', [0,2,15,20,90]]
], false

use_usa_units = parameters[0]
use_si_units = parameters[1]
save_peak_flow = parameters[2]
include_peak_flow = parameters[3]
unpeakable_flow_as_base_flow = parameters[4]
peakable_point_flow_as_trade_flow = parameters[5]
peakable_coverage_as_additional_foul_flow = parameters[6]
k_value = parameters[7].to_f
p_value = parameters[8].to_f
use_peakable_coverage_load = parameters[9]
peakable_coverage_load = parameters[10].to_f
a_value = parameters[11].to_f
b_value = parameters[12].to_f
c_value = parameters[13].to_f
d_value = parameters[14].to_f
e_value = parameters[15].to_f
alternative_peaking_curve = parameters[16]
x_coverage = parameters[17].to_f
y_peaking_multiplier = parameters[18].to_f

# Get the list of timesteps
ts = cn.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name
res_field_name = 'us_flow'

# Iterate through the selected objects in the network
cn.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = cn.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Initialize variables for statistics
      total_flow = 0.0
      count = 0
      min_value = results.first.to_f
      max_value = results.first.to_f

      # Iterate through the results and update statistics
      results.each do |result|
        flow_value = result.to_f

        # Calculate peak GPM using the provided k and p values
        peak_gpm = k_value * flow_value ** p_value

        total_flow += flow_value
        min_value = [min_value, flow_value].min
        max_value = [max_value, flow_value].max
        count += 1

        # Print the value for each element with link id
        puts format("Link ID: %-10s | ICM Peaking Flow: %-10s | Total Flow GPM: %-10s", sel.id, '%.2f' % flow_value, '%.2f' % peak_gpm)
      end

      # Calculate the mean value
      mean_value = total_flow / count
      
      # Print the statistics
      puts format("Link: %-12s | Field: %-12s | Mean: %15.4f | Max: %15.4f | Min: %15.4f | Steps: %15d", sel.id, res_field_name, mean_value, max_value, min_value, count)
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end
  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end

# Assign values to the respective columns
cn.each_selected do |sel|
  begin
    ro = cn.row_object('_links', sel.id)
    next if ro.nil?

    ro['base_flow'] = total_flow - peakable_coverage_load
    ro['trade_flow'] = peakable_coverage_load
    ro['additional_foul_flow'] = x_coverage * y_peaking_multiplier
    ro.write
  rescue => e
    puts "Error assigning values to link with ID #{sel.id}. Error: #{e.message}"
  end
end

# Get the list of timesteps
ts = cn.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name
res_field_name = 'us_flow'

# Iterate through the selected objects in the network
cn.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = cn.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Initialize variables for statistics
      total_flow = 0.0
      count = 0
      min_value = results.first.to_f
      max_value = results.first.to_f

      # Iterate through the results and update statistics
      results.each do |result|
        flow_value = result.to_f

        # Calculate peak GPM using the provided k and p values
        peak_gpm = k_value * flow_value ** p_value

        total_flow += flow_value
        min_value = [min_value, flow_value].min
        max_value = [max_value, flow_value].max
        count += 1

        # Print the value for each element with link id
        puts format("Link ID: %-10s | ICM Peaking Flow: %-10s | Total Flow GPM: %-10s", sel.id, '%.2f' % flow_value, '%.2f' % peak_gpm)
      end

      # Calculate the mean value
      mean_value = total_flow / count
      
      # Print the statistics
      puts format("Link: %-12s | Field: %-12s | Mean: %15.4f | Max: %15.4f | Min: %15.4f | Steps: %15d", sel.id, res_field_name, mean_value, max_value, min_value, count)
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end
  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end