db = WSApplication.current_database
nw = WSApplication.current_network
my_object = nw.model_object

p_id = my_object.parent_id
p_type = my_object.parent_type
parent_object = db.model_object_from_type_and_id p_type, p_id


(0..999).each do
	temp_p_id = parent_object.parent_id
	temp_p_type = parent_object.parent_type
	#puts parent_object.name
	break if temp_p_id == 0
	parent_object = db.model_object_from_type_and_id temp_p_type, temp_p_id
end

#puts parent_object.name

# Set the directory for the data here
Dir.chdir 'C:\Temp'
# Set the error file and other ODIC options - see the IExchange help section for details

options=Hash.new
options['Error File'] = '.\ICMExportErrors.txt'
#options['Export Selection'] = true

# Nodes
puts "Node Export commenced: #{ DateTime.now.to_time } "
             nw.odec_export_ex('MIF', '.\ICMFieldMapping.cfg', options, 'Node', '.\\' + parent_object.name)
puts "Node Export complete: #{ DateTime.now.to_time } "

# Pipes
puts "Conduit Export commenced: #{ DateTime.now.to_time } "
               nw.odec_export_ex('MIF', '.\ICMFieldMapping.cfg', options, 'Conduit', '.\\' + parent_object.name)
puts "Conduit Export complete: #{ DateTime.now.to_time } "
