require 'date'

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

# Global accumulators for total raw QNODE and QRAIN across all HW Nodes
$global_qnode_total = 0.0
$global_qrain_total = 0.0

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
      extra_info = ""
      if type == 'HW Node' && (field_name.upcase == 'QNODE' || field_name.upcase == 'QRAIN')
        extra_info = " | Raw Sum: #{'%15.4f' % total}"
        # Accumulate totals for all selected nodes
        if field_name.upcase == 'QNODE'
          $global_qnode_total += total
        elsif field_name.upcase == 'QRAIN'
          $global_qrain_total += total
        end
      end
      
      puts "#{type}: #{'%-12s' % asset_id} | #{'%-16s' % field_name} | Sum: #{'%15.4f' % total_integrated} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}#{extra_info}"
    rescue => e
      # Optionally log errors:
      # puts "Error processing field #{field_name} for asset #{asset_id}: #{e.message}"
    end
  end
end

begin
  cn = WSApplication.current_network
  ts = cn.list_timesteps
  ts_size = ts.count
  puts "Time step size: #{ts_size}"
  ts = cn.list_timesteps
  time_interval = ts.size > 1 ? (ts[1] - ts[0]).abs * 24 * 60 * 60 : 0
  puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60]
  puts

  # Print table details (optional)
  print_table_results(cn)

  # Define the result fields for HW Node, HW Conduit, and HW Pump assets.
  HW_NODE_FIELDS = %w[DEPNOD FLOOD_LEVEL FLOODDEPTH FLOODVOLUME FLVOL MAX_DEPNOD MAX_FLOODDEPTH MAX_FLOODVOLUME MAX_FLVOL MAX_QINFNOD MAX_QNODE MAX_QRAIN QINCUM QINFNOD QNODE QRAIN VFLOOD VGROUND MAX_VOLUME VOLBAL VOLUME PCVOLBAL]
  HW_CONDUIT_FIELDS = %w[HEIGHT HYDGRAD LENGTH MAX_QINFLNK MAX_QLINK MAX_SURCHARGE MAX_US_DEPTH MAX_US_FLOW MAX_US_FROUDE MAX_US_TOTALHEAD MAX_US_VEL MAXSURCHARGESTATE PFC QINFLNK QLICUM QLINK SURCHARGER TYPE US_DEPTH US_FLOW US_FROUDE US_INVERT US_QCUM US_TOTALHEAD US_VEL VOLUME DS_DEPTH DS_FLOW DS_FROUDE DS_INVERT DS_QCUM DS_TOTALHEAD DS_VEL MAX_DS_DEPTH MAX_DS_FLOW MAX_DS_FROUDE MAX_DS_TOTALHEAD MAX_DS_VEL]
  HW_PUMP_FIELDS = HW_CONDUIT_FIELDS.dup

  # Process each selected asset. No CSV file is created.
  cn.each_selected do |asset|
    begin
      ro_node = cn.row_object('hw_node', asset.id)
      process_results(ro_node, asset.id, HW_NODE_FIELDS, time_interval, ts_size, 'HW Node') if ro_node
      
      ro_conduit = cn.row_object('hw_conduit', asset.id)
      process_results(ro_conduit, asset.id, HW_CONDUIT_FIELDS, time_interval, ts_size, 'HW Conduit') if ro_conduit
      
      ro_pump = cn.row_object('hw_pump', asset.id)
      process_results(ro_pump, asset.id, HW_PUMP_FIELDS, time_interval, ts_size, 'HW Pump') if ro_pump
    rescue => e
      puts "Error processing asset ID #{asset.id}: #{e.message}"
    end
  end

  # After processing all assets, print aggregated totals for QNODE and QRAIN raw sums.
  puts "\nAggregated Integrated Totals for all selected HW Nodes (Raw Sum * time_interval):"
  puts "Total QNODE Integrated Sum: #{'%15.4f' % ($global_qnode_total * time_interval)}"
  puts "Total QRAIN Integrated Sum: #{'%15.4f' % ($global_qrain_total * time_interval)}"

rescue => e
  puts "An error occurred: #{e.message}"
end