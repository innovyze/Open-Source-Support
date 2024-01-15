# ICM UI script can be used to create SUDS control data for each subcatchment

open_net = WSApplication.current_network

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

open_net.transaction_begin

# Iterate over each subcatchment and its SUDS controls
open_net.row_objects('hw_subcatchment').each do |sub|

  sub.suds_controls.each do |control|
    # Set properties of the control
    control.id = sub.subcatchment_id + "_SUDS"
    puts control.ID
  end
  sub.suds_controls.write
end

puts "Finished creating SUDS control data for each subcatchment"
open_net.transaction_commit

=begin
suds_controls.area
suds_controls.area_subcatchment_pct
suds_controls.control_type
suds_controls.drain_to_node
suds_controls.id
suds_controls.impervious_area_treated_pct
suds_controls.initial_saturation_pct
suds_controls.num_units
suds_controls.outflow_to
suds_controls.pervious_area_treated_pct
suds_controls.suds_structure
suds_controls.unit_surface_width
suds_controls.surface
=end