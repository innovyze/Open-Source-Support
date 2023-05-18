net=WSApplication.current_network
nodes=Array.new
net.row_object_collection('hw_node').each do |n|
        if n.selected?
                temp=Array.new
                temp << n.id
                temp << n.x
                temp << n.y
                temp << n.system_type
                nodes << temp
        end
end
net.transaction_begin
net.row_object_collection('hw_subcatchment').each do |s|
        if s.selected?
                node_system_type = ''
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
                        node_system_type = nodes[i][3].downcase
                        if distance < nearest_distance && s.system_type == node_system_type
                                nearest_distance=distance
                                s.node_id = n_id
                        end
                        if distance < nearest_storm_distance && node_system_type == "storm"
                                nearest_storm_distance = distance
                                s.user_text_1 = n_id
                        elsif distance < nearest_foul_distance && node_system_type == "foul"
                                nearest_foul_distance = distance
                                s.user_text_2 = n_id
                        elsif distance < nearest_sanitary_distance && node_system_type == "sanitary"
                                nearest_sanitary_distance = distance
                                s.user_text_3 = n_id
                        elsif distance < nearest_combined_distance && node_system_type == "combined"
                                nearest_combined_distance = distance
                                s.user_text_4 = n_id
                        elsif distance < nearest_overland_distance && node_system_type == "overland"
                                nearest_overland_distance = distance
                                s.user_text_5 = n_id
                        elsif distance < nearest_other_distance && node_system_type == "other"
                                nearest_other_distance = distance
                                s.user_text_6 = n_id
                        end
                end
        end
        s.write
end
net.transaction_commit