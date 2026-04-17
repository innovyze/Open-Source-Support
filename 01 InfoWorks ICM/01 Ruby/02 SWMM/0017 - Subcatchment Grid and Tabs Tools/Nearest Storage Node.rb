net=WSApplication.current_network
net.transaction_begin

puts 'Connecting subcatchments to the closest storage node to centroid:'

#loop through each subcatchment object extracting the X,Y and setting a default distance of 999999999
subcatchment=net.row_objects('hw_subcatchment').each do |subcatchment| 
	if subcatchment.node_id == "" #where field is blank
	x=subcatchment.x
	y=subcatchment.y
	di=9999999999
	dischargeNode=''
	
node=net.row_objects('hw_node').each do |node| 
	if node.node_type.downcase == "storage" #only calculate against note_type = storage
	#.downcase makes the match case insensitive
	tdi=((x-node.x)**2+(y-node.y)**2)**0.5 #calculate distance to node
		if (tdi<di)
		dischargeNode=node['node_id'] #updates node id for smallest distance
		di=tdi
		end
	end
end 

puts subcatchment['subcatchment_id']+':'+ dischargeNode
subcatchment['node_id'] = dischargeNode
subcatchment.write 

	end
end

net.transaction_commit