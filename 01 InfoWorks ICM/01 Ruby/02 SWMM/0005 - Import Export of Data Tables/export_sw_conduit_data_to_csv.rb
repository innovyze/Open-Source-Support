require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Conduit Fields ---
# IMPORTANT: The symbols (e.g., :id, :us_node_id) MUST match the actual
# method names available on 'sw_conduit' objects in your environment.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names.
FIELDS_TO_EXPORT = [
  # Common SWMM fields - verify these against your specific API version
  ['Include Conduit ID', :id, true, 'ConduitID'], # Made concise
  ['Include US Node ID', :us_node_id, true, 'US_NodeID'],
  ['Include DS Node ID', :ds_node_id, true, 'DS_NodeID'],
  ['Include Length', :length, true, 'Length'],
  ['Include Point Array', :point_array, false, 'PointArray'], # Complex
  ['Include Shape', :shape, true, 'Shape'], # Textual, not for stats
  
  ['Include Horiz Ellipse Size Code', :horiz_ellipse_size_code, false, 'HorizElSzC'],
  ['Include Vert Ellipse Size Code', :vert_ellipse_size_code, false, 'VertElSzC'],
  ['Include Arch Material', :arch_material, false, 'ArchMat'],
  ['Include Arch Concrete Size Code', :arch_concrete_size_code, false, 'ArchConSzC'],
  ['Include Arch Plate 18 Size Code', :arch_plate_18_size_code, false, 'ArchPl18SzC'],
  ['Include Arch Plate 31 Size Code', :arch_plate_31_size_code, false, 'ArchPl31SzC'],
  ['Include Arch Steel Half Size Code', :arch_steel_half_size_code, false, 'ArchStHfSzC'],
  ['Include Arch Steel Inch Size Code', :arch_steel_inch_size_code, false, 'ArchStInSzC'],
  
  ['Include Conduit Height', :conduit_height, true, 'CondHeight'],
  ['Include Conduit Width', :conduit_width, true, 'CondWidth'],
  ['Include Number of Barrels', :number_of_barrels, false, 'NumBarrels'],
  
  ['Include Roughness DW', :roughness_DW, false, 'RoughDW'],
  ['Include Roughness HW', :roughness_HW, false, 'RoughHW'],
  ['Include Mannings N', :Mannings_N, true, 'ManningsN'],

  ['Include Top Radius', :top_radius, false, 'TopRadius'],
  ['Include Left Slope', :left_slope, false, 'LeftSlope'],
  ['Include Right Slope', :right_slope, false, 'RightSlope'],
  ['Include Triangle Height', :triangle_height, false, 'TriHeight'],
  ['Include Bottom Radius', :bottom_radius, false, 'BotRadius'],
  ['Include Shape Curve', :shape_curve, false, 'ShapeCurve'], # Textual ID
  ['Include Shape Exponent', :shape_exponent, false, 'ShapeExp'],
  ['Include Transect', :transect, false, 'TransectID'], # Textual ID

  ['Include US Invert', :us_invert, true, 'US_Invert'], # Changed from false
  ['Include DS Invert', :ds_invert, true, 'DS_Invert'], # Changed from false
  ['Include US Headloss Coeff', :us_headloss_coeff, false, 'US_HLCoeff'],
  ['Include DS Headloss Coeff', :ds_headloss_coeff, false, 'DS_HLCoeff'],
  ['Include Initial Flow', :initial_flow, false, 'InitFlow'],
  ['Include Max Flow', :max_flow, false, 'MaxFlow'], # Potentially for stats, but often a result or limit
  
  ['Include Bottom Mannings N', :bottom_mannings_N, false, 'BotMannN'],
  ['Include Roughness Depth Threshold', :roughness_depth_threshold, false, 'RoughDepThr'],
  ['Include Sediment Depth', :sediment_depth, false, 'SedDepth'],
  ['Include Avg Headloss Coeff', :av_headloss_coeff, false, 'AvgHLCoeff'],
  ['Include Seepage Rate', :seepage_rate, false, 'SeepRate'],
  ['Include Culvert Code', :culvert_code, false, 'CulvertCode'], # Textual
  ['Include Flap Gate', :flap_gate, false, 'FlapGate'], # Boolean
  
  ['Include Branch ID', :branch_id, false, 'BranchID'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'], # Complex
  ['Include Notes', :notes, false, 'Notes'], # Textual
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
# conduit_example = cn.row_objects('sw_conduit').first 
# if conduit_example
#   puts "--- DEBUG: Available methods for the first 'sw_conduit' object ---"
#   puts conduit_example.methods.sort.inspect 
#   if conduit_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_conduit' object ---"
#      puts conduit_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit 
# else
#   puts "DEBUG: No 'sw_conduit' objects found in the network to inspect."
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

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Conduit Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Conduit export at #{Time.now}"
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
file_path = File.join(export_folder, "selected_swmm_conduits_export_#{timestamp}.csv")

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

conduits_iterated_count = 0
conduits_written_count = 0
numeric_data_for_stats = {} # To store numeric data

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing SWMM Conduit objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('sw_conduit') # Target 'sw_conduit'
    raise "Failed to retrieve 'sw_conduit' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |conduit_obj| # Changed variable name from pipe to conduit_obj
      conduits_iterated_count += 1
      current_conduit_id_for_log = "UNKNOWN_CONDUIT_ITER_#{conduits_iterated_count}"
      if conduit_obj.respond_to?(:id) && conduit_obj.id
        current_conduit_id_for_log = conduit_obj.id.to_s
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
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for SWMM Conduit '#{current_conduit_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for SWMM Conduit '#{current_conduit_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if conduit_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (SWMM Conduits) ---"
  puts "Total SWMM Conduit objects iterated in network: #{conduits_iterated_count}"
  if conduits_written_count > 0
    puts "Successfully wrote #{conduits_written_count} selected SWMM Conduit objects to #{file_path}"
  else
    puts "No SWMM Conduit objects were selected or matched criteria for export."
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
    puts "\n--- Statistics for Exported Numeric Fields (SWMM Conduits) ---"
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
        :id, :us_node_id, :ds_node_id, :point_array, :shape, :arch_material, 
        :shape_curve, :transect, :culvert_code, :branch_id, :hyperlinks, :notes,
        :horiz_ellipse_size_code, :vert_ellipse_size_code, :arch_concrete_size_code,
        :arch_plate_18_size_code, :arch_plate_31_size_code, :arch_steel_half_size_code,
        :arch_steel_inch_size_code
      ]
      
      is_likely_text_or_id = field_info[:header].downcase.include?('id') ||
                              field_info[:header].downcase.include?('type') || # For link_type
                              field_info[:header].downcase.include?('code') || # For size codes, culvert_code
                              field_info[:header].downcase.include?('material') ||
                              field_info[:header].downcase.include?('shape') || # For shape and shape_curve
                              field_info[:header].downcase.include?('transect') ||
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
    puts "\nNo conduits were written to the CSV, so no statistics calculated."
  end

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
elsif conduits_written_count == 0 && conduits_iterated_count >= 0
  message = "No SWMM conduits were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message, 'OK',nil,false)
else
  WSApplication.message_box("Export for SWMM Conduits did not complete as expected. No conduits written. Check console messages. The CSV file may not exist or is empty.", 'OK',nil,false)
end

puts "\nScript execution for SWMM Conduits complete."
