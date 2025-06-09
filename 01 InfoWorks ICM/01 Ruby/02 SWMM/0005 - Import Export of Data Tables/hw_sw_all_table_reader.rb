# Generic Infoworks/SWMM Object Data Exporter with Statistics
#
# This script allows users to select any object type (e.g., hw_node, sw_subcatchment)
# and specific fields within that object type for export to a CSV file.
# It also calculates basic statistics for numeric fields.
#
# Based on a user-provided parameters.rb file (hw_parameters.rb or sw_parameters.rb)
# for field definitions.

require 'csv'
require 'fileutils'

# --- Helper Functions for Statistics ---
def calculate_mean(arr)
  return nil if arr.nil? || arr.empty?
  arr.sum.to_f / arr.length
end

def calculate_std_dev(arr, mean)
  return nil if arr.nil? || arr.empty? || mean.nil? || arr.length < 2
  sum_sq_diff = arr.map { |x| (x - mean)**2 }.sum
  Math.sqrt(sum_sq_diff / (arr.length.to_f - 1.0)) # Use floating point division for sample std dev
end

# --- Parameters File Parser ---
# Parses the parameters.rb file to get a list of tables and their fields.
# Returns a hash: { "table_name" => ["field1", "field2", ...], ... }
def parse_parameters_file(file_path)
  tables = {}
  current_table_name = nil
  current_fields = []
  # Regex to capture table names like ****hw_node or ****sw_node
  table_name_regex = /^\*{4}((?:sw|hw)_[a-zA-Z0-9_]+)/

  # Field regex: captures primary field names
  field_define_regex = /^\s*\d+\.\s*([a-zA-Z_][a-zA-Z0-9_]*)/

  begin
    File.foreach(file_path) do |line|
      stripped_line = line.strip
      if match = stripped_line.match(table_name_regex)
        if current_table_name && !current_fields.empty?
          tables[current_table_name] = current_fields.uniq
        end
        current_table_name = match[1]
        current_fields = []
      elsif current_table_name && (match = stripped_line.match(field_define_regex))
        field_name = match[1]
        unless field_name.end_with?('_flag')
          current_fields << field_name
        end
      end
    end
    # Save the last table's fields
    if current_table_name && !current_fields.empty?
      tables[current_table_name] = current_fields.uniq
    end
  rescue Errno::ENOENT
    puts "ERROR: Could not find the Parameters file at '#{file_path}'."
    return nil
  rescue => e
    puts "ERROR: Failed to parse Parameters file '#{file_path}': #{e.message}"
    return nil
  end

  if tables.empty?
    puts "Warning: No tables or fields were parsed from '#{file_path}'."
  end
  tables
end

# --- Main Script Logic ---
def run_export_script
  overall_start_time = Time.now
  puts "Starting Generic Object Exporter script at #{overall_start_time}"

  # --- 1. Connect to WSApplication and get current network ---
  begin
    cn = WSApplication.current_network
    raise "No network loaded. Please open a network before running the script." if cn.nil?
  rescue NameError => e
    puts "ERROR: WSApplication not found. Are you running this script within the application environment?"
    return
  rescue => e
    puts "ERROR: Could not get current network. Details: #{e.class} - #{e.message}"
    return
  end

  # --- 2. Prompt for Parameters File Path ---
  parameters_file_path = nil
  begin
    parameters_file_path = WSApplication.file_dialog(
      true, 'rb', 'HW or SW Parameters Ruby File', nil, false, false
    )
    if parameters_file_path.nil?
      puts "User cancelled file selection. Exiting."
      return
    end
    unless File.exist?(parameters_file_path)
      puts "ERROR: The specified Parameters file does not exist: '#{parameters_file_path}'. Exiting."
      return
    end
    puts "Selected parameters file: #{parameters_file_path}"
  rescue => e
    puts "Error during file selection: #{e.message}"
    return
  end

  # --- 3. Parse Parameters File ---
  available_tables_with_fields = parse_parameters_file(parameters_file_path)
  if available_tables_with_fields.nil? || available_tables_with_fields.empty?
    puts "Exiting due to issues parsing Parameters file."
    return
  end
  puts "Successfully parsed #{available_tables_with_fields.keys.length} tables."

  # --- 4. Prompt user to select Object Types (Tables) ---
  selected_tables = []
  begin
    table_names = available_tables_with_fields.keys.sort
    if table_names.empty?
      puts "Error: No tables were found in the parameters file. Exiting."
      return
    end

    table_selection_prompts = table_names.map { |name| [name, 'Boolean', false] }
    user_selections = WSApplication.prompt("Select Object Types to Export", table_selection_prompts, false)

    if user_selections.nil?
      puts "User cancelled table selection. Exiting."
      return
    end

    table_names.each_with_index do |table_name, index|
      selected_tables << table_name if user_selections[index]
    end

    if selected_tables.empty?
      puts "No tables were selected. Exiting."
      return
    end
    puts "User selected the following tables for export: #{selected_tables.join(', ')}"
  rescue => e
    puts "Error during table selection: #{e.message}"
    return
  end

  # --- 5. Main Loop: Process each selected table ---
  selected_tables.each do |selected_table_name|
    puts "\n#{'='*20} Processing Table: #{selected_table_name.upcase} #{'='*20}"
    start_time = Time.now

    object_type_fields = available_tables_with_fields[selected_table_name]
    if object_type_fields.nil? || object_type_fields.empty?
      puts "Error: No fields found for '#{selected_table_name}'. Skipping."
      next
    end
    
    puts "Found #{object_type_fields.length} potential fields for '#{selected_table_name}'."

    # --- 6. Prompt for Fields and Options for the current table ---
    field_prompt_options = [
      ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
      ["SELECT/DESELECT ALL FIELDS for #{selected_table_name}", 'Boolean', false],
      ['Calculate Statistics for Numeric Fields', 'Boolean', true]
    ]
    
    dynamic_fields_to_export_config = object_type_fields.map do |field_name|
      [
        "Include #{field_name.gsub('_', ' ').capitalize}", # Display Label
        field_name.to_sym,                                # Attribute Symbol
        false,                                            # Default check state
        field_name.split('_').map(&:capitalize).join('_') # CSV Header
      ]
    end

    dynamic_fields_to_export_config.each do |field_config|
      field_prompt_options << [field_config[0], 'Boolean', field_config[2]]
    end

    field_dialog_title = "Select options for #{selected_table_name} export"
    chosen_options = WSApplication.prompt(field_dialog_title, field_prompt_options, false)

    if chosen_options.nil?
      puts "User cancelled options for '#{selected_table_name}'. Skipping."
      next
    end

    export_folder = chosen_options[0]
    select_all_fields_state = chosen_options[1]
    calculate_stats = chosen_options[2]

    unless export_folder && !export_folder.empty?
      puts "ERROR: Export folder not specified for '#{selected_table_name}'. Skipping."
      next
    end

    begin
      Dir.mkdir(export_folder) unless Dir.exist?(export_folder)
    rescue => e
      puts "ERROR: Could not create directory '#{export_folder}'. Skipping. - #{e.message}"
      next
    end

    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    file_path = File.join(export_folder, "selected_#{selected_table_name}_export_#{timestamp}.csv")
    
    selected_fields_config_for_export = []
    csv_header_row = []
    field_option_start_index = 3 
    
    dynamic_fields_to_export_config.each_with_index do |field_config_template, index|
      is_selected = chosen_options[index + field_option_start_index]
      if select_all_fields_state || is_selected
        selected_fields_config_for_export << {
          attribute: field_config_template[1],
          header: field_config_template[3],
          original_label: field_config_template[0]
        }
        csv_header_row << field_config_template[3]
      end
    end

    if selected_fields_config_for_export.empty?
      puts "No fields selected for export from '#{selected_table_name}'. Skipping."
      next
    end
    
    puts "Exporting #{selected_fields_config_for_export.length} fields for '#{selected_table_name}'."

    # --- 7. CSV Export Process for the current table ---
    objects_iterated_count = 0
    objects_written_count = 0
    numeric_data_for_stats = {} 

    begin
      CSV.open(file_path, "w") do |csv_file|
        puts "Writing CSV header: #{csv_header_row.join(', ')}"
        csv_file << csv_header_row

        row_objects_iterator = cn.row_objects(selected_table_name)
        raise "Failed to retrieve '#{selected_table_name}' objects." if row_objects_iterator.nil?

        row_objects_iterator.each do |current_obj|
          objects_iterated_count += 1
          obj_id_for_log = (current_obj.respond_to?(:id) && current_obj.id) ? current_obj.id.to_s : "ITER_#{objects_iterated_count}"

          if current_obj && current_obj.respond_to?(:selected) && current_obj.selected
            row_data_values = []
            selected_fields_config_for_export.each do |field_info|
              attr_sym = field_info[:attribute]
              value_for_csv = ""
              value_for_stats = nil
              begin
                raw_value = current_obj.send(attr_sym)
                
                if raw_value.is_a?(Array)
                  case attr_sym
                  when :treatment
                    value_for_csv = raw_value.map { |t|
                      pollutant = t.is_a?(Hash) ? (t[:pollutant] || t['pollutant']) : (t.respond_to?(:pollutant) ? t.pollutant : 'N/A')
                      result_expr = t.is_a?(Hash) ? (t[:result] || t['result']) : (t.respond_to?(:result) ? t.result : 'N/A') 
                      func_expr = t.is_a?(Hash) ? (t[:function] || t['function']) : (t.respond_to?(:function) ? t.function : 'N/A') 
                      "#{pollutant.to_s.gsub(/[;,]/, '')}:#{result_expr.to_s.gsub(/[;,]/, '')}:#{func_expr.to_s.gsub(/[;,]/, '')}"
                    }.join(';')
                  when :pollutant_inflows, :pollutant_dwf
                    value_for_csv = raw_value.map { |pi|
                      pollutant = pi.is_a?(Hash) ? (pi[:pollutant] || pi['pollutant']) : (pi.respond_to?(:pollutant) ? pi.pollutant : 'N/A')
                      conc = pi.is_a?(Hash) ? (pi[:concentration] || pi['concentration'] || pi[:baseline]) : (pi.respond_to?(:concentration) ? pi.concentration : (pi.respond_to?(:baseline) ? pi.baseline : 'N/A'))
                      pattern = pi.is_a?(Hash) ? (pi[:pattern_id] || pi['pattern_id']) : (pi.respond_to?(:pattern_id) ? pi.pattern_id : '')
                      "#{pollutant.to_s.gsub(/[;,]/, '')}:#{conc.to_s.gsub(/[;,]/, '')}" + (pattern.to_s.empty? ? "" : ":#{pattern.to_s.gsub(/[;,]/, '')}")
                    }.join(';')
                  when :additional_dwf 
                     value_for_csv = raw_value.map{|item| 
                        b = item.is_a?(Hash) ? (item[:baseline] || item['baseline']) : (item.respond_to?(:baseline) ? item.baseline : 'N/A')
                        p1 = item.is_a?(Hash) ? (item[:bf_pattern_1] || item['bf_pattern_1']) : (item.respond_to?(:bf_pattern_1) ? item.bf_pattern_1 : '')
                        "B:#{b.to_s.gsub(/[;,]/, '')}|P1:#{p1.to_s.gsub(/[;,]/, '')}"
                     }.join('||')
                  when :hyperlinks
                    value_for_csv = raw_value.map { |hl|
                      desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                      url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                      "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
                    }.join(';')
                  else 
                    value_for_csv = raw_value.map{|item| item.to_s.gsub(/[;,]/, '')}.join(', ')
                  end
                else
                  value_for_csv = (raw_value.nil? ? "" : raw_value)
                  if calculate_stats && !raw_value.nil? && raw_value.to_s != ""
                    begin
                      if raw_value.is_a?(TrueClass)
                        value_for_stats = 1.0
                      elsif raw_value.is_a?(FalseClass)
                        value_for_stats = 0.0
                      else
                        value_for_stats = Float(raw_value)
                      end
                    rescue ArgumentError, TypeError
                    end
                  end
                end
                row_data_values << value_for_csv

                if calculate_stats && !value_for_stats.nil?
                  numeric_data_for_stats[attr_sym] ||= []
                  numeric_data_for_stats[attr_sym] << value_for_stats
                end
              rescue NoMethodError
                puts "Warning (CSV): Attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for Object '#{obj_id_for_log}'."
                row_data_values << "AttributeMissing"
              rescue => e
                puts "Error (CSV): Accessing ':#{attr_sym}' (for '#{field_info[:original_label]}') for Object '#{obj_id_for_log}': #{e.class} - #{e.message}"
                row_data_values << "AccessError"
              end
            end
            csv_file << row_data_values
            objects_written_count += 1
          end
        end
      end
    rescue Errno::EACCES, Errno::ENOSPC, CSV::MalformedCSVError => e
      puts "FATAL ERROR (CSV Export): #{e.class} - #{e.message}"
    rescue => e
      puts "FATAL ERROR (CSV Export): Unexpected failure - #{e.class}: #{e.message}\nBacktrace: #{e.backtrace.first(5).join("\n")}"
    end


    # --- 8. Final Summary & Statistics for the current table ---
    puts "\n--- Processing Summary (#{selected_table_name}) ---"
    puts "Total #{selected_table_name} objects iterated in network: #{objects_iterated_count}"

    if objects_written_count > 0
      puts "Successfully wrote #{objects_written_count} selected objects to #{file_path}"
    else
      puts "No objects were selected or met criteria for export."
      if !file_path.empty? && File.exist?(file_path)
        header_line_content_size = csv_header_row.empty? ? 0 : CSV.generate_line(csv_header_row).bytesize
        newline_size = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? 2 : 1) 
        header_only_file_size = header_line_content_size + (csv_header_row.empty? ? 0 : newline_size)

        if File.size(file_path) <= header_only_file_size
          line_count_in_file = 0
          begin; line_count_in_file = File.foreach(file_path).count; rescue; end
          if line_count_in_file <= (csv_header_row.empty? ? 0 : 1)
            puts "Deleting file as it's empty or contains only the header: #{file_path}"
            File.delete(file_path) rescue puts "Warning: Could not delete empty file #{file_path}."
          end
        end
      end
    end
     
    if objects_written_count > 0 && objects_iterated_count > 0 && objects_written_count < objects_iterated_count
      puts "Note: #{objects_iterated_count - objects_written_count} objects were iterated but not written (likely not selected)."
    end

    if calculate_stats && objects_written_count > 0
      puts "\n--- Statistics for Exported Numeric Fields (#{selected_table_name}) ---"
      param_col_width = 35
      puts "| %-#{param_col_width}s | %-8s | %-12s | %-12s | %-15s | %-15s |" % ["Parameter", "Count", "Min", "Max", "Mean", "Std Dev"]
      puts "-" * (param_col_width + 78)
      
      found_numeric_data_for_table = false
      selected_fields_config_for_export.each do |field_info|
        attr_sym = field_info[:attribute]
        data_array = numeric_data_for_stats[attr_sym]

        header_lower = field_info[:header].downcase
        attr_lower = attr_sym.to_s.downcase
        is_likely_text_or_id = header_lower.end_with?('id', 'type', 'name', 'pattern', 'curve', 'flag', 'code') ||
                               attr_lower.end_with?('_id', '_type', '_name', '_pattern', '_curve', '_flag', '_code') ||
                               header_lower.include?('text') || header_lower.include?('notes') || header_lower.include?('hyperlink') ||
                               attr_lower.include?('text') || attr_lower.include?('notes') || attr_lower.include?('hyperlink')

        if data_array && !data_array.empty? && !is_likely_text_or_id
          found_numeric_data_for_table = true
          mean_val = calculate_mean(data_array)
          std_dev_val = calculate_std_dev(data_array, mean_val)
          display_header = field_info[:header].length > param_col_width ? field_info[:header][0...(param_col_width-3)] + "..." : field_info[:header]

          puts "| %-#{param_col_width}s | %-8d | %-12.3f | %-12.3f | %-15.3f | %-15s |" % [
            display_header,
            data_array.length, 
            data_array.min, 
            data_array.max, 
            mean_val,
            (std_dev_val.nil? ? "N/A (n<2)" : "%.3f" % std_dev_val)
          ]
        end
      end
      puts "-" * (param_col_width + 78)
      unless found_numeric_data_for_table
          puts "No suitable numeric data found among selected fields to calculate statistics."
      end
    elsif calculate_stats
      puts "\nNo objects were written to the CSV, so no statistics calculated."
    end
    
    puts "If 'AttributeMissing' warnings appeared, uncomment a DEBUG block in the script to verify field names."

    time_spent = Time.now - start_time
    puts "Finished processing '#{selected_table_name}' in #{'%.2f' % time_spent} seconds."

    # --- 9. Show per-table summary dialog ---
    if File.exist?(file_path) && objects_written_count > 0
        summary_layout = [
            ['Export File Path', 'READONLY', file_path],
            ["Objects Written", 'NUMBER', objects_written_count],
            ['Fields Exported', 'NUMBER', csv_header_row.count] 
        ]
        WSApplication.prompt("Export Summary: #{selected_table_name}", summary_layout, false)
    else
        WSApplication.message_box("No '#{selected_table_name}' objects were exported.", 'OK', nil, false)
    end
  end # --- End of Main Loop for each table ---

  overall_end_time = Time.now
  total_time_spent = overall_end_time - overall_start_time
  puts "\n#{'='*25} Script Complete #{'='*25}"
  puts "Total script execution time: #{'%.2f' % total_time_spent} seconds."
  WSApplication.message_box("All selected exports are complete.", 'OK', nil, false)
end

# --- Basic String helper for singularize ---
class String
  def singularize
    # Basic singularization for finding ID fields
    if self.end_with?('ies')
      self[0..-4] + 'y'
    elsif self.end_with?('s')
      self[0..-2] # Corrected from original to handle simple plurals
    else
      self
    end
  end
end

# --- Run the script ---
run_export_script
