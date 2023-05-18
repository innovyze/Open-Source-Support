## List the Pipe Clean ID and the IDs of the Pipes from the pipes sub-table
net=WSApplication.current_network
obj=net.row_objects_selection('cams_pipe_clean')
puts "Pipe Clean ID :	Pipes"
obj.each do |s|
	if !s.pipes.nil? && s.pipes.size>0
		jp=s.pipes
		join=Array.new
		jp.each do |j|
			join<<j.us_node_id+'.'+j.us_node_id+'.'+j.link_suffix
		end
		puts "#{s.id} :	#{join.join(', ')}"
	end
end
