## Display and Export to CSV the point_array of selected Pipes to to the file on line 5.

net=WSApplication.current_network
require 'csv'
CSV.open("c:\\temp\\pipes.csv", "wb") do |csv|
	pipes=net.row_objects_selection('cams_pipe')		## Remove "_selection" to run on whole network
	pipes.each do |s|
		unless s.point_array.nil?
			puts "#{s.us_node_id}.#{s.ds_node_id}.#{s.link_suffix} #{s.point_array}"
			csv << ["#{s.us_node_id}", "#{s.ds_node_id}", "#{s.link_suffix}", "#{s.point_array}"]
		else
			puts "#{s.us_node_id}.#{s.ds_node_id}.#{s.link_suffix}"
			csv << ["#{s.us_node_id}", "#{s.ds_node_id}", "#{s.link_suffix}",]	
		end
	end
end

