net=WSApplication.current_network
net.row_objects('hw_river_reach').each do |rr|
    blob = rr.conveyance
    i = 1
    j = 0
    while i < blob.length
        section_key = blob[i - 1]['key']
        if blob[i]['key'] == blob[i - 1]['key']
            diff = blob[i]['conveyance'] - blob[i - 1]['conveyance']
        else
            diff = 0
            j = i
        end
        puts "CHECK => River Reach: #{rr.id} || Section key #{section_key} || Row #{i - j + 1} || Diff = #{diff}" if diff < 0
        i+=1
    end
end
puts "complete"