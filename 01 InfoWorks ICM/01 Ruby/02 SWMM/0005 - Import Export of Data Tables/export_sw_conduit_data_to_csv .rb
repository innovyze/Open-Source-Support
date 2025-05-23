require 'csv'
require 'fileutils'
# Removed: require 'set'

# --- Configuration: Define SWMM Conduit Fields ---
# IMPORTANT: The symbols (e.g., :id, :us_node_id) MUST match the actual
# method names available on 'sw_conduit' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Common SWMM fields - verify these against your specific API version
  ['Include Conduit ID', :id, true, 'Conduit ID'],
  ['Include US Node ID', :us_node_id, true, 'US Node ID'],
  ['Include DS Node ID', :ds_node_id, true, 'DS Node ID'],
  ['Include Length', :length, true, 'Length'],
  ['Include Point Array', :point_array, false, 'Point Array'],
  ['Include Shape', :shape, true, 'Shape'],
  
  ['Include Horiz Ellipse Size Code', :horiz_ellipse_size_code, false, 'Horiz Ellipse Size Code'],
  ['Include Vert Ellipse Size Code', :vert_ellipse_size_code, false, 'Vert Ellipse Size Code'],
  ['Include Arch Material', :arch_material, false, 'Arch Material'],
  ['Include Arch Concrete Size Code', :arch_concrete_size_code, false, 'Arch Concrete Size Code'],
  ['Include Arch Plate 18 Size Code', :arch_plate_18_size_code, false, 'Arch Plate 18 Size Code'],
  ['Include Arch Plate 31 Size Code', :arch_plate_31_size_code, false, 'Arch Plate 31 Size Code'],
  ['Include Arch Steel Half Size Code', :arch_steel_half_size_code, false, 'Arch Steel Half Size Code'],
  ['Include Arch Steel Inch Size Code', :arch_steel_inch_size_code, false, 'Arch Steel Inch Size Code'],
  
  ['Include Conduit Height', :conduit_height, true, 'Conduit Height'],
  ['Include Conduit Width', :conduit_width, true, 'Conduit Width'],
  ['Include Number of Barrels', :number_of_barrels, false, 'Number of Barrels'],
  
  ['Include Roughness DW', :roughness_DW, false, 'Roughness DW'],
  ['Include Roughness HW', :roughness_HW, false, 'Roughness HW'],
  ['Include Mannings N', :Mannings_N, true, 'Mannings N'],

  ['Include Top Radius', :top_radius, false, 'Top Radius'],
  ['Include Left Slope', :left_slope, false, 'Left Slope'],
  ['Include Right Slope', :right_slope, false, 'Right Slope'],
  ['Include Triangle Height', :triangle_height, false, 'Triangle Height'],
  ['Include Bottom Radius', :bottom_radius, false, 'Bottom Radius'],
  ['Include Shape Curve', :shape_curve, false, 'Shape Curve'],
  ['Include Shape Exponent', :shape_exponent, false, 'Shape Exponent'],
  ['Include Transect', :transect, false, 'Transect'],

  ['Include US Invert', :us_invert, false, 'US Invert'],
  ['Include DS Invert', :ds_invert, false, 'DS Invert'],
  ['Include US Headloss Coeff', :us_headloss_coeff, false, 'US Headloss Coeff'],
  ['Include DS Headloss Coeff', :ds_headloss_coeff, false, 'DS Headloss Coeff'],
  ['Include Initial Flow', :initial_flow, false, 'Initial Flow'],
  ['Include Max Flow', :max_flow, false, 'Max Flow'],
  
  ['Include Bottom Mannings N', :bottom_mannings_N, false, 'Bottom Mannings N'],
  ['Include Roughness Depth Threshold', :roughness_depth_threshold, false, 'Roughness Depth Threshold'],
  ['Include Sediment Depth', :sediment_depth, false, 'Sediment Depth'],
  ['Include Avg Headloss Coeff', :av_headloss_coeff, false, 'Avg Headloss Coeff'],
  ['Include Seepage Rate', :seepage_rate, false, 'Seepage Rate'],
  ['Include Culvert Code', :culvert_code, false, 'Culvert Code'],
  ['Include Flap Gate', :flap_gate, false, 'Flap Gate'],
  
  ['Include Branch ID', :branch_id, false, 'Branch ID'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
  ['Include Notes', :notes, false, 'Notes'],
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

# Removed: $already_debugged_missing_attributes = Set.new

# --- Main Script Logic ---

begin
  # Get the current network
  cn = WSApplication.current_network
  raise "No network loaded. Please open a network before running the script." if cn.nil?
rescue NameError => e
  puts "ERROR: WSApplication not found. Are you running this script within the application environment (e.g., InfoWorks ICM, InfoSWMM)?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Optional Debugging Block (Simplified) ---
# Uncomment the following lines to print available methods for the first 'sw_conduit' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# conduit_example = cn.row_objects('sw_conduit').first # Target 'sw_conduit'
# if conduit_example
#   puts "--- DEBUG: Available methods for the first 'sw_conduit' object ---"
#   puts conduit_example.methods.sort.inspect # Print sorted methods
#   if conduit_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_conduit' object ---"
#      puts conduit_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'sw_conduit' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Conduit rows", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Conduit export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_conduits_export_#{timestamp}.csv")

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

conduits_iterated_count = 0
conduits_written_count = 0
# Removed: missing_attributes_summary = Set.new

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing SWMM conduits... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('sw_conduit')
    raise "Failed to retrieve 'sw_conduit' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |pipe|
      conduits_iterated_count += 1
      current_pipe_id_for_log = "UNKNOWN_CONDUIT_ID_ITER_#{conduits_iterated_count}"
      if pipe.respond_to?(:id) && pipe.id
        current_pipe_id_for_log = pipe.id.to_s
      elsif pipe.respond_to?(:asset_id)
        current_pipe_id_for_log = pipe.asset_id.to_s
      end

      if pipe && pipe.respond_to?(:selected) && pipe.selected
        conduits_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            # Direct access attempt, relying on rescue for missing methods
            value = pipe.send(attr_sym)
            
            if value.is_a?(Array) && attr_sym == :point_array
              row_data << value.map { |pt| (pt.is_a?(Array) && pt.length >= 2) ? "#{pt[0]},#{pt[1]}" : "InvalidPointData" }.join(';')
            elsif value.is_a?(Array)
              row_data << value.join(', ')
            else
              row_data << (value.nil? ? "" : value) # Using empty string for nil
            end
          rescue NoMethodError
            # Inline warning for missing attribute
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for selected SWMM Conduit '#{current_pipe_id_for_log}'."
            row_data << "AttributeMissing" # Placeholder in CSV
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for SWMM Conduit '#{current_pipe_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError" # Placeholder in CSV
          end
        end
        csv << row_data
      end # if pipe selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (SWMM Conduits) ---"
  puts "Total SWMM conduits iterated in network: #{conduits_iterated_count}"
  if conduits_written_count > 0
    puts "Successfully wrote #{conduits_written_count} selected SWMM conduits to #{file_path}"
  else
    puts "No SWMM conduits were selected or matched criteria for export."
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
  # Removed the detailed "Missing Attributes Summary" block.
  # Warnings are now only printed inline during processing.
  # A general advice message can be added here if needed.
  if conduits_written_count > 0 && conduits_iterated_count > 0 && conduits_written_count < conduits_iterated_count
      puts "Note: Some conduits were iterated but not written (likely not selected or failed criteria)."
  end
  puts "If 'AttributeMissing' warnings appeared, uncomment the DEBUG block at the top of the script to verify field names."


rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during SWMM Conduit CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for SWMM Conduit export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && conduits_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected SWMM Conduits Written', 'NUMBER', conduits_written_count],
    ['Number of Fields Exported Per Conduit', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Conduits)", summary_layout, false)
elsif conduits_written_count == 0 && conduits_iterated_count > 0
  WSApplication.message_box("No SWMM conduits were selected for export. The CSV file was not created or was empty (and thus deleted).", 'Info', :OK, false)
else
  WSApplication.message_box("Export for SWMM Conduits did not complete as expected. No conduits written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for SWMM Conduits complete."
