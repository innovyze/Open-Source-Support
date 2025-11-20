#peak_gpm = val * 2.6/ (val*1.547)**0.16

# Import the 'date' library
require 'date'

puts "\n" + "=" * 80
puts "ICM InfoWorks Peaking Factor Calculator"
puts "Script Start: #{DateTime.now}"
puts "=" * 80

# Get the current network object from InfoWorks
cn = WSApplication.current_network

puts "\nDEBUG: Checking network access mode..."
puts "DEBUG: Network: #{cn.inspect}"

# Check if network is read-only
network_read_only = false
begin
  # Try to detect read-only mode
  # In ICM, read-only networks don't allow field modifications
  test_node = cn.row_objects('Node').first rescue nil
  if test_node
    # Try to read current value
    current_val = test_node['user_text_10'] rescue ''
    # Try to write same value back (should fail if read-only)
    begin
      test_node['user_text_10'] = current_val
      test_node.write
      puts "DEBUG: Network is WRITABLE (edit mode)"
    rescue => e
      if e.message.include?('read only')
        network_read_only = true
        puts "WARNING: Network is READ-ONLY!"
      end
    end
  end
rescue => e
  puts "DEBUG: Could not determine network mode: #{e.message}"
end

# If read-only, warn and exit
if network_read_only
  puts "\n" + "!" * 80
  puts "ERROR: NETWORK IS IN READ-ONLY MODE!"
  puts "!" * 80
  puts "\nThis script needs to WRITE data to link fields."
  puts "Read-only networks do not allow field modifications."
  puts "\nHOW TO FIX:"
  puts "  1. Close this network"
  puts "  2. Re-open it in EDIT mode:"
  puts "     - File > Open"
  puts "     - Select your network"
  puts "     - Make sure 'Read Only' is UNCHECKED"
  puts "     - Click Open"
  puts "  3. Re-run this script"
  puts "\nAlternatively, if you have the network open elsewhere:"
  puts "  - Close any other instances viewing this network"
  puts "  - The network may be locked by another process"
  puts "!" * 80
  
  ans = WSApplication.prompt(
    "Network is read-only. Cannot write to fields.\n\nDo you want to continue anyway?\n(Will only calculate, not save results)",
    [['Continue in read-only mode (no data saved)', 'Boolean', false]],
    false
  )
  
  unless ans && ans[0]
    puts "\nScript cancelled. Please open network in edit mode and try again."
    return
  else
    puts "\nWARNING: Continuing in read-only mode."
    puts "WARNING: Calculations will be performed but NOT saved to network!"
  end
end

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
  ['Alternative Peaking Curve', 'Boolean', false],
  ['X Coverage', 'NUMBER', 23, nil, 'LIST', [0,1,5,10,50]],
  ['Y Peaking Multiplier', 'NUMBER', 23, nil, 'LIST', [0,2,15,20,90]]
], false

if parameters.nil?
  puts "User cancelled."
  return
end

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

puts "\nDEBUG: Parameters loaded:"
puts "  k = #{k_value}, p = #{p_value}"
puts "  Peakable coverage load = #{peakable_coverage_load}"
puts "  Alternative peaking = #{alternative_peaking_curve}"

# Get the list of timesteps
ts = cn.list_timesteps
puts "\nDEBUG: Timesteps: #{ts.size}"

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "ERROR: Not enough timesteps available! (Found: #{ts.size})"
  return
end

# Define the result field name
res_field_name = 'us_flow'

# ============================================================================
# PHASE 1: Calculate statistics and store per-link data
# ============================================================================
puts "\n" + "=" * 80
puts "PHASE 1: Calculating statistics for each link"
puts "=" * 80

# Hash to store calculated values for each link
link_data = {}

# Iterate through the selected objects in the network
cn.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = cn.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    if ro.nil?
      puts "WARNING: Could not get link object for #{sel.id}"
      next
    end

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Initialize variables for statistics
      total_flow = 0.0
      count = 0
      min_value = results.first.to_f
      max_value = results.first.to_f
      peak_flow_sum = 0.0

      # Iterate through the results and update statistics
      results.each do |result|
        flow_value = result.to_f

        # Calculate peak flow using the provided k and p values
        if alternative_peaking_curve && a_value != 0.0 && b_value != 0.0
          # Alternative: PF = a / (flow * b)^p
          if flow_value > 0
            peak_factor = a_value / ((flow_value * b_value) ** p_value)
          else
            peak_factor = k_value
          end
          peak_flow = flow_value * peak_factor
        else
          # Standard: peak = k * flow^p
          peak_flow = k_value * (flow_value ** p_value)
        end

        total_flow += flow_value
        peak_flow_sum += peak_flow
        min_value = [min_value, flow_value].min
        max_value = [max_value, flow_value].max
        count += 1
      end

      # Calculate the mean values
      mean_value = total_flow / count
      mean_peak = peak_flow_sum / count
      
      # Store calculated data for this link
      link_data[sel.id] = {
        total_flow: total_flow,
        mean_flow: mean_value,
        min_flow: min_value,
        max_flow: max_value,
        mean_peak: mean_peak,
        count: count
      }
      
      # Print the statistics
      puts format("Link: %-12s | Mean: %10.4f | Max: %10.4f | Min: %10.4f | Peak: %10.4f | Steps: %5d", 
                  sel.id, mean_value, max_value, min_value, mean_peak, count)
    else
      puts "ERROR: Mismatch in timestep count for link #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end
  rescue => e
    # Output error message if any error occurred during processing this object
    puts "ERROR processing link #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end

puts "\nDEBUG: Phase 1 complete. Stored data for #{link_data.size} links"

# ============================================================================
# PHASE 2: Assign calculated values to link fields
# ============================================================================
puts "\n" + "=" * 80
puts "PHASE 2: Assigning values to link fields"
puts "=" * 80

if network_read_only
  puts "\n" + "!" * 80
  puts "SKIPPING PHASE 2 - Network is read-only"
  puts "!" * 80
  puts "\nCalculations were performed but will NOT be saved."
  puts "To save results, open network in edit mode and re-run script."
  puts "\nPhase 1 results are shown above for your reference."
else
  assigned_count = 0
  error_count = 0

  # Assign values to the respective columns
  cn.each_selected do |sel|
    begin
      ro = cn.row_object('_links', sel.id)
      
      if ro.nil?
        puts "WARNING: Could not get link object for #{sel.id}"
        next
      end
      
      # Retrieve stored data for this link
      data = link_data[sel.id]
      
      if data.nil?
        puts "WARNING: No calculated data found for link #{sel.id} - skipping"
        next
      end

      # Get the total flow for this specific link
      total_flow = data[:total_flow]
      mean_flow = data[:mean_flow]
      
      puts "\nDEBUG: Link #{sel.id}:"
      puts "  Total flow = #{total_flow}"
      puts "  Mean flow = #{mean_flow}"

      # Assign flow components based on user selections
      if unpeakable_flow_as_base_flow
        # Base flow = total - peakable coverage load
        base_value = total_flow - peakable_coverage_load
        ro['base_flow'] = base_value
        puts "  base_flow = #{base_value}"
      end
      
      if peakable_point_flow_as_trade_flow
        # Trade flow = peakable coverage load
        ro['trade_flow'] = peakable_coverage_load
        puts "  trade_flow = #{peakable_coverage_load}"
      end
      
      if peakable_coverage_as_additional_foul_flow
        # Additional foul flow = coverage * multiplier
        addl_value = x_coverage * y_peaking_multiplier
        ro['additional_foul_flow'] = addl_value
        puts "  additional_foul_flow = #{addl_value}"
      end
      
      # Optionally save peak flow
      if save_peak_flow
        begin
          ro['conduit_flow'] = data[:mean_peak]
          puts "  conduit_flow (peak) = #{data[:mean_peak]}"
        rescue => e
          puts "  WARNING: Could not write to conduit_flow field: #{e.message}"
        end
      end
      
      ro.write
      assigned_count += 1
      puts "  STATUS: Written successfully"
      
    rescue => e
      error_count += 1
      
      # Check if it's a read-only error
      if e.message.include?('read only')
        puts "ERROR: Network became read-only during execution!"
        puts "  Link #{sel.id}: #{e.message}"
        puts "\nStopping Phase 2. Network must be in edit mode."
        break
      else
        puts "ERROR assigning values to link #{sel.id}: #{e.message}"
        puts "  Backtrace: #{e.backtrace.first(3).join("\n  ")}"
      end
    end
  end

  puts "\n" + "=" * 80
  puts "PHASE 2 COMPLETE"
  puts "  Successfully assigned: #{assigned_count}"
  puts "  Errors: #{error_count}"
  puts "=" * 80
end

# ============================================================================
# FINAL SUMMARY
# ============================================================================
puts "\n" + "=" * 80
puts "SCRIPT COMPLETE"
puts "Timestamp: #{DateTime.now}"
puts "=" * 80
puts "\nSUMMARY:"
puts "  Total links processed: #{link_data.size}"

if network_read_only
  puts "  Network mode: READ-ONLY"
  puts "  Values calculated but NOT saved"
  puts "\n  TO SAVE RESULTS:"
  puts "    1. Close network"
  puts "    2. Re-open in EDIT mode (uncheck 'Read Only')"
  puts "    3. Re-run this script"
else
  puts "  Network mode: EDITABLE"
  puts "  Values assigned to: #{assigned_count rescue 0} links"
  puts "  Errors encountered: #{error_count rescue 0}"
end

puts "=" * 80

# Export results to console for reference
if link_data.size > 0
  puts "\n" + "=" * 80
  puts "CALCULATION RESULTS SUMMARY"
  puts "=" * 80
  puts format("%-15s | %12s | %12s | %12s | %12s", "Link ID", "Mean Flow", "Max Flow", "Min Flow", "Peak Flow")
  puts "-" * 80
  link_data.each do |link_id, data|
    puts format("%-15s | %12.6f | %12.6f | %12.6f | %12.6f", 
                link_id, data[:mean_flow], data[:max_flow], data[:min_flow], data[:mean_peak])
  end
  puts "=" * 80
  
  if network_read_only
    puts "\nNOTE: These results were NOT saved to the network (read-only mode)."
    puts "You can copy this table for documentation purposes."
  end
end
 
