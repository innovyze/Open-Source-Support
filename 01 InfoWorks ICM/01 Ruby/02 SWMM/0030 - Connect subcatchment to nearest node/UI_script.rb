net=WSApplication.current_network
puts 'running ruby for InfoWorks Networks'
nodes=Array.new
net.row_object_collection('hw_node').each do |n|
        if n.selected?
                temp=Array.new
                temp << n.id
                temp << n.x
                temp << n.y
                nodes << temp
        end
end
net.transaction_begin
net.row_object_collection('hw_subcatchment').each do |s|
        if s.selected?
                sx = s.x
                sy = s.y
                nearest_distance = 999999999.9
                nearest_storm_distance = 999999999.9
                nearest_foul_distance = 999999999.9
                nearest_sanitary_distance = 999999999.9
                nearest_combined_distance = 999999999.9
                nearest_overland_distance = 999999999.9
                nearest_other_distance = 999999999.9
                (0...nodes.size).each do |i|
                        nx = nodes[i][1]
                        ny = nodes[i][2]
                        n_id = nodes[i][0]
                        distance=((sx-nx)*(sx-nx))+((sy-ny)*(sy-ny))
                        if distance < nearest_distance
                                nearest_distance=distance
                                s.node_id = n_id
                        end
                end
        else
        puts 'You forgot to select anything'
        end
        s.write
end
puts 'ending ruby'
net.transaction_commit

