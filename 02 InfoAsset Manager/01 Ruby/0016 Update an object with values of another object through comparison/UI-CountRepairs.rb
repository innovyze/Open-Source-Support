##Count the quantity of 'Reactive Network' Pipe Repairs (user_text_8) based on Asset ID (user_text_10) and write to Pipe.
net=WSApplication.current_network
repairs=Hash.new
net.row_objects('cams_pipe_repair').each do |p|
	type=p.user_text_8.downcase
	if !type.nil? && type.length>0 && type=='reactive network'
		repair=p.user_text_10.downcase
		if !repair.nil? && repair.length>0
				if !repairs.has_key? repair
					repairs[repair]=1
				elsif repairs.has_key? repair
					repairs[repair]=repairs[repair]+1
			end
		end
	end
end
##Write the count of 'Reactive Network' Pipe Repairs onto the Pipe based on the Asset ID
puts repairs
net.transaction_begin
net.row_objects('cams_pipe').each do |i|
	repair=i.asset_id.downcase
	if !repair.nil?
		if repairs.has_key? repair
			i.user_text_6=repairs[repair]
			i.write
		end
	end
end
net.transaction_commit
