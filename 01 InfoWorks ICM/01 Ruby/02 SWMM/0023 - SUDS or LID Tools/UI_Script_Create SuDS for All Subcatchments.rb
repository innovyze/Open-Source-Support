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

