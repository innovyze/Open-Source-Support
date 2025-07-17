require 'csv'
require 'fileutils'

# --- Configuration: Define hw_pump Fields (excluding flags) ---
# IMPORTANT: The symbols MUST match the actual method names available on
# 'hw_pump' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Key Identifiers
  ['Include Upstream Node ID', :us_node_id, true, 'US_NodeID'],
  ['Include Link Suffix', :link_suffix, true, 'LinkSuffix'],
  ['Include Downstream Node ID', :ds_node_id, true, 'DS_NodeID'],
  ['Include Asset ID', :asset_id, true, 'AssetID'],
  ['Include Asset UID', :asset_uid, false, 'AssetUID'],
  ['Include Infonet ID', :infonet_id, false, 'InfonetID'], # If applicable

  # Basic Pump Properties
  ['Include Link Type', :link_type, true, 'LinkType'], # Should be PUMP
  ['Include System Type', :system_type, false, 'SystemType'],
  ['Include Sewer Reference', :sewer_reference, false, 'SewerRef'],
  ['Include Branch ID', :branch_id, false, 'BranchID'],

  # Pump Operational Parameters
  ['Include Switch On Level', :switch_on_level, true, 'SwitchOnLvl'],
  ['Include Switch Off Level', :switch_off_level, true, 'SwitchOffLvl'],
  ['Include Pump Discharge', :discharge, true, 'Discharge'], # For fixed discharge pumps
  ['Include Head Discharge ID', :head_discharge_id, false, 'HD_CurveID'],
  ['Include Base Level', :base_level, false, 'BaseLevel'], # for HD Curve
  ['Include On Delay (sec)', :delay, false, 'OnDelaySec'], 
  ['Include Off Delay (sec)', :off_delay, false, 'OffDelaySec'],

  # Flow and Speed Control (for variable speed/controlled pumps)
  ['Include Minimum Flow', :minimum_flow, false, 'MinFlow'],
  ['Include Maximum Flow', :maximum_flow, false, 'MaxFlow'],
  ['Include Positive Change in Flow', :positive_change_in_flow, false, 'PosChgFlow'],
  ['Include Negative Change in Flow', :negative_change_in_flow, false, 'NegChgFlow'],
  ['Include Flow Threshold', :threshold, false, 'FlowThresh'], 
  ['Include Maximum Speed', :maximum_speed, false, 'MaxSpeed'],
  ['Include Minimum Speed', :minimum_speed, false, 'MinSpeed'],
  ['Include Positive Change in Speed', :positive_change_in_speed, false, 'PosChgSpeed'],
  ['Include Negative Change in Speed', :negative_change_in_speed, false, 'NegChgSpeed'],
  ['Include Nominal Speed', :nominal_speed, false, 'NominalSpd'],
  ['Include Speed Threshold', :threshold_speed, false, 'SpeedThresh'],
  ['Include Nominal Flow', :nominal_flow, false, 'NominalFlow'], # for VSP
  ['Include Electric-Hydraulic Ratio', :electric_hydraulic_ratio, false, 'ElecHydRatio'],

  # Settlement Efficiencies
  ['Include Upstream Settlement Eff.', :us_settlement_eff, false, 'US_SettEff'],
  ['Include Downstream Settlement Eff.', :ds_settlement_eff, false, 'DS_SettEff'],

  # Geometry
  ['Include Point Array (Geometry)', :point_array, false, 'PointArray'], # X1,Y1;X2,Y2;...

  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'], 
  ['Include User Number 1', :user_number_1, false, 'UserNum1'],
  ['Include User Number 2', :user_number_2, false, 'UserNum2'],
  ['Include User Number 3', :user_number_3, false, 'UserNum3'],
  ['Include User Number 4', :user_number_4, false, 'UserNum4'],
  ['Include User Number 5', :user_number_5, false, 'UserNum5'],
  ['Include User Number 6', :user_number_6, false, 'UserNum6'],
  ['Include User Number 7', :user_number_7, false, 'UserNum7'],
  ['Include User Number 8', :user_number_8, false, 'UserNum8'],
  ['Include User Number 9', :user_number_9, false, 'UserNum9'],
  ['Include User Number 10', :user_number_10, false, 'UserNum10'],
  ['Include User Text 1', :user_text_1, false, 'UserTxt1'],
  ['Include User Text 2', :user_text_2, false, 'UserTxt2'],
  ['Include User Text 3', :user_text_3, false, 'UserTxt3'],
  ['Include User Text 4', :user_text_4, false, 'UserTxt4'],
  ['Include User Text 5', :user_text_5, false, 'UserTxt5'],
  ['Include User Text 6', :user_text_6, false, 'UserTxt6'],
  ['Include User Text 7', :user_text_7, false, 'UserTxt7'],
  ['Include User Text 8', :user_text_8, false, 'UserTxt8'],
  ['Include User Text 9', :user_text_9, false, 'UserTxt9'],
  ['Include User Text 10', :user_text_10, false, 'UserTxt10']
].freeze


# --- Helper Functions for Statistics ---
def calculate_mean(arr)
  return nil if arr.nil? || arr.empty?
  arr.sum.to_f / arr.length
end

def calculate_std_dev(arr, mean)
  return nil if arr.nil? || arr.empty? || mean.nil? || arr.length < 2
  sum_sq_diff = arr.map { |x| (x - mean)**2 }.sum
  Math.sqrt(sum_sq_diff / (arr.length - 1))
end

# --- Main Script Logic ---

begin
  # Get the current network
  cn = WSApplication.current_network
  raise "No network loaded. Please open a network before running the script." if cn.nil?
rescue NameError => e
  puts "ERROR: WSApplication not found. Are you running this script within the application environment (e.g., InfoWorks ICM)?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Optional Debugging Block ---
# pump_example = cn.row_objects('hw_pump').first
# if pump_example
#   puts "--- DEBUG: Available methods for the first 'hw_pump' object ---"
#   puts pump_example.methods.sort.inspect
#   if pump_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'hw_pump' object ---"
#      puts pump_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit 
# else
#   puts "DEBUG: No 'hw_pump' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false],
  ['Calculate Statistics for Numeric Fields', 'Boolean', false] # New option
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED 'hw_pump' Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for 'hw_pump' export at #{Time.now}"
start_time = Time.now

export_folder = options[0]
select_all_state = options[1]
calculate_stats = options[2] # Get state of the new checkbox

unless export_folder && !export_folder.empty?
  puts "ERROR: Export folder not specified. Exiting."
  exit
end

begin
  Dir.mkdir(export_folder) unless Dir.exist?(export_folder)
rescue Errno::EACCES => e
  puts "ERROR: Permission denied creating directory '#{export_folder}'. Check permissions. - #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not create directory '#{export_folder}'. - #{e.message}"
  exit
end
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
file_path = File.join(export_folder, "selected_hw_pumps_export_#{timestamp}.csv")

selected_fields_config = []
header = []
field_option_start_index = 3 
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  individual_field_selected = options[index + field_option_start_index]
  if select_all_state || individual_field_selected
    selected_fields_config << { attribute: field_config[1], header: field_config[3], original_label: field_config[0] }
    header << field_config[3]
  end
end

if selected_fields_config.empty?
  puts "No fields selected for export. Exiting."
  exit
end

pumps_iterated_count = 0
pumps_written_count = 0
numeric_data_for_stats = {} # To store numeric data

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing 'hw_pump' objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('hw_pump') # Target 'hw_pump'
    raise "Failed to retrieve 'hw_pump' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |pump_obj|
      pumps_iterated_count += 1
      current_pump_id_for_log = "UNKNOWN_PUMP_ITER_#{pumps_iterated_count}"
      us_node_val = pump_obj.respond_to?(:us_node_id) ? pump_obj.us_node_id.to_s : 'N/A'
      suffix_val = pump_obj.respond_to?(:link_suffix) ? pump_obj.link_suffix.to_s : 'N/A'
      current_pump_id_for_log = "#{us_node_val}.#{suffix_val}"
      if pump_obj.respond_to?(:asset_id) && pump_obj.asset_id && !pump_obj.asset_id.empty?
        current_pump_id_for_log += " (Asset: #{pump_obj.asset_id})"
      end

      if pump_obj && pump_obj.respond_to?(:selected) && pump_obj.selected
        pumps_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          value_for_csv = ""
          value_for_stats = nil
          begin
            raw_value = pump_obj.send(attr_sym)
            
            if raw_value.is_a?(Array)
              case attr_sym
              when :point_array
                value_for_csv = raw_value.map { |pt|
                  x_val = 'N/A'; y_val = 'N/A'
                  if pt.is_a?(Hash)
                    x_val = pt[:x] || pt['x']; y_val = pt[:y] || pt['y']
                  elsif pt.is_a?(Array) && pt.length >= 2
                    x_val = pt[0]; y_val = pt[1]
                  elsif pt.respond_to?(:x) && pt.respond_to?(:y)
                     x_val = pt.x; y_val = pt.y
                  end
                  "#{x_val.to_s.gsub(/[;,]/, '')},#{y_val.to_s.gsub(/[;,]/, '')}"
                }.join(';')
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
                  # Not a number
                end
              end
            end
            row_data << value_for_csv

            if calculate_stats && !value_for_stats.nil?
              numeric_data_for_stats[attr_sym] ||= []
              numeric_data_for_stats[attr_sym] << value_for_stats
            end

          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for 'hw_pump' '#{current_pump_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for 'hw_pump' '#{current_pump_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if pump_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (hw_pump) ---"
  puts "Total 'hw_pump' objects iterated in network: #{pumps_iterated_count}"
  if pumps_written_count > 0
    puts "Successfully wrote #{pumps_written_count} selected 'hw_pump' objects to #{file_path}"
  else
    puts "No 'hw_pump' objects were selected or matched criteria for export."
    if File.exist?(file_path)
      header_line_content_size = header.empty? ? 0 : CSV.generate_line(header).bytesize
      newline_size = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? 2 : 1)
      header_only_file_size = header_line_content_size + (header.empty? ? 0 : newline_size)

      if File.size(file_path) <= header_only_file_size
        line_count_in_file = 0
        begin; line_count_in_file = File.foreach(file_path).count; rescue; end
        if line_count_in_file <= (header.empty? ? 0 : 1)
            puts "Deleting CSV file as it's empty or contains only the header: #{file_path}"
            File.delete(file_path)
        end
      end
    end
  end
  
  if calculate_stats && pumps_written_count > 0
    puts "\n--- Statistics for Exported Numeric Fields (hw_pump) ---"
    param_col_width = 30
    count_col_width = 8
    min_col_width = 12
    max_col_width = 12
    mean_col_width = 15
    std_dev_col_width = 15
    total_width = param_col_width + count_col_width + min_col_width + max_col_width + mean_col_width + std_dev_col_width + (6 * 3) 

    puts "-" * total_width
    puts "| %-#{param_col_width}s | %-#{count_col_width}s | %-#{min_col_width}s | %-#{max_col_width}s | %-#{mean_col_width}s | %-#{std_dev_col_width}s |" % 
         ["Parameter (Header)", "Count", "Min", "Max", "Mean", "Std Dev"]
    puts "-" * total_width
    
    found_numeric_data_for_table = false
    selected_fields_config.each do |field_info|
      attr_sym = field_info[:attribute]
      data_array = numeric_data_for_stats[attr_sym]

      non_numeric_symbols = [:us_node_id, :link_suffix, :ds_node_id, :asset_id, :asset_uid, 
                             :infonet_id, :link_type, :system_type, :sewer_reference, :branch_id, 
                             :head_discharge_id, :point_array, :notes, :hyperlinks]
      
      is_likely_text_or_id = field_info[:header].downcase.include?('id') ||
                              field_info[:header].downcase.include?('type') ||
                              field_info[:header].downcase.include?('ref') ||
                              non_numeric_symbols.include?(attr_sym)

      if data_array && !data_array.empty? && !is_likely_text_or_id
        found_numeric_data_for_table = true
        count_val = data_array.length
        min_val = data_array.min
        max_val = data_array.max
        mean_val = calculate_mean(data_array)
        std_dev_val = calculate_std_dev(data_array, mean_val)
        display_header = field_info[:header].length > param_col_width ? field_info[:header][0...(param_col_width-3)] + "..." : field_info[:header]

        puts "| %-#{param_col_width}s | %-#{count_col_width}d | %-#{min_col_width}.3f | %-#{max_col_width}.3f | %-#{mean_col_width}.3f | %-#{std_dev_col_width}s |" % [
          display_header,
          count_val, 
          min_val, 
          max_val, 
          mean_val,
          (std_dev_val.nil? ? "N/A (n<2)" : "%.3f" % std_dev_val)
        ]
      end
    end
    puts "-" * total_width
    unless found_numeric_data_for_table
        puts "No suitable numeric data found among selected fields to calculate statistics."
    end
  elsif calculate_stats
    puts "\nNo pumps were written to the CSV, so no statistics calculated."
  end

rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during 'hw_pump' CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for 'hw_pump' export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && pumps_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Pumps Written', 'NUMBER', pumps_written_count],
    ['Number of Fields Exported Per Pump', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected 'hw_pump' Objects)", summary_layout, false)
elsif pumps_written_count == 0 && pumps_iterated_count >= 0
  message = "No 'hw_pump' objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message,  'OK',nil,false)
else
  WSApplication.message_box("Export for 'hw_pump' did not complete as expected. No pumps written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for 'hw_pump' complete."
