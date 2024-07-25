#Below script will export the manhole ids, system type and depth of all the manholes in the network to a csv file. 
#The csv file will be read by a python script which will filter the manholes based on the system type and depth.
#The python script will export the filtered manholes to a csv file.
#The csv file exported by the python script will be read by the ruby script and the manholes will be selected in the network.

require 'csv'
on=WSApplication.current_network

#Get all the nodes in the network
all_node=on.row_objects('hw_node')

#Store the manhole id, system type and depth of all the manholes in the network in an array
export_array=[]
export_array<<["Manhole ID","System Type","Depth"]
all_node.each do |node|
    system_type=node.system_type
    node_id=node.id
    depth=node.chamber_roof-node.chamber_floor
    export_array<<[node_id,system_type,depth]
end

#Folder path where the current ruby script is located
current_folder=File.dirname(__FILE__)

#Path for the csv file where the manhole data will be exported
#CSV file will be created in the same folder where the ruby script is located
csv_path= File.dirname(__FILE__)+"/manhole.csv"

#Export the manhole data to a csv file
CSV.open("#{current_folder}/manhole.csv", "wb") do |csv|
    export_array.each do |node|
        csv<<node
    end
end

#path of the python script which will filter the manholes based on the system type and depth
#Python script should be located in the same folder where the ruby script is located
python_file_name="#{current_folder}/python.py"

#Run the python script
system("python",python_file_name)

#Read the csv file exported by the python script
python_csv_export_file_path="#{current_folder}/filtered_data.csv"
csv_array=CSV.read(python_csv_export_file_path)

#Remove first element from the csv array as it contains the header
csv_array.shift
#Select the manholes in the network based on the manhole id
csv_array.each do |element|
    #puts element.to_s
    on.row_object("hw_node",element[0]).selected=true
end
