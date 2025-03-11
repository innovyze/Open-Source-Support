require 'date'
require 'csv'

def print_table_results(cn)
  puts "\nTime-Integrated Link and Load Information Evaluation"
  puts "HW Tables and their result fields in this ICM Infoworks Run\n"
  
  cn.tables.each do |table|
    results_array = []
    found_results = false

    cn.row_object_collection(table.name).each do |row_object|
      if row_object.table_info.results_fields && !found_results
        row_object.table_info.results_fields.each { |field| results_array << field.name }
        found_results = true
        break
      end
    end

    next if results_array.empty?
    
    puts "Table: #{table.name.upcase}"
    results_array.each { |field| puts "Result field: #{field}" }
    puts
  end
end

def calculate_statistics(data)
  data.each do |param, entries|
    entries.each do |id, values|
      next if values.empty?
      
      total = values.sum
      count = values.size
      mean_value = total / count
      min_value = values.min
      max_value = values.max

      puts "Parameter: #{param} | ID: #{id} | Sum: #{'%15.4f' % total} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    end
  end
end

def process_results(ro, asset_id, field_names, time_interval, ts_size, type)
  field_names.each do |field_name|
    begin
      rs_size = ro.results(field_name).count
      next unless rs_size == ts_size

      total = 0.0
      total_integrated = 0.0
      min_value = Float::INFINITY
      max_value = -Float::INFINITY
      count = 0

      ro.results(field_name).each do |result|
        value = result.to_f
        total += value
        total_integrated += value * time_interval
        min_value = [min_value, value].min
        max_value = [max_value, value].max
        count += 1
      end

      mean_value = count > 0 ? total / count : 0
      puts "#{type}: #{'%-12s' % asset_id} | #{'%-16s' % field_name} | Sum: #{'%15.4f' % total_integrated} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    rescue
      next
    end
  end
end

begin
  cn = WSApplication.current_network
  result = WSApplication.prompt "Select an Output CSV File",
    [
      ['RPT File', 'String', nil, nil, 'FILE', true, '*.*', 'csv', false],
      ['Read the CSV File', 'Boolean', true],
      ['Stats for Tables', 'Boolean', true]
    ], false

  if result.nil?
    puts "File selection cancelled"
    exit
  end

  puts "Selected file: #{result[0]}"
  ts_size = cn.list_timesteps.count
  puts "Time step size: #{ts_size}"
  
  ts = cn.list_timesteps
  time_interval = ts.size > 1 ? (ts[1] - ts[0]).abs * 24 * 60 * 60 : 0
  puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60]
  puts

  print_table_results(cn) if result[2]

  HW_NODE_FIELDS = %w[DEPNOD FLOOD_LEVEL FLOODDEPTH FLOODVOLUME FLVOL MAX_DEPNOD MAX_FLOODDEPTH MAX_FLOODVOLUME MAX_FLVOL MAX_QINFNOD MAX_QNODE MAX_QRAIN QINCUM QINFNOD QNODE QRAIN VFLOOD VGROUND MAX_VOLUME VOLBAL VOLUME PCVOLBAL]
  HW_CONDUIT_FIELDS = %w[HEIGHT HYDGRAD LENGTH MAX_QINFLNK MAX_QLINK MAX_SURCHARGE MAX_US_DEPTH MAX_US_FLOW MAX_US_FROUDE MAX_US_TOTALHEAD MAX_US_VEL MAXSURCHARGESTATE PFC QINFLNK QLICUM QLINK SURCHARGE TYPE US_DEPTH US_FLOW US_FROUDE US_INVERT US_QCUM US_TOTALHEAD US_VEL VOLUME DS_DEPTH DS_FLOW DS_FROUDE DS_INVERT DS_QCUM DS_TOTALHEAD DS_VEL MAX_DS_DEPTH MAX_DS_FLOW MAX_DS_FROUDE MAX_DS_TOTALHEAD MAX_DS_VEL]

  if result[1]
    # Read and parse the CSV file matching the provided format
    csv_data = CSV.read(result[0], headers: true)  # Use headers: true to treat the first row as headers
    data = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = [] } }

    # Extract parameter names from headers
    params = csv_data.headers

    # Process each row of the CSV file
    csv_data.each do |row|
      id = row[0]  # First column is the ID
      params.each_with_index do |param, index|
        next if index == 0  # Skip the first column (ID)
        value = row[param].to_f
        data[param][id] << value
      end
    end

    calculate_statistics(data)
  else
    cn.each_selected do |asset|
      begin
        ro_node = cn.row_object('hw_node', asset.id)
        process_results(ro_node, asset.id, HW_NODE_FIELDS, time_interval, ts_size, 'HW Node') if ro_node
        
        ro_conduit = cn.row_object('hw_conduit', asset.id)
        process_results(ro_conduit, asset.id, HW_CONDUIT_FIELDS, time_interval, ts_size, 'HW Conduit') if ro_conduit
      rescue => e
        puts "Error processing asset ID #{asset.id}: #{e.message}"
      end
    end
  end

rescue => e
  puts "An error occurred: #{e.message}"
end