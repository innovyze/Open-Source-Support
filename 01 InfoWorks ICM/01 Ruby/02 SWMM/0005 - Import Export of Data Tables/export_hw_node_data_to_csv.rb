require 'csv'
require 'fileutils'

# --- Configuration: Define hw_node Fields (excluding flags) ---
# IMPORTANT: The symbols (e.g., :node_id, :storage_array) MUST match the actual
# method names available on 'hw_node' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Key Identifiers & Coordinates
  ['Include Node ID', :node_id, true, 'NodeID'],
  ['Include X Coordinate', :x, true, 'X_Coord'],
  ['Include Y Coordinate', :y, true, 'Y_Coord'],
  ['Include Asset ID', :asset_id, false, 'AssetID'],
  ['Include Asset UID', :asset_uid, false, 'AssetUID'],
  ['Include Infonet ID', :infonet_id, false, 'InfonetID'],

  # Basic Node Properties
  ['Include Node Type', :node_type, true, 'NodeType'], 
  ['Include Ground Level', :ground_level, true, 'GndLevel'],
  ['Include Flood Level', :flood_level, false, 'FloodLevel'],
  ['Include System Type', :system_type, false, 'SystemType'],
  ['Include Connection Type', :connection_type, false, 'ConnectTyp'], 

  # Storage and Area related fields
  ['Include Storage Array', :storage_array, false, 'StorArray'], 
  ['Include Shaft Area', :shaft_area, false, 'ShaftArea'],
  ['Include Chamber Area', :chamber_area, false, 'ChmbrArea'],
  ['Include Chamber Roof', :chamber_roof, false, 'ChmbrRoof'],
  ['Include Chamber Floor', :chamber_floor, false, 'ChmbrFloor'],
  ['Include Shaft Area Additional', :shaft_area_additional, false, 'ShaftAddAr'],
  ['Include Shaft Area Add Comp', :shaft_area_add_comp, false, 'ShftCompAr'],
  ['Include Shaft Area Add Simplify', :shaft_area_add_simplify, false, 'ShftSimpAr'],
  ['Include Shaft Area Add NCorrect', :shaft_area_add_ncorrect, false, 'ShftNCorAr'],
  ['Include Shaft Area Additional Total', :shaft_area_additional_total, false, 'ShftTotAdd'],
  ['Include Chamber Area Additional', :chamber_area_additional, false, 'ChmbAddAr'],
  ['Include Chamber Area Add Comp', :chamber_area_add_comp, false, 'ChmbCompAr'],
  ['Include Chamber Area Add Simplify', :chamber_area_add_simplify, false, 'ChmbSimpAr'],
  ['Include Chamber Area Add NCorrect', :chamber_area_add_ncorrect, false, 'ChmbNCorAr'],
  ['Include Chamber Area Additional Total', :chamber_area_additional_total, false, 'ChmbTotAdd'],
  ['Include Base Area', :base_area, false, 'BaseArea'],
  ['Include Perimeter', :perimeter, false, 'Perimeter'],

  # Flooding related fields
  ['Include Flood Type', :flood_type, false, 'FloodType'], 
  ['Include Element Area Factor 2D', :element_area_factor_2d, false, 'ElemAreaF2D'],
  ['Include Flooding Discharge Coeff', :flooding_discharge_coeff, false, 'FloodDisCf'],
  ['Include Floodable Area', :floodable_area, false, 'FloodArea'],
  ['Include Flood Depth 1', :flood_depth_1, false, 'FloodDep1'],
  ['Include Flood Depth 2', :flood_depth_2, false, 'FloodDep2'],
  ['Include Flood Area 1', :flood_area_1, false, 'FloodArea1'],
  ['Include Flood Area 2', :flood_area_2, false, 'FloodArea2'],

  # 2D Connection fields
  ['Include 2D Connect Line', :connect_2d_line, false, 'Conn2DLine'], # Use :_2d_connect_line if API requires
  ['Include 2D Link Type', :link_type_2d, false, 'LinkType2D'], # Use :_2d_link_type if API requires

  # Lateral Connection fields
  ['Include Lateral Node ID', :lateral_node_id, false, 'LatNodeID'],
  ['Include Lateral Link Suffix', :lateral_link_suffix, false, 'LatLinkSuf'],

  # Infiltration fields
  ['Include Infiltration Coefficient', :infiltration_coeff, false, 'InfilCoeff'],
  ['Include Porosity', :porosity, false, 'Porosity'], 
  ['Include Vegetation Level', :vegetation_level, false, 'VegLevel'],
  ['Include Liner Level', :liner_level, false, 'LinerLevel'],
  ['Include Infiltration Coeff Above Veg', :infiltratn_coeff_abv_vegn, false, 'InfCfAbVeg'],
  ['Include Infiltration Coeff Above Liner', :infiltratn_coeff_abv_liner, false, 'InfCfAbLin'],
  ['Include Infiltration Coeff Below Liner', :infiltratn_coeff_blw_liner, false, 'InfCfBeLin'],

  # Inlet Parameters
  ['Include Relative Stages', :relative_stages, false, 'RelStages'],
  ['Include Inlet Input Type', :inlet_input_type, false, 'InletInTyp'],
  ['Include Inlet Type', :inlet_type, false, 'InletType'],
  ['Include Cross Slope', :cross_slope, false, 'CrossSlope'],
  ['Include Grate Width', :grate_width, false, 'GrateWidth'],
  ['Include Grate Length', :grate_length, false, 'GrateLen'],
  ['Include Opening Length', :opening_length, false, 'OpenLen'],
  ['Include Opening Height', :opening_height, false, 'OpenHght'],
  ['Include Gutter Depression', :gutter_depression, false, 'GutDepress'],
  ['Include Lateral Depression', :lateral_depression, false, 'LatDepress'],
  ['Include Velocity Splashover', :velocity_splashover, false, 'VelSplash'],
  ['Include Debris Factor/Percentage', :debris, false, 'DebrisFact'],
  ['Include Depth Weir', :depth_weir, false, 'DepthWeir'],
  ['Include Clear Opening', :clear_opening, false, 'ClearOpen'],
  ['Include Head Discharge ID', :head_discharge_id, false, 'HD_ID'],
  ['Include Flow Efficiency ID', :flow_efficiency_id, false, 'FlowEffID'],
  ['Include Inlet UE_A', :inlet_UE_a, false, 'InletUE_A'], 
  ['Include Inlet UE_B', :inlet_UE_b, false, 'InletUE_B'], 
  ['Include Number of Gullies', :n_gullies, false, 'NumGullies'],
  ['Include Num Transverse Bars', :num_transverse_bars, false, 'NumTrnsBar'],
  ['Include Num Longitudinal Bars', :num_longitudinal_bars, false, 'NumLngBar'],
  ['Include Num Diagonal Bars', :num_diagonal_bars, false, 'NumDiagBar'],
  ['Include Min Area Inc Voids', :min_area_inc_voids, false, 'MinAreaVds'],
  ['Include Area of Voids', :area_of_voids, false, 'AreaVoids'],
  ['Include Half Road Width', :half_road_width, false, 'HalfRdWdth'],
  ['Include Benching Method', :benching_method, false, 'BenchMthd'],

  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
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
  puts "ERROR: WSApplication not found. Are you running this script within the application environment (e.g., InfoWorks ICM)?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Optional Debugging Block ---
# node_example = cn.row_objects('hw_node').first 
# if node_example
#   puts "--- DEBUG: Available methods for the first 'hw_node' object ---"
#   puts node_example.methods.sort.inspect 
#   if node_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'hw_node' object ---"
#      puts node_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit 
# else
#   puts "DEBUG: No 'hw_node' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false],
  ['Calculate Statistics for Numeric Fields', 'Boolean', false] # New option
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
file_path = File.join(export_folder, "selected_hw_nodes_export_#{timestamp}.csv")

selected_fields_config = [] 
header = []
field_option_start_index = 3 # options[0]=folder, options[1]=select_all, options[2]=calc_stats
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
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

nodes_iterated_count = 0  
nodes_written_count = 0   
numeric_data_for_stats = {} # To store numeric data

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing 'hw_node' objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('hw_node') 
    raise "Failed to retrieve 'hw_node' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |node_obj| 
      nodes_iterated_count += 1
      current_node_id_for_log = "UNKNOWN_NODE_ID_ITER_#{nodes_iterated_count}"
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
          value_for_csv = ""
          value_for_stats = nil
          begin
            raw_value = node_obj.send(attr_sym)
            
            if raw_value.is_a?(Array)
              case attr_sym
              when :storage_array
                value_for_csv = raw_value.map { |sa|
                  level = sa.is_a?(Hash) ? (sa[:level] || sa['level']) : (sa.respond_to?(:level) ? sa.level : 'N/A')
                  area = sa.is_a?(Hash) ? (sa[:area] || sa['area']) : (sa.respond_to?(:area) ? sa.area : 'N/A')
                  perimeter = sa.is_a?(Hash) ? (sa[:perimeter] || sa['perimeter']) : (sa.respond_to?(:perimeter) ? sa.perimeter : 'N/A')
                  "#{level},#{area},#{perimeter}"
                }.join(';')
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
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for 'hw_node' '#{current_node_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for 'hw_node' '#{current_node_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
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

  if calculate_stats && nodes_written_count > 0
    puts "\n--- Statistics for Exported Numeric Fields (hw_node) ---"
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

      non_numeric_symbols = [:node_id, :asset_id, :asset_uid, :infonet_id, :node_type, 
                             :system_type, :connection_type, :storage_array, :flood_type, 
                             :connect_2d_line, :link_type_2d, :lateral_node_id, 
                             :lateral_link_suffix, :inlet_input_type, :inlet_type, 
                             :head_discharge_id, :flow_efficiency_id, :notes, :hyperlinks,
                             :inlet_UE_a, :inlet_UE_b] # Added inlet_UE_a/b as likely non-numeric
      
      is_likely_text_or_id = field_info[:header].downcase.include?('id') ||
                              field_info[:header].downcase.include?('type') ||
                              field_info[:header].downcase.include?('array') || # storage_array
                              field_info[:header].downcase.include?('line') ||  # connect_2d_line
                              field_info[:header].downcase.include?('suffix') || # lateral_link_suffix
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
    puts "\nNo nodes were written to the CSV, so no statistics calculated."
  end

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

file_exists_and_has_data = File.exist?(file_path) && nodes_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Nodes Written', 'NUMBER', nodes_written_count],
    ['Number of Fields Exported Per Node', 'NUMBER', selected_fields_config.count] 
  ]
  WSApplication.prompt("Export Summary (Selected 'hw_node' Objects)", summary_layout, false)
elsif nodes_written_count == 0 && nodes_iterated_count >= 0
  message = "No 'hw_node' objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message, 'Info', :OK, false)
else
  WSApplication.message_box("Export for 'hw_node' did not complete as expected. No nodes written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for 'hw_node' complete."
