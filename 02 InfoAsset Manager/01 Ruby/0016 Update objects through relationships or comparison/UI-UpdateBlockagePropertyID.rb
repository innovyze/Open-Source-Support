net=WSApplication.current_network
properties=Hash.new
net.row_objects('cams_property').each do |p|
		id=p.id
		address=p.property_address.downcase
	if !address.nil? && address.length>0
			if !properties.has_key? address
				properties[address]=id
		end
	end
end
net.transaction_begin
net.row_objects('cams_incident_blockage').each do |i|
	if !i.property_id.nil? && i.property_id.length==0
		address=i.location.downcase
		if !address.nil?
			if properties.has_key? address
				i.property_id=properties[address]
				i.write
			end
		end
	end
end
net.transaction_commit
