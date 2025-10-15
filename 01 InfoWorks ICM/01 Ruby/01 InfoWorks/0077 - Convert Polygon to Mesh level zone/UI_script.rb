# Convert Selected Polygon Objects to Mesh Level Zone Objects

net = WSApplication.current_network
 
net.transaction_begin
 
net.row_object_collection('hw_polygon').each do |polygon|
 
  next if polygon.selected == false
 
  new_mlz = net.new_row_object('hw_mesh_level_zone')

  new_mlz.polygon_id = "MLZ#{polygon.id}"

  coordinates_array = polygon.boundary_array.each_slice(2).to_a # Convert flat array to array of [x,y] pairs

  new_mlz.level_sections.length = coordinates_array.length + 1 # +1 to close the polygon

  for i in (0..coordinates_array.length - 1)
 
    x = coordinates_array[i][0]
 
    y = coordinates_array[i][1]

    new_mlz.level_sections[i].X = x

    new_mlz.level_sections[i].Y = y

    new_mlz.level_sections[i].vertex_elev_type = 'Ground model' # Choices are 'Ground model', 'Set', 'Interpolate'

  end
  
  # Close the polygon by adding the first coordinate at the end
  new_mlz.level_sections[coordinates_array.length].X = coordinates_array[0][0]

  new_mlz.level_sections[coordinates_array.length].Y = coordinates_array[0][1]

  new_mlz.level_sections[coordinates_array.length].vertex_elev_type = 'Ground model'

  new_mlz.level_sections.write

  new_mlz.write
 
end
 
net.transaction_commit
