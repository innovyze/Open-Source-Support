require 'csv'

# Get the current network
cn = WSApplication.current_network
if cn.nil?
  puts "ERROR: No current network available"
  raise "No network loaded"
end

# Define all unique hw_conduit variables as boolean options (no flags, no duplicates)
prompt_options = [
  ['Folder for Exported File', 'String', nil, nil, 'FOLDER', 'Export Folder'],
  ['Include Pipe ID', 'Boolean', true],
  ['Include US Node ID', 'Boolean', false],
  ['Include Link Suffix', 'Boolean', false],
  ['Include DS Node ID', 'Boolean', false],
  ['Include Link Type', 'Boolean', false],
  ['Include Asset ID', 'Boolean', false],
  ['Include Sewer Reference', 'Boolean', false],
  ['Include System Type', 'Boolean', false],
  ['Include Branch ID', 'Boolean', false],
  ['Include Point Array', 'Boolean', false],
  ['Include Is Merged', 'Boolean', false],
  ['Include Asset UID', 'Boolean', false],
  ['Include US Settlement Eff', 'Boolean', false],
  ['Include DS Settlement Eff', 'Boolean', false],
  ['Include Solution Model', 'Boolean', false],
  ['Include Min Computational Nodes', 'Boolean', false],
  ['Include Critical Sewer Category', 'Boolean', false],
  ['Include Taking Off Reference', 'Boolean', false],
  ['Include Conduit Material', 'Boolean', false],
  ['Include Design Group', 'Boolean', false],
  ['Include Site Condition', 'Boolean', false],
  ['Include Ground Condition', 'Boolean', false],
  ['Include Conduit Type', 'Boolean', false],
  ['Include Min Space Step', 'Boolean', false],
  ['Include Slot Width', 'Boolean', false],
  ['Include Connection Coefficient', 'Boolean', false],
  ['Include Shape', 'Boolean', false],
  ['Include Conduit Width', 'Boolean', true],
  ['Include Conduit Height', 'Boolean', false],
  ['Include Springing Height', 'Boolean', false],
  ['Include Sediment Depth', 'Boolean', false],
  ['Include Number of Barrels', 'Boolean', false],
  ['Include Roughness Type', 'Boolean', false],
  ['Include Bottom Roughness CW', 'Boolean', false],
  ['Include Top Roughness CW', 'Boolean', false],
  ['Include Bottom Roughness Manning', 'Boolean', false],
  ['Include Top Roughness Manning', 'Boolean', false],
  ['Include Bottom Roughness N', 'Boolean', false],
  ['Include Top Roughness N', 'Boolean', false],
  ['Include Bottom Roughness HW', 'Boolean', false],
  ['Include Top Roughness HW', 'Boolean', false],
  ['Include Conduit Length', 'Boolean', false],
  ['Include Inflow', 'Boolean', false],
  ['Include Gradient', 'Boolean', false],
  ['Include Capacity', 'Boolean', false],
  ['Include US Invert', 'Boolean', false],
  ['Include DS Invert', 'Boolean', false],
  ['Include US Headloss Type', 'Boolean', false],
  ['Include DS Headloss Type', 'Boolean', false],
  ['Include US Headloss Coeff', 'Boolean', false],
  ['Include DS Headloss Coeff', 'Boolean', false],
  ['Include Base Height', 'Boolean', false],
  ['Include Infiltration Coeff Base', 'Boolean', false],
  ['Include Infiltration Coeff Side', 'Boolean', false],
  ['Include Fill Material Conductivity', 'Boolean', false],
  ['Include Porosity', 'Boolean', false],
  ['Include Diff1D Type', 'Boolean', false],
  ['Include Diff1D D0', 'Boolean', false],
  ['Include Diff1D D1', 'Boolean', false],
  ['Include Diff1D D2', 'Boolean', false],
  ['Include Inlet Type Code', 'Boolean', false],
  ['Include Reverse Flow Model', 'Boolean', false],
  ['Include Equation', 'Boolean', false],
  ['Include K', 'Boolean', false],
  ['Include M', 'Boolean', false],
  ['Include C', 'Boolean', false],
  ['Include Y', 'Boolean', false],
  ['Include US Ki', 'Boolean', false],
  ['Include US Ko', 'Boolean', false],
  ['Include Outlet Type Code', 'Boolean', false],
  ['Include Equation O', 'Boolean', false],
  ['Include K O', 'Boolean', false],
  ['Include M O', 'Boolean', false],
  ['Include C O', 'Boolean', false],
  ['Include Y O', 'Boolean', false],
  ['Include DS Ki', 'Boolean', false],
  ['Include DS Ko', 'Boolean', false],
  ['Include Notes', 'Boolean', false],
  ['Include Hyperlinks', 'Boolean', false],
  ['Include User Number 1', 'Boolean', false],
  ['Include User Number 2', 'Boolean', false],
  ['Include User Number 3', 'Boolean', false],
  ['Include User Number 4', 'Boolean', false],
  ['Include User Number 5', 'Boolean', false],
  ['Include User Number 6', 'Boolean', false],
  ['Include User Number 7', 'Boolean', false],
  ['Include User Number 8', 'Boolean', false],
  ['Include User Number 9', 'Boolean', false],
  ['Include User Number 10', 'Boolean', false],
  ['Include User Text 1', 'Boolean', false],
  ['Include User Text 2', 'Boolean', false],
  ['Include User Text 3', 'Boolean', false],
  ['Include User Text 4', 'Boolean', false],
  ['Include User Text 5', 'Boolean', false],
  ['Include User Text 6', 'Boolean', false],
  ['Include User Text 7', 'Boolean', false],
  ['Include User Text 8', 'Boolean', false],
  ['Include User Text 9', 'Boolean', false],
  ['Include User Text 10', 'Boolean', false]
]

# Display prompt dialog and capture user selections
options = WSApplication.prompt("Select options for CSV export of hw_conduit rows", prompt_options, false)
if options.nil?
  puts "User cancelled the operation."
  exit
end

# Log start time
puts "Starting script at #{Time.now}"
start_time = Time.now

# Ensure directory exists and set file path
dir = options[0]
Dir.mkdir(dir) unless Dir.exist?(dir)
file_path = File.join(dir, "pipes.csv")

# Map all options to variables (indices match prompt_options order)
include_pipe_id = options[1]
include_us_node_id = options[2]
include_link_suffix = options[3]
include_ds_node_id = options[4]
include_link_type = options[5]
include_asset_id = options[6]
include_sewer_reference = options[7]
include_system_type = options[8]
include_branch_id = options[9]
include_point_array = options[10]
include_is_merged = options[11]
include_asset_uid = options[12]
include_us_settlement_eff = options[13]
include_ds_settlement_eff = options[14]
include_solution_model = options[15]
include_min_computational_nodes = options[16]
include_critical_sewer_category = options[17]
include_taking_off_reference = options[18]
include_conduit_material = options[19]
include_design_group = options[20]
include_site_condition = options[21]
include_ground_condition = options[22]
include_conduit_type = options[23]
include_min_space_step = options[24]
include_slot_width = options[25]
include_connection_coefficient = options[26]
include_shape = options[27]
include_conduit_width = options[28]
include_conduit_height = options[29]
include_springing_height = options[30]
include_sediment_depth = options[31]
include_number_of_barrels = options[32]
include_roughness_type = options[33]
include_bottom_roughness_CW = options[34]
include_top_roughness_CW = options[35]
include_bottom_roughness_Manning = options[36]
include_top_roughness_Manning = options[37]
include_bottom_roughness_N = options[38]
include_top_roughness_N = options[39]
include_bottom_roughness_HW = options[40]
include_top_roughness_HW = options[41]
include_conduit_length = options[42]
include_inflow = options[43]
include_gradient = options[44]
include_capacity = options[45]
include_us_invert = options[46]
include_ds_invert = options[47]
include_us_headloss_type = options[48]
include_ds_headloss_type = options[49]
include_us_headloss_coeff = options[50]
include_ds_headloss_coeff = options[51]
include_base_height = options[52]
include_infiltration_coeff_base = options[53]
include_infiltration_coeff_side = options[54]
include_fill_material_conductivity = options[55]
include_porosity = options[56]
include_diff1d_type = options[57]
include_diff1d_d0 = options[58]
include_diff1d_d1 = options[59]
include_diff1d_d2 = options[60]
include_inlet_type_code = options[61]
include_reverse_flow_model = options[62]
include_equation = options[63]
include_k = options[64]
include_m = options[65]
include_c = options[66]
include_y = options[67]
include_us_ki = options[68]
include_us_ko = options[69]
include_outlet_type_code = options[70]
include_equation_o = options[71]
include_k_o = options[72]
include_m_o = options[73]
include_c_o = options[74]
include_y_o = options[75]
include_ds_ki = options[76]
include_ds_ko = options[77]
include_notes = options[78]
include_hyperlinks = options[79]
include_user_number_1 = options[80]
include_user_number_2 = options[81]
include_user_number_3 = options[82]
include_user_number_4 = options[83]
include_user_number_5 = options[84]
include_user_number_6 = options[85]
include_user_number_7 = options[86]
include_user_number_8 = options[87]
include_user_number_9 = options[88]
include_user_number_10 = options[89]
include_user_text_1 = options[90]
include_user_text_2 = options[91]
include_user_text_3 = options[92]
include_user_text_4 = options[93]
include_user_text_5 = options[94]
include_user_text_6 = options[95]
include_user_text_7 = options[96]
include_user_text_8 = options[97]
include_user_text_9 = options[98]
include_user_text_10 = options[99]

# Build CSV header based on selected options
header = []
header << "Pipe ID" if include_pipe_id
header << "US Node ID" if include_us_node_id
header << "Link Suffix" if include_link_suffix
header << "DS Node ID" if include_ds_node_id
header << "Link Type" if include_link_type
header << "Asset ID" if include_asset_id
header << "Sewer Reference" if include_sewer_reference
header << "System Type" if include_system_type
header << "Branch ID" if include_branch_id
header << "Point Array" if include_point_array
header << "Is Merged" if include_is_merged
header << "Asset UID" if include_asset_uid
header << "US Settlement Eff" if include_us_settlement_eff
header << "DS Settlement Eff" if include_ds_settlement_eff
header << "Solution Model" if include_solution_model
header << "Min Computational Nodes" if include_min_computational_nodes
header << "Critical Sewer Category" if include_critical_sewer_category
header << "Taking Off Reference" if include_taking_off_reference
header << "Conduit Material" if include_conduit_material
header << "Design Group" if include_design_group
header << "Site Condition" if include_site_condition
header << "Ground Condition" if include_ground_condition
header << "Conduit Type" if include_conduit_type
header << "Min Space Step" if include_min_space_step
header << "Slot Width" if include_slot_width
header << "Connection Coefficient" if include_connection_coefficient
header << "Shape" if include_shape
header << "Conduit Width" if include_conduit_width
header << "Conduit Height" if include_conduit_height
header << "Springing Height" if include_springing_height
header << "Sediment Depth" if include_sediment_depth
header << "Number of Barrels" if include_number_of_barrels
header << "Roughness Type" if include_roughness_type
header << "Bottom Roughness CW" if include_bottom_roughness_CW
header << "Top Roughness CW" if include_top_roughness_CW
header << "Bottom Roughness Manning" if include_bottom_roughness_Manning
header << "Top Roughness Manning" if include_top_roughness_Manning
header << "Bottom Roughness N" if include_bottom_roughness_N
header << "Top Roughness N" if include_top_roughness_N
header << "Bottom Roughness HW" if include_bottom_roughness_HW
header << "Top Roughness HW" if include_top_roughness_HW
header << "Conduit Length" if include_conduit_length
header << "Inflow" if include_inflow
header << "Gradient" if include_gradient
header << "Capacity" if include_capacity
header << "US Invert" if include_us_invert
header << "DS Invert" if include_ds_invert
header << "US Headloss Type" if include_us_headloss_type
header << "DS Headloss Type" if include_ds_headloss_type
header << "US Headloss Coeff" if include_us_headloss_coeff
header << "DS Headloss Coeff" if include_ds_headloss_coeff
header << "Base Height" if include_base_height
header << "Infiltration Coeff Base" if include_infiltration_coeff_base
header << "Infiltration Coeff Side" if include_infiltration_coeff_side
header << "Fill Material Conductivity" if include_fill_material_conductivity
header << "Porosity" if include_porosity
header << "Diff1D Type" if include_diff1d_type
header << "Diff1D D0" if include_diff1d_d0
header << "Diff1D D1" if include_diff1d_d1
header << "Diff1D D2" if include_diff1d_d2
header << "Inlet Type Code" if include_inlet_type_code
header << "Reverse Flow Model" if include_reverse_flow_model
header << "Equation" if include_equation
header << "K" if include_k
header << "M" if include_m
header << "C" if include_c
header << "Y" if include_y
header << "US Ki" if include_us_ki
header << "US Ko" if include_us_ko
header << "Outlet Type Code" if include_outlet_type_code
header << "Equation O" if include_equation_o
header << "K O" if include_k_o
header << "M O" if include_m_o
header << "C O" if include_c_o
header << "Y O" if include_y_o
header << "DS Ki" if include_ds_ki
header << "DS Ko" if include_ds_ko
header << "Notes" if include_notes
header << "Hyperlinks" if include_hyperlinks
header << "User Number 1" if include_user_number_1
header << "User Number 2" if include_user_number_2
header << "User Number 3" if include_user_number_3
header << "User Number 4" if include_user_number_4
header << "User Number 5" if include_user_number_5
header << "User Number 6" if include_user_number_6
header << "User Number 7" if include_user_number_7
header << "User Number 8" if include_user_number_8
header << "User Number 9" if include_user_number_9
header << "User Number 10" if include_user_number_10
header << "User Text 1" if include_user_text_1
header << "User Text 2" if include_user_text_2
header << "User Text 3" if include_user_text_3
header << "User Text 4" if include_user_text_4
header << "User Text 5" if include_user_text_5
header << "User Text 6" if include_user_text_6
header << "User Text 7" if include_user_text_7
header << "User Text 8" if include_user_text_8
header << "User Text 9" if include_user_text_9
header << "User Text 10" if include_user_text_10

# Export to CSV with timing and error handling
conduit_count = 0
begin
  CSV.open(file_path, "w") do |csv|
    puts "Writing to #{file_path}"
    csv << header 
    cn.row_objects('hw_conduit').each do |pipe|
      conduit_count += 1
      row = []
      row << pipe.id if include_pipe_id
      row << (pipe.us_node_id.nil? ? "N/A" : pipe.us_node_id) if include_us_node_id
      row << (pipe.link_suffix.nil? ? "N/A" : pipe.link_suffix) if include_link_suffix
      row << (pipe.ds_node_id.nil? ? "N/A" : pipe.ds_node_id) if include_ds_node_id
      row << (pipe.link_type.nil? ? "N/A" : pipe.link_type) if include_link_type
      row << (pipe.asset_id.nil? ? "N/A" : pipe.asset_id) if include_asset_id
      row << (pipe.sewer_reference.nil? ? "N/A" : pipe.sewer_reference) if include_sewer_reference
      row << (pipe.system_type.nil? ? "N/A" : pipe.system_type) if include_system_type
      row << (pipe.branch_id.nil? ? "N/A" : pipe.branch_id) if include_branch_id
      row << (pipe.point_array.nil? ? "N/A" : pipe.point_array) if include_point_array
      row << (pipe.is_merged.nil? ? "N/A" : pipe.is_merged) if include_is_merged
      row << (pipe.asset_uid.nil? ? "N/A" : pipe.asset_uid) if include_asset_uid
      row << (pipe.us_settlement_eff.nil? ? "N/A" : pipe.us_settlement_eff) if include_us_settlement_eff
      row << (pipe.ds_settlement_eff.nil? ? "N/A" : pipe.ds_settlement_eff) if include_ds_settlement_eff
      row << (pipe.solution_model.nil? ? "N/A" : pipe.solution_model) if include_solution_model
      row << (pipe.min_computational_nodes.nil? ? "N/A" : pipe.min_computational_nodes) if include_min_computational_nodes
      row << (pipe.critical_sewer_category.nil? ? "N/A" : pipe.critical_sewer_category) if include_critical_sewer_category
      row << (pipe.taking_off_reference.nil? ? "N/A" : pipe.taking_off_reference) if include_taking_off_reference
      row << (pipe.conduit_material.nil? ? "N/A" : pipe.conduit_material) if include_conduit_material
      row << (pipe.design_group.nil? ? "N/A" : pipe.design_group) if include_design_group
      row << (pipe.site_condition.nil? ? "N/A" : pipe.site_condition) if include_site_condition
      row << (pipe.ground_condition.nil? ? "N/A" : pipe.ground_condition) if include_ground_condition
      row << (pipe.conduit_type.nil? ? "N/A" : pipe.conduit_type) if include_conduit_type
      row << (pipe.min_space_step.nil? ? "N/A" : pipe.min_space_step) if include_min_space_step
      row << (pipe.slot_width.nil? ? "N/A" : pipe.slot_width) if include_slot_width
      row << (pipe.connection_coefficient.nil? ? "N/A" : pipe.connection_coefficient) if include_connection_coefficient
      row << (pipe.shape.nil? ? "N/A" : pipe.shape) if include_shape
      row << (pipe.conduit_width.nil? ? "N/A" : pipe.conduit_width) if include_conduit_width
      row << (pipe.conduit_height.nil? ? "N/A" : pipe.conduit_height) if include_conduit_height
      row << (pipe.springing_height.nil? ? "N/A" : pipe.springing_height) if include_springing_height
      row << (pipe.sediment_depth.nil? ? "N/A" : pipe.sediment_depth) if include_sediment_depth
      row << (pipe.number_of_barrels.nil? ? "N/A" : pipe.number_of_barrels) if include_number_of_barrels
      row << (pipe.roughness_type.nil? ? "N/A" : pipe.roughness_type) if include_roughness_type
      row << (pipe.bottom_roughness_CW.nil? ? "N/A" : pipe.bottom_roughness_CW) if include_bottom_roughness_CW
      row << (pipe.top_roughness_CW.nil? ? "N/A" : pipe.top_roughness_CW) if include_top_roughness_CW
      row << (pipe.bottom_roughness_Manning.nil? ? "N/A" : pipe.bottom_roughness_Manning) if include_bottom_roughness_Manning
      row << (pipe.top_roughness_Manning.nil? ? "N/A" : pipe.top_roughness_Manning) if include_top_roughness_Manning
      row << (pipe.bottom_roughness_N.nil? ? "N/A" : pipe.bottom_roughness_N) if include_bottom_roughness_N
      row << (pipe.top_roughness_N.nil? ? "N/A" : pipe.top_roughness_N) if include_top_roughness_N
      row << (pipe.bottom_roughness_HW.nil? ? "N/A" : pipe.bottom_roughness_HW) if include_bottom_roughness_HW
      row << (pipe.top_roughness_HW.nil? ? "N/A" : pipe.top_roughness_HW) if include_top_roughness_HW
      row << (pipe.conduit_length.nil? ? "N/A" : pipe.conduit_length) if include_conduit_length
      row << (pipe.inflow.nil? ? "N/A" : pipe.inflow) if include_inflow
      row << (pipe.gradient.nil? ? "N/A" : pipe.gradient) if include_gradient
      row << (pipe.capacity.nil? ? "N/A" : pipe.capacity) if include_capacity
      row << (pipe.us_invert.nil? ? "N/A" : pipe.us_invert) if include_us_invert
      row << (pipe.ds_invert.nil? ? "N/A" : pipe.ds_invert) if include_ds_invert
      row << (pipe.us_headloss_type.nil? ? "N/A" : pipe.us_headloss_type) if include_us_headloss_type
      row << (pipe.ds_headloss_type.nil? ? "N/A" : pipe.ds_headloss_type) if include_ds_headloss_type
      row << (pipe.us_headloss_coeff.nil? ? "N/A" : pipe.us_headloss_coeff) if include_us_headloss_coeff
      row << (pipe.ds_headloss_coeff.nil? ? "N/A" : pipe.ds_headloss_coeff) if include_ds_headloss_coeff
      row << (pipe.base_height.nil? ? "N/A" : pipe.base_height) if include_base_height
      row << (pipe.infiltration_coeff_base.nil? ? "N/A" : pipe.infiltration_coeff_base) if include_infiltration_coeff_base
      row << (pipe.infiltration_coeff_side.nil? ? "N/A" : pipe.infiltration_coeff_side) if include_infiltration_coeff_side
      row << (pipe.fill_material_conductivity.nil? ? "N/A" : pipe.fill_material_conductivity) if include_fill_material_conductivity
      row << (pipe.porosity.nil? ? "N/A" : pipe.porosity) if include_porosity
      row << (pipe.diff1d_type.nil? ? "N/A" : pipe.diff1d_type) if include_diff1d_type
      row << (pipe.diff1d_d0.nil? ? "N/A" : pipe.diff1d_d0) if include_diff1d_d0
      row << (pipe.diff1d_d1.nil? ? "N/A" : pipe.diff1d_d1) if include_diff1d_d1
      row << (pipe.diff1d_d2.nil? ? "N/A" : pipe.diff1d_d2) if include_diff1d_d2
      row << (pipe.inlet_type_code.nil? ? "N/A" : pipe.inlet_type_code) if include_inlet_type_code
      row << (pipe.reverse_flow_model.nil? ? "N/A" : pipe.reverse_flow_model) if include_reverse_flow_model
      row << (pipe.equation.nil? ? "N/A" : pipe.equation) if include_equation
      row << (pipe.k.nil? ? "N/A" : pipe.k) if include_k
      row << (pipe.m.nil? ? "N/A" : pipe.m) if include_m
      row << (pipe.c.nil? ? "N/A" : pipe.c) if include_c
      row << (pipe.y.nil? ? "N/A" : pipe.y) if include_y
      row << (pipe.us_ki.nil? ? "N/A" : pipe.us_ki) if include_us_ki
      row << (pipe.us_ko.nil? ? "N/A" : pipe.us_ko) if include_us_ko
      row << (pipe.outlet_type_code.nil? ? "N/A" : pipe.outlet_type_code) if include_outlet_type_code
      row << (pipe.equation_o.nil? ? "N/A" : pipe.equation_o) if include_equation_o
      row << (pipe.k_o.nil? ? "N/A" : pipe.k_o) if include_k_o
      row << (pipe.m_o.nil? ? "N/A" : pipe.m_o) if include_m_o
      row << (pipe.c_o.nil? ? "N/A" : pipe.c_o) if include_c_o
      row << (pipe.y_o.nil? ? "N/A" : pipe.y_o) if include_y_o
      row << (pipe.ds_ki.nil? ? "N/A" : pipe.ds_ki) if include_ds_ki
      row << (pipe.ds_ko.nil? ? "N/A" : pipe.ds_ko) if include_ds_ko
      row << (pipe.notes.nil? ? "N/A" : pipe.notes) if include_notes
      row << (pipe.hyperlinks.nil? ? "N/A" : pipe.hyperlinks) if include_hyperlinks
      row << (pipe.user_number_1.nil? ? "N/A" : pipe.user_number_1) if include_user_number_1
      row << (pipe.user_number_2.nil? ? "N/A" : pipe.user_number_2) if include_user_number_2
      row << (pipe.user_number_3.nil? ? "N/A" : pipe.user_number_3) if include_user_number_3
      row << (pipe.user_number_4.nil? ? "N/A" : pipe.user_number_4) if include_user_number_4
      row << (pipe.user_number_5.nil? ? "N/A" : pipe.user_number_5) if include_user_number_5
      row << (pipe.user_number_6.nil? ? "N/A" : pipe.user_number_6) if include_user_number_6
      row << (pipe.user_number_7.nil? ? "N/A" : pipe.user_number_7) if include_user_number_7
      row << (pipe.user_number_8.nil? ? "N/A" : pipe.user_number_8) if include_user_number_8
      row << (pipe.user_number_9.nil? ? "N/A" : pipe.user_number_9) if include_user_number_9
      row << (pipe.user_number_10.nil? ? "N/A" : pipe.user_number_10) if include_user_number_10
      row << (pipe.user_text_1.nil? ? "N/A" : pipe.user_text_1) if include_user_text_1
      row << (pipe.user_text_2.nil? ? "N/A" : pipe.user_text_2) if include_user_text_2
      row << (pipe.user_text_3.nil? ? "N/A" : pipe.user_text_3) if include_user_text_3
      row << (pipe.user_text_4.nil? ? "N/A" : pipe.user_text_4) if include_user_text_4
      row << (pipe.user_text_5.nil? ? "N/A" : pipe.user_text_5) if include_user_text_5
      row << (pipe.user_text_6.nil? ? "N/A" : pipe.user_text_6) if include_user_text_6
      row << (pipe.user_text_7.nil? ? "N/A" : pipe.user_text_7) if include_user_text_7
      row << (pipe.user_text_8.nil? ? "N/A" : pipe.user_text_8) if include_user_text_8
      row << (pipe.user_text_9.nil? ? "N/A" : pipe.user_text_9) if include_user_text_9
      row << (pipe.user_text_10.nil? ? "N/A" : pipe.user_text_10) if include_user_text_10
      csv << row
    end
    puts "Completed: #{conduit_count} conduits written"
  end
rescue Errno::EACCES => e
  puts "ERROR: Permission denied - #{e.message}"
rescue => e
  puts "ERROR: Unexpected failure - #{e.message}"
end

# Log completion time
end_time = Time.now
time_spent = end_time - start_time
puts "Script finished at #{end_time}"
puts "Time spent after picking your options: #{time_spent} seconds"

# Define the layout for the prompt
layout = [
  ['ICM InfoWorks Version', 'READONLY', WSApplication.version],
  ['Number of Conduits written from the Network', 'NUMBER', conduit_count]
]

# Display the prompt and get user input
user_input = WSApplication.prompt('ICM InfoWorks Network Information', layout, true)