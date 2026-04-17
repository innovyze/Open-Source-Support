# This is a simple script for reviewing ICM results against measured data within the UI.
# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits 

# Example script to compare model vs measured data
require 'date'

# Locate path with sensor data files
sensor_dir = WSApplication.folder_dialog 'Select a folder for sensor data files',  true 

# Define Sensor to Model Mapping for all desired locations:
locations=Hash.new
locations['50135.1'] = {"sensor_file"=>'sensor_1.txt',"output"=>'us_flow',"symbol"=>'Cross', "Color"=>WSApplication.colour(0,0,255)}
locations['50009.1'] = {"sensor_file"=>'sensor_2.txt',"output"=>'us_flow',"symbol"=>'Circle',"Color"=>WSApplication.colour(0,255,0)}
locations['72332.1'] = {"sensor_file"=>'sensor_3.txt',"output"=>'us_flow',"symbol"=>'Square',"Color"=>WSApplication.colour(255,0,0)}
locations['72346.1'] = {"sensor_file"=>'sensor_4.txt',"output"=>'us_flow',"symbol"=>'Star',  "Color"=>WSApplication.colour(0,0,0)}

# Prep common graph settings
graph_window=Hash.new
graph_window['YAxisLabel']='Flow rate (ft3/s)'
graph_window['IsTime']=true
icm_color=WSApplication.colour(0,0,255)
sensor_color=WSApplication.colour(255,0,0)

# Initialize ICM Network and results
net=WSApplication.current_network
n = net.timestep_count

# Loop through each defined location
scatter_trace=Array.new
locations.each do | location, options |
# Fetch Sensor Data from file	
	sensor_data = IO.readlines(sensor_dir+'\\'+options['sensor_file'])
	sensor = sensor_data.slice(0,n) # ensure arrays are the same size

# Read ICM results data and compare against measured values
	pipe=net.row_object('hw_conduit',location)
	results=pipe.results('us_flow')
	squared_difference = 0.0
	results.each_index {|t| squared_difference += (results[t]-sensor[t].to_f)**2}
	#puts "Location #{} has Variance of: #{squared_difference/n}"

# Build Graph Arrays	
	traces=Array.new
	traces << {'Title'=>location,'TraceColour'=>icm_color,'LineType'=>'Solid','Marker'=>"None", "XArray"=>net.list_timesteps,"YArray"=>results}
	traces << {'Title'=>options['sensor_file'],'TraceColour'=>sensor_color,'LineType'=>'Solid','Marker'=>"None", "XArray"=>net.list_timesteps,"YArray"=>sensor}
	scatter_trace << {'Title'=>location,'LineType'=>'None','Marker'=>options['symbol'],'SymbolColour'=>options['Color'],"XArray"=>sensor,"YArray"=>results}

# Generate Line Graph of Sensor vs ICM results
	graph_window['WindowTitle']=location
	graph_window['GraphTitle']=location+' Variance = '+(squared_difference/n).to_s
	graph_window['Traces']=traces
	WSApplication.graph graph_window
end

# Generate Scatter graph with all locations
graph_window['WindowTitle']='Scatter Comparison of all locations'
graph_window['GraphTitle']=''
graph_window['Traces']=scatter_trace
graph_window['IsTime']=false
graph_window['YAxisLabel']='Flow rate (ft3/s)'
graph_window['XAxisLabel']='Flow rate (ft3/s)'
WSApplication.graph graph_window