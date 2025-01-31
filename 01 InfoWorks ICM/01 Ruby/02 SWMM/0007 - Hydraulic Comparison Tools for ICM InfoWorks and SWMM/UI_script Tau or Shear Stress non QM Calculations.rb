require 'date'

def print_table_results(cn)
  # Iterate over each table in the network
  puts
  puts "Tables and their result fields in this ICM InfoWorks Run"
  puts
  cn.tables.each do |table|
    # Initialize an array to store the names of result fields
    results_array = []
    found_results = false

    # Check each row object in the current table
    cn.row_object_collection(table.name).each do |row_object|
      # Check if the row object has a 'results_fields' property and results have not been found yet
      if row_object.table_info.results_fields && !found_results
        # If yes, add the field names to the results_array
        row_object.table_info.results_fields.each do |field|
          results_array << field.name
        end
        found_results = true  # Set flag to true after finding the first set of results
        break  # Exit the loop after processing the first row with results
      end
    end

    # Print the table name and each of its result fields on a separate row only if there are result fields
    unless results_array.empty?
      puts "Table: #{table.name.upcase}"
      results_array.each do |field|
        puts "Result field: #{field}"
      end
      puts
    end
  end
end

# Usage example
cn = WSApplication.current_network

val = WSApplication.prompt "Choose USA or SI Units for the Tau calculation",
[
  ['USA Units','Boolean',false],
  ['SI  Units','Boolean',true]
], false
USA = val[0]
SI  = val[1]

# Get the count of timesteps
ts_size = cn.list_timesteps.count
puts "Time step size: #{ts_size}"

# Get the list of timesteps
ts = cn.list_timesteps

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs
# Print the time interval in seconds and minutes
puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval*86400.0, time_interval*1440.0]

# Define the result field names to fetch the results for all selected nodes
result_field_names = [
  'HYDGRAD','us_depth','ds_depth'
]

# Iterate through the selected objects in the network
cn.each_selected do |sel|
  begin
    # Try to get the row object for the current node
    ro = cn.row_object('hw_conduit', sel.id) 

    # If ro is nil, then the object with the given id is not a link
    #raise "Object with ID #{sel.node_id} is not a link." if ro.nil?

    # Initialize variables for us_tau and ds_tau statistics
    us_tau_values = []
    ds_tau_values = []

    # Iterate through each time step
    (0...ts_size).each do |time_step_index|
      #In SI units:
      # Unit weight of water = 998.34 N/m³
      # In US customary units:
      # Unit weight of water = 62.4 lb/ft³
      if USA
        density = 62.4
      else
        density = 998.34
      end
      # change for your formula for tau  
      us_tau_calc = density * ro.results('HYDGRAD')[time_step_index].abs * (ro.results('us_depth')[time_step_index] )
      ds_tau_calc = density * ro.results('HYDGRAD')[time_step_index].abs * (ro.results('ds_depth')[time_step_index] )

      # Collect us_tau and ds_tau values
      us_tau_values << us_tau_calc
      ds_tau_values << ds_tau_calc
    end

    # Calculate mean, max, and min for us_tau and ds_tau
    us_tau_mean = us_tau_values.sum / us_tau_values.size
    us_tau_max = us_tau_values.max
    us_tau_min = us_tau_values.min

    ds_tau_mean = ds_tau_values.sum / ds_tau_values.size
    ds_tau_max = ds_tau_values.max
    ds_tau_min = ds_tau_values.min

    # Print the statistics for us_tau and ds_tau
    puts "ID: #{'%20s' % sel.id} | US Tau - Mean: #{'%11.4f' % us_tau_mean}, Max: #{'%11.4f' % us_tau_max}, Min: #{'%11.4f' % us_tau_min} | DS Tau - Mean: #{'%11.4f' % ds_tau_mean}, Max: #{'%11.4f' % ds_tau_max}, Min: #{'%11.4f' % ds_tau_min}" 
  rescue => e
    # Output error message if any error occurred during processing this object
    #puts "Error processing node with ID #{sel.id}. Error: #{e.message}"
  end
end