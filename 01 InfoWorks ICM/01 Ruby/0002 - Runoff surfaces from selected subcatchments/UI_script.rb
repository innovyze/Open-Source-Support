net=WSApplication.current_network
selectedRunoffSurfaces=Hash.new
net.row_objects_selection('hw_runoff_surface').each do |rs|
        selectedRunoffSurfaces[rs.id.to_s]=0
end
selectedLandUses=Hash.new
net.row_objects('hw_land_use').each do |lu|
        (1..10).each do |i|
                runoffSurface=lu['runoff_index_'+i.to_s]
                if !runoffSurface.nil?
                        puts runoffSurface
                        if selectedRunoffSurfaces.has_key? runoffSurface.to_s
                                selectedLandUses[lu.id.to_s]=0
                                lu.selected=true
                        end
                end
        end
end
net.row_objects('hw_subcatchment').each do |s|
        if selectedLandUses.has_key? s.land_use_id
                s.selected=true
        end
end
