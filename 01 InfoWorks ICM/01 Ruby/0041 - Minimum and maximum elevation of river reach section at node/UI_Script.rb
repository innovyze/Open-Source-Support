net=WSApplication.current_network
net.each_selected do |object|
    if object.table == 'hw_node'
        z_array = Array.new
        object.navigate('us_links').each do |us_links|
            if us_links.table == 'hw_river_reach'
                blob = us_links.sections
                ds_section = blob[blob.length - 1].key
                blob.each do |blob_row|
                    if ds_section == blob_row.key
                        z_array << blob_row.z
                    end
                end
            end
        end
        object.navigate('ds_links').each do |ds_links|
            if ds_links.table == 'hw_river_reach'
                blob = ds_links.sections
                us_section = blob[0].key
                blob.each do |blob_row|
                    if us_section == blob_row.key
                        z_array << blob_row.z
                    end
                end
            end
        end
        puts min_z = z_array.min
        puts max_z = z_array.max
    end
end