net=WSApplication.current_network
puts 'Running ruby for SWMM Networks'
nodes=Array.new
net.row_object_collection('sw_node').each do |n|
        if n.selected?
                temp=Array.new
                temp << n.id
                temp << n.x
                temp << n.y
                nodes << temp
        end
end
net.transaction_begin
net.row_object_collection('sw_subcatchment').each do |s|
        if s.selected?
                sx = s.x
                sy = s.y
                nearest_distance = 999999999.9
                (0...nodes.size).each do |i|
                        nx = nodes[i][1]
                        ny = nodes[i][2]
                        n_id = nodes[i][0]
                        distance=((sx-nx)*(sx-nx))+((sy-ny)*(sy-ny))
                        if distance < nearest_distance
                                nearest_distance=distance
                                s.outlet_id = n_id
                        end
                end
        else
        puts 'You forgot to select anything'
        end
        s.write
end
puts 'Ending ruby'
net.transaction_commit

