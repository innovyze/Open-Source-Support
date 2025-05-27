require 'csv'
require 'fileutils'

# --- Configuration: Define SWMM Weir Fields (from sw_parameters.rb) ---
# IMPORTANT: The symbols MUST match the actual method names available on 'sw_weir' objects.
# UNCOMMENT AND RUN THE DEBUGGING BLOCK BELOW to verify these names if needed.
FIELDS_TO_EXPORT = [
  # Core Weir Identifiers
  ['Include Weir ID', :id, true, 'Weir_ID'], # SWMM Weir ID
  ['Include US Node ID', :us_node_id, true, 'US_Node'],
  ['Include DS Node ID', :ds_node_id, true, 'DS_Node'],
  # Note: SWMM weirs typically don't have a 'link_suffix' like ICM links.

  # Weir Characteristics & Operation
  ['Include Link Type', :link_type, true, 'LinkType'], # e.g., TRANSVERSE, SIDEFLOW, V-NOTCH, TRAPEZOIDAL, ROADWAY
  ['Include Crest Level', :crest, true, 'CrestElev'], # Crest_ht in SWMM5 .inp
  ['Include Weir Height', :weir_height, true, 'WeirHeight'], # Geom1 for SWMM5 (Height for TRANSVERSE/SIDEFLOW, V-NOTCH; Depth for ROADWAY)
  ['Include Weir Width', :weir_width, false, 'WeirWidth'],   # Geom2 for SWMM5 (Width for TRANSVERSE/SIDEFLOW; Top Width for TRAPEZOIDAL; Surface Width for ROADWAY)
  ['Include Left Slope (Trapezoidal/Roadway)', :left_slope, false, 'LeftSlope'], # Geom3 for SWMM5
  ['Include Right Slope (Trapezoidal)', :right_slope, false, 'RightSlope'],# Geom4 for SWMM5
  ['Include Variable Discharge Coeff', :var_dis_coeff, false, 'VarDischCf'], # YES/NO or 1/0, for using weir curve for Cd
  ['Include Discharge Coefficient', :discharge_coeff, true, 'DischCoeff'], # Cd
  ['Include Sideflow Discharge Coeff', :sideflow_discharge_coeff, false, 'SideFlwCf'], # Cd_side for SIDEFLOW weirs
  ['Include Weir Curve ID', :weir_curve, false, 'WeirCrvID'], # Name of weir curve if var_dis_coeff is YES
  ['Include Flap Gate Present', :flap_gate, false, 'FlapGate'], # YES/NO
  ['Include End Contractions', :end_contractions, false, 'EndContrct'], # Number of end contractions
  ['Include Secondary Discharge Coeff (Drowned)', :secondary_discharge_coeff, false, 'SecDischCf'], # Cd_surch for surcharge algorithm
  ['Include Allows Surcharge', :allows_surcharge, false, 'AllowSurch'], # YES/NO for surcharge algorithm
  
  # Roadway Weir Specific (if applicable and distinct from general width/height)
  # ['Include Roadway Width', :width, false, 'RoadWidth'], # Often covered by weir_width for ROADWAY type
  # ['Include Roadway Surface Type', :surface, false, 'RoadSurf'], # PAVED/GRAVEL

  # Geometry & Network Info
  ['Include Point Array (Vertices)', :point_array, false, 'VerticesXY'], # X1,Y1;X2,Y2;...
  ['Include Branch ID', :branch_id, false, 'BranchID'], # If applicable

  # User Data and Notes
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'], # Desc1,URL1;Desc2,URL2;...
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
  puts "ERROR: WSApplication not found. Are you running this script within the application environment (e.g., InfoSWMM, InfoWorks ICM)?"
  puts "Details: #{e.message}"
  exit
rescue => e
  puts "ERROR: Could not get current network."
  puts "Details: #{e.class} - #{e.message}"
  exit
end

# --- Optional Debugging Block ---
# weir_example = cn.row_objects('sw_weir').first
# if weir_example
#   puts "--- DEBUG: Available methods for the first 'sw_weir' object ---"
#   puts weir_example.methods.sort.inspect
#   if weir_example.respond_to?(:fields)
#      puts "\n--- DEBUG: Output of '.fields' method for the first 'sw_weir' object ---"
#      puts weir_example.fields.inspect
#   end
#   puts "--- END DEBUG ---"
#   # exit
# else
#   puts "DEBUG: No 'sw_weir' objects found in the network to inspect."
# end
# --- End Optional Debugging Block ---

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['SELECT/DESELECT ALL FIELDS', 'Boolean', false],
  ['Calculate Statistics for Numeric Fields', 'Boolean', false] # New option for statistics
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED SWMM Weir Objects", prompt_options, false)
if options.nil?
  puts "User cancelled the operation. Exiting."
  exit
end

puts "Starting script for SWMM Weir export at #{Time.now}"
start_time = Time.now

export_folder = options[0]
select_all_state = options[1]
calculate_stats = options[2] # Get the state of the new checkbox

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
file_path = File.join(export_folder, "selected_swmm_weirs_export_#{timestamp}.csv")

selected_fields_config = []
header = []
# Adjust index for reading field selection options due to the new "Calculate Statistics" option
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

weirs_iterated_count = 0
weirs_written_count = 0
numeric_data_for_stats = {} # To store numeric data for statistics calculation

begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}: #{header.join(', ')}"
    csv << header

    puts "Processing SWMM Weir objects... (Checking selection status for each)"
    
    row_objects_iterator = cn.row_objects('sw_weir') # Target 'sw_weir'
    raise "Failed to retrieve 'sw_weir' objects." if row_objects_iterator.nil?

    row_objects_iterator.each do |weir_obj|
      weirs_iterated_count += 1
      current_weir_id_for_log = "UNKNOWN_WEIR_ITER_#{weirs_iterated_count}"
      if weir_obj.respond_to?(:id) && weir_obj.id
        current_weir_id_for_log = weir_obj.id.to_s
      end

      if weir_obj && weir_obj.respond_to?(:selected) && weir_obj.selected
        weirs_written_count += 1
        row_data = []
        
        selected_fields_config.each do |field_info|
          attr_sym = field_info[:attribute]
          value_for_csv = ""
          value_for_stats = nil
          begin
            raw_value = weir_obj.send(attr_sym)
            
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
              # Attempt to convert to float for statistics
              if calculate_stats && !raw_value.nil? && raw_value.to_s != ""
                begin
                  value_for_stats = Float(raw_value)
                rescue ArgumentError, TypeError
                  # Not a number, do nothing for stats for this value
                end
              end
            end
            row_data << value_for_csv

            # Store numeric value for stats
            if calculate_stats && !value_for_stats.nil?
              numeric_data_for_stats[attr_sym] ||= []
              numeric_data_for_stats[attr_sym] << value_for_stats
            end

          rescue NoMethodError
            puts "Warning: Attribute (method) ':#{attr_sym}' (for field '#{field_info[:original_label]}') not found for SWMM Weir '#{current_weir_id_for_log}'."
            row_data << "AttributeMissing"
          rescue => e
            puts "Error: Accessing attribute ':#{attr_sym}' (for field '#{field_info[:original_label]}') for SWMM Weir '#{current_weir_id_for_log}' failed: #{e.class} - #{e.message}"
            row_data << "AccessError"
          end
        end
        csv << row_data
      end # if weir_obj selected
    end # cn.row_objects.each
  end # CSV.open block

  puts "\n--- Processing Summary (SWMM Weirs) ---"
  puts "Total SWMM Weir objects iterated in network: #{weirs_iterated_count}"
  if weirs_written_count > 0
    puts "Successfully wrote #{weirs_written_count} selected SWMM Weir objects to #{file_path}"
  else
    puts "No SWMM Weir objects were selected or matched criteria for export."
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

  # Calculate and print statistics if requested
  if calculate_stats && weirs_written_count > 0
    puts "\n--- Statistics for Exported Numeric Fields (SWMM Weirs) ---"
    puts "----------------------------------------------------------------------------------------------------"
    puts "| %-30s | %-10s | %-10s | %-15s | %-15s |" % ["Parameter", "Min", "Max", "Mean", "Std Dev"]
    puts "----------------------------------------------------------------------------------------------------"
    
    found_numeric_data = false
    selected_fields_config.each do |field_info|
      attr_sym = field_info[:attribute]
      data_array = numeric_data_for_stats[attr_sym]

      if data_array && !data_array.empty?
        found_numeric_data = true
        min_val = data_array.min
        max_val = data_array.max
        mean_val = calculate_mean(data_array)
        std_dev_val = calculate_std_dev(data_array, mean_val)

        puts "| %-30s | %-10.3f | %-10.3f | %-15.3f | %-15s |" % [
          field_info[:header], 
          min_val, 
          max_val, 
          mean_val,
          (std_dev_val.nil? ? "N/A (n<2)" : "%.3f" % std_dev_val)
        ]
      elsif [:point_array, :hyperlinks, :notes].include?(attr_sym) || field_info[:header].downcase.include?('id') || field_info[:header].downcase.include?('type')
        # Skip non-numeric or identifier fields explicitly in the stats table for clarity
      else
         # Optionally, indicate fields for which no numeric data was found or that were not suitable for stats
         # puts "| %-30s | %-10s | %-10s | %-15s | %-15s |" % [field_info[:header], "N/A", "N/A", "N/A", "N/A"]
      end
    end
    puts "----------------------------------------------------------------------------------------------------"
    unless found_numeric_data
        puts "No numeric data found for selected fields to calculate statistics."
    end
  elsif calculate_stats
    puts "\nNo weirs were written to the CSV, so no statistics calculated."
  end


rescue Errno::EACCES => e
  puts "FATAL ERROR: Permission denied writing to file '#{file_path}'. - #{e.message}"
rescue Errno::ENOSPC => e
  puts "FATAL ERROR: No space left on device writing to file '#{file_path}'. - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "FATAL ERROR: CSV formatting issue during write to '#{file_path}'. - #{e.message}"
rescue => e
  puts "FATAL ERROR: Unexpected failure during SWMM Weir CSV export. - #{e.class}: #{e.message}"
  puts "Backtrace (first 5 lines):\n#{e.backtrace.first(5).join("\n")}"
end

end_time = Time.now
time_spent = end_time - start_time
puts "\nScript for SWMM Weir export finished at #{end_time}"
puts "Total time spent: #{'%.2f' % time_spent} seconds"

file_exists_and_has_data = File.exist?(file_path) && weirs_written_count > 0

if file_exists_and_has_data
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected SWMM Weirs Written', 'NUMBER', weirs_written_count],
    ['Number of Fields Exported Per Weir', 'NUMBER', selected_fields_config.count]
  ]
  WSApplication.prompt("Export Summary (Selected SWMM Weir Objects)", summary_layout, false)
elsif weirs_written_count == 0 && weirs_iterated_count >= 0
  message = "No SWMM Weir objects were selected for export."
  message += " The CSV file was not created or was empty (and thus deleted)." if !file_path.empty? && !File.exist?(file_path)
  WSApplication.message_box(message, 'Info', :OK, false)
else
  WSApplication.message_box("Export for SWMM Weirs did not complete as expected. No weirs written. Check console messages. The CSV file may not exist or is empty.", 'Info', :OK, false)
end

puts "\nScript execution for SWMM Weir complete."
