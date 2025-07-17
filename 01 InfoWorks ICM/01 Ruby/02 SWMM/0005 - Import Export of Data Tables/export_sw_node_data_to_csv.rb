require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Node Fields ---
# The symbols MUST match the actual method names available on 'sw_node' objects.
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
  ['Include Conductivity', :conductivity, false, 'GW_Conduct'], 
  ['Include Evaporation Factor', :evaporation_factor, false, 'EvapFactor'],

  # Outfall Specific
  ['Include Outfall Type', :outfall_type, false, 'OutfallTyp'],
  ['Include Fixed Stage', :fixed_stage, false, 'OutfallFix'],
  ['Include Tidal Curve ID', :tidal_curve_id, false, 'OutfallTID'],
  ['Include Flap Gate', :flap_gate, false, 'Flap_Gate'], 

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
  ['Include Additional DWF', :additional_dwf, false, 'Add_DWF'], # Complex array

  # Water Quality
  ['Include Treatment Expressions', :treatment, false, 'Treatment'], # Complex array
  ['Include Pollutant Inflows', :pollutant_inflows, false, 'Poll_Inf'], # Complex array
  ['Include Pollutant DWF', :pollutant_dwf, false, 'Poll_DWF'], # Complex array
  
  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'], # Complex array
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
# node_example = cn.row_objects('sw_node').first
# if node_example
#   puts "--- DEBUG: Available methods for the first 'sw_node' object ---"
#   puts node_example.methods.sort.inspect
#   if node_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_node' object ---"
#      puts node_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit
# else
#   puts "DEBUG: No 'sw_node' objects found in the network to inspect."
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

dialog_title = "Select options for SWMM Node export"
options = WSApplication.prompt(dialog_title, prompt_options, false)

if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Node export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_nodes_export_#{timestamp}.csv")
nodes_iterated_count = 0
nodes_written_count = 0
numeric_data_for_stats = {} # To store numeric data

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

begin
  CSV.open(file_path, "w") do |csv_file|
    puts "Writing CSV header: #{header.join(', ')}"
    csv_file << header

    row_objects_iterator = cn.row_objects('sw_node')
    raise "Failed to retrieve 'sw_node' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |node_obj|
      nodes_iterated_count += 1
      current_node_id_for_log = (node_obj.respond_to?(:node_id) && node_obj.node_id) ? node_obj.node_id.to_s : "ITER_#{nodes_iterated_count}"

      if node_obj && node_obj.respond_to?(:selected) && node_obj.selected
        row_data = []
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          value_for_csv = ""
          value_for_stats = nil
          begin
            raw_value = node_obj.send(attr_sym)
            
            if raw_value.is_a?(Array)
              case attr_sym
              when :treatment
                value_for_csv = raw_value.map { |t|
                  pollutant = t.is_a?(Hash) ? (t[:pollutant] || t['pollutant']) : (t.respond_to?(:pollutant) ? t.pollutant : 'N/A')
                  result_expr = t.is_a?(Hash) ? (t[:result] || t['result']) : (t.respond_to?(:result) ? t.result : 'N/A') 
                  func_expr = t.is_a?(Hash) ? (t[:function] || t['function']) : (t.respond_to?(:function) ? t.function : 'N/A') 
                  "#{pollutant.to_s.gsub(/[;,]/, '')}:#{result_expr.to_s.gsub(/[;,]/, '')}:#{func_expr.to_s.gsub(/[;,]/, '')}"
                }.join(';')
              when :pollutant_inflows, :pollutant_dwf
                value_for_csv = raw_value.map { |pi|
                  pollutant = pi.is_a?(Hash) ? (pi[:pollutant] || pi['pollutant']) : (pi.respond_to?(:pollutant) ? pi.pollutant : 'N/A')
                  conc = pi.is_a?(Hash) ? (pi[:concentration] || pi['concentration'] || pi[:baseline]) : (pi.respond_to?(:concentration) ? pi.concentration : (pi.respond_to?(:baseline) ? pi.baseline : 'N/A'))
                  pattern = pi.is_a?(Hash) ? (pi[:pattern_id] || pi['pattern_id']) : (pi.respond_to?(:pattern_id) ? pi.pattern_id : '')
                  "#{pollutant.to_s.gsub(/[;,]/, '')}:#{conc.to_s.gsub(/[;,]/, '')}" + (pattern.to_s.empty? ? "" : ":#{pattern.to_s.gsub(/[;,]/, '')}")
                }.join(';')
              when :additional_dwf 
                 value_for_csv = raw_value.map{|item| 
                    b = item.is_a?(Hash) ? (item[:baseline] || item['baseline']) : (item.respond_to?(:baseline) ? item.baseline : 'N/A')
                    p1 = item.is_a?(Hash) ? (item[:bf_pattern_1] || item['bf_pattern_1']) : (item.respond_to?(:bf_pattern_1) ? item.bf_pattern_1 : '')
                    # Add p2, p3, p4 if they exist in the structure and are needed
                    "B:#{b.to_s.gsub(/[;,]/, '')}|P1:#{p1.to_s.gsub(/[;,]/, '')}"
                 }.join('||') # Use double pipe to separate multiple DWF entries
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
            puts "Warning (CSV): Attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for Node '#{current_node_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error (CSV): Accessing ':#{attr_sym}' (for '#{field_info[:original_label]}') for Node '#{current_node_id_for_log}': #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv_file << row_data
        nodes_written_count += 1
      end # if node_obj selected
    end # row_objects_iterator.each
  end # CSV.open
rescue Errno::EACCES, Errno::ENOSPC, CSV::MalformedCSVError => e
  puts "FATAL ERROR (CSV Export): #{e.class} - #{e.message}"
rescue => e
  puts "FATAL ERROR (CSV Export): Unexpected failure - #{e.class}: #{e.message}\nBacktrace: #{e.backtrace.first(5).join("\n")}"
end


# --- Final Summary & Statistics ---
puts "\n--- Processing Summary (SWMM Nodes) ---"
puts "Total SWMM Nodes iterated in network: #{nodes_iterated_count}"

if nodes_written_count > 0
  puts "Successfully wrote #{nodes_written_count} selected SWMM Nodes to #{file_path}"
else
  puts "No SWMM Nodes were selected or met criteria for export."
  if !file_path.empty? && File.exist?(file_path)
    header_line_content_size = header.empty? ? 0 : CSV.generate_line(header).bytesize
    newline_size = (RUBY_PLATFORM =~ /mswin|mingw|cygwin/ ? 2 : 1) 
    header_only_file_size = header_line_content_size + (header.empty? ? 0 : newline_size)

    if File.size(file_path) <= header_only_file_size
      line_count_in_file = 0
      begin; line_count_in_file = File.foreach(file_path).count; rescue; end
      if line_count_in_file <= (header.empty? ? 0 : 1)
        puts "Deleting file as it's empty or contains only the header: #{file_path}"
        File.delete(file_path) rescue puts "Warning: Could not delete empty file #{file_path}."
      end
    end
  end
end
 
if nodes_written_count > 0 && nodes_iterated_count > 0 && nodes_written_count < nodes_iterated_count
  puts "Note: #{nodes_iterated_count - nodes_written_count} SWMM Nodes were iterated but not written (likely not selected or failed other criteria)."
end

if calculate_stats && nodes_written_count > 0
  puts "\n--- Statistics for Exported Numeric Fields (SWMM Nodes) ---"
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

    non_numeric_symbols = [
      :node_id, :node_type, :route_subcatchment, :unit_hydrograph_id, 
      :flood_type, :outfall_type, :tidal_curve_id, :storage_type, :storage_curve,
      :inflow_pattern, :bf_pattern_1, :bf_pattern_2, :bf_pattern_3, :bf_pattern_4,
      :additional_dwf, :treatment, :pollutant_inflows, :pollutant_dwf,
      :notes, :hyperlinks
    ]
    
    is_likely_text_or_id = field_info[:header].downcase.include?('id') ||
                            field_info[:header].downcase.include?('type') ||
                            field_info[:header].downcase.include?('pattern') ||
                            field_info[:header].downcase.include?('curve') ||
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
  puts "\nNo SWMM Nodes were written to the CSV, so no statistics calculated."
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
    ['Number of Selected SWMM Nodes Written', 'NUMBER', nodes_written_count],
    ['Number of Fields Exported Per Node', 'NUMBER', header.count] 
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Nodes)", summary_layout, false)
elsif nodes_written_count == 0 && nodes_iterated_count >= 0 
  message = "No SWMM Nodes were selected or qualified for export."
  message += " The output file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path) 
  WSApplication.message_box(message,'OK',nil,false)
else 
  WSApplication.message_box("Export for SWMM Nodes did not complete as expected. No nodes written. Check console messages.", 'OK',nil,false)
end

puts "\nScript execution for SWMM Nodes complete."
