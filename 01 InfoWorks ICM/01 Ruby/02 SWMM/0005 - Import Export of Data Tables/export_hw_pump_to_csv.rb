require 'csv'
require 'fileutils'

# --- Configuration: Define hw_pump Fields (excluding flags) ---
# IMPORTANT: The symbols MUST match the actual method names available on
# 'hw_pump' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Key Identifiers
  ['Include Upstream Node ID', :us_node_id, true, 'Upstream Node ID'],
  ['Include Link Suffix', :link_suffix, true, 'Link Suffix'],
  ['Include Downstream Node ID', :ds_node_id, true, 'Downstream Node ID'],
  ['Include Asset ID', :asset_id, true, 'Asset ID'],
  ['Include Asset UID', :asset_uid, false, 'Asset UID'],
  ['Include Infonet ID', :infonet_id, false, 'Infonet ID'], # If applicable to pumps

  # Basic Pump Properties
  ['Include Link Type', :link_type, true, 'Link Type'], # Should be PUMP
  ['Include System Type', :system_type, false, 'System Type'],
  ['Include Sewer Reference', :sewer_reference, false, 'Sewer Reference'],
  ['Include Branch ID', :branch_id, false, 'Branch ID'],

  # Pump Operational Parameters
  ['Include Switch On Level', :switch_on_level, true, 'Switch On Level'],
  ['Include Switch Off Level', :switch_off_level, true, 'Switch Off Level'],
  ['Include Pump Discharge', :discharge, true, 'Pump Discharge (Fixed)'], # For fixed discharge pumps
  ['Include Head Discharge ID', :head_discharge_id, false, 'Head Discharge ID (Curve)'],
  ['Include Base Level', :base_level, false, 'Base Level (for HD Curve)'],
  ['Include On Delay', :delay, false, 'On Delay (seconds)'], # Original field name is 'delay'
  ['Include Off Delay', :off_delay, false, 'Off Delay (seconds)'],

  # Flow and Speed Control (for variable speed/controlled pumps)
  ['Include Minimum Flow', :minimum_flow, false, 'Minimum Flow'],
  ['Include Maximum Flow', :maximum_flow, false, 'Maximum Flow'],
  ['Include Positive Change in Flow', :positive_change_in_flow, false, 'Positive Change in Flow Rate'],
  ['Include Negative Change in Flow', :negative_change_in_flow, false, 'Negative Change in Flow Rate'],
  ['Include Flow Threshold', :threshold, false, 'Flow Threshold'], # Original field name is 'threshold'
  ['Include Maximum Speed', :maximum_speed, false, 'Maximum Speed'],
  ['Include Minimum Speed', :minimum_speed, false, 'Minimum Speed'],
  ['Include Positive Change in Speed', :positive_change_in_speed, false, 'Positive Change in Speed Rate'],
  ['Include Negative Change in Speed', :negative_change_in_speed, false, 'Negative Change in Speed Rate'],
  ['Include Nominal Speed', :nominal_speed, false, 'Nominal Speed'],
  ['Include Speed Threshold', :threshold_speed, false, 'Speed Threshold'],
  ['Include Nominal Flow', :nominal_flow, false, 'Nominal Flow (for VSP)'],
  ['Include Electric-Hydraulic Ratio', :electric_hydraulic_ratio, false, 'Electric-Hydraulic Ratio'],

  # Settlement Efficiencies
  ['Include Upstream Settlement Eff.', :us_settlement_eff, false, 'Upstream Settlement Efficiency'],
  ['Include Downstream Settlement Eff.', :ds_settlement_eff, false, 'Downstream Settlement Efficiency'],

  # Geometry
  ['Include Point Array (Geometry)', :point_array, false, 'Point Array (X1,Y1;X2,Y2;...)'],

  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks (Desc,URL;...)'],
  ['Include User Number 1', :user_number_1, false, 'User Number 1'],
  ['Include User Number 2', :user_number_2, false, 'User Number 2'],
  ['Include User Number 3', :user_number_3, false, 'User Number 3'],
  ['Include User Number 4', :user_number_4, false, 'User Number 4'],
  ['Include User Number 5', :user_number_5, false, 'User Number 5'],
  ['Include User Number 6', :user_number_6, false, 'User Number 6'],
  ['Include User Number 7', :user_number_7, false, 'User Number 7'],
  ['Include User Number 8', :user_number_8, false, 'User Number 8'],
  ['Include User Number 9', :user_number_9, false, 'User Number 9'],
  ['Include User Number 10', :user_number_10, false, 'User Number 10'],
  ['Include User Text 1', :user_text_1, false, 'User Text 1'],
  ['Include User Text 2', :user_text_2, false, 'User Text 2'],
  ['Include User Text 3', :user_text_3, false, 'User Text 3'],
  ['Include User Text 4', :user_text_4, false, 'User Text 4'],
  ['Include User Text 5', :user_text_5, false, 'User Text 5'],
  ['Include User Text 6', :user_text_6, false, 'User Text 6'],
  ['Include User Text 7', :user_text_7, false, 'User Text 7'],
  ['Include User Text 8', :user_text_8, false, 'User Text 8'],
  ['Include User Text 9', :user_text_9, false, 'User Text 9'],
  ['Include User Text 10', :user_text_10, false, 'User Text 10']
].freeze

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
# Uncomment the following lines to print available methods for the first 'hw_pump' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# pump_example = cn.row_objects('hw_pump').first
# if pump_example
#   puts "--- DEBUG: Available methods for the first 'hw_pump' object ---"
#   puts pump_example.methods.sort.inspect
#   if pump_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'hw_pump' object ---"
#      puts pump_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'hw_pump' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
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
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  individual_field_selected = options[index + 2]
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

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing 'hw_pump' objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('hw_pump')
    raise "Failed to retrieve 'hw_pump' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |pump_obj|
      pumps_iterated_count += 1
      current_pump_id_for_log = "UNKNOWN_PUMP_ITER_#{pumps_iterated_count}"
      # Try to get a meaningful ID for the pump
      us_node = pump_obj.respond_to?(:us_node_id) ? pump_obj.us_node_id.to_s : 'N/A'
      suffix = pump_obj.respond_to?(:link_suffix) ? pump_obj.link_suffix.to_s : 'N/A'
      current_pump_id_for_log = "#{us_node}.#{suffix}"
      if pump_obj.respond_to?(:asset_id) && pump_obj.asset_id && !pump_obj.asset_id.empty?
        current_pump_id_for_log += " (Asset: #{pump_obj.asset_id})"
      end


      if pump_obj && pump_obj.respond_to?(:selected) && pump_obj.selected
        pumps_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            value = pump_obj.send(attr_sym)
            
            if value.is_a?(Array) && attr_sym == :point_array
              # Assuming point_array contains objects/hashes with :x and :y methods/keys
              row_data << value.map { |pt|
                x_val = pt.is_a?(Hash) ? (pt[:x] || pt['x']) : (pt.respond_to?(:x) ? pt.x : 'N/A')
                y_val = pt.is_a?(Hash) ? (pt[:y] || pt['y']) : (pt.respond_to?(:y) ? pt.y : 'N/A')
                "#{x_val.to_s.gsub(/[;,]/, '')},#{y_val.to_s.gsub(/[;,]/, '')}"
              }.join(';')
            elsif value.is_a?(Array) && attr_sym == :hyperlinks
              row_data << value.map { |hl|
                desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                url =  hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
              }.join(';')
            elsif value.is_a?(Array)
              # Generic array to comma-separated string
              row_data << value.map{|item| item.to_s.gsub(/[;,]/, '')}.join(', ')
            else
              row_data << (value.nil? ? "" : value)
            end
          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for selected 'hw_pump' '#{current_pump_id_for_log}'."
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
puts "\nScript for 'hw_pump' finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && pumps_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Pumps Written', 'NUMBER', pumps_written_count],
    ['Number of Fields Exported Per Pump', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected 'hw_pump' Objects)", summary_layout, false)
elsif pumps_written_count == 0 && pumps_iterated_count > 0
  WSApplication.message_box("No 'hw_pump' objects were selected for export. The CSV file was not created or was empty (and thus deleted).", 'Info', :OK, false)
else
  WSApplication.message_box("Export for 'hw_pump' did not complete as expected. No pumps written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for 'hw_pump' complete."
