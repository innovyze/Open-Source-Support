#this script attempts to reduce each river each down to only the first and last sections (keys)
net=WSApplication.current_network
net.transaction_begin
net.row_objects('hw_river_reach').each do |rr|
    if rr.selected?
        blob=rr.sections
		first_key=blob[0].key
		last_key=blob[blob.length - 1].key
		# creates a new values_array array that has a sequence of exploded values matching first_key and last_key
		values_array=Array.new
		i=0
        while i < blob.length
            if blob[i].key == first_key || blob[i].key == last_key
				values_array << blob[i].key
                values_array << blob[i].X
                values_array << blob[i].Y
                values_array << blob[i].Z
                values_array << blob[i].roughness_N
                values_array << blob[i].new_panel
            end
            i+=1
        end
		# resets the size of the blob to the number of divided by 6 fields
		blob.size=values_array.length/6
		# starts iterating the new shortened blob with exploded values from values_array
		i=0
		blob.each do |row|
			row.key=values_array[i+0]
			row.X=values_array[i+1]
			row.Y=values_array[i+2]
			row.Z=values_array[i+3]
			row.roughness_N=values_array[i+4]
			row.new_panel=values_array[i+5]
			i=i+6
		end
    end
    rr.sections.write
    rr.write
end
net.transaction_commit