require 'csv'
require 'fileutils'

# --- Configuration: Define Fields ---
FIELDS_TO_EXPORT = [
  ['Include Pipe ID', :id, true, 'Pipe ID'],
  ['Include US Node ID', :us_node_id, false, 'US Node ID'],
  ['Include Link Suffix', :link_suffix, false, 'Link Suffix'],
  ['Include DS Node ID', :ds_node_id, false, 'DS Node ID'],
  ['Include Link Type', :link_type, false, 'Link Type'],
  ['Include Asset ID', :asset_id, false, 'Asset ID'],
  ['Include Sewer Reference', :sewer_reference, false, 'Sewer Reference'],
  ['Include System Type', :system_type, false, 'System Type'],
  ['Include Branch ID', :branch_id, false, 'Branch ID'],
  ['Include Point Array', :point_array, false, 'Point Array'],
  ['Include Is Merged', :is_merged, false, 'Is Merged'],
  ['Include Asset UID', :asset_uid, false, 'Asset UID'],
  ['Include US Settlement Eff', :us_settlement_eff, false, 'US Settlement Eff'],
  ['Include DS Settlement Eff', :ds_settlement_eff, false, 'DS Settlement Eff'],
  ['Include Solution Model', :solution_model, false, 'Solution Model'],
  ['Include Min Computational Nodes', :min_computational_nodes, false, 'Min Computational Nodes'],
  ['Include Critical Sewer Category', :critical_sewer_category, false, 'Critical Sewer Category'],
  ['Include Taking Off Reference', :taking_off_reference, false, 'Taking Off Reference'],
  ['Include Conduit Material', :conduit_material, false, 'Conduit Material'],
  ['Include Design Group', :design_group, false, 'Design Group'],
  ['Include Site Condition', :site_condition, false, 'Site Condition'],
  ['Include Ground Condition', :ground_condition, false, 'Ground Condition'],
  ['Include Conduit Type', :conduit_type, false, 'Conduit Type'],
  ['Include Min Space Step', :min_space_step, false, 'Min Space Step'],
  ['Include Slot Width', :slot_width, false, 'Slot Width'],
  ['Include Connection Coefficient', :connection_coefficient, false, 'Connection Coefficient'],
  ['Include Shape', :shape, false, 'Shape'],
  ['Include Conduit Width', :conduit_width, true, 'Conduit Width'],
  ['Include Conduit Height', :conduit_height, false, 'Conduit Height'],
  ['Include Springing Height', :springing_height, false, 'Springing Height'],
  ['Include Sediment Depth', :sediment_depth, false, 'Sediment Depth'],
  ['Include Number of Barrels', :number_of_barrels, false, 'Number of Barrels'],
  ['Include Roughness Type', :roughness_type, false, 'Roughness Type'],
  ['Include Bottom Roughness CW', :bottom_roughness_CW, false, 'Bottom Roughness CW'],
  ['Include Top Roughness CW', :top_roughness_CW, false, 'Top Roughness CW'],
  ['Include Bottom Roughness Manning', :bottom_roughness_Manning, false, 'Bottom Roughness Manning'],
  ['Include Top Roughness Manning', :top_roughness_Manning, false, 'Top Roughness Manning'],
  ['Include Bottom Roughness N', :bottom_roughness_N, false, 'Bottom Roughness N'],
  ['Include Top Roughness N', :top_roughness_N, false, 'Top Roughness N'],
  ['Include Bottom Roughness HW', :bottom_roughness_HW, false, 'Bottom Roughness HW'],
  ['Include Top Roughness HW', :top_roughness_HW, false, 'Top Roughness HW'],
  ['Include Conduit Length', :conduit_length, false, 'Conduit Length'],
  ['Include Inflow', :inflow, false, 'Inflow'],
  ['Include Gradient', :gradient, false, 'Gradient'],
  ['Include Capacity', :capacity, false, 'Capacity'],
  ['Include US Invert', :us_invert, false, 'US Invert'],
  ['Include DS Invert', :ds_invert, false, 'DS Invert'],
  ['Include US Headloss Type', :us_headloss_type, false, 'US Headloss Type'],
  ['Include DS Headloss Type', :ds_headloss_type, false, 'DS Headloss Type'],
  ['Include US Headloss Coeff', :us_headloss_coeff, false, 'US Headloss Coeff'],
  ['Include DS Headloss Coeff', :ds_headloss_coeff, false, 'DS Headloss Coeff'],
  ['Include Base Height', :base_height, false, 'Base Height'],
  ['Include Infiltration Coeff Base', :infiltration_coeff_base, false, 'Infiltration Coeff Base'],
  ['Include Infiltration Coeff Side', :infiltration_coeff_side, false, 'Infiltration Coeff Side'],
  ['Include Fill Material Conductivity', :fill_material_conductivity, false, 'Fill Material Conductivity'],
  ['Include Porosity', :porosity, false, 'Porosity'],
  ['Include Diff1D Type', :diff1d_type, false, 'Diff1D Type'],
  ['Include Diff1D D0', :diff1d_d0, false, 'Diff1D D0'],
  ['Include Diff1D D1', :diff1d_d1, false, 'Diff1D D1'],
  ['Include Diff1D D2', :diff1d_d2, false, 'Diff1D D2'],
  ['Include Inlet Type Code', :inlet_type_code, false, 'Inlet Type Code'],
  ['Include Reverse Flow Model', :reverse_flow_model, false, 'Reverse Flow Model'],
  ['Include Equation', :equation, false, 'Equation'],
  ['Include K', :k, false, 'K'],
  ['Include M', :m, false, 'M'],
  ['Include C', :c, false, 'C'],
  ['Include Y', :y, false, 'Y'],
  ['Include US Ki', :us_ki, false, 'US Ki'],
  ['Include US Ko', :us_ko, false, 'US Ko'],
  ['Include Outlet Type Code', :outlet_type_code, false, 'Outlet Type Code'],
  ['Include Equation O', :equation_o, false, 'Equation O'],
  ['Include K O', :k_o, false, 'K O'],
  ['Include M O', :m_o, false, 'M O'],
  ['Include C O', :c_o, false, 'C O'],
  ['Include Y O', :y_o, false, 'Y O'],
  ['Include DS Ki', :ds_ki, false, 'DS Ki'],
  ['Include DS Ko', :ds_ko, false, 'DS Ko'],
  ['Include Notes', :notes, false, 'Notes'],
  ['Include Hyperlinks', :hyperlinks, false, 'Hyperlinks'],
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
  cn = WSApplication.current_network
  raise "No network loaded" if cn.nil?
rescue => e
  puts "ERROR: Could not get current network."
  puts e.message
  exit
end

prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder']
]
FIELDS_TO_EXPORT.each do |field_config|
  prompt_options << [field_config[0], 'Boolean', field_config[2]]
end

options = WSApplication.prompt("Select options for CSV export of SELECTED hw_conduit rows", prompt_options, false)
if options.nil?
  puts "User cancelled the operation."
  exit
end

puts "Starting script at #{Time.now}"
start_time = Time.now

export_folder = options[0]
unless export_folder && !export_folder.empty?
  puts "ERROR: Export folder not specified."
  exit
end
begin
  Dir.mkdir(export_folder) unless Dir.exist?(export_folder)
rescue Errno::EACCES => e
   puts "ERROR: Permission denied creating directory '#{export_folder}' - #{e.message}"
   exit
rescue => e
   puts "ERROR: Could not create directory '#{export_folder}' - #{e.message}"
   exit
end
file_path = File.join(export_folder, "selected_pipes_export_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv")

selected_fields = []
header = []
FIELDS_TO_EXPORT.each_with_index do |field_config, index|
  if options[index + 1]
    selected_fields << { attribute: field_config[1], header: field_config[3] }
    header << field_config[3]
  end
end

if selected_fields.empty?
  puts "No fields selected for export. Exiting."
  exit
end

conduit_count = 0
begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing header to #{file_path}"
    csv << header

    puts "Processing conduits... (Checking selection status for each)"
    # NOTE: This iterates ALL conduits. Using cn.selection is generally faster.
    cn.row_objects('hw_conduit').each do |pipe|
       # Check if pipe exists, has a 'selected' property/method, and it's true
       if pipe && pipe.respond_to?(:selected) && pipe.selected
          # --- Process Selected Pipe ---
          conduit_count += 1
          row_data = []
          selected_fields.each do |field_info|
            begin
              value = pipe.send(field_info[:attribute])
              row_data << (value.nil? ? "N/A" : value)
            rescue NoMethodError
              pipe_identifier = pipe.id rescue (pipe.asset_id rescue 'UNKNOWN_ID')
              puts "Warning: Attribute '#{field_info[:attribute]}' not found for selected pipe '#{pipe_identifier}' (row #{conduit_count})"
              row_data << "AttributeError"
            rescue => e
              pipe_identifier = pipe.id rescue (pipe.asset_id rescue 'UNKNOWN_ID')
              puts "Warning: Error accessing attribute '#{field_info[:attribute]}' for selected pipe '#{pipe_identifier}' (row #{conduit_count}): #{e.message}"
              row_data << "AccessError"
            end
          end
          csv << row_data
          # --- End Process Selected Pipe ---
       end # if pipe selected
    end # cn.row_objects.each
  end # CSV.open block

  # Check if any conduits were actually selected and written
  if conduit_count > 0
    puts "Successfully wrote #{conduit_count} selected conduits to #{file_path}"
  else
    puts "No conduits were selected in the network, or file writing failed before processing."
    # Optional: Delete the empty file if no conduits were selected?
    # File.delete(file_path) if File.exist?(file_path)
  end

rescue Errno::EACCES => e
  puts "ERROR: Permission denied writing to file - #{e.message}"
rescue Errno::ENOSPC => e
  puts "ERROR: No space left on device writing to file - #{e.message}"
rescue CSV::MalformedCSVError => e
  puts "ERROR: CSV formatting issue during write - #{e.message}"
rescue => e
  puts "ERROR: Unexpected failure during CSV export - #{e.class}: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end

end_time = Time.now
time_spent = end_time - start_time
puts "Script finished at #{end_time}"
puts "Time spent processing and writing: #{'%.2f' % time_spent} seconds"

# Display summary prompt
if File.exist?(file_path) || conduit_count > 0
  summary_layout = [
    ['Export File Path', 'READONLY', file_path],
    ['Number of Selected Conduits Written', 'NUMBER', conduit_count], # Updated label
    ['Number of Fields Exported Per Conduit', 'NUMBER', selected_fields.count] # Updated label
  ]
  WSApplication.prompt('Export Summary (Selected Conduits)', summary_layout, false)
else
  puts "No selected conduits were processed or file was not created."
end

puts "Script execution complete."