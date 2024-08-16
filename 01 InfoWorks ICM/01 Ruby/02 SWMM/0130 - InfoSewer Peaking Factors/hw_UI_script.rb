# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name
res_field_name = 'us_flow'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Initialize variables for statistics
      total = 0.0
      count = 0
      min_value = results.first.to_f
      max_value = results.first.to_f

      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f

        val = val * 448.8 # Convert from MGD to GPM
        peak_gpm = val * 2.6/ (val*1.547)**0.16

        total += val
        min_value = [min_value, val].min
        max_value = [max_value, val].max
        count += 1

        # Print the value for each element
        puts "ICM Peaking Flow in link: #{'%.2f' % val}, Total Flow GPM: #{'%.2f' % peak_gpm}"
      end

      # Calculate the mean value
      mean_value = total / count
      
      # Print the statistics
      puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end
  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
#==============================================================================
# Define database fields for ICM network nodes
database_fields = [
  'trade_flow',
  'base_flow',
  'additional_foul_flow',
  'user_number_1'
]

net.clear_selection
puts "Scenario     : #{net.current_scenario}"

# Prepare hash for storing data of each field for database_fields
fields_data = {}
database_fields.each { |field| fields_data[field] = [] }

# Initialize the count of processed rows
row_count = 0
total_expected = 0.0

# Collect data for each field from hw_subcatchment
net.row_objects('hw_subcatchment').each do |ro|
  row_count += 1
  database_fields.each do |field|
    fields_data[field] << ro[field] if ro[field]
  end
end

# Print min, max, mean, standard deviation, total, and row count for each field
database_fields.each do |field|
  data = fields_data[field]
  if data.empty?
    #puts "#{field} has no data!"
    next
  end

  min_value = data.min
  max_value = data.max
  sum = data.inject(0.0) { |sum, val| sum + val }
  mean_value = sum / data.size
  # Calculate the standard deviation
  sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
  standard_deviation = Math.sqrt(sum_of_squares / data.size)
  total_value = sum

  # Updated printf statement with row count
  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
        field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
end