require 'CSV'
net=WSApplication.current_network

CSVsaveloc=WSApplication.file_dialog(false, "csv", "Comma Separated Variable File", "Drainage Capacity Factor Assessment",false,true)
f = File.new(CSVsaveloc, "w")

#CSV save location & open csv file
 
arr=Array.new
arr << "ID"
arr << "Total Subcatchment Area (ha)"
arr << "Contributing Subcatchment Area (ha)"
arr << "Total Pavement Area (ha)"
arr << "Total Roof Area (ha)"
arr << "Total Permeable Area (ha)"
arr << "Population"
arr << "Non Domentic Flow (l/s)"
arr << "Infiltration (l/s)"

#build array

f.puts arr.to_csv 

#array to csv

##net.each_selected do |an|

	arr=Array.new
	
	arr << "Total"
	curlen = 0
	sccount = 0
	
	totscareaf = 0
	conscareaf = 0
	populf = 0
	paveareaf = 0
	roofareaf = 0
	permareaf = 0
	totscareac = 0
	conscareac = 0
	populc = 0
	paveareac = 0
	roofareac = 0
	permareac = 0
	totscareao = 0
	conscareao = 0
	populo = 0
	paveareao = 0
	roofareao = 0
	permareao = 0
	tradeflow = 0
	baseflow = 0
	addfoulflow = 0
	pavearea = 0
	roofarea = 0
	permarea = 0
	totscarea = 0
	conscarea = 0
	popul = 0

	#New array for individual IDs
	
	net.row_objects('_subcatchments').each do |sc|
		if sc.selected
			sccount = sccount + 1
			if sc.system_type.downcase == "foul"
				if !sc.total_area.nil?
					totscareaf = totscareaf + sc.total_area
				end
				if !sc.contributing_area.nil?
					conscareaf = conscareaf + sc.contributing_area
				end
				if !sc.population.nil?
					populf = populf + sc.population
				end
				if !sc.additional_foul_flow.nil?
					addfoulflow = addfoulflow + sc.additional_foul_flow
				end
				if !sc.area_absolute_1.nil?
					paveareaf = paveareaf + sc.area_absolute_1
				end
				if !sc.area_absolute_2.nil?
					roofareaf = roofareaf + sc.area_absolute_2
				end
				if !sc.area_absolute_3.nil?
					permareaf = permareaf + sc.area_absolute_3
				end
			elsif sc.system_type.downcase == "combined"
				if !sc.total_area.nil?
					totscareac = totscareac + sc.total_area
				end
				if !sc.contributing_area.nil?
					conscareac = conscareac + sc.contributing_area
				end
				if !sc.population.nil?
					populc = populc + sc.population
				end
				if !sc.additional_foul_flow.nil?
					addfoulflow = addfoulflow + sc.additional_foul_flow
				end
				if !sc.area_absolute_1.nil?
					paveareac = paveareac + sc.area_absolute_1
				end
				if !sc.area_absolute_2.nil?
					roofareac = roofareac + sc.area_absolute_2
				end
				if !sc.area_absolute_3.nil?
					permareac = permareac + sc.area_absolute_3
				end
			else
				if !sc.total_area.nil?
					totscareao = totscareao + sc.total_area
				end
				if !sc.contributing_area.nil?
					conscareao = conscareao + sc.contributing_area
				end
				if !sc.population.nil?
					populo = populo + sc.population
				end
				if !sc.additional_foul_flow.nil?
					addfoulflow = addfoulflow + sc.additional_foul_flow
				end
				if !sc.area_absolute_1.nil?
					paveareao = paveareao + sc.area_absolute_1
				end
				if !sc.area_absolute_2.nil?
					roofareao = roofareao + sc.area_absolute_2
				end
				if !sc.area_absolute_3.nil?
					permareao = permareao + sc.area_absolute_3
				end
			end
			
			if !sc.trade_flow.nil?
				tradeflow = tradeflow + sc.trade_flow
			end

			if !sc.base_flow.nil?
				baseflow = baseflow + sc.base_flow
			end
		end
	end

	#Subcatchment analysis

	tradeflow = tradeflow*1000
	baseflow = baseflow*1000
	addfoulflow = addfoulflow*1000
	totscarea = totscareaf + totscareac + totscareao
	conscarea = conscareaf + conscareac + conscareao
	popul = populf + populc + populo
	pavearea = paveareaf + paveareac + paveareao
	roofarea = roofareaf + roofareac + roofareao
	permarea = permareaf + permareac + permareao

	#Rationalise values

	arr << '%.2f' % totscarea
	arr << '%.2f' % conscarea
	arr << '%.2f' % pavearea
	arr << '%.2f' % roofarea
	arr << '%.2f' % permarea
	arr << '%.1f' % popul
	arr << '%.2f' % tradeflow
	arr << '%.2f' % baseflow
	
	f.puts arr.to_csv

##end

	#array to csv

f.close
text = "Routine completed successfully."
oicon = "Information"
WSApplication.message_box(text,'OK',oicon,nil)