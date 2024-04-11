# Import the 'date' library
require 'csv'
require 'date'

# Initialize an array to store all statistics
all_stats = []

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected Subcatchments
field_names = [
  'qfoul', 'qtrade', 'rainfall', 'evaprate', 'grndstor', 'soilstor', 'qsoil',
  'qinfsoil', 'qrdii', 'qinfilt', 'qinfgrnd', 'qground', 'plowfw', 'plowsnow',
  'impfw', 'pervfw', 'impmelt', 'pervmelt', 'impsnow', 'pervsnow', 'losttogw',
  'napi', 'qcatch', 'q_lid_in', 'q_lid_out', 'q_lid_drain', 'q_exceedance',
  'rainprof', 'effrain', 'qbase', 'v_exceedance', 'runoff', 'qsurf01',
  'qsurf02', 'qsurf03', 'qsurf04', 'qsurf05', 'qsurf06', 'qsurf07', 'qsurf08',
  'qsurf09', 'qsurf10', 'qsurf11', 'qsurf12'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    ro = net.row_object('_subcatchments', sel.id)
    raise "Object with ID #{sel.id} is not a subcatchment." if ro.nil?

    field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        if rs_size == ts_size
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0

          # Assuming the time steps are evenly spaced, calculate the time interval in seconds
          time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1

          ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            total_integrated_over_time += result.to_f * time_interval 
            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          mean_value = count > 0 ? total / count : 0

          total_integrated_over_time /= 3600.0 if res_field_name == 'rainfall'
          total_integrated_over_time = total_integrated_over_time * 12.0 / (sel.total_area * 43560.0) if res_field_name != 'rainfall'      
          (1..12).each do |i|
            field_name = "qsurf%02d" % i
            area_percent_key = "area_percent_#{i}".to_sym
          
            if res_field_name == field_name && sel.respond_to?(area_percent_key)
              area_percent_value = sel.send(area_percent_key) / 100.0
              puts area_percent_value
              total_integrated_over_time *= area_percent_value
            end
          end

          # Save statistics in the array
          all_stats << {
            subcatchment_id: sel.id,
            field_name: res_field_name,
            sum: total_integrated_over_time ,
            mean: mean_value,
            max: max_value,
            min: min_value,
            steps: count,
            area: sel.total_area
          }
        end

      rescue
        next
      end
    end

  rescue => e
    next
  end
end

# Print the summary header
puts '  *******************************************'
puts '  Subcatchment Runoff Summary (ICM InfoWorks)'
puts '  *******************************************'
puts ''
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts '                            Total      Total      Total      Total    qsurf01    qsurf02      Total       Total     Peak     Runoff    qsurf03    qsurf04    qsurf05    qsurf06    qsurf07    qsurf08    qsurf09    qsurf10    qsurf11    qsurf12'
puts '                           Precip      Runon       Evap      Infil     Runoff     Runoff     Runoff      Runoff   Runoff      Coeff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff'
puts '  Subcatchment                 in         in         in         in         in         in         in    10^6 ltr      MGD                    in         in         in         in         in         in         in         in         in         in'
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'

field_width = 10 # Width for the field value
id_width = 21   # Width for the subcatchment ID 

# Initialize a hash to store aggregated data for each subcatchment
aggregated_data = {}

# Aggregate data
all_stats.each do |stat|
  sub_id = stat[:subcatchment_id]
  field_name = stat[:field_name]

  # Initialize subcatchment data if not already present
  aggregated_data[sub_id] ||= {}

  # Store all the statistics for the corresponding field
  aggregated_data[sub_id][field_name] = stat
end

# Print the aggregated data for each subcatchment
aggregated_data.each do |sub_id, data|
  output_line = "#{'%*s ' % [id_width, sub_id]}"

  # Append stats for specific fields to the output line
  # Example for rainfall
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:min]]}"
  end
  if data['evaprate']
    stats = data['evaprate']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qinfsoil']
    stats = data['qinfsoil']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf01']
    stats = data['qsurf01']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf02']
    stats = data['qsurf02']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['runoff']
    stats = data['runoff']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end

  # Similar blocks can be added for other fields like 'evaprate', 'qinfsoil', etc.

  # Example for runoff (with specific calculations for second and third runoff values)
  if data['runoff']
    stats = data['runoff']
    second_runoff = stats[:sum] * 43560.0 / 12.0 *  stats[:area] 
    third_runoff  = stats[:max] 
    output_line += " #{'%*.4f' % [field_width, second_runoff]}"
    output_line += " #{'%*.4f' % [field_width, third_runoff]}"
  end

  # Calculate and append runoff coefficient (RC)
rainfall_sum = data['rainfall'] ? data['rainfall'][:sum] : 0
runoff_sum = data['runoff'] ? data['runoff'][:sum] : 0

# Ensure rainfall_sum is not zero to avoid division by zero
if rainfall_sum > 0
  rc = runoff_sum / rainfall_sum
  output_line += " #{'%*.3f' % [field_width, rc]}"
else
  output_line += " #{'%*s' % [field_width, 'N/A']}"  # If no rainfall data, RC cannot be computed
end

# Check and append qsurf03 to qsurf12
(3..12).each do |i|
  key = "qsurf%02d" % i  # Generates qsurf03, qsurf04, ..., qsurf12
  if data[key]
    stats = data[key]
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
end

  puts output_line
end