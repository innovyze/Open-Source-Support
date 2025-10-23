## Set the User Text 33 field of a Pipe to the point_array value.
net=WSApplication.current_network
net.transaction_begin
ob=net.row_objects('cams_pipe')
ob.each do |s|
	unless s.point_array.nil?
		puts "#{s.us_node_id}.#{s.ds_node_id}.#{s.link_suffix} #{s.point_array}"
		s['user_text_33'] = s.point_array.to_s
	end
	s.write
end
net.transaction_commit