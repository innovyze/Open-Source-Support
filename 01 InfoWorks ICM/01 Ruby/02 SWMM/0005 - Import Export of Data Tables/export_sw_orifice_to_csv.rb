require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Orifice Fields (from sw_parameters.rb) ---
# IMPORTANT: The symbols MUST match the actual method names available on 'sw_orifice' objects.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names if needed.
FIELDS_TO_EXPORT = [
  # Core Orifice Identifiers
  ['Include Orifice ID', :id, true, 'OrificeID'], # SWMM Orifice ID
  ['Include US Node ID', :us_node_id, true, 'US_Node'],
  ['Include DS Node ID', :ds_node_id, true, 'DS_Node'],
  # Note: SWMM orifices typically don't have a 'link_suffix' like ICM links.
  # If your SWMM version/interface uses it, it can be added.

  # Orifice Characteristics & Operation
  ['Include Link Type', :link_type, true, 'LinkType'], # Should be ORIFICE
  ['Include Shape', :shape, true, 'Shape'], # e.g., CIRCULAR, RECT_CLOSED
  ['Include Orifice Height', :orifice_height, true, 'OrifHeight'], # Geom1 for SWMM5
  ['Include Orifice Width', :orifice_width, false, 'OrifWidth'],   # Geom2 for SWMM5 (used for RECT_OPEN, RECT_CLOSED)
  ['Include Invert Level', :invert, true, 'InvertElev'], # Crest_ht in SWMM5 .inp for some types
  ['Include Discharge Coefficient', :discharge_coeff, true, 'DischCoeff'], # Cd
  ['Include Flap Gate Present', :flap_gate, false, 'FlapGate'], # YES/NO
  ['Include Time to Open/Close (secs)', :time_to_open, false, 'OpenCloseT'], # Time to open/close for gated

  # Geometry & Network Info
  ['Include Point Array (Vertices)', :point_array, false, 'VerticesXY'], # X1,Y1;X2,Y2;...
  ['Include Branch ID', :branch_id, false, 'BranchID'], # If applicable in your model

  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'], # Desc1,URL1;Desc2,URL2;...
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
# Uncomment the following lines to print available methods for the first 'sw_orifice' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# orifice_example = cn.row_objects('sw_orifice').first # Target 'sw_orifice'
# if orifice_example
#   puts "--- DEBUG: Available methods for the first 'sw_orifice' object ---"
#   puts orifice_example.methods.sort.inspect
#   if orifice_example.respond_to?(:fields) # Some objects might have a .fields hash
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_orifice' object ---"
#      puts orifice_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'sw_orifice' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Orifice Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Orifice export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_orifices_export_#{timestamp}.csv")

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

orifices_iterated_count = 0
orifices_written_count = 0

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing SWMM Orifice objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('sw_orifice') # Target 'sw_orifice'
    raise "Failed to retrieve 'sw_orifice' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |orifice_obj|
      orifices_iterated_count += 1
      current_orifice_id_for_log = "UNKNOWN_ORIFICE_ITER_#{orifices_iterated_count}"
      if orifice_obj.respond_to?(:id) && orifice_obj.id
        current_orifice_id_for_log = orifice_obj.id.to_s
      end

      if orifice_obj && orifice_obj.respond_to?(:selected) && orifice_obj.selected
        orifices_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            value = orifice_obj.send(attr_sym)
            
            if value.is_a?(Array)
              case attr_sym
              when :point_array
                row_data << value.map { |pt|
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
                row_data << value.map { |hl|
                  desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                  url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                  "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              else
                row_data << value.map{|item| item.to_s.gsub(/[;,]/, '')}.join(', ')
              end
            else
              row_data << (value.nil? ? "" : value)
            end
          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for SWMM Orifice '#{current_orifice_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for SWMM Orifice '#{current_orifice_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if orifice_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (SWMM Orifices) ---"
  puts "Total SWMM Orifice objects iterated in network: #{orifices_iterated_count}"
  if orifices_written_count > 0
    puts "Successfully wrote #{orifices_written_count} selected SWMM Orifice objects to #{file_path}"
  else
    puts "No SWMM Orifice objects were selected or matched criteria for export."
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
  puts "FATAL ERROR: Unexpected failure during SWMM Orifice CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for SWMM Orifice export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && orifices_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected SWMM Orifices Written', 'NUMBER', orifices_written_count],
    ['Number of Fields Exported Per Orifice', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Orifice Objects)", summary_layout, false)
elsif orifices_written_count == 0 && orifices_iterated_count >= 0
  message = "No SWMM Orifice objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message, 'Info', :OK, false)
else
  WSApplication.message_box("Export for SWMM Orifices did not complete as expected. No orifices written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for SWMM Orifice complete."
