##Count the quantity of Connection Pipes with user_text_1 unique values.
net=WSApplication.current_network
connections=Hash.new
net.row_objects('cams_connection_pipe').each do |p|
		connection=p.user_text_1.downcase
	if !connection.nil? && connection.length>0
			if !connections.has_key? connection
				connections[connection]=1
			elsif connections.has_key? connection
				connections[connection]+=
		end
	end
end
##Write the count of Connection Pipes onto the Pipe based on the Asset ID
puts connections
net.transaction_begin
net.row_objects('cams_pipe').each do |i|
	connection=i.asset_id.downcase
	if !connection.nil?
		if connections.has_key? connection
			i.user_text_5=connections[connection]
			i.write
		end
	end
end
net.transaction_commit
