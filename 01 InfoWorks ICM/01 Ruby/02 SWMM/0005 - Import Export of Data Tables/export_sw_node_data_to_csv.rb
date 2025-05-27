require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Node Fields (from sw_parameters.rb) ---
# IMPORTANT: The symbols MUST match the actual method names available on 'sw_node' objects.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names if needed.
FIELDS_TO_EXPORT = [
  # Core Node Identifiers & Location
  ['Include Node ID', :node_id, true, 'Node_ID'],
  ['Include Node Type', :node_type, true, 'Node_Type'],
  ['Include X Coordinate', :x, true, 'X_Coord'],
  ['Include Y Coordinate', :y, true, 'Y_Coord'],

  # Routing & Hydrograph
  ['Include Route to Subcatchment', :route_subcatchment, false, 'Route_Subc'],
  ['Include Unit Hydrograph ID', :unit_hydrograph_id, false, 'UH_ID'],
  ['Include Unit Hydrograph Area', :unit_hydrograph_area, false, 'UH_Area'],

  # Elevations and Depths
  ['Include Ground Level', :ground_level, true, 'Gnd_Level'],
  ['Include Invert Elevation', :invert_elevation, true, 'Inv_Elev'],
  ['Include Maximum Depth', :maximum_depth, false, 'Max_Depth'],
  ['Include Surcharge Depth', :surcharge_depth, false, 'Surch_Dpth'],
  ['Include Initial Depth', :initial_depth, false, 'Init_Depth'],
  ['Include Ponded Area', :ponded_area, false, 'Ponded_Ara'],

  # Flooding
  ['Include Flood Type', :flood_type, false, 'Flood_Type'],
  ['Include Flooding Discharge Coeff', :flooding_discharge_coeff, false, 'FloodCoeff'],

  # Groundwater Parameters
  ['Include Initial Moisture Deficit', :initial_moisture_deficit, false, 'GW_MoistDf'],
  ['Include Suction Head', :suction_head, false, 'GW_SucHead'],
  ['Include Conductivity', :conductivity, false, 'GW_Conduct'], # From sw_node parameters
  ['Include Evaporation Factor', :evaporation_factor, false, 'EvapFactor'],

  # Outfall Specific
  ['Include Outfall Type', :outfall_type, false, 'OutfallTyp'],
  ['Include Fixed Stage', :fixed_stage, false, 'OutfallFix'],
  ['Include Tidal Curve ID', :tidal_curve_id, false, 'OutfallTID'],
  ['Include Flap Gate', :flap_gate, false, 'Flap_Gate'], # General, but often for outfalls

  # Storage Node Specific
  ['Include Storage Type', :storage_type, false, 'StorageTyp'],
  ['Include Storage Curve ID', :storage_curve, false, 'StorCrvID'],
  ['Include Functional Coefficient', :functional_coefficient, false, 'StorFCoeff'],
  ['Include Functional Constant', :functional_constant, false, 'StorFConst'],
  ['Include Functional Exponent', :functional_exponent, false, 'StorFExp'],

  # Inflows & DWF
  ['Include Inflow Baseline', :inflow_baseline, false, 'Inf_Base'],
  ['Include Inflow Scaling Factor', :inflow_scaling, false, 'Inf_Scale'],
  ['Include Inflow Pattern ID', :inflow_pattern, false, 'Inf_PatID'],
  ['Include Base DWF Flow', :base_flow, false, 'DWF_Base'],
  ['Include DWF Pattern 1', :bf_pattern_1, false, 'DWF_Pat1'],
  ['Include DWF Pattern 2', :bf_pattern_2, false, 'DWF_Pat2'],
  ['Include DWF Pattern 3', :bf_pattern_3, false, 'DWF_Pat3'],
  ['Include DWF Pattern 4', :bf_pattern_4, false, 'DWF_Pat4'],
  ['Include Additional DWF', :additional_dwf, false, 'Add_DWF_Array'], # Complex array

  # Water Quality
  ['Include Treatment Expressions', :treatment, false, 'Treatment_Array'], # Complex array
  ['Include Pollutant Inflows', :pollutant_inflows, false, 'Poll_Inf_Array'], # Complex array
  ['Include Pollutant DWF', :pollutant_dwf, false, 'Poll_DWF_Array'], # Complex array
  
  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks_Array'], # Complex array
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
# Uncomment the following lines to print available methods for the first 'sw_node' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# node_example = cn.row_objects('sw_node').first # Target 'sw_node'
# if node_example
#   puts "--- DEBUG: Available methods for the first 'sw_node' object ---"
#   puts node_example.methods.sort.inspect
#   if node_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_node' object ---"
#      puts node_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'sw_node' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Node Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Node export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_nodes_export_#{timestamp}.csv")

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

nodes_iterated_count = 0
nodes_written_count = 0

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing SWMM Node objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('sw_node') # Target 'sw_node'
    raise "Failed to retrieve 'sw_node' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |node_obj|
      nodes_iterated_count += 1
      current_node_id_for_log = "UNKNOWN_NODE_ITER_#{nodes_iterated_count}"
      if node_obj.respond_to?(:node_id) && node_obj.node_id
        current_node_id_for_log = node_obj.node_id.to_s
      end

      if node_obj && node_obj.respond_to?(:selected) && node_obj.selected
        nodes_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            value = node_obj.send(attr_sym)
            
            if value.is_a?(Array)
              case attr_sym
              when :treatment
                # Expected structure: Array of Hashes/Objects with :pollutant, :result, :function
                row_data << value.map { |t|
                  pollutant = t.is_a?(Hash) ? (t[:pollutant] || t['pollutant']) : (t.respond_to?(:pollutant) ? t.pollutant : 'N/A')
                  result_expr = t.is_a?(Hash) ? (t[:result] || t['result']) : (t.respond_to?(:result) ? t.result : 'N/A')
                  func_expr = t.is_a?(Hash) ? (t[:function] || t['function']) : (t.respond_to?(:function) ? t.function : 'N/A')
                  "#{pollutant.to_s.gsub(/[;,]/, '')}:#{result_expr.to_s.gsub(/[;,]/, '')}:#{func_expr.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              when :pollutant_inflows, :pollutant_dwf
                # Expected structure: Array of Hashes/Objects with :pollutant, and :concentration or :baseline, and optionally :pattern_id
                row_data << value.map { |pi|
                  pollutant = pi.is_a?(Hash) ? (pi[:pollutant] || pi['pollutant']) : (pi.respond_to?(:pollutant) ? pi.pollutant : 'N/A')
                  conc = pi.is_a?(Hash) ? (pi[:concentration] || pi['concentration'] || pi[:baseline]) : (pi.respond_to?(:concentration) ? pi.concentration : (pi.respond_to?(:baseline) ? pi.baseline : 'N/A'))
                  pattern = pi.is_a?(Hash) ? (pi[:pattern_id] || pi['pattern_id']) : (pi.respond_to?(:pattern_id) ? pi.pattern_id : '') # Pattern might not always be present
                  "#{pollutant.to_s.gsub(/[;,]/, '')}:#{conc.to_s.gsub(/[;,]/, '')}" + (pattern.to_s.empty? ? "" : ":#{pattern.to_s.gsub(/[;,]/, '')}")
                }.join(';')
              when :additional_dwf
                # Expected structure: Array of Hashes/Objects with :baseline, :bf_pattern_1, etc.
                row_data << value.map { |dwf_item|
                  b = dwf_item.is_a?(Hash) ? (dwf_item[:baseline] || dwf_item['baseline']) : (dwf_item.respond_to?(:baseline) ? dwf_item.baseline : 'N/A')
                  p1 = dwf_item.is_a?(Hash) ? (dwf_item[:bf_pattern_1] || dwf_item['bf_pattern_1']) : (dwf_item.respond_to?(:bf_pattern_1) ? dwf_item.bf_pattern_1 : '')
                  # ... add p2, p3, p4 if needed and present
                  "B:#{b.to_s.gsub(/[;,]/, '')}|P1:#{p1.to_s.gsub(/[;,]/, '')}" # Example format
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
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for SWMM Node '#{current_node_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for SWMM Node '#{current_node_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if node_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (SWMM Nodes) ---"
  puts "Total SWMM Node objects iterated in network: #{nodes_iterated_count}"
  if nodes_written_count > 0
    puts "Successfully wrote #{nodes_written_count} selected SWMM Node objects to #{file_path}"
  else
    puts "No SWMM Node objects were selected or matched criteria for export."
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
  puts "FATAL ERROR: Unexpected failure during SWMM Node CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for SWMM Node export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && nodes_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected SWMM Nodes Written', 'NUMBER', nodes_written_count],
    ['Number of Fields Exported Per Node', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Node Objects)", summary_layout, false)
elsif nodes_written_count == 0 && nodes_iterated_count >= 0
  message = "No SWMM Node objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message, 'Info', :OK, false)
else
  WSApplication.message_box("Export for SWMM Nodes did not complete as expected. No nodes written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for SWMM Node complete."
