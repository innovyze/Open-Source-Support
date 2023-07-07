# Original Source https://github.com/ngerdts7/ICM_Tools
# Modified for ICM SWMM Networks

net=WSApplication.current_network

# Define which parameters will be varied by the script. 
# Key   = name of ICM variable to be modified
# name  = abreviation of parameter to be used in scenario name
# table = name of table to be edited that contains the parameter
# id    = model ID in specified table where parameter changes are made (e.g. subcatchment ID, pipe ID, etc.)
# Range = [min, max, # of steps] -> define the range to be tested and how many steps you want the script to try.
#       Example: [0,1,5] -> will create 5 scenarios where the parameter ranges from 0 to 1 -> [0, 0.25, 0.5, 0.75, 1.0]

# Remove/add param rows as needed to account for different variables. The loop below supports up to 8 variables, but it can be expanded.
param=Hash.new
param['p_area_1'] =               {'name'=>'p1', 'table'=>'hw_land_use',            'id'=>'12430', 'Range'=>[0.3,1,2]}
param['p_area_2'] =               {'name'=>'p2', 'table'=>'hw_land_use',            'id'=>'12430', 'Range'=>[10,20,2]}
param['runoff_routing_value'] =   {'name'=>'rv', 'table'=>'hw_runoff_surface',      'id'=>'2',     'Range'=>[10,30,2]}
param['percolation_coefficient'] ={'name'=>'pc', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[2,10,3]}
param['percolation_threshold'] =  {'name'=>'pt', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[40,80,3]}
param['percolation_percentage'] = {'name'=>'pp', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[15,25,2]}
param['baseflow_coefficient'] =   {'name'=>'bc', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[30,50,2]}
param['infiltration_coefficient']={'name'=>'ic', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[10,20,2]}
var = param.keys

# =======================================================================================
# Prepare methods used later in the iteration loop:
#
def list_values(range_array)
# Method to convert range array into array of values to be used:
	dx = (range_array[1]-range_array[0])/(range_array[2]-1.00)
	return Array.new(range_array[2]) {|i| i*dx+range_array[0]}
end

def create_scenario(param,var,vars,net)
# Method to generate a new scenario and apply parameter changes based on input set
	scenario = ''
	for i in 0..var.length-1
		# assemble unique scenario name based on parameter composition
		scenario << param[var[i]]['name'] + "=" + vars[i].to_s + "_"
	end
	net.add_scenario(scenario,nil,'') 
	net.current_scenario=scenario
	net.clear_selection
	net.transaction_begin
	for i in 0..var.length-1
		# Apply parameter changes in scenario as defined by vars array
		puts param[var[i]]['table']
		puts param[var[i]]['id']
		row_obj = net.row_object(param[var[i]]['table'],param[var[i]]['id'])
		row_obj[var[i]] = vars[i]
		row_obj.write
	end
	net.transaction_commit
	v=net.validate(scenario)
	return scenario
end

# =======================================================================================
# Generate scenarios for every possible parameter combination:
scenarios=Array.new
var1 = list_values(param[var[0]]['Range'])
var1.each do | v1 |
	if var.length >= 2
		var2 = list_values(param[var[1]]['Range'])
		var2.each do | v2 |
			if var.length >= 3
				var3 = list_values(param[var[2]]['Range'])
				var3.each do | v3 |
					if var.length >= 4
						var4 = list_values(param[var[3]]['Range'])
						var4.each do | v4 |
							if var.length >= 5
								var5 = list_values(param[var[4]]['Range'])
								var5.each do | v5 |
									if var.length >= 6
										var6 = list_values(param[var[5]]['Range'])
										var6.each do | v6 |
											if var.length >= 7
												var7 = list_values(param[var[6]]['Range'])
												var7.each do | v7 |
													if var.length >= 8
														var8 = list_values(param[var[7]]['Range'])
														var8.each do | v8 |
															scenario = create_scenario(param,var,[v1,v2,v3,v4,v5,v6,v7,v8],net)
															puts "Configured scenario #{scenario} with 8 variables"
															scenarios << scenario
														end
													else
														puts "Configuring scenarios for 7 variables"
														scenario = create_scenario(param,var,[v1,v2,v3,v4,v5,v6,v7],net)
														scenarios << scenario
													end
												end
											else
												puts "Configuring scenarios for 6 variables"
												scenario = create_scenario(param,var,[v1,v2,v3,v4,v5,v6],net)
												scenarios << scenario
											end
										end
									else
										puts "Configuring scenarios for 5 variables"
										scenario = create_scenario(param,var,[v1,v2,v3,v4,v5],net)
										scenarios << scenario
									end
								end
							else
								puts "Configuring scenarios for 4 variables"
								scenario = create_scenario(param,var,[v1,v2,v3,v4],net)
								scenarios << scenario
							end
						end
					else
						puts "Configuring scenarios for 3 variables"
						scenario = create_scenario(param,var,[v1,v2,v3],net)
						scenarios << scenario
					end
				end
			else
				puts "Configuring scenarios for 2 variables"
				scenario = create_scenario(param,var,[v1,v2],net)
				scenarios << scenario
			end
		end
	else
		puts "Configuring scenarios for 1 variable"
		scenario = create_scenario(param,var,[v1],net)
		scenarios << scenario
	end
end
