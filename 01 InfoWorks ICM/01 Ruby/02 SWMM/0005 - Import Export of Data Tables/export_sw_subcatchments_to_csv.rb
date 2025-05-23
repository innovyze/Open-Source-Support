require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Subcatchment Fields ---
# IMPORTANT: The symbols (e.g., :subcatchment_id, :area) MUST match the actual
# method names available on 'sw_subcatchment' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Core Subcatchment Identifiers & Basic Properties
  ['Include Subcatchment ID', :subcatchment_id, true, 'Subcatchment ID'],
  ['Include Raingauge ID', :raingauge_id, true, 'Raingauge ID'],
  ['Include Outlet ID', :outlet_id, true, 'Outlet ID'], # Node or Subcatchment ID it drains to
  ['Include Area', :area, true, 'Total Area'],
  ['Include X Coordinate', :x, false, 'X Coordinate (Centroid/Outlet)'], # SWMM uses this for display
  ['Include Y Coordinate', :y, false, 'Y Coordinate (Centroid/Outlet)'], # SWMM uses this for display
  ['Include Width', :width, true, 'Characteristic Width'],
  ['Include Slope (%)', :catchment_slope, true, 'Avg. Surface Slope (%)'], # SWMM uses percent
  ['Include Percent Impervious', :percent_impervious, true, '% Impervious'],
  
  # Runoff Parameters
  ['Include Roughness Impervious', :roughness_impervious, true, 'N-Imperv (Manning\'s n)'],
  ['Include Roughness Pervious', :roughness_pervious, true, 'N-Perv (Manning\'s n)'],
  ['Include Storage Depth Impervious', :storage_impervious, true, 'Dstore-Imperv (Depth)'],
  ['Include Storage Depth Pervious', :storage_pervious, true, 'Dstore-Perv (Depth)'],
  ['Include Percent Zero Imperv Storage', :percent_no_storage, false, '%Zero-Imperv (Area with no depression storage)'],
  
  # Routing
  ['Include Route To', :route_to, false, 'Route To'], # OUTLET or PERVIOUS
  ['Include Percent Routed (%)', :percent_routed, false, '% Routed (Subarea routing)'],

  # Infiltration Model (select one model's parameters, or make them all optional)
  # Horton / Modified Horton
  ['Include Infiltration Model', :infiltration, false, 'Infiltration Model Type'], # HORTON, MODIFIED_HORTON, GREEN_AMPT, CURVE_NUMBER
  ['Include Max Infiltration Rate (Horton)', :initial_infiltration, false, 'Max Infil Rate (Horton)'], # f0
  ['Include Min Infiltration Rate (Horton)', :limiting_infiltration, false, 'Min Infil Rate (Horton)'], # f_inf
  ['Include Decay Constant (Horton)', :decay_factor, false, 'Decay Constant (Horton)'], # decay
  ['Include Drying Time (Horton)', :drying_time, false, 'Drying Time (days)'],
  ['Include Max Infiltration Volume (Horton)', :max_infiltration_volume, false, 'Max Infil Volume (Horton)'], # Only for Modified Horton

  # Green-Ampt
  ['Include Avg Capillary Suction (Green-Ampt)', :average_capillary_suction, false, 'Suction Head (Green-Ampt)'],
  ['Include Saturated Hydraulic Conductivity (Green-Ampt)', :saturated_hydraulic_conductivity, false, 'Conductivity (Green-Ampt)'],
  ['Include Initial Moisture Deficit (Green-Ampt)', :initial_moisture_deficit, false, 'Initial Deficit (Green-Ampt)'], # iMax - iInitial

  # SCS Curve Number
  ['Include Curve Number (SCS)', :curve_number, false, 'Curve Number (SCS)'],
  # Initial Abstraction for SCS can be complex (depth, factor, or type)
  ['Include Initial Abstraction Depth (SCS)', :initial_abstraction, false, 'Initial Abstraction Depth (SCS)'],
  ['Include Initial Abstraction Factor (SCS)', :initial_abstraction_factor, false, 'Initial Abstraction Factor (SCS)'],
  ['Include Initial Abstraction Type (SCS)', :initial_abstraction_type, false, 'Initial Abstraction Type (SCS)'],


  # Groundwater (Aquifer Interaction)
  ['Include Aquifer ID', :aquifer_id, false, 'Aquifer ID'],
  ['Include Aquifer Node ID (Water Table)', :aquifer_node_id, false, 'Aquifer Water Table Node ID'],
  ['Include Aquifer Ground Elevation', :aquifer_elevation, false, 'Aquifer Ground Elevation'], # Elevation of ground surface over aquifer
  ['Include Aquifer Initial Groundwater Elev', :aquifer_initial_groundwater, false, 'Aquifer Initial GW Elev'],
  ['Include Aquifer Initial Moisture Content', :aquifer_initial_moisture_content, false, 'Aquifer Initial Moisture (vol/vol)'],
  ['Include Groundwater Flow Coefficient', :groundwater_coefficient, false, 'GW Coeff (A1)'], # A1 for A1*(Hgw-Hsw)^B1
  ['Include Groundwater Flow Exponent', :groundwater_exponent, false, 'GW Exponent (B1)'],
  ['Include Groundwater Threshold Elev/Depth', :groundwater_threshold, false, 'GW Surface Water Elev/Depth Threshold'],
  ['Include Lateral GW Flow Equation', :lateral_gwf_equation, false, 'Lateral GW Flow Equation'], # User-defined
  ['Include Deep GW Flow Equation', :deep_gwf_equation, false, 'Deep GW Flow Equation'], # User-defined
  ['Include Surface GW Coefficient', :surface_coefficient, false, 'GW Surface Elev Coeff (A2)'], # A2 for A2*Hgw^B2
  ['Include Surface GW Depth', :surface_depth, false, 'GW Surface Depth (Hgs)'], # Fixed surface water depth at receiving node
  ['Include Surface GW Exponent', :surface_exponent, false, 'GW Surface Elev Exponent (B2)'],
  ['Include Surface GW Coefficient (Flow to Upper Zone)', :surface_groundwater_coefficient, false, 'GW Coeff Upper Zone (A3)'], # A3 for flow to upper soil zone

  # Snow Pack
  ['Include Snow Pack ID', :snow_pack_id, false, 'Snow Pack ID'],

  # Other / Advanced
  ['Include Hydraulic Length (for Overland Flow)', :hydraulic_length, false, 'Hydraulic Length'], # Typically same as Width
  ['Include Area for Average Rain', :area_average_rain, false, 'Area for Average Rain'], # If different from total area
  ['Include Curb Length', :curb_length, false, 'Curb Length (for street sweeping)'],
  ['Include Runoff Model Type', :runoff_model_type, false, 'Runoff Model Type'], # NONLINEAR, KINWAVE (SWMM uses this implicitly)
  ['Include Shape Factor (Nonlinear Reservoir)', :shape_factor, false, 'Shape Factor (Nonlinear Reservoir)'],
  ['Include Time of Concentration', :time_of_concentration, false, 'Time of Concentration (for some UHs)'],
  ['Include SW Drains To', :sw_drains_to, false, 'SW Drains To (alternative outlet)'], # Usually covered by outlet_id

  # Complex Array Fields (Serialization needed)
  ['Include Land Use Coverages', :coverages, false, 'Land Use Coverages (LU,Area;...)'],
  ['Include Pollutant Loadings', :loadings, false, 'Pollutant Loadings (Poll,BuildUp;...)'],
  ['Include Soil Composition', :soil, false, 'Soil Composition (Soil,Area;...)'],
  ['Include Boundary Array', :boundary_array, false, 'Boundary Vertices (X,Y;...)'],
  ['Include SUDS Controls', :suds_controls, false, 'SUDS Controls (ID,Struct,Area...;...)'],

  # Time Patterns (for varying parameters)
  ['Include N-Perv Pattern ID', :n_perv_pattern, false, 'N-Perv Pattern ID'],
  ['Include Dstore Pattern ID', :dstore_pattern, false, 'Dstore Pattern ID'], # For depression storage
  ['Include Infiltration Pattern ID', :infil_pattern, false, 'Infiltration Pattern ID'],

  # General / User Fields
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks (Desc,URL;...)'],
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
# Uncomment the following lines to print available methods for the first 'sw_subcatchment' object.
# This helps verify the symbols used in FIELDS_TO_EXPORT.
# ---
# subcatchment_example = cn.row_objects('sw_subcatchment').first # Target 'sw_subcatchment'
# if subcatchment_example
#   puts "--- DEBUG: Available methods for the first 'sw_subcatchment' object ---"
#   puts subcatchment_example.methods.sort.inspect # Print sorted methods
#   if subcatchment_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_subcatchment' object ---"
#      puts subcatchment_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit # Uncomment to stop after debugging
# else
#   puts "DEBUG: No 'sw_subcatchment' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false]
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Subcatchment rows", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Subcatchment export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_subcatchments_export_#{timestamp}.csv") # Changed filename

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

subcatchments_iterated_count = 0
subcatchments_written_count = 0

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing SWMM Subcatchments... (Checking selection status for each)" # Changed message
    
    row_objects_iterator = cn.row_objects('sw_subcatchment') # Target 'sw_subcatchment'
    raise "Failed to retrieve 'sw_subcatchment' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |sub_obj| # Renamed loop variable
      subcatchments_iterated_count += 1
      current_sub_id_for_log = "UNKNOWN_SUBCATCHMENT_ID_ITER_#{subcatchments_iterated_count}"
      if sub_obj.respond_to?(:subcatchment_id) && sub_obj.subcatchment_id
        current_sub_id_for_log = sub_obj.subcatchment_id.to_s
      elsif sub_obj.respond_to?(:id) && sub_obj.id # Fallback
        current_sub_id_for_log = sub_obj.id.to_s
      end

      if sub_obj && sub_obj.respond_to?(:selected) && sub_obj.selected
        subcatchments_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          begin
            value = sub_obj.send(attr_sym)
            
            # Special handling for potential complex array/hash fields
            if value.is_a?(Array)
              case attr_sym
              when :coverages
                # Example: land_use_id,area (actual structure needs verification)
                row_data << value.map { |c|
                  land_use = c.is_a?(Hash) ? (c[:land_use] || c['land_use']) : (c.respond_to?(:land_use) ? c.land_use : 'N/A')
                  area_val = c.is_a?(Hash) ? (c[:area] || c['area']) : (c.respond_to?(:area) ? c.area : 'N/A')
                  "#{land_use.to_s.gsub(/[;,]/, '')}:#{area_val}"
                }.join(';')
              when :loadings
                # Example: pollutant,build_up_value (actual structure needs verification)
                row_data << value.map { |l|
                  pollutant = l.is_a?(Hash) ? (l[:pollutant] || l['pollutant']) : (l.respond_to?(:pollutant) ? l.pollutant : 'N/A')
                  build_up = l.is_a?(Hash) ? (l[:build_up] || l['build_up']) : (l.respond_to?(:build_up) ? l.build_up : 'N/A')
                  "#{pollutant.to_s.gsub(/[;,]/, '')}:#{build_up}"
                }.join(';')
              when :soil
                 # Example: soil_type_id,area (actual structure needs verification)
                row_data << value.map { |s|
                  soil_type = s.is_a?(Hash) ? (s[:soil] || s['soil']) : (s.respond_to?(:soil) ? s.soil : 'N/A') # Assuming 'soil' is the key for soil type ID
                  area_val = s.is_a?(Hash) ? (s[:area] || s['area']) : (s.respond_to?(:area) ? s.area : 'N/A')
                  "#{soil_type.to_s.gsub(/[;,]/, '')}:#{area_val}"
                }.join(';')
              when :boundary_array # Array of [x,y] pairs
                row_data << value.map { |pt| (pt.is_a?(Array) && pt.length >= 2) ? "#{pt[0]},#{pt[1]}" : "InvalidPoint" }.join(';')
              when :suds_controls # This is very complex, needs careful checking of its structure
                row_data << value.map { |sc|
                  # Example serialization, actual fields depend on API
                  sc_id = sc.is_a?(Hash) ? (sc[:id] || sc['id']) : (sc.respond_to?(:id) ? sc.id : 'N/A')
                  sc_struct = sc.is_a?(Hash) ? (sc[:suds_structure] || sc['suds_structure']) : (sc.respond_to?(:suds_structure) ? sc.suds_structure : 'N/A')
                  # Add more fields as needed, cleaning delimiters
                  "#{sc_id.to_s.gsub(/[;,]/, '')}:#{sc_struct.to_s.gsub(/[;,]/, '')}" # Simplified
                }.join('||') # Using double pipe to separate SUDS controls if multiple
              when :hyperlinks
                row_data << value.map { |hl|
                  desc = hl.is_a?(Hash) ? (hl[:description] || hl['description']) : (hl.respond_to?(:description) ? hl.description : '')
                  url = hl.is_a?(Hash) ? (hl[:url] || hl['url']) : (hl.respond_to?(:url) ? hl.url : '')
                  "#{desc.to_s.gsub(/[;,]/, '')},#{url.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              else # Generic array handling
                row_data << value.join(', ')
              end
            else
              row_data << (value.nil? ? "" : value) # Using empty string for nil
            end
          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for selected SWMM Subcatchment '#{current_sub_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for SWMM Subcatchment '#{current_sub_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if sub_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (SWMM Subcatchments) ---"
  puts "Total SWMM Subcatchments iterated in network: #{subcatchments_iterated_count}"
  if subcatchments_written_count > 0
    puts "Successfully wrote #{subcatchments_written_count} selected SWMM Subcatchments to #{file_path}"
  else
    puts "No SWMM Subcatchments were selected or matched criteria for export."
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
  
  if subcatchments_written_count > 0 && subcatchments_iterated_count > 0 && subcatchments_written_count < subcatchments_iterated_count
      puts "Note: Some SWMM Subcatchments were iterated but not written (likely not selected or failed criteria)."
  end
  puts "If 'AttributeMissing' warnings appeared, uncomment the DEBUG block at the top of the script to verify field names."

rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during SWMM Subcatchment CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for SWMM Subcatchment export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && subcatchments_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected SWMM Subcatchments Written', 'NUMBER', subcatchments_written_count],
    ['Number of Fields Exported Per Subcatchment', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Subcatchments)", summary_layout, false)
elsif subcatchments_written_count == 0 && subcatchments_iterated_count > 0
  WSApplication.message_box("No SWMM Subcatchments were selected for export. The CSV file was not created or was empty (and thus deleted).", 'Info', :OK, false)
else
  WSApplication.message_box("Export for SWMM Subcatchments did not complete as expected. No subcatchments written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for SWMM Subcatchments complete."
