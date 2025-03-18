require 'date'

net=WSApplication.current_network
net.transaction_begin
net.row_object_collection('cams_screen').each do |ob|
    if ob.selected?
        su = net.new_row_object('cams_flood_defence_survey')
		points = ob.point_array
        su['id'] = ob.id + '_' + DateTime.now.to_s
		su['user_text_33'] = ob.id
		
		line=su.point_array
		line.length=2
		line[0].x=points[0]
		line[0].y=points[1]
		line[1].x=points[2]
		line[1].y=points[3]
		
		su.point_array.write
        su.write
    end
end
net.transaction_commit