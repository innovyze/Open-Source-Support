#Below UI script clears SUDS control data (blob structure) from all the subcatchments
require 'CSV'
require 'date'

on=WSApplication.current_network
start_time=Time.now

on.transaction_begin
on.row_objects('_subcatchments').each do |ro|
	ro.suds_controls.size=0
	ro.suds_controls.write
	ro.write
	arr.ti.fields.each do |field|
		puts field+' '+ro.results(field).to_s
	end
end
on.transaction_commit

end_time=Time.now

net_time= end_time - start_time

puts
puts 'Script Runtime :'+ net_time.to_s + ' sec'

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