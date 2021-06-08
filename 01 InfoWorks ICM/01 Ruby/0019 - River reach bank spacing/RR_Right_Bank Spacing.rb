net=WSApplication.current_network
ros=net.row_objects('hw_river_reach')
threshold=5.0
ros.each do |ro|
    blob=ro['right_bank']
    x_last=0.0
    y_last=0.0
    total=0.0
    n=1
    blob.each do |l|
        if n==1
            x_last=l.X
            y_last=l.Y
            dist=0.0
            total=0.0
        else
            x=l.X
            y=l.Y
            dist=(((x-x_last)**2)+((y-y_last)**2))**0.5
            total+=dist
            x_last=x
            y_last=y
            if dist<threshold
                puts " Check River Reach = #{ro.id}, Row id = #{n}, Distance #{dist}m"             
                ro.selected=true
            end
        end
        n+=1
    end
end 