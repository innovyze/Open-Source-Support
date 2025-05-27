require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Pump Fields (from sw_parameters.rb) ---
# IMPORTANT: The symbols MUST match the actual method names available on 'sw_pump' objects.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names if needed.
FIELDS_TO_EXPORT = [
  # Core Pump Identifiers
  ['Include Pump ID', :id, true, 'Pump_ID'], # SWMM Pump ID
  ['Include US Node ID', :us_node_id, true, 'US_Node'],
  ['Include DS Node ID', :ds_node_id, true, 'DS_Node'],

  # Pump Characteristics & Operation
  ['Include Ideal Pump', :ideal, false, 'Ideal_Pump'], # Boolean: YES/NO or 1/0
  ['Include Pump Curve ID', :pump_curve, true, 'Curve_ID'], # Name of the pump curve
  ['Include Initial Status', :initial_status, false, 'InitStatus'], # ON/OFF
  ['Include Startup Depth', :start_up_depth, false, 'StartDepth'],
  ['Include Shutoff Depth', :shut_off_depth, false, 'ShutDepth'],
  
  # Geometry & Network Info
  ['Include Point Array (Geometry)', :point_array, false, 'PointArray'], # X1,Y1;X2,Y2;...
  ['Include Branch ID', :branch_id, false, 'Branch_ID'],

  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks_Array'], # Desc1,URL1;Desc2,URL2;...
  ['Include User Number 1', :user_number_1, false, 'User_Num1'],
  ['Include User Number 2', :user_number_2, false, 'User_Num2'],
  ['Include User Number 3', :user_number_3, false, 'User_Num3'],
  ['Include User Number 4', :user_number_4, false, 'User_Num4'],
  ['Include User Number 5', :user_number_5, false, 'User_Num5'],
  ['Include User Number 6', :user_number_6, false, 'User_Num6'],
  ['Include User Number 7', :user_number_7, false, 'User_Num7'],
  ['Include User Number 8', :user_number_8, false, 'User_Num8'],
  ['Include User Number 9', :user_number_9, false, 'User_Num9'],
  ['Include User Number 10', :user_number_10, false, 'User_Num10'],
  ['Include User Text 1', :user_text_1, false, 'User_Txt1'],
  ['Include User Text 2', :user_text_2, false, 'User_Txt2'],
  ['Include User Text 3', :user_text_3, false, 'User_Txt3'],
  ['Include User Text 4', :user_text_4, false, 'User_Txt4'],
  ['Include User Text 5', :user_text_5, false, 'User_Txt5'],
  ['Include User Text 6', :user_text_6, false, 'User_Txt6'],
  ['Include User Text 7', :user_text_7, false, 'User_Txt7'],
  ['Include User Text 8', :user_text_8, false, 'User_Txt8'],
  ['Include User Text 9', :user_text_9, false, 'User_Txt9'],
  ['Include User Text 10', :user_text_10, false, 'User_Txt10']
].freeze

# --- Main Script Logic ---

begin
  # Get the current network
  cn = WSApplication.current_network
  raise "No network loaded. Please open a network before running the script." if cn.nil?
rescue NameError => e
  puts "ERROR: WSApplication not found. Are you running this script within the application environment (e.g., InfoSWMM, InfoWorks ICM)?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Optional Debugging Block ---
# Uncomment the following lines to print available methods for the first 'sw_pump' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# pump_example = cn.row_objects('sw_pump').first # Target 'sw_pump'
# if pump_example
#   puts "--- DEBUG: Available methods for the first 'sw_pump' object ---"
#   puts pump_example.methods.sort.inspect
#   if pump_example.respond_to?(:fields) # Some objects might have a .fields hash
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_pump' object ---"
#      puts pump_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'sw_pump' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Pump Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Pump export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_pumps_export_#{timestamp}.csv")

selected_fields_config = []
header = []
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  individual_field_selected = options[index + 2] # options[0] is folder, options[1] is select_all
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

    puts "Processing SWMM Pump objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('sw_pump') # Target 'sw_pump'
    raise "Failed to retrieve 'sw_pump' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |pump_obj|
      pumps_iterated_count += 1
      current_pump_id_for_log = "UNKNOWN_PUMP_ITER_#{pumps_iterated_count}"
      if pump_obj.respond_to?(:id) && pump_obj.id
        current_pump_id_for_log = pump_obj.id.to_s
      end

      if pump_obj && pump_obj.respond_to?(:selected) && pump_obj.selected
        pumps_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            value = pump_obj.send(attr_sym)
            
            if value.is_a?(Array)
              case attr_sym
              when :point_array
                # Assuming point_array contains objects/hashes with :x and :y or is an array of [x,y] pairs
                row_data << value.map { |pt|
                  x_val = 'N/A'
                  y_val = 'N/A'
                  if pt.is_a?(Hash)
                    x_val = pt[:x] || pt['x']
                    y_val = pt[:y] || pt['y']
                  elsif pt.is_a?(Array) && pt.length >= 2
                    x_val = pt[0]
                    y_val = pt[1]
                  elsif pt.respond_to?(:x) && pt.respond_to?(:y)
                     x_val = pt.x
                     y_val = pt.y
                  end
                  "#{x_val.to_s.gsub(/[;,]/, '')},#{y_val.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              when :hyperlinks
                row_data << value.map { |hl|
                  desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                  url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                  "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              else
                # Generic array to comma-separated string
                row_data << value.map{|item| item.to_s.gsub(/[;,]/, '')}.join(', ')
              end
            else
              row_data << (value.nil? ? "" : value)
            end
          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for SWMM Pump '#{current_pump_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for SWMM Pump '#{current_pump_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if pump_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (SWMM Pumps) ---"
  puts "Total SWMM Pump objects iterated in network: #{pumps_iterated_count}"
  if pumps_written_count > 0
    puts "Successfully wrote #{pumps_written_count} selected SWMM Pump objects to #{file_path}"
  else
    puts "No SWMM Pump objects were selected or matched criteria for export."
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
  puts "FATAL ERROR: Unexpected failure during SWMM Pump CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for SWMM Pump export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && pumps_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected SWMM Pumps Written', 'NUMBER', pumps_written_count],
    ['Number of Fields Exported Per Pump', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Pump Objects)", summary_layout, false)
elsif pumps_written_count == 0 && pumps_iterated_count >= 0
  message = "No SWMM Pump objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message, 'OK',nil,false)
else
  WSApplication.message_box("Export for SWMM Pumps did not complete as expected. No pumps written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for SWMM Pump complete."
