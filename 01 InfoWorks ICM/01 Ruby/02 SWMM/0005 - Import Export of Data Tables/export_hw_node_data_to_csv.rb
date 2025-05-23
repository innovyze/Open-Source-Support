require 'csv'
require 'fileutils'

# --- Configuration: Define hw_node Fields (excluding flags) ---
# IMPORTANT: The symbols (e.g., :node_id, :storage_array) MUST match the actual
# method names available on 'hw_node' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Key Identifiers & Coordinates
  ['Include Node ID', :node_id, true, 'Node ID'],
  ['Include X Coordinate', :x, true, 'X Coordinate'],
  ['Include Y Coordinate', :y, true, 'Y Coordinate'],
  ['Include Asset ID', :asset_id, false, 'Asset ID'],
  ['Include Asset UID', :asset_uid, false, 'Asset UID'],
  ['Include Infonet ID', :infonet_id, false, 'Infonet ID'],

  # Basic Node Properties
  ['Include Node Type', :node_type, true, 'Node Type'], # e.g., MANHOLE, OUTFALL, STORAGE
  ['Include Ground Level', :ground_level, true, 'Ground Level'],
  ['Include Flood Level', :flood_level, false, 'Flood Level'],
  ['Include System Type', :system_type, false, 'System Type'],
  ['Include Connection Type', :connection_type, false, 'Connection Type'], # e.g., SEALED, VENTED (for manholes)

  # Storage and Area related fields
  ['Include Storage Array', :storage_array, false, 'Storage Array (L,A,P;...)'], # level,area,perimeter
  ['Include Shaft Area', :shaft_area, false, 'Shaft Area'],
  ['Include Chamber Area', :chamber_area, false, 'Chamber Area'],
  ['Include Chamber Roof', :chamber_roof, false, 'Chamber Roof Level'],
  ['Include Chamber Floor', :chamber_floor, false, 'Chamber Floor Level'],
  ['Include Shaft Area Additional', :shaft_area_additional, false, 'Shaft Area Additional'],
  ['Include Shaft Area Add Comp', :shaft_area_add_comp, false, 'Shaft Area Add Comp'],
  ['Include Shaft Area Add Simplify', :shaft_area_add_simplify, false, 'Shaft Area Add Simplify'],
  ['Include Shaft Area Add NCorrect', :shaft_area_add_ncorrect, false, 'Shaft Area Add NCorrect'],
  ['Include Shaft Area Additional Total', :shaft_area_additional_total, false, 'Shaft Area Additional Total'],
  ['Include Chamber Area Additional', :chamber_area_additional, false, 'Chamber Area Additional'],
  ['Include Chamber Area Add Comp', :chamber_area_add_comp, false, 'Chamber Area Add Comp'],
  ['Include Chamber Area Add Simplify', :chamber_area_add_simplify, false, 'Chamber Area Add Simplify'],
  ['Include Chamber Area Add NCorrect', :chamber_area_add_ncorrect, false, 'Chamber Area Add NCorrect'],
  ['Include Chamber Area Additional Total', :chamber_area_additional_total, false, 'Chamber Area Additional Total'],
  ['Include Base Area', :base_area, false, 'Base Area (for infiltration)'],
  ['Include Perimeter', :perimeter, false, 'Perimeter (for infiltration)'],

  # Flooding related fields
  ['Include Flood Type', :flood_type, false, 'Flood Type'], # e.g., SEALED, GRILL, GULLY, NONE
  ['Include Element Area Factor 2D', :element_area_factor_2d, false, '2D Element Area Factor'],
  ['Include Flooding Discharge Coeff', :flooding_discharge_coeff, false, 'Flooding Discharge Coeff'],
  ['Include Floodable Area', :floodable_area, false, 'Floodable Area'],
  ['Include Flood Depth 1', :flood_depth_1, false, 'Flood Depth 1'],
  ['Include Flood Depth 2', :flood_depth_2, false, 'Flood Depth 2'],
  ['Include Flood Area 1', :flood_area_1, false, 'Flood Area 1'],
  ['Include Flood Area 2', :flood_area_2, false, 'Flood Area 2'],

  # 2D Connection fields
  # Note: Ruby symbols cannot start with a number. If the actual method is e.g. _2d_connect_line, use :_2d_connect_line
  # The debug block will reveal the correct name. For now, using a valid symbol name.
  ['Include 2D Connect Line', :connect_2d_line, false, '2D Connect Line'],
  ['Include 2D Link Type', :link_type_2d, false, '2D Link Type'],

  # Lateral Connection fields
  ['Include Lateral Node ID', :lateral_node_id, false, 'Lateral Node ID'],
  ['Include Lateral Link Suffix', :lateral_link_suffix, false, 'Lateral Link Suffix'],

  # Infiltration fields
  ['Include Infiltration Coefficient', :infiltration_coeff, false, 'Infiltration Coefficient'],
  ['Include Porosity', :porosity, false, 'Porosity (for SUDS controls)'],
  ['Include Vegetation Level', :vegetation_level, false, 'Vegetation Level (SUDS)'],
  ['Include Liner Level', :liner_level, false, 'Liner Level (SUDS)'],
  ['Include Infiltration Coeff Above Veg', :infiltratn_coeff_abv_vegn, false, 'Infiltration Coeff Above Vegetation'],
  ['Include Infiltration Coeff Above Liner', :infiltratn_coeff_abv_liner, false, 'Infiltration Coeff Above Liner'],
  ['Include Infiltration Coeff Below Liner', :infiltratn_coeff_blw_liner, false, 'Infiltration Coeff Below Liner'],

  # Inlet Parameters (many are specific to inlet type)
  ['Include Relative Stages', :relative_stages, false, 'Relative Stages (for inlets)'],
  ['Include Inlet Input Type', :inlet_input_type, false, 'Inlet Input Type'],
  ['Include Inlet Type', :inlet_type, false, 'Inlet Type'],
  ['Include Cross Slope', :cross_slope, false, 'Cross Slope (Inlet)'],
  ['Include Grate Width', :grate_width, false, 'Grate Width (Inlet)'],
  ['Include Grate Length', :grate_length, false, 'Grate Length (Inlet)'],
  ['Include Opening Length', :opening_length, false, 'Opening Length (Inlet)'],
  ['Include Opening Height', :opening_height, false, 'Opening Height (Inlet)'],
  ['Include Gutter Depression', :gutter_depression, false, 'Gutter Depression (Inlet)'],
  ['Include Lateral Depression', :lateral_depression, false, 'Lateral Depression (Inlet)'],
  ['Include Velocity Splashover', :velocity_splashover, false, 'Velocity Splashover (Inlet)'],
  ['Include Debris Factor/Percentage', :debris, false, 'Debris Factor/Percentage (Inlet)'],
  ['Include Depth Weir', :depth_weir, false, 'Depth Weir (Inlet)'],
  ['Include Clear Opening', :clear_opening, false, 'Clear Opening (Inlet)'],
  ['Include Head Discharge ID', :head_discharge_id, false, 'Head Discharge ID (Inlet)'],
  ['Include Flow Efficiency ID', :flow_efficiency_id, false, 'Flow Efficiency ID (Inlet)'],
  ['Include Inlet UE_A (User Equation A)', :inlet_UE_a, false, 'Inlet User Equation A'], # Check exact symbol name
  ['Include Inlet UE_B (User Equation B)', :inlet_UE_b, false, 'Inlet User Equation B'], # Check exact symbol name
  ['Include Number of Gullies', :n_gullies, false, 'Number of Gullies (Inlet)'],
  ['Include Num Transverse Bars', :num_transverse_bars, false, 'Num Transverse Bars (Inlet)'],
  ['Include Num Longitudinal Bars', :num_longitudinal_bars, false, 'Num Longitudinal Bars (Inlet)'],
  ['Include Num Diagonal Bars', :num_diagonal_bars, false, 'Num Diagonal Bars (Inlet)'],
  ['Include Min Area Inc Voids', :min_area_inc_voids, false, 'Min Area Inc Voids (Inlet)'],
  ['Include Area of Voids', :area_of_voids, false, 'Area of Voids (Inlet)'],
  ['Include Half Road Width', :half_road_width, false, 'Half Road Width (Inlet)'],
  ['Include Benching Method', :benching_method, false, 'Benching Method'],

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
# Uncomment the following lines to print available methods for the first 'hw_node' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# node_example = cn.row_objects('hw_node').first # Target 'hw_node'
# if node_example
#   puts "--- DEBUG: Available methods for the first 'hw_node' object ---"
#   puts node_example.methods.sort.inspect # Print sorted methods
#   if node_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'hw_node' object ---"
#      puts node_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'hw_node' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED 'hw_node' Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for 'hw_node' export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_hw_nodes_export_#{timestamp}.csv")

selected_fields_config = [] # Changed from selected_fields to match previous structure
header = []
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  individual_field_selected = options[index + 2]
  if select_all_state || individual_field_selected
    # Storing more info, though only attribute and header are strictly needed for this simplified version
    selected_fields_config << { attribute: field_config[1], header: field_config[3], original_label: field_config[0] }
    header << field_config[3]
  end
end

if selected_fields_config.empty?
  puts "No fields selected for export. Exiting."
  exit
end

nodes_iterated_count = 0  # Changed from conduit_count
nodes_written_count = 0   # Changed from conduit_count

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing 'hw_node' objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('hw_node') # Target 'hw_node'
    raise "Failed to retrieve 'hw_node' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |node_obj| # Renamed loop variable 'pipe' to 'node_obj'
      nodes_iterated_count += 1
      current_node_id_for_log = "UNKNOWN_NODE_ID_ITER_#{nodes_iterated_count}"
      # Try to get a meaningful ID for the node
      if node_obj.respond_to?(:node_id) && node_obj.node_id
        current_node_id_for_log = node_obj.node_id.to_s
      elsif node_obj.respond_to?(:id) && node_obj.id
        current_node_id_for_log = node_obj.id.to_s
      elsif node_obj.respond_to?(:asset_id) && node_obj.asset_id
        current_node_id_for_log = node_obj.asset_id.to_s
      end

      if node_obj && node_obj.respond_to?(:selected) && node_obj.selected
        nodes_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            # Direct access attempt, relying on rescue for missing methods
            value = node_obj.send(attr_sym)
            
            # Special handling for complex array fields
            if value.is_a?(Array) && attr_sym == :storage_array
              row_data << value.map { |sa|
                level = sa.is_a?(Hash) ? (sa[:level] || sa['level']) : (sa.respond_to?(:level) ? sa.level : 'N/A')
                area = sa.is_a?(Hash) ? (sa[:area] || sa['area']) : (sa.respond_to?(:area) ? sa.area : 'N/A')
                perimeter = sa.is_a?(Hash) ? (sa[:perimeter] || sa['perimeter']) : (sa.respond_to?(:perimeter) ? sa.perimeter : 'N/A')
                "#{level},#{area},#{perimeter}"
              }.join(';')
            elsif value.is_a?(Array) && attr_sym == :hyperlinks
              row_data << value.map { |hl|
                desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
              }.join(';')
            elsif value.is_a?(Array)
              row_data << value.join(', ')
            else
              row_data << (value.nil? ? "" : value) # Using empty string for nil
            end
          rescue NoMethodError
            # This warning will print for every missing attribute on every selected node if not corrected.
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for selected 'hw_node' '#{current_node_id_for_log}'."
            row_data << "AttributeMissing" # Placeholder in CSV
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for 'hw_node' '#{current_node_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError" # Placeholder in CSV
          end
        end
        csv << row_data
      end # if node_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (hw_node) ---"
  puts "Total 'hw_node' objects iterated in network: #{nodes_iterated_count}"
  if nodes_written_count > 0
    puts "Successfully wrote #{nodes_written_count} selected 'hw_node' objects to #{file_path}"
  else
    puts "No 'hw_node' objects were selected or matched criteria for export."
    # Clean up empty/header-only CSV file, similar to the simpler conduit script
    if File.exist?(file_path)
      # Check if file contains more than just the header
      # This logic is similar to the user's hw_conduit script example
      header_line_content_size = header.empty? ? 0 : CSV.generate_line(header).bytesize
      # Add 1 or 2 for newline characters (LF or CRLF)
      # Gem.win_platform? can be used if available, otherwise assume common newline size
      newline_size = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? 2 : 1)
      header_only_file_size = header_line_content_size + (header.empty? ? 0 : newline_size)

      if File.size(file_path) <= header_only_file_size
        line_count_in_file = 0
        begin; line_count_in_file = File.foreach(file_path).count; rescue; end # Double check line count
        if line_count_in_file <= (header.empty? ? 0 : 1)
            puts "Deleting CSV file as it's empty or contains only the header: #{file_path}"
            File.delete(file_path)
        end
      end
    end
  end
  # Removed the detailed "Missing Attributes Summary" block to align with the simpler conduit script.
  # Warnings are now only printed inline during processing.

rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during 'hw_node' CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for 'hw_node' finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

# Display summary prompt, similar to the simpler conduit script
file_exists_and_has_data = File.exist?(file_path) && nodes_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Nodes Written', 'NUMBER', nodes_written_count],
    ['Number of Fields Exported Per Node', 'NUMBER', selected_fields_config.count] # Using .count on array of hashes
  ]
  WSApplication.prompt("Export Summary (Selected 'hw_node' Objects)", summary_layout, false)
elsif nodes_written_count == 0 && nodes_iterated_count > 0
  WSApplication.message_box("No 'hw_node' objects were selected for export. The CSV file was not created or was empty (and thus deleted).", 'Info', :OK, false)
else
  WSApplication.message_box("Export for 'hw_node' did not complete as expected. No nodes written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for 'hw_node' complete."
