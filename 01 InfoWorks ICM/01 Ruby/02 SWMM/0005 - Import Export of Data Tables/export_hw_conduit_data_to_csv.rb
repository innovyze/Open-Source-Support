require 'csv'
require 'fileutils'

# --- Configuration: Define Fields ---
FIELDS_TO_EXPORT = [
  ['Include Pipe ID', :id, true, 'Pipe_ID'], # Shortened for potential Shapefile use, though not implemented here
  ['Include US Node ID', :us_node_id, true, 'US_NodeID'],
  ['Include Link Suffix', :link_suffix, false, 'LinkSuffix'],
  ['Include DS Node ID', :ds_node_id, true, 'DS_NodeID'],
  ['Include Link Type', :link_type, false, 'LinkType'],
  ['Include Asset ID', :asset_id, false, 'AssetID'],
  ['Include Sewer Reference', :sewer_reference, false, 'SewerRef'],
  ['Include System Type', :system_type, false, 'SystemType'],
  ['Include Branch ID', :branch_id, false, 'BranchID'],
  ['Include Point Array', :point_array, false, 'PointArray'], # Complex field, stringified
  ['Include Is Merged', :is_merged, false, 'IsMerged'],
  ['Include Asset UID', :asset_uid, false, 'AssetUID'],
  ['Include US Settlement Eff', :us_settlement_eff, false, 'US_SettEff'],
  ['Include DS Settlement Eff', :ds_settlement_eff, false, 'DS_SettEff'],
  ['Include Solution Model', :solution_model, false, 'SolModel'],
  ['Include Min Computational Nodes', :min_computational_nodes, false, 'MinCompNod'],
  ['Include Critical Sewer Category', :critical_sewer_category, false, 'CritSwrCat'],
  ['Include Taking Off Reference', :taking_off_reference, false, 'TakeOffRef'],
  ['Include Conduit Material', :conduit_material, false, 'Material'],
  ['Include Design Group', :design_group, false, 'DesignGrp'],
  ['Include Site Condition', :site_condition, false, 'SiteCond'],
  ['Include Ground Condition', :ground_condition, false, 'GndCond'],
  ['Include Conduit Type', :conduit_type, false, 'CondType'],
  ['Include Min Space Step', :min_space_step, false, 'MinSpcStep'],
  ['Include Slot Width', :slot_width, false, 'SlotWidth'],
  ['Include Connection Coefficient', :connection_coefficient, false, 'ConnectCoeff'],
  ['Include Shape', :shape, true, 'Shape'],
  ['Include Conduit Width', :conduit_width, true, 'CondWidth'],
  ['Include Conduit Height', :conduit_height, true, 'CondHeight'],
  ['Include Springing Height', :springing_height, false, 'SpringHght'],
  ['Include Sediment Depth', :sediment_depth, false, 'SedDepth'],
  ['Include Number of Barrels', :number_of_barrels, false, 'NumBarrels'],
  ['Include Roughness Type', :roughness_type, false, 'RoughType'],
  ['Include Bottom Roughness CW', :bottom_roughness_CW, false, 'BotRoughCW'],
  ['Include Top Roughness CW', :top_roughness_CW, false, 'TopRoughCW'],
  ['Include Bottom Roughness Manning', :bottom_roughness_Manning, true, 'BotRoughM'],
  ['Include Top Roughness Manning', :top_roughness_Manning, false, 'TopRoughM'],
  ['Include Bottom Roughness N', :bottom_roughness_N, false, 'BotRoughN'], # Often same as Manning
  ['Include Top Roughness N', :top_roughness_N, false, 'TopRoughN'],     # Often same as Manning
  ['Include Bottom Roughness HW', :bottom_roughness_HW, false, 'BotRoughHW'],
  ['Include Top Roughness HW', :top_rough_HW, false, 'TopRoughHW'], # Corrected symbol from original file
  ['Include Conduit Length', :conduit_length, true, 'Length'],
  ['Include Inflow', :inflow, false, 'Inflow'],
  ['Include Gradient', :gradient, true, 'Gradient'],
  ['Include Capacity', :capacity, false, 'Capacity'],
  ['Include US Invert', :us_invert, true, 'US_Invert'],
  ['Include DS Invert', :ds_invert, true, 'DS_Invert'],
  ['Include US Headloss Type', :us_headloss_type, false, 'US_HL_Type'],
  ['Include DS Headloss Type', :ds_headloss_type, false, 'DS_HL_Type'],
  ['Include US Headloss Coeff', :us_headloss_coeff, false, 'US_HLCoeff'],
  ['Include DS Headloss Coeff', :ds_headloss_coeff, false, 'DS_HLCoeff'],
  ['Include Base Height', :base_height, false, 'BaseHeight'],
  ['Include Infiltration Coeff Base', :infiltration_coeff_base, false, 'InfCoBase'],
  ['Include Infiltration Coeff Side', :infiltration_coeff_side, false, 'InfCoSide'],
  ['Include Fill Material Conductivity', :fill_material_conductivity, false, 'FillCond'],
  ['Include Porosity', :porosity, false, 'Porosity'],
  ['Include Diff1D Type', :diff1d_type, false, 'Diff1DType'],
  ['Include Diff1D D0', :diff1d_d0, false, 'Diff1DD0'],
  ['Include Diff1D D1', :diff1d_d1, false, 'Diff1DD1'],
  ['Include Diff1D D2', :diff1d_d2, false, 'Diff1DD2'],
  ['Include Inlet Type Code', :inlet_type_code, false, 'InletCode'],
  ['Include Reverse Flow Model', :reverse_flow_model, false, 'RevFlowMod'],
  ['Include Equation', :equation, false, 'Equation'],
  ['Include K', :k, false, 'K_Coeff'],
  ['Include M', :m, false, 'M_Coeff'],
  ['Include C', :c, false, 'C_Coeff'],
  ['Include Y', :y, false, 'Y_Coeff'],
  ['Include US Ki', :us_ki, false, 'US_Ki'],
  ['Include US Ko', :us_ko, false, 'US_Ko'],
  ['Include Outlet Type Code', :outlet_type_code, false, 'OutletCode'],
  ['Include Equation O', :equation_o, false, 'Equation_O'],
  ['Include K O', :k_o, false, 'K_O_Coeff'],
  ['Include M O', :m_o, false, 'M_O_Coeff'],
  ['Include C O', :c_o, false, 'C_O_Coeff'],
  ['Include Y O', :y_o, false, 'Y_O_Coeff'],
  ['Include DS Ki', :ds_ki, false, 'DS_Ki'],
  ['Include DS Ko', :ds_ko, false, 'DS_Ko'],
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'], # Complex field
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
# conduit_example = cn.row_objects('hw_conduit').first
# if conduit_example
#   puts "--- DEBUG: Available methods for hw_conduit object ---"
#   puts conduit_example.methods.sort
#   if conduit_example.respond_to?(:fields)
#      puts "\n--- DEBUG: '.fields' output ---"
#      puts conduit_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit
# else
#   puts "DEBUG: No 'hw_conduit' objects found to inspect."
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

options = WSApplication.prompt("Select options for CSV export of SELECTED 'hw_conduit' Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for 'hw_conduit' export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_hw_conduits_export_#{timestamp}.csv")

selected_fields_config = []
header = []
# Adjust index for reading field selection options
field_option_start_index = 3 
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

conduits_iterated_count = 0
conduits_written_count = 0
numeric_data_for_stats = {} # To store numeric data

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing 'hw_conduit' objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('hw_conduit')
    raise "Failed to retrieve 'hw_conduit' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |conduit_obj|
      conduits_iterated_count += 1
      current_conduit_id_for_log = "UNKNOWN_CONDUIT_ITER_#{conduits_iterated_count}"
      if conduit_obj.respond_to?(:id) && conduit_obj.id # 'id' is common for conduits
        current_conduit_id_for_log = conduit_obj.id.to_s
      elsif conduit_obj.respond_to?(:asset_id) && conduit_obj.asset_id
         current_conduit_id_for_log = conduit_obj.asset_id.to_s
      end


      if conduit_obj && conduit_obj.respond_to?(:selected) && conduit_obj.selected
        conduits_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          value_for_csv = ""
          value_for_stats = nil
          begin
            raw_value = conduit_obj.send(attr_sym)
            
            if raw_value.is_a?(Array)
              case attr_sym
              when :point_array
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
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for selected 'hw_conduit' '#{current_conduit_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for 'hw_conduit' '#{current_conduit_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if conduit_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (hw_conduit) ---"
  puts "Total 'hw_conduit' objects iterated in network: #{conduits_iterated_count}"
  if conduits_written_count > 0
    puts "Successfully wrote #{conduits_written_count} selected 'hw_conduit' objects to #{file_path}"
  else
    puts "No 'hw_conduit' objects were selected or matched criteria for export."
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

  if calculate_stats && conduits_written_count > 0
    puts "\n--- Statistics for Exported Numeric Fields (hw_conduit) ---"
    param_col_width = 30
    count_col_width = 8
    min_col_width = 12
    max_col_width = 12
    mean_col_width = 15
    std_dev_col_width = 15
    total_width = param_col_width + count_col_width + min_col_width + max_col_width + mean_col_width + std_dev_col_width + (5 * 3)

    puts "-" * total_width
    puts "| %-#{param_col_width}s | %-#{count_col_width}s | %-#{min_col_width}s | %-#{max_col_width}s | %-#{mean_col_width}s | %-#{std_dev_col_width}s |" % 
         ["Parameter", "Count", "Min", "Max", "Mean", "Std Dev"]
    puts "-" * total_width
    
    found_numeric_data_for_table = false
    selected_fields_config.each do |field_info|
      attr_sym = field_info[:attribute]
      data_array = numeric_data_for_stats[attr_sym]

      if data_array && !data_array.empty?
        found_numeric_data_for_table = true
        count_val = data_array.length
        min_val = data_array.min
        max_val = data_array.max
        mean_val = calculate_mean(data_array)
        std_dev_val = calculate_std_dev(data_array, mean_val)

        puts "| %-#{param_col_width}s | %-#{count_col_width}d | %-#{min_col_width}.3f | %-#{max_col_width}.3f | %-#{mean_col_width}.3f | %-#{std_dev_col_width}s |" % [
          field_info[:header].slice(0, param_col_width),
          count_val, 
          min_val, 
          max_val, 
          mean_val,
          (std_dev_val.nil? ? "N/A (n<2)" : "%.3f" % std_dev_val)
        ]
      elsif [:point_array, :hyperlinks, :notes, :id, :us_node_id, :ds_node_id, :link_type, :shape, :asset_id, :sewer_reference, :system_type, :solution_model, :critical_sewer_category, :taking_off_reference, :conduit_material, :design_group, :site_condition, :ground_condition, :conduit_type, :roughness_type, :us_headloss_type, :ds_headloss_type, :diff1d_type, :inlet_type_code, :reverse_flow_model, :equation, :outlet_type_code, :equation_o].include?(attr_sym) || field_info[:header].downcase.include?('id') || field_info[:header].downcase.include?('type') || field_info[:header].downcase.include?('ref') || field_info[:header].downcase.include?('code') || field_info[:header].downcase.include?('model') || field_info[:header].downcase.include?('cat')
        # Skip non-numeric, ID, type, reference, code, model, or category fields in the stats table
      end
    end
    puts "-" * total_width
    unless found_numeric_data_for_table
        puts "No numeric data found for selected fields to calculate statistics."
    end
  elsif calculate_stats
    puts "\nNo conduits were written to the CSV, so no statistics calculated."
  end

rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during 'hw_conduit' CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for 'hw_conduit' export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && conduits_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Conduits Written', 'NUMBER', conduits_written_count],
    ['Number of Fields Exported Per Conduit', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected 'hw_conduit' Objects)", summary_layout, false)
elsif conduits_written_count == 0 && conduits_iterated_count >= 0
  message = "No 'hw_conduit' objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message, 'OK',nil,false)
else
  WSApplication.message_box("Export for 'hw_conduit' did not complete as expected. No conduits written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for 'hw_conduit' complete."
