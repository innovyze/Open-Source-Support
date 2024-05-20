net = WSApplication.current_network
net.transaction_begin
net.row_objects('hw_conduit').each do |conduit|
	# if conduit.selected?
		net.row_objects('hw_cross_section_survey').each do |cross_section|
			# if cross_section.selected?
				cross_section.section_array.each do |point|
					if point.x == conduit.us_node.x && point.y == conduit.us_node.y
						conduit.us_invert = point.z
					end
					if point.x == conduit.ds_node.x && point.y == conduit.ds_node.y
						conduit.ds_invert = point.z
					end
				end
			# end
		end
	# end
	conduit.write
end
net.transaction_commit