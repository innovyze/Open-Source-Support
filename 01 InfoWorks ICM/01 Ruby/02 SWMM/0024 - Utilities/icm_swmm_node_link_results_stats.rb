require 'date'

def print_table_results(cn)
  puts "\nTime-Integrated Link and Load Information Evaluation"
  puts "SW Tables and their result fields in this ICM SWMM Run\n"

  cn.tables.each do |table|
    results_array = []
    found_results = false

    begin
      cn.row_object_collection(table.name).each do |row_object|
        # Check if results_fields is available; fallback to predefined fields if not
        if row_object.respond_to?(:table_info) && row_object.table_info.respond_to?(:results_fields) && !found_results
          row_object.table_info.results_fields.each { |field| results_array << field.name }
          found_results = true
          break
        end
      end
    rescue NoMethodError => e
      # Optionally print a warning:
      # puts "Warning: Could not retrieve results_fields for table #{table.name}: #{e.message}"
      next
    end

    next if results_array.empty?

    puts "Table: #{table.name.upcase}"
    results_array.each { |field| puts "Result field: #{field}" }
    puts
  end
end

# Global accumulators for total raw values across all SW Nodes
$global_qnode_total           = 0.0  # (if used elsewhere)
$global_qrain_total           = 0.0  # (if used elsewhere)
$global_lateral_inflow_total  = 0.0
$global_total_inflow_total    = 0.0

def process_results(ro, asset_id, field_names, time_interval, ts_size, type)
  return unless ro  # Skip if row object is nil

  field_names.each do |field_name|
    begin
      results = ro.results(field_name)
      rs_size = results&.count || 0
      next unless rs_size == ts_size && rs_size > 0

      total = 0.0
      total_integrated = 0.0
      min_value = Float::INFINITY
      max_value = -Float::INFINITY
      count = 0

      results.each do |result|
        value = result.to_f
        total += value
        total_integrated += value * time_interval
        min_value = [min_value, value].min
        max_value = [max_value, value].max
        count += 1
      end

      mean_value = count > 0 ? total / count : 0

      # For SW Node, accumulate lateral and total inflow raw totals 
      if type == 'Node'
        if field_name.upcase == 'LATERAL_INFLOW'
          $global_lateral_inflow_total += total
        elsif field_name.upcase == 'TOTAL_INFLOW'
          $global_total_inflow_total += total
        end
      end

      puts "#{type}: #{'%-12s' % asset_id} | #{'%-16s' % field_name} | Sum: #{'%15.4f' % total_integrated} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    rescue => e
      # Optional: puts "Error processing field #{field_name} for asset #{asset_id}: #{e.message}"
      next
    end
  end
end

begin
  cn = WSApplication.current_network
  ts = cn.list_timesteps
  ts_size = ts.count
  puts "Time step size: #{ts_size}"
  puts "No CSV file will be written; only statistics will be printed."

  time_interval = if ts.size > 1
                    (ts[1] - ts[0]).abs * 24 * 60 * 60
                  else
                    0.0
                  end
  puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60]
  puts

  print_table_results(cn)

  SW_CONDUIT_FIELDS = %w[FLOW MAX_FLOW DEPTH MAX_VELOCITY VELOCITY HGL FLOW_VOLUME FLOW_CLASS CAPACITY MAX_CAPACITY SURCHARGED ENTRY_LOSS EXIT_LOSS]
  SW_NODE_FIELDS    = %w[DEPTH MAX_DEPTH HEAD MAX_HEAD VOLUME LATERAL_INFLOW MAX_TOTAL_INFLOW TOTAL_INFLOW FLOODING PRESSURE INVERT_ELEVATION HEAD_CLASS TOTAL_FLOOD_VOLUME TOTAL_FLOOD_TIME FLOW_VOLUME_DIFFERENCE TOTAL_INFLOW_VOLUME]
  SW_PUMP_FIELDS    = %w[FLOW]
  SW_ORIFICE_FIELDS = %w[FLOW]
  SW_WEIR_FIELDS    = %w[FLOW]

  # Process each selected asset in the current network
  cn.each_selected do |sel|
    begin
      ro_node = cn.row_object('sw_node', sel.id)
      process_results(ro_node, sel.id, SW_NODE_FIELDS, time_interval, ts_size, 'Node') if ro_node

      ro_conduit = cn.row_object('sw_conduit', sel.id)
      process_results(ro_conduit, sel.id, SW_CONDUIT_FIELDS, time_interval, ts_size, 'Link') if ro_conduit

      ro_pump = cn.row_object('sw_pump', sel.id)
      process_results(ro_pump, sel.id, SW_PUMP_FIELDS, time_interval, ts_size, 'Pump') if ro_pump

      ro_orifice = cn.row_object('sw_orifice', sel.id)
      process_results(ro_orifice, sel.id, SW_ORIFICE_FIELDS, time_interval, ts_size, 'Orifice') if ro_orifice

      ro_weirs = cn.row_object('sw_weirs', sel.id)
      process_results(ro_weirs, sel.id, SW_WEIR_FIELDS, time_interval, ts_size, 'Weirs') if ro_weirs
    rescue => e
      # Optionally log errors:
      # puts "Error processing asset ID #{sel.id}: #{e.message}"
    end
  end

  # After processing all assets, print aggregated global summary for lateral and total inflow.
  puts "\nAggregated Integrated Totals for all selected SW Nodes (Raw Sum * time_interval):"
  puts "Total LATERAL_INFLOW Integrated Sum: #{'%15.4f' % ($global_lateral_inflow_total * time_interval)}"
  puts "Total TOTAL_INFLOW Integrated Sum: #{'%15.4f' % ($global_total_inflow_total * time_interval)}"

rescue => e
  # Optionally log top-level errors:
  # puts "An error occurred: #{e.message}"
end