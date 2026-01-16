# Combined Results Field Exporter with Automatic Field Detection and Statistics
#
# This script automatically detects result fields from the simulation,
# exports user-selected result data to CSV files, and calculates statistics.
# No external parameter files needed - it reads fields directly from the results.
# Uses ICM UI prompts for all user interaction.

require 'csv'
require 'fileutils'
require 'date'

# --- Helper Functions for Statistics ---
def calculate_mean(arr)
  return nil if arr.nil? || arr.empty?
  arr.sum.to_f / arr.length
end

def calculate_std_dev(arr, mean)
  return nil if arr.nil? || arr.empty? || mean.nil? || arr.length < 2
  sum_sq_diff = arr.map { |x| (x - mean)**2 }.sum
  Math.sqrt(sum_sq_diff / (arr.length.to_f - 1.0))
end

# --- Safe numeric formatting ---
def safe_format(value, decimals = 4)
  return "0.0000" if value.nil?
  return "0.0000" unless value.respond_to?(:to_f)
  
  float_val = value.to_f
  return "0.0000" unless float_val.finite?
  
  begin
    sprintf("%.#{decimals}f", float_val)
  rescue
    "0.0000"
  end
end

# --- Get Result Fields from Network ---
# Extracts all available result fields from the current network
def get_result_fields_from_network(cn)
  tables_with_results = {}
  
  puts "\nScanning network for result fields..."
  
  # Iterate over each table in the network
  cn.tables.each do |table|
    results_array = []
    found_results = false

    # Check each row object in the current table
    begin
      cn.row_object_collection(table.name).each do |row_object|
        # Check if the row object has a 'results_fields' property
        if row_object.respond_to?(:table_info) && 
           row_object.table_info.respond_to?(:results_fields) && 
           row_object.table_info.results_fields && 
           !found_results
          
          # Add the field names to the results_array
          row_object.table_info.results_fields.each do |field|
            results_array << field.name
          end
          found_results = true
          break  # Exit after finding the first object with results
        end
      end
    rescue => e
      #puts "Warning: Could not check table '#{table.name}' for results: #{e.message}"
    end

    # Store the results if any were found
    unless results_array.empty?
      tables_with_results[table.name] = results_array
      puts "  - #{table.name}: found #{results_array.length} result fields"
    end
  end
  
  if tables_with_results.empty?
    puts "No result fields found in any tables."
  else
    puts "Found result fields in #{tables_with_results.keys.length} tables."
  end
  
  tables_with_results
end

# --- UI-based field selection ---
def get_user_field_selection_ui(table_name, available_fields)
  # Create checkbox prompts for all fields
  field_prompts = [["Select ALL FIELDS", 'Boolean', false]]
  
  available_fields.each do |field|
    field_prompts << [field, 'Boolean', false]
  end
  
  user_selections = WSApplication.prompt(
    "Select #{table_name} Result Fields to Export",
    field_prompts,
    false
  )
  
  return [] if user_selections.nil?
  
  selected_fields = []
  select_all = user_selections[0]
  
  # Process selections (skip index 0 which is SELECT ALL)
  available_fields.each_with_index do |field, index|
    if select_all || user_selections[index + 1]
      selected_fields << field
    end
  end
  
  selected_fields
end

# --- Get export options via UI ---
def get_export_options_ui(table_name)
  # Get the user's desktop path
  desktop_path = File.join(ENV['HOME'] || ENV['USERPROFILE'], 'Desktop')
  
  options_prompts = [
    ['Export Folder', 'String', desktop_path, nil, 'FOLDER', 'Select Export Folder'],
    ['Calculate Statistics', 'Boolean', true],
    ['Export Time Series Data', 'Boolean', true],
    ['Export Summary Statistics', 'Boolean', true]
  ]
  
  user_options = WSApplication.prompt(
    "Export Options for #{table_name}",
    options_prompts,
    false
  )
  
  return nil if user_options.nil?
  
  {
    folder: user_options[0],
    calculate_stats: user_options[1],
    export_time_series: user_options[2],
    export_summary: user_options[3]
  }
end

# --- Process Single Table Results Export ---
def process_single_table_results(cn, selected_table_name, available_result_fields, timesteps, time_interval)
  puts "\n#{'='*20} Processing Table: #{selected_table_name.upcase} #{'='*20}"
  start_time = Time.now

  result_fields = available_result_fields[selected_table_name]
  if result_fields.nil? || result_fields.empty?
    WSApplication.message_box(
      "No result fields found for '#{selected_table_name}'.",
      'OK',
      nil,
      false
    )
    return false
  end
  
  puts "Found #{result_fields.length} result fields for '#{selected_table_name}'."

  # Get field selection
  selected_fields = get_user_field_selection_ui(selected_table_name, result_fields)
  
  if selected_fields.empty?
    puts "No fields selected for export from '#{selected_table_name}'. Skipping."
    return false
  end
  
  # Get export options
  options = get_export_options_ui(selected_table_name)
  return false if options.nil?
  
  export_folder = options[:folder]
  calculate_stats = options[:calculate_stats]
  export_time_series = options[:export_time_series]
  export_summary = options[:export_summary]
  
  # Check if we're exporting to CSV
  export_to_csv = !export_folder.empty? && (export_summary || export_time_series)
  
  if export_to_csv
    begin
      Dir.mkdir(export_folder) unless Dir.exist?(export_folder)
    rescue => e
      WSApplication.message_box(
        "Could not create directory '#{export_folder}': #{e.message}\n\nProceeding with statistics only.",
        'OK',
        nil,
        false
      )
      export_to_csv = false
    end
  end
  
  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  
  puts "Processing #{selected_fields.length} fields..."

  # Track overall progress
  total_objects_processed = 0
  field_summaries = []

  # Process each selected field
  selected_fields.each_with_index do |field_name, field_index|
    field_start_time = Time.now
    puts "\nProcessing field #{field_index + 1}/#{selected_fields.length}: #{field_name}"
    
    # Prepare file paths
    summary_file_path = nil
    timeseries_file_path = nil
    
    if export_to_csv
      summary_file_path = File.join(export_folder, "#{selected_table_name}_#{field_name}_summary_#{timestamp}.csv") if export_summary
      timeseries_file_path = File.join(export_folder, "#{selected_table_name}_#{field_name}_timeseries_#{timestamp}.csv") if export_time_series
    end
    
    # Data collection
    objects_processed = 0
    summary_data = []
    
    # CSV files
    summary_csv = nil
    timeseries_csv = nil
    
    begin
      if export_to_csv
        # Open summary CSV
        if summary_file_path
          summary_csv = CSV.open(summary_file_path, "w")
          summary_headers = ['Object_ID', 'Field', 'Count', 'Min', 'Max', 'Mean', 'StdDev', 'Sum']
          summary_csv << summary_headers
        end
        
        # Open time series CSV if requested
        if timeseries_file_path
          timeseries_csv = CSV.open(timeseries_file_path, "w")
          # Header: Object_ID, Timestep_1, Timestep_2, ...
          timeseries_headers = ['Object_ID'] + timesteps.map { |ts| ts.strftime('%Y-%m-%d %H:%M:%S') }
          timeseries_csv << timeseries_headers
        end
      end
      
      # Process objects
      row_objects = cn.row_objects(selected_table_name)
      
      row_objects.each do |obj|
        # Skip if object is not selected
        next unless obj.respond_to?(:selected) && obj.selected
        
        obj_id = obj.respond_to?(:id) ? obj.id : "Object_#{objects_processed + 1}"
        
        begin
          # Get results for this field
          results = obj.results(field_name)
          
          if results && results.count > 0
            # Collect data - ensure all values are numeric and valid
            values = []
            results.each do |result|
              begin
                val = result.to_f
                values << (val.finite? ? val : 0.0)
              rescue
                values << 0.0
              end
            end
            
            # Calculate statistics
            min_val = values.min
            max_val = values.max
            mean_val = calculate_mean(values)
            std_dev = calculate_std_dev(values, mean_val)
            sum_val = values.sum
            
            # Store summary data - ensure all values are properly formatted
            summary_row = [
              obj_id, 
              field_name, 
              values.count, 
              min_val.round(6), 
              max_val.round(6), 
              mean_val.round(6), 
              std_dev ? std_dev.round(6) : 0.0, 
              sum_val.round(6)
            ]
            
            # Write to summary CSV
            summary_csv << summary_row if summary_csv
            
            # Print to console if calculating stats
            if calculate_stats
              begin
                puts "#{selected_table_name}: #{'%-12s' % obj_id} | #{'%-16s' % field_name} | End: #{safe_format(values.last, 4)} | Mean: #{safe_format(mean_val, 4)} | Max: #{safe_format(max_val, 4)} | Min: #{safe_format(min_val, 4)} | Steps: #{'%6d' % values.count}"
              rescue => e
                puts "#{selected_table_name}: #{obj_id} | #{field_name} | Error formatting statistics: #{e.message}"
              end
            end
            
            # Write time series data
            if timeseries_csv
              # Round values for CSV output to avoid precision issues
              timeseries_row = [obj_id] + values.map { |v| v.round(6) }
              timeseries_csv << timeseries_row
            end
            
            objects_processed += 1
          end
          
        rescue => e
          #puts "Warning: Could not process results for object '#{obj_id}', field '#{field_name}': #{e.message}"
        end
      end
      
    ensure
      summary_csv.close if summary_csv
      timeseries_csv.close if timeseries_csv
    end
    
    # Field summary
    field_time = Time.now - field_start_time
    field_summary = "Field '#{field_name}': #{objects_processed} objects in #{'%.2f' % field_time}s"
    
    if export_to_csv && objects_processed > 0
      field_summary += "\n  Summary: #{summary_file_path}" if summary_file_path
      field_summary += "\n  Time series: #{timeseries_file_path}" if timeseries_file_path
    end
    
    field_summaries << field_summary
    total_objects_processed += objects_processed
    
    puts "\n#{field_summary}"
  end
  
  time_spent = Time.now - start_time
  
  # Show summary dialog
  summary_message = "Table: #{selected_table_name}\n"
  summary_message += "Total objects processed: #{total_objects_processed}\n"
  summary_message += "Processing time: #{'%.2f' % time_spent} seconds\n\n"
  summary_message += "Fields processed:\n"
  field_summaries.each { |fs| summary_message += "- #{fs}\n" }
  
  WSApplication.message_box(
    summary_message,
    'OK',
    nil,
    false
  )
  
  return true
end

# --- UI-based table selection ---
def get_user_table_selection_ui(available_tables)
  # Create checkbox prompts for all tables
  table_prompts = [["Select ALL TABLES", 'Boolean', false]]
  
  available_tables.each do |table|
    table_prompts << [table, 'Boolean', false]
  end
  
  user_selections = WSApplication.prompt(
    "Select Tables to Export Results",
    table_prompts,
    false
  )
  
  return [] if user_selections.nil?
  
  selected_tables = []
  select_all = user_selections[0]
  
  # Process selections (skip index 0 which is SELECT ALL)
  available_tables.each_with_index do |table, index|
    if select_all || user_selections[index + 1]
      selected_tables << table
    end
  end
  
  selected_tables
end

# --- Main Script Logic ---
def run_results_export_script
  overall_start_time = Time.now
  puts "Starting Results Field Exporter at #{overall_start_time}"
  puts "=" * 60

  # Connect to current network
  begin
    cn = WSApplication.current_network
    raise "No network loaded." if cn.nil?
  rescue => e
    WSApplication.message_box(
      "Could not access current network.\n\nPlease ensure a network is loaded and try again.",
      'OK',
      nil,
      false
    )
    return
  end

  # Get timesteps
  begin
    timesteps = cn.list_timesteps
    if timesteps.nil? || timesteps.empty?
      WSApplication.message_box(
        "No timesteps found.\n\nPlease ensure you have simulation results loaded.",
        'OK',
        nil,
        false
      )
      return
    end
    
    ts_count = timesteps.count
    time_interval = 0
    
    if ts_count > 1
      time_interval = (timesteps[1] - timesteps[0]).abs
    end
    
    # Show simulation info
    sim_info = "Simulation Information:\n"
    sim_info += "- Total timesteps: #{ts_count}\n"
    sim_info += "- Start time: #{timesteps.first}\n"
    sim_info += "- End time: #{timesteps.last}\n"
    sim_info += "- Time interval: %.4f seconds (%.4f minutes)" % [time_interval, time_interval / 60.0] if ts_count > 1
    
    puts sim_info
    
  rescue => e
    WSApplication.message_box(
      "Could not get timesteps: #{e.message}",
      'OK',
      nil,
      false
    )
    return
  end

  # Get result fields from network
  available_tables_with_results = get_result_fields_from_network(cn)
  
  if available_tables_with_results.empty?
    WSApplication.message_box(
      "No result fields found in the network.\n\nPlease ensure you have simulation results loaded.",
      'OK',
      nil,
      false
    )
    return
  end

  # Show initial information dialog
  info_message = "Results Export Ready\n\n"
  info_message += "Found result fields in #{available_tables_with_results.keys.length} tables:\n"
  available_tables_with_results.each do |table, fields|
    info_message += "- #{table}: #{fields.length} fields\n"
  end
  info_message += "\nTime interval: %.4f seconds" % time_interval if ts_count > 1
  
  continue = WSApplication.message_box(
    info_message + "\n\nProceed with export?",
    'YESNO',
    nil,
    false
  )
  
  return if continue == 'NO'

  # Main export loop
  table_names = available_tables_with_results.keys.sort
  total_tables_exported = 0
  continue_exporting = true
  
  while continue_exporting
    selected_tables = get_user_table_selection_ui(table_names)
    
    if selected_tables.empty?
      WSApplication.message_box(
        "No tables selected.",
        'OK',
        nil,
        false
      )
      break
    end

    puts "\nSelected tables: #{selected_tables.join(', ')}"

    tables_processed = 0
    selected_tables.each do |table_name|
      begin
        if process_single_table_results(cn, table_name, available_tables_with_results, timesteps, time_interval)
          total_tables_exported += 1
          tables_processed += 1
        end
      rescue => e
        puts "Error processing table '#{table_name}': #{e.message}"
        error_choice = WSApplication.message_box(
          "Error processing table '#{table_name}':\n#{e.message}\n\nContinue with remaining tables?",
          'YESNO',
          nil,
          false
        )
        break if error_choice == 'NO'
      end
    end

    # Ask if user wants to continue
    batch_message = "Batch complete!\n\nTables processed: #{tables_processed}"
    
    continue_choice = WSApplication.message_box(
      batch_message + "\n\nProcess more tables?",
      'YESNO',
      nil,
      false
    )
    
    continue_exporting = (continue_choice == 'YES')
  end

  # Final Summary
  overall_end_time = Time.now
  total_time_spent = overall_end_time - overall_start_time
  
  final_message = "Export Complete!\n\n"
  final_message += "Total tables exported: #{total_tables_exported}\n"
  final_message += "Total execution time: #{'%.2f' % total_time_spent} seconds"
  
  WSApplication.message_box(
    final_message,
    'OK',
    nil,
    false
  )
  
  puts "\n#{'='*25} Script Complete #{'='*25}"
  puts "Total tables exported: #{total_tables_exported}"
  puts "Total execution time: #{'%.2f' % total_time_spent} seconds"
end

# Run the script
run_results_export_script