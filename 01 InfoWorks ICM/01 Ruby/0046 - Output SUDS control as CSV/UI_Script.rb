#Below ICM UI script can be used to export SUDS control data from each subcatchment to a csv
require 'csv'
on=WSApplication.current_network

val=WSApplication.prompt "Export Subcatchment SUDS control as CSV",
[['Output folder','String',nil,nil,'FILE',true,'csv',"CSV",false]
],false
csv_path=val[0]


header=["Subcatchment ID","SUDS structure ID",	"SUDS control ID",	"Control type",	"Area",	"Number of units",	"Area of subcatchment (%)",	"Unit surface width",	"Initial saturation (%)",	"Impervious area treated (%)",	"Pervious area treated (%)",	"Outflow to",	"Drain to subcatchment",	"Drain to node",	"Surface"]

suds_array=[header]
on.row_objects('_subcatchments').each do |sub|
  sub.SUDS_controls.each do |control|
    suds_array.push([
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
  end
end


CSV.open(csv_path, "w") do |csv|
	suds_array.each do |aa|
		csv<<aa
	end
		
end
