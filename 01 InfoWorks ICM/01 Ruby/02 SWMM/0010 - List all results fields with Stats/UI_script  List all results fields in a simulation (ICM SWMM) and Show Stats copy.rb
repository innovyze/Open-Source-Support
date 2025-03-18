require 'date'
require 'csv'

def print_table_results(cn)
  puts "\nTime-Integrated Link and Load Information Evaluation"
  puts "SW Tables and their result fields in this ICM SWMM Run\n"
  
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

def process_results(ro, asset_id, field_names, time_interval, ts_size, type, csv_data, csv_headers, csv_ids)
  field_names.each do |field_name|
    begin
      rs_size = ro.results(field_name).count
      next unless rs_size == ts_size

      total = 0.0
      total_integrated = 0.0
      min_value = Float::INFINITY
      max_value = -Float::INFINITY
      count = 0
      csv_column = []

      csv_headers << field_name
      csv_ids << asset_id

      ro.results(field_name).each do |result|
        value = result.to_f
        total += value
        total_integrated += value * time_interval
        min_value = [min_value, value].min
        max_value = [max_value, value].max
        count += 1
        csv_column << value
      end

      mean_value = count > 0 ? total / count : 0
      puts "#{type}: #{'%-12s' % asset_id} | #{'%-16s' % field_name} | Sum: #{'%15.4f' % total_integrated} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"

      csv_column.each_with_index do |value, index|
        csv_data[index + 2] ||= []
        csv_data[index + 2] << value
      end
    rescue
      next
    end
  end
end

begin
  cn = WSApplication.current_network
  ts_size = cn.list_timesteps.count
  puts "Time step size: #{ts_size}"

  result = WSApplication.prompt "Select an Output CSV File",
    [
      ['RPT File', 'String', nil, nil, 'FILE', true, '*.*', 'csv', false],
      ['Make the CSV File', 'Boolean', true]
    ], false

  if result.nil?
    puts "File selection cancelled"
    exit
  end

  puts "Selected file: #{result[0]}"
  ts = cn.list_timesteps
  time_interval = ts.size > 1 ? (ts[1] - ts[0]).abs * 24 * 60 * 60 : 0
  puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60]
  puts

  print_table_results(cn)

  SW_CONDUIT_FIELDS = %w[FLOW MAX_FLOW DEPTH MAX_VELOCITY VELOCITY HGL FLOW_VOLUME FLOW_CLASS CAPACITY MAX_CAPACITY SURCHARGED ENTRY_LOSS EXIT_LOSS]
  SW_NODE_FIELDS = %w[DEPTH MAX_DEPTH HEAD MAX_HEAD VOLUME LATERAL_INFLOW MAX_TOTAL_INFLOW TOTAL_INFLOW FLOODING PRESSURE INVERT_ELEVATION HEAD_CLASS TOTAL_FLOOD_VOLUME TOTAL_FLOOD_TIME FLOW_VOLUME_DIFFERENCE TOTAL_INFLOW_VOLUME]

  csv_data = []
  csv_headers = []
  csv_ids = []
  csv_data << csv_headers << csv_ids

  cn.each_selected do |sel|
    begin
      ro_node = cn.row_object('sw_node', sel.id)
      process_results(ro_node, sel.id, SW_NODE_FIELDS, time_interval, ts_size, 'Node', csv_data, csv_headers, csv_ids) if ro_node

      ro_conduit = cn.row_object('sw_conduit', sel.id)
      process_results(ro_conduit, sel.id, SW_CONDUIT_FIELDS, time_interval, ts_size, 'Link', csv_data, csv_headers, csv_ids) if ro_conduit
    rescue => e
      puts "Error processing asset ID #{sel.id}: #{e.message}"
    end
  end

  if result[1]
    CSV.open(result[0], "wb") do |csv|
      csv_data.each { |row| csv << row }
    end
    puts "CSV file saved: #{result[0]}"
  end

rescue => e
  puts "An error occurred: #{e.message}"
end