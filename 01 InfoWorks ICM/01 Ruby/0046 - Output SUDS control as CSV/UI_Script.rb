#Below ICM UI script can be used to export SUDS control data from each subcatchment to a csv
require 'csv'
on=WSApplication.current_network

val=WSApplication.prompt "Export Subcatchment SUDS control as CSV",
[['Output folder','String',nil,nil,'FILE',true,'csv',"CSV",false]
],false
csv_path=val[0]


header=["Subcatchment ID","SUDS structure ID",	"SUDS control ID",	"Control type",	"Area",	"Number of units",	"Area of subcatchment (%)",	"Unit surface width",	"Initial saturation (%)",	"Impervious area treated (%)",	"Pervious area treated (%)",	"Outflow to",	"Drain to subcatchment",	"Drain to node",	"Surface"]

suds_array=[]
suds_array<<header
on.row_objects('_subcatchments').each do |sub|
	sub.SUDS_controls.each do |a|
	working_array=[]
	working_array<<sub.subcatchment_id
	working_array<<a.id
	working_array<<a.suds_structure
	working_array<<a.control_type
	working_array<<a.area
	working_array<<a.num_units
	working_array<<a.area_subcatchment_pct
	working_array<<a.unit_surface_width
	working_array<<a.initial_saturation_pct
	working_array<<a.impervious_area_treated_pct
	working_array<<a.pervious_area_treated_pct
	working_array<<a.outflow_to
	working_array<<a.drain_to_subcatchment
	working_array<<a.drain_to_node
	working_array<<a.surface
	
	suds_array<<working_array
	end
		
end


CSV.open(csv_path, "w") do |csv|
	suds_array.each do |aa|
		csv<<aa
	end
		
end
