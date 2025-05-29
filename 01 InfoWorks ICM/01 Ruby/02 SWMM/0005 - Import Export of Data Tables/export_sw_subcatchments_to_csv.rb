require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Subcatchment Fields ---
# IMPORTANT: The symbols (e.g., :subcatchment_id, :area) MUST match the actual
# method names available on 'sw_subcatchment' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Core Subcatchment Identifiers & Basic Properties
  ['Include Subcatchment ID', :subcatchment_id, true, 'SubcID'],
  ['Include Raingauge ID', :raingauge_id, true, 'RaingageID'],
  ['Include Outlet ID', :outlet_id, true, 'OutletID'], 
  ['Include Area', :area, true, 'Area'],
  ['Include X Coordinate', :x, false, 'X_Coord'], 
  ['Include Y Coordinate', :y, false, 'Y_Coord'], 
  ['Include Width', :width, true, 'Width'],
  ['Include Slope (%)', :catchment_slope, true, 'Slope_pct'], 
  ['Include Percent Impervious', :percent_impervious, true, 'PctImperv'],
  
  # Runoff Parameters
  ['Include Roughness Impervious', :roughness_impervious, true, 'N_Imperv'],
  ['Include Roughness Pervious', :roughness_pervious, true, 'N_Perv'],
  ['Include Storage Depth Impervious', :storage_impervious, true, 'DstoreImp'],
  ['Include Storage Depth Pervious', :storage_pervious, true, 'DstorePerv'],
  ['Include Percent Zero Imperv Storage', :percent_no_storage, false, 'PctZeroImp'],
  
  # Routing
  ['Include Route To', :route_to, false, 'RouteTo'], # OUTLET or PERVIOUS
  ['Include Percent Routed (%)', :percent_routed, false, 'PctRouted'],

  # Infiltration Model
  ['Include Infiltration Model', :infiltration, false, 'InfilModel'], 
  ['Include Max Infil Rate (Horton)', :initial_infiltration, false, 'MaxInfilH'], 
  ['Include Min Infil Rate (Horton)', :limiting_infiltration, false, 'MinInfilH'], 
  ['Include Decay Constant (Horton)', :decay_factor, false, 'DecayH'], 
  ['Include Drying Time (Horton)', :drying_time, false, 'DryTimeH'],
  ['Include Max Infil Volume (ModHorton)', :max_infiltration_volume, false, 'MaxInfilVolH'],
  ['Include Suction Head (Green-Ampt)', :average_capillary_suction, false, 'SucHeadGA'],
  ['Include Conductivity (Green-Ampt)', :saturated_hydraulic_conductivity, false, 'KsatGA'],
  ['Include Initial Deficit (Green-Ampt)', :initial_moisture_deficit, false, 'InitDefGA'],
  ['Include Curve Number (SCS)', :curve_number, false, 'CurveNum'],
  ['Include Init Abstraction Depth (SCS)', :initial_abstraction, false, 'InitAbsDep'],
  ['Include Init Abstraction Factor (SCS)', :initial_abstraction_factor, false, 'InitAbsFac'],
  ['Include Init Abstraction Type (SCS)', :initial_abstraction_type, false, 'InitAbsTyp'],

  # Groundwater (Aquifer Interaction)
  ['Include Aquifer ID', :aquifer_id, false, 'AquiferID'],
  ['Include Aquifer Node ID (Water Table)', :aquifer_node_id, false, 'AquNodeID'],
  ['Include Aquifer Ground Elevation', :aquifer_elevation, false, 'AquGndElev'],
  ['Include Aquifer Initial Groundwater Elev', :aquifer_initial_groundwater, false, 'AquInitGW'],
  ['Include Aquifer Initial Moisture Content', :aquifer_initial_moisture_content, false, 'AquInitMoist'],
  ['Include Groundwater Flow Coefficient', :groundwater_coefficient, false, 'GW_CoeffA1'], 
  ['Include Groundwater Flow Exponent', :groundwater_exponent, false, 'GW_ExpB1'],
  ['Include Groundwater Threshold Elev/Depth', :groundwater_threshold, false, 'GW_Thresh'],
  ['Include Lateral GW Flow Equation', :lateral_gwf_equation, false, 'LatGW_Eq'], 
  ['Include Deep GW Flow Equation', :deep_gwf_equation, false, 'DeepGW_Eq'], 
  ['Include Surface GW Coefficient', :surface_coefficient, false, 'SurfGWCoeff'], 
  ['Include Surface GW Depth', :surface_depth, false, 'SurfGWDep'], 
  ['Include Surface GW Exponent', :surface_exponent, false, 'SurfGWExp'],
  ['Include Surface GW Coefficient (Upper Zone)', :surface_groundwater_coefficient, false, 'GWCoUpZone'], 

  # Snow Pack
  ['Include Snow Pack ID', :snow_pack_id, false, 'SnowPackID'],

  # Other / Advanced
  ['Include Hydraulic Length', :hydraulic_length, false, 'HydLength'], 
  ['Include Area for Avg Rain', :area_average_rain, false, 'AreaAvgRain'], 
  ['Include Curb Length', :curb_length, false, 'CurbLength'],
  ['Include Runoff Model Type', :runoff_model_type, false, 'RunoffMdlT'],
  ['Include Shape Factor (Nonlinear)', :shape_factor, false, 'ShapeFactor'],
  ['Include Time of Concentration', :time_of_concentration, false, 'ToC'],
  ['Include SW Drains To', :sw_drains_to, false, 'SWDrainsTo'],

  # Complex Array Fields (Serialization needed)
  ['Include Land Use Coverages', :coverages, false, 'Coverages'],
  ['Include Pollutant Loadings', :loadings, false, 'Loadings'],
  ['Include Soil Composition', :soil, false, 'SoilComp'],
  ['Include Boundary Array', :boundary_array, false, 'BoundaryXY'],
  ['Include SUDS Controls', :suds_controls, false, 'SUDS_Ctrl'],

  # Time Patterns (for varying parameters)
  ['Include N-Perv Pattern ID', :n_perv_pattern, false, 'Nperv_PatID'],
  ['Include Dstore Pattern ID', :dstore_pattern, false, 'Dstore_PatID'], 
  ['Include Infiltration Pattern ID', :infil_pattern, false, 'Infil_PatID'],

  # General / User Fields
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
  ['Include Notes', :notes, false, 'Notes'],
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
  puts "ERROR: WSApplication not found. Are you running this script within the application environment (e.g., InfoWorks ICM, InfoSWMM)?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Optional Debugging Block ---
# subcatchment_example = cn.row_objects('sw_subcatchment').first
# if subcatchment_example
#   puts "--- DEBUG: Available methods for the first 'sw_subcatchment' object ---"
#   puts subcatchment_example.methods.sort.inspect
#   if subcatchment_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_subcatchment' object ---"
#      puts subcatchment_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit 
# else
#   puts "DEBUG: No 'sw_subcatchment' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false],
  ['Calculate Statistics for Numeric Fields', 'Boolean', false] # New option
]
FIELDS_TO_EXPORT.each do |field_config|
  if field_config.is_a?(Array) && field_config.length >= 3 && field_config[0].is_a?(String) && (field_config[2].is_a?(TrueClass) || field_config[2].is_a?(FalseClass))
    prompt_options << [field_config[0], 'Boolean', field_config[2]]
  else
    puts "Warning: Skipping invalid entry in FIELDS_TO_EXPORT when building prompt: #{field_config.inspect}"
  end
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Subcatchment Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Subcatchment export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_subcatchments_export_#{timestamp}.csv")

selected_fields_config = []
header = []
field_option_start_index = 3 
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  unless field_config.is_a?(Array) && field_config.length >= 4
    puts "Warning: Skipping invalid field_config during header/selection setup: #{field_config.inspect}"
    next
  end
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

subcatchments_iterated_count = 0
subcatchments_written_count = 0
numeric_data_for_stats = {} # To store numeric data

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing SWMM Subcatchment objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('sw_subcatchment') 
    raise "Failed to retrieve 'sw_subcatchment' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |sub_obj| 
      subcatchments_iterated_count += 1
      current_sub_id_for_log = "UNKNOWN_SUBC_ITER_#{subcatchments_iterated_count}"
      if sub_obj.respond_to?(:subcatchment_id) && sub_obj.subcatchment_id
        current_sub_id_for_log = sub_obj.subcatchment_id.to_s
      elsif sub_obj.respond_to?(:id) && sub_obj.id 
        current_sub_id_for_log = sub_obj.id.to_s
      end

      if sub_obj && sub_obj.respond_to?(:selected) && sub_obj.selected
        subcatchments_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          value_for_csv = ""
          value_for_stats = nil
          begin
            raw_value = sub_obj.send(attr_sym)
            
            if raw_value.is_a?(Array)
              case attr_sym
              when :coverages
                value_for_csv = raw_value.map { |c|
                  lu = c.is_a?(Hash) ? (c[:land_use] || c['land_use']) : (c.respond_to?(:land_use) ? c.land_use : 'N/A')
                  ar = c.is_a?(Hash) ? (c[:area] || c['area']) : (c.respond_to?(:area) ? c.area : 'N/A')
                  "#{lu.to_s.gsub(/[;,]/, '')}:#{ar}"
                }.join(';')
              when :loadings
                value_for_csv = raw_value.map { |l|
                  poll = l.is_a?(Hash) ? (l[:pollutant] || l['pollutant']) : (l.respond_to?(:pollutant) ? l.pollutant : 'N/A')
                  bu = l.is_a?(Hash) ? (l[:build_up] || l['build_up']) : (l.respond_to?(:build_up) ? l.build_up : 'N/A')
                  "#{poll.to_s.gsub(/[;,]/, '')}:#{bu}"
                }.join(';')
              when :soil 
                value_for_csv = raw_value.map { |s|
                  soil_id = s.is_a?(Hash) ? (s[:soil] || s['soil']) : (s.respond_to?(:soil) ? s.soil : 'N/A')
                  area_val = s.is_a?(Hash) ? (s[:area] || s['area']) : (s.respond_to?(:area) ? s.area : 'N/A')
                  "#{soil_id.to_s.gsub(/[;,]/, '')}:#{area_val}"
                }.join(';')
              when :boundary_array
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
              when :suds_controls
                 value_for_csv = raw_value.map { |sc|
                  sc_id = sc.is_a?(Hash) ? (sc[:id] || sc['id']) : (sc.respond_to?(:id) ? sc.id : 'N/A')
                  sc_struct = sc.is_a?(Hash) ? (sc[:suds_structure] || sc['suds_structure']) : (sc.respond_to?(:suds_structure) ? sc.suds_structure : 'N/A')
                  sc_area = sc.is_a?(Hash) ? (sc[:area] || sc['area']) : (sc.respond_to?(:area) ? sc.area : 'N/A')
                  "#{sc_id.to_s.gsub(/[;,]/,'')}:#{sc_struct.to_s.gsub(/[;,]/,'')}:#{sc_area}"
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
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for SWMM Subcatchment '#{current_sub_id_for_log}'."
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
  puts "Total SWMM Subcatchment objects iterated in network: #{subcatchments_iterated_count}"
  if subcatchments_written_count > 0
    puts "Successfully wrote #{subcatchments_written_count} selected SWMM Subcatchment objects to #{file_path}"
  else
    puts "No SWMM Subcatchment objects were selected or matched criteria for export."
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
  
  if calculate_stats && subcatchments_written_count > 0
    puts "\n--- Statistics for Exported Numeric Fields (SWMM Subcatchments) ---"
    param_col_width = 35 
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

      non_numeric_symbols = [
        :subcatchment_id, :raingauge_id, :outlet_id, :route_to, :infiltration, 
        :initial_abstraction_type, :aquifer_id, :aquifer_node_id, :lateral_gwf_equation, 
        :deep_gwf_equation, :snow_pack_id, :runoff_model_type, :sw_drains_to, 
        :coverages, :loadings, :soil, :boundary_array, :suds_controls, 
        :n_perv_pattern, :dstore_pattern, :infil_pattern, :notes, :hyperlinks
      ]
      
      is_likely_text_or_id = field_info[:header].downcase.include?('id') ||
                              field_info[:header].downcase.include?('type') ||
                              field_info[:header].downcase.include?('model') ||
                              field_info[:header].downcase.include?('pattern') ||
                              field_info[:header].downcase.include?('eq') || 
                              field_info[:header].downcase.include?('array') ||
                              field_info[:header].downcase.include?('xy') || 
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
    puts "\nNo subcatchments were written to the CSV, so no statistics calculated."
  end

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
  WSApplication.prompt("Export Summary (Selected SWMM Subcatchment Objects)", summary_layout, false)
elsif subcatchments_written_count == 0 && subcatchments_iterated_count >= 0
  message = "No SWMM Subcatchment objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message,  'OK',nil,false) 
else
  WSApplication.message_box("Export for SWMM Subcatchments did not complete as expected. No subcatchments written. Check console messages. The CSV file may not exist or is empty.",'OK',nil,false) 
end

puts "\nScript execution for SWMM Subcatchments complete."
