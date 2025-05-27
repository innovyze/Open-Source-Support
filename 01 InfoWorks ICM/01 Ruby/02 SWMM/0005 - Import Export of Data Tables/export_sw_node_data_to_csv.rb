require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Node Fields ---
# (FIELDS_TO_EXPORT array remains unchanged)
FIELDS_TO_EXPORT = [
  # Core Node Identifiers & Location
  ['Include Node ID', :node_id, true, 'Node ID'],
  ['Include X Coordinate', :x, true, 'X Coord'],
  ['Include Y Coordinate', :y, true, 'Y Coord'],
  ['Include Node Type', :node_type, true, 'Node Type'],

  # Elevations and Depths
  ['Include Ground Level', :ground_level, true, 'Gnd Level'],
  ['Include Invert Elevation', :invert_elevation, true, 'Inv Elev'],
  ['Include Maximum Depth', :maximum_depth, false, 'Max Depth'],
  ['Include Initial Depth', :initial_depth, false, 'Init Depth'],
  ['Include Surcharge Depth', :surcharge_depth, false, 'Surch Dpth'],
  ['Include Ponded Area', :ponded_area, false, 'Ponded Area'],

  # Routing and Hydrograph
  ['Include Route to Subcatchment', :route_subcatchment, false, 'Route Subc'],
  ['Include Unit Hydrograph ID', :unit_hydrograph_id, false, 'UH ID'],
  ['Include Unit Hydrograph Area', :unit_hydrograph_area, false, 'UH Area'],

  # Flooding
  ['Include Flood Type', :flood_type, false, 'Flood Type'],
  ['Include Flooding Discharge Coeff', :flooding_discharge_coeff, false, 'Flood Coeff'],

  # Groundwater
  ['Include Initial Moisture Deficit', :initial_moisture_deficit, false, 'GW MoistDef'],
  ['Include Suction Head', :suction_head, false, 'GW SucHead'],
  ['Include Conductivity', :conductivity, false, 'GW Conduct'],
  ['Include Evaporation Factor', :evaporation_factor, false, 'Evap Factor'],

  # Outfall Specific
  ['Include Outfall Type', :outfall_type, false, 'Outfall Typ'],
  ['Include Fixed Stage', :fixed_stage, false, 'Outfall FixStg'],
  ['Include Tidal Curve ID', :tidal_curve_id, false, 'Outfall TdlID'],
  ['Include Flap Gate (Outfall)', :flap_gate, false, 'Outfall FlapG'],

  # Storage Node Specific
  ['Include Storage Type', :storage_type, false, 'Storage Typ'],
  ['Include Storage Curve ID', :storage_curve, false, 'Stor CrvID'],
  ['Include Functional Coefficient', :functional_coefficient, false, 'Stor FuncCoeff'],
  ['Include Functional Exponent', :functional_exponent, false, 'Stor FuncExp'],
  ['Include Functional Constant', :functional_constant, false, 'Stor FuncConst'],

  # Inflows
  ['Include Inflow Baseline', :inflow_baseline, false, 'Inflow Base'],
  ['Include Inflow Scaling Factor', :inflow_scaling, false, 'Inflow Scale'],
  ['Include Inflow Pattern ID', :inflow_pattern, false, 'Inflow PatID'],
  ['Include Base DWF Flow', :base_flow, false, 'DWF Base'],
  ['Include DWF Pattern 1', :bf_pattern_1, false, 'DWF Pat1'],
  ['Include DWF Pattern 2', :bf_pattern_2, false, 'DWF Pat2'],
  ['Include DWF Pattern 3', :bf_pattern_3, false, 'DWF Pat3'],
  ['Include DWF Pattern 4', :bf_pattern_4, false, 'DWF Pat4'],
  ['Include Additional DWF', :additional_dwf, false, 'Add DWF Cmplx'],

  # Water Quality / Treatment
  ['Include Treatment Expressions', :treatment, false, 'Treatment Exp'],
  ['Include Pollutant Inflows', :pollutant_inflows, false, 'Poll Inflows'],
  ['Include Pollutant DWF', :pollutant_dwf, false, 'Poll DWF'],

  # General / User Fields
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
  ['Include Notes', :notes, false, 'Notes'],
  ['Include User Number 1', :user_number_1, false, 'User Num1'],
  ['Include User Number 2', :user_number_2, false, 'User Num2'],
  ['Include User Number 3', :user_number_3, false, 'User Num3'],
  ['Include User Number 4', :user_number_4, false, 'User Num4'],
  ['Include User Number 5', :user_number_5, false, 'User Num5'],
  ['Include User Number 6', :user_number_6, false, 'User Num6'],
  ['Include User Number 7', :user_number_7, false, 'User Num7'],
  ['Include User Number 8', :user_number_8, false, 'User Num8'],
  ['Include User Number 9', :user_number_9, false, 'User Num9'],
  ['Include User Number 10', :user_number_10, false, 'User Num10'],
  ['Include User Text 1', :user_text_1, false, 'User Txt1'],
  ['Include User Text 2', :user_text_2, false, 'User Txt2'],
  ['Include User Text 3', :user_text_3, false, 'User Txt3'],
  ['Include User Text 4', :user_text_4, false, 'User Txt4'],
  ['Include User Text 5', :user_text_5, false, 'User Txt5'],
  ['Include User Text 6', :user_text_6, false, 'User Txt6'],
  ['Include User Text 7', :user_text_7, false, 'User Txt7'],
  ['Include User Text 8', :user_text_8, false, 'User Txt8'],
  ['Include User Text 9', :user_text_9, false, 'User Txt9'],
  ['Include User Text 10', :user_text_10, false, 'User Txt10']
].freeze

# --- Main Script Logic ---
begin
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

# --- Optional Debugging Block ---
# (Debugging block remains unchanged)
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  # MODIFIED: Simplified COMBO box definition
  ['Export Format', 'String', 'CSV', ['CSV', 'Shapefile (WKT CSV)']],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

dialog_title = "Select options for SWMM Node export"
options = WSApplication.prompt(dialog_title, prompt_options, false) # This is the line (around original 123) that causes the error

if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Subcatchment rows", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Node export at #{Time.now}"
start_time = Time.now

export_folder = options[0]
export_format = options[1]
select_all_state = options[2]

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
file_path = ""
nodes_iterated_count = 0
nodes_written_count = 0

selected_fields_config = []
csv_header = []
shp_wkt_csv_header = ["WKT"]

FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  individual_field_selected = options[index + 3]
  if select_all_state || individual_field_selected
    attr_sym = field_config[1]
    original_display_label = field_config[0]
    raw_header_name = field_config[3] || attr_sym.to_s
    raw_header_name = attr_sym.to_s if raw_header_name.nil? || raw_header_name.empty?

    current_field_info = {
      attribute: attr_sym,
      csv_header: raw_header_name,
      original_label: original_display_label
    }
    
    selected_fields_config << current_field_info
    csv_header << raw_header_name
    
    if export_format == 'Shapefile (WKT CSV)'
      shp_wkt_csv_header << raw_header_name
    end
  end
end

# (The rest of the script for CSV and Shapefile (WKT CSV) export remains the same as the previous version
# where sanitization was removed, as the error occurs before this logic is reached)

if export_format == 'CSV'
  if selected_fields_config.empty?
    puts "No fields selected for CSV export. Exiting."
    exit
  end
  file_path = File.join(export_folder, "selected_swmm_nodes_export_#{timestamp}.csv")
  puts "Exporting as CSV to: #{file_path}"
  active_header = csv_header

  begin
    CSV.open(file_path, "w") do |csv_file|
      puts "Writing CSV header: #{active_header.join(', ')}"
      csv_file << active_header

      row_objects_iterator = cn.row_objects('sw_node')
      raise "Failed to retrieve 'sw_node' objects." if row_objects_iterator.nil?

      row_objects_iterator.each do |node_obj|
        nodes_iterated_count += 1
        current_node_id_for_log = (node_obj.respond_to?(:node_id) && node_obj.node_id) ? node_obj.node_id.to_s : "ITER_#{nodes_iterated_count}"

        if node_obj && node_obj.respond_to?(:selected) && node_obj.selected
          row_data = []
          selected_fields_config.each do |field_info|
            attr_sym = field_info[:attribute]
            begin
              value = node_obj.send(attr_sym)
              if value.is_a?(Array)
                case attr_sym
                when :treatment
                  row_data << value.map { |t|
                    pollutant = t.is_a?(Hash) ? (t[:pollutant] || t['pollutant']) : (t.respond_to?(:pollutant) ? t.pollutant : 'N/A')
                    result_expr = t.is_a?(Hash) ? (t[:result] || t['result']) : (t.respond_to?(:result) ? t.result : 'N/A')
                    func_expr = t.is_a?(Hash) ? (t[:function] || t['function']) : (t.respond_to?(:function) ? t.function : 'N/A')
                    "#{pollutant.to_s.gsub(/[;,]/, '')}:#{result_expr.to_s.gsub(/[;,]/, '')}:#{func_expr.to_s.gsub(/[;,]/, '')}"
                  }.join(';')
                when :pollutant_inflows, :pollutant_dwf
                  row_data << value.map { |pi|
                    pollutant = pi.is_a?(Hash) ? (pi[:pollutant] || pi['pollutant']) : (pi.respond_to?(:pollutant) ? pi.pollutant : 'N/A')
                    conc = pi.is_a?(Hash) ? (pi[:concentration] || pi['concentration'] || pi[:baseline]) : (pi.respond_to?(:concentration) ? pi.concentration : (pi.respond_to?(:baseline) ? pi.baseline : 'N/A'))
                    pattern = pi.is_a?(Hash) ? (pi[:pattern_id] || pi['pattern_id']) : (pi.respond_to?(:pattern_id) ? pi.pattern_id : '')
                    "#{pollutant.to_s.gsub(/[;,]/, '')}:#{conc}:#{pattern.to_s.gsub(/[;,]/, '')}"
                  }.join(';')
                when :additional_dwf
                  row_data << value.join(', ') 
                when :hyperlinks
                  row_data << value.map { |hl|
                    desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                    url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                    "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
                  }.join(';')
                else 
                  row_data << value.join(', ')
                end
              else
                row_data << (value.nil? ? "" : value)
              end
            rescue NoMethodError
              puts "Warning (CSV): Attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for Node '#{current_node_id_for_log}'."
              row_data << "AttributeMissing"
            rescue => e
              puts "Error (CSV): Accessing ':#{attr_sym}' (for '#{field_info[:original_label]}') for Node '#{current_node_id_for_log}': #{e.class} - #{e.message}"
              row_data << "AccessError"
            end
          end
          csv_file << row_data
          nodes_written_count += 1
        end 
      end 
    end 
  rescue Errno::EACCES, Errno::ENOSPC, CSV::MalformedCSVError => e
    puts "FATAL ERROR (CSV): #{e.class} - #{e.message}"
  rescue => e
    puts "FATAL ERROR (CSV): Unexpected failure - #{e.class}: #{e.message}\nBacktrace: #{e.backtrace.first(5).join("\n")}"
  end

elsif export_format == 'Shapefile (WKT CSV)'
  file_path = File.join(export_folder, "selected_swmm_nodes_wkt_for_shp_#{timestamp}.csv")
  puts "Exporting as Shapefile (WKT CSV) to: #{file_path}"
  puts "This CSV can be imported into GIS software to create a Shapefile."
  puts "NOTE: Field names are NOT sanitized by this script. Ensure they are Shapefile-compatible if issues arise during import."
  active_header = shp_wkt_csv_header
  
  x_coord_attr_sym = :x
  y_coord_attr_sym = :y

  begin
    CSV.open(file_path, "w") do |csv_file|
      puts "Writing Shapefile (WKT CSV) header: #{active_header.join(', ')}"
      csv_file << active_header

      row_objects_iterator = cn.row_objects('sw_node')
      raise "Failed to retrieve 'sw_node' objects." if row_objects_iterator.nil?

      row_objects_iterator.each do |node_obj|
        nodes_iterated_count += 1
        current_node_id_for_log = (node_obj.respond_to?(:node_id) && node_obj.node_id) ? node_obj.node_id.to_s : "ITER_#{nodes_iterated_count}"

        if node_obj && node_obj.respond_to?(:selected) && node_obj.selected
          node_x_val = nil
          node_y_val = nil
          
          begin
            node_x_val = node_obj.send(x_coord_attr_sym) if node_obj.respond_to?(x_coord_attr_sym)
            node_y_val = node_obj.send(y_coord_attr_sym) if node_obj.respond_to?(y_coord_attr_sym)
          rescue => e
             puts "Warning (WKT): Error fetching coordinates for Node '#{current_node_id_for_log}': #{e.message}. Skipping WKT."
          end

          if node_x_val.nil? || node_y_val.nil?
            puts "Warning (WKT): Node '#{current_node_id_for_log}' is missing X or Y coordinates. Skipping WKT for this node."
            next 
          end
          
          wkt_string = "POINT (#{node_x_val} #{node_y_val})"
          row_data = [wkt_string] 

          selected_fields_config.each do |field_info|
            attr_sym = field_info[:attribute]
            begin
              value = node_obj.send(attr_sym)
              if value.is_a?(Array)
                case attr_sym
                when :treatment
                  row_data << value.map { |t|
                    pollutant = t.is_a?(Hash) ? (t[:pollutant] || t['pollutant']) : (t.respond_to?(:pollutant) ? t.pollutant : 'N/A')
                    result_expr = t.is_a?(Hash) ? (t[:result] || t['result']) : (t.respond_to?(:result) ? t.result : 'N/A')
                    func_expr = t.is_a?(Hash) ? (t[:function] || t['function']) : (t.respond_to?(:function) ? t.function : 'N/A')
                    "#{pollutant.to_s.gsub(/[;,]/, '')}:#{result_expr.to_s.gsub(/[;,]/, '')}:#{func_expr.to_s.gsub(/[;,]/, '')}"
                  }.join(';')
                when :pollutant_inflows, :pollutant_dwf
                  row_data << value.map { |pi|
                    pollutant = pi.is_a?(Hash) ? (pi[:pollutant] || pi['pollutant']) : (pi.respond_to?(:pollutant) ? pi.pollutant : 'N/A')
                    conc = pi.is_a?(Hash) ? (pi[:concentration] || pi['concentration'] || pi[:baseline]) : (pi.respond_to?(:concentration) ? pi.concentration : (pi.respond_to?(:baseline) ? pi.baseline : 'N/A'))
                    pattern = pi.is_a?(Hash) ? (pi[:pattern_id] || pi['pattern_id']) : (pi.respond_to?(:pattern_id) ? pi.pattern_id : '')
                    "#{pollutant.to_s.gsub(/[;,]/, '')}:#{conc}:#{pattern.to_s.gsub(/[;,]/, '')}"
                  }.join(';')
                when :additional_dwf
                  row_data << value.join(', ') 
                when :hyperlinks
                  row_data << value.map { |hl|
                    desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                    url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                    "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
                  }.join(';')
                else 
                  row_data << value.join(', ')
                end
              else
                row_data << (value.nil? ? "" : value)
              end
            rescue NoMethodError
              puts "Warning (WKT Attr): Attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for Node '#{current_node_id_for_log}'."
              row_data << "AttributeMissing"
            rescue => e
              puts "Error (WKT Attr): Accessing ':#{attr_sym}' (for '#{field_info[:original_label]}') for Node '#{current_node_id_for_log}': #{e.class} - #{e.message}"
              row_data << "AccessError"
            end
          end
          csv_file << row_data
          nodes_written_count += 1
        end 
      end 
    end 
  rescue Errno::EACCES, Errno::ENOSPC, CSV::MalformedCSVError => e
    puts "FATAL ERROR (WKT CSV): #{e.class} - #{e.message}"
  rescue => e
    puts "FATAL ERROR (WKT CSV): Unexpected failure - #{e.class}: #{e.message}\nBacktrace: #{e.backtrace.first(5).join("\n")}"
  end
else
  puts "Error: Unknown export format '#{export_format}'. Exiting."
  exit
end

puts "\n--- Processing Summary (SWMM Nodes) ---"
puts "Export Format: #{export_format}"
puts "Total SWMM Nodes iterated in network: #{nodes_iterated_count}"

final_header_for_count = (export_format == 'CSV') ? csv_header : shp_wkt_csv_header

if nodes_written_count > 0
  puts "Successfully wrote #{nodes_written_count} selected SWMM Nodes to #{file_path}"
  if export_format == 'Shapefile (WKT CSV)'
      puts "The output is a CSV file with WKT geometries. To create a Shapefile in GIS software (e.g., QGIS, ArcGIS):"
      puts "1. Import the CSV as a delimited text layer."
      puts "2. Specify geometry from the 'WKT' column."
      puts "3. Set the correct Coordinate Reference System (CRS/Projection)."
      puts "4. Export/Save the layer as an Esri Shapefile."
      puts "   (Note: Ensure attribute field names from the CSV are compatible with Shapefile limits if issues occur.)"
  end
else
  puts "No SWMM Nodes were selected or met criteria for export."
  if !file_path.empty? && File.exist?(file_path)
    header_line_content_size = final_header_for_count.empty? ? 0 : CSV.generate_line(final_header_for_count).bytesize
    newline_size = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? 2 : 1)
    header_only_file_size = header_line_content_size + (final_header_for_count.empty? ? 0 : newline_size)

    if File.size(file_path) <= header_only_file_size
      line_count_in_file = 0
      begin; line_count_in_file = File.foreach(file_path).count; rescue; end
      if line_count_in_file <= (final_header_for_count.empty? ? 0 : 1)
        puts "Deleting file as it's empty or contains only the header: #{file_path}"
        File.delete(file_path) rescue puts "Warning: Could not delete empty file #{file_path}."
      end
    end
  end
end
 
if nodes_written_count > 0 && nodes_iterated_count > 0 && nodes_written_count < nodes_iterated_count
  puts "Note: #{nodes_iterated_count - nodes_written_count} SWMM Nodes were iterated but not written (likely not selected, missing coordinates for WKT, or failed other criteria)."
end
puts "If 'AttributeMissing' warnings appeared, uncomment the DEBUG block at the top of the script to verify field names."

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for SWMM Node export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = !file_path.empty? && File.exist?(file_path) && nodes_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Export Format', 'READONLY', export_format],
    ['Number of Selected SWMM Nodes Written', 'NUMBER', nodes_written_count],
    ['Number of Fields Exported Per Node', 'NUMBER', final_header_for_count.count] 
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Nodes)", summary_layout, false)
elsif nodes_written_count == 0 && nodes_iterated_count >= 0 
  message = "No SWMM Nodes were selected or qualified for export."
  message += " The output file was not created or was empty (and thus deleted)." if !file_path.empty?
  WSApplication.message_box(message, 'Info', :OK, false)
else 
  WSApplication.message_box("Export for SWMM Nodes did not complete as expected. No nodes written. Check console messages.",'OK',nil,false)
end

puts "\nScript execution for SWMM Nodes complete."