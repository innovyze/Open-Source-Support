#Below ICM UI script can be used to export SUDS control data from each subcatchment to a csv

require 'csv'

open_net = WSApplication.current_network

# Prompt user for an output folder
result = WSApplication.prompt "Export Subcatchment SUDS control as CSV",
[
  ['Output folder', 'String', nil, nil, 'FILE', true, 'csv', 'CSV', false]
], false
output_folder = result[0]

# Set up the CSV header
header = [
  "Subcatchment ID",
  "SUDS structure ID",
  "SUDS control ID",
  "Control type",
  "Area",
  "Number of units",
  "Area of subcatchment (%)",
  "Unit surface width",
  "Initial saturation (%)",
  "Impervious area treated (%)",
  "Pervious area treated (%)",
  "Outflow to",
  "Drain to subcatchment",
  "Drain to node",
  "Surface"
]

# Initialize an array to store the CSV data
suds_data = [header]

# Iterate over each subcatchment and its SUDS controls
open_net.row_objects('_subcatchments').each do |sub|
  sub.SUDS_controls.each do |control|
    # Add a row to the CSV data for each SUDS control
    puts sub.subcatchment_id
    puts control.id
    puts control.suds_structure
    puts control.control_type
    puts control.area
    puts control.num_units
    puts control.area_subcatchment_pct
    puts control.unit_surface_width
    puts control.initial_saturation_pct
    puts control.impervious_area_treated_pct
    puts control.pervious_area_treated_pct
    puts control.outflow_to
    puts control.drain_to_subcatchment
    puts control.drain_to_node
    puts control.surface

    suds_data.push([
     sub.subcatchment_id,
      control.id,
      control.suds_structure,
      control.control_type,
      control.area,
      control.num_units,
      control.area_subcatchment_pct,
      control.unit_surface_width,
      control.initial_saturation_pct,
      control.impervious_area_treated_pct,
      control.pervious_area_treated_pct,
      control.outflow_to,
      control.drain_to_subcatchment,
      control.drain_to_node,
      control.surface
    ])

    
      # Print all attributes of the control object
      control.instance_variables.each do |var|
        puts "#{var}: #{control.instance_variable_get(var)}"
      end

  end
end

# Write the CSV data to a file in the specified output folder
CSV.open(output_folder, "w") do |csv|
  suds_data.each do |row|
    csv << row
  end
end
