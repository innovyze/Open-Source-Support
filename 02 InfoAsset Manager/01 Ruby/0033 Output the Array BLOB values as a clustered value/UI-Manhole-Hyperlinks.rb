## List the Hyperlinks.URL values as a single clustered value for each Manhole object

net=WSApplication.current_network
obj=net.row_objects_selection('cams_manhole')
obj.each do |s|
	if !s.hyperlinks.nil? && s.hyperlinks.size>0
		jp=s.hyperlinks
		join=Array.new
		jp.each do |j|
			join<<j.url
		end
		puts "#{s.id} :	#{join.join(', ')}"
	end
end