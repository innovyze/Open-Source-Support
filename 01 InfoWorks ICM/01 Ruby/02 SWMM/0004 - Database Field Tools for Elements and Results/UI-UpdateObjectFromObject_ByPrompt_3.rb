net=WSApplication.current_network

assets='cams_channel','cams_connection_node','cams_connection_pipe','cams_data_logger','cams_defence_area','cams_defence_structure','cams_flume','cams_general_asset','cams_general_line','cams_generator','cams_manhole','cams_orifice','cams_outlet','cams_pipe','cams_pump','cams_pump_station','cams_screen','cams_siphon','cams_sluice','cams_storage','cams_wtw','cams_ancillary','cams_valve','cams_vortex','cams_weir'
surveys='cams_cctv_survey','cams_cross_section_survey','cams_drain_test','cams_dye_test','cams_fog_inspection','cams_gps_survey','cams_general_survey','cams_general_survey_line','cams_manhole_survey','cams_mon_survey','cams_pump_station_survey','cams_smoke_defect','cams_smoke_test'
repairs='cams_general_maintenance','cams_manhole_repair','cams_pipe_clean','cams_pipe_repair','cams_pump_station_em','cams_pump_station_mm'
zones='cams_property','cams_zone','cams_work_package'
incidents='cams_incident_blockage','cams_incident_collapse','cams_incident_complaint','cams_incident_flooding','cams_incident_general','cams_incident_odor','cams_incident_pollution'

destobjects=surveys+incidents+repairs #Choose a list for the DESTINATION tables choices
sourceobjects=assets+zones #Choose a list for the SOURCE tables choices

val=WSApplication.prompt "Update Options",
[
['DESTINATION: Select an Object type to update','String','',nil,'LIST',destobjects],
['DESTINATION: Enter the field to be updated','String'],
['DESTINATION: Enter the comparison field','String'],
['SOURCE: Select a lookup Object type','String','',nil,'LIST',sourceobjects],
['SOURCE: Enter the field to update from','String'],
['SOURCE: Enter the comparison field','String'],
['OVERWRITE existing DESTINATION values?','Boolean',false],
['FLAG for updated values','String'],
],false

desttable=val[0].to_s
destlookup=val[1].to_s
destlookupflag=val[1].to_s+'_flag'
destcomp=val[2].to_s
sourcetable=val[3].to_s
sourcelookup=val[4].to_s
sourcecomp=val[5].to_s
overwrite=val[6].to_s
destflag=val[7].to_s


puts 'Object ' + desttable+ ' Field: ' + destlookup + ' will be updated with ' + sourcetable + ' Field ' + sourcelookup + ' by comparing ' + destcomp + ' to ' + sourcecomp
puts 'Destination Table: '+ desttable
puts 'Destination Field: '+ destlookup
puts 'Destination Comparison: '+ destcomp
puts 'Source Table: '+ sourcetable
puts 'Source Field: '+ sourcelookup
puts 'Source Comparison: '+ sourcecomp
puts 'Overwrite Existing Values: '+ overwrite

sourcevalues=Hash.new
net.row_objects(sourcetable).each do |p|
	id=p[sourcelookup]
		sourcevalue=p[sourcecomp].downcase
	if !sourcevalue.nil? && sourcevalue.length>0
			if !sourcevalues.has_key? sourcevalue
				sourcevalues[sourcevalue]=id
		end
	end
end

if overwrite=='false'
	net.transaction_begin
	net.row_objects(desttable).each do |i|
		if !i[destlookup].nil? && i[destlookup].length==0
			sourcevalue=i[destcomp].downcase
			if !sourcevalue.nil?
				if sourcevalues.has_key? sourcevalue
					i[destlookup]=sourcevalues[sourcevalue]
					i.write
					if i[destlookup]==sourcevalues[sourcevalue] && !i[destlookup].nil? && i[destlookup].length>0
						i[destlookupflag]=destflag
						i.write
					end
				end
			end
		end
	end
	net.transaction_commit
elsif overwrite=='true'
	net.transaction_begin
	net.row_objects(desttable).each do |i|
		sourcevalue=i[destcomp].downcase
		if !sourcevalue.nil?
			if sourcevalues.has_key? sourcevalue
				i[destlookup]=sourcevalues[sourcevalue]
				i.write
				if i[destlookup]==sourcevalues[sourcevalue] && !i[destlookup].nil? && i[destlookup].length>0
					i[destlookupflag]=destflag
					i.write
				end
			end
		end
	end
	net.transaction_commit
end