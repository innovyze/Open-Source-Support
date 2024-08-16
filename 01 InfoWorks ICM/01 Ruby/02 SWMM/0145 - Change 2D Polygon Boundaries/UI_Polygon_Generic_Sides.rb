# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Function to generate the boundary for a polygon with a given number of sides
def generate_polygon_boundary(boundary_array, sides)
    # Calculate the minimum and maximum x and y coordinates
    min_x = boundary_array.each_slice(2).map(&:first).min
    max_x = boundary_array.each_slice(2).map(&:first).max
    min_y = boundary_array.each_slice(2).map(&:last).min
    max_y = boundary_array.each_slice(2).map(&:last).max

    # Calculate the width and height
    width = max_x - min_x
    height = max_y - min_y

    # Calculate the points of the polygon
    polygon_boundary = []
    sides.times do |i|
        angle = 2 * Math::PI / sides * i
        x = min_x + width * 0.5 + width * 0.5 * Math.cos(angle)
        y = min_y + height * 0.5 + height * 0.5 * Math.sin(angle)
        polygon_boundary << x << y
    end
    polygon_boundary << polygon_boundary[0] << polygon_boundary[1]  # Close the shapet
    polygon_boundary
end

# Define the types of polygons that can be reshaped
polygon_types = ['hw_2d_infiltration_zone', 'hw_2d_permeable_zone', 'hw_mesh_zone', 'hw_2d_results_polygon','hw_roughness_zone', 'hw_porous_polygon', 'hw_polygon']

# Iterate over each type of polygon
polygon_types.each do |polygon_type|
  # Iterate over all polygon objects of the current type in the network
  net.row_object_collection(polygon_type).each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
      # Get the boundary array of the polygon
      boundary_array = polygon.boundary_array

      # Set the new boundary array
      sides = 9 
      polygon.boundary_array = generate_polygon_boundary(boundary_array, sides)  # Change the number of sides here
      polygon.write
    end
  end
end

# Commit the transaction, making all changes permanent
net.transaction_commit

# All ICM InfoWorks 
# hw_2d Polygons move to net.row_object_collection('# hw_mesh_level_zone').each do |polygon| for each polygon tyupe 
# hw_2d_zone
# hw_2d_ic_polygon
# hw_2d_point_source
# hw_2d_boundary_line
# hw_2d_bridge
# hw_2d_line_source
# hw_2d_results_polygon
# hw_2d_results_line
# hw_2d_results_point
# hw_2d_zone_defaults
# hw_2d_infil_surface
# hw_2d_infiltration_zone   YES it can be uses for polygon reshaping
# hw_2d_wq_ic_polygon
# hw_2d_inf_ic_polygon
# hw_2d_sed_ic_polygon
# hw_2d_turbulence_model
# hw_2d_turbulence_zone
# hw_2d_permeable_zone     YES it can be uses for polygon reshaping
# hw_2d_connect_line
# hw_2d_sluice
# hw_2d_linear_structure
# hw_building               No use level_sections
# hw_mesh_zone              YES it can be uses for polygon reshaping
# hw_mesh_level_zone        No use level_sections
# hw_roughness_zone         YES it can be uses for polygon reshaping
# hw_porous_polygon         YES it can be uses for polygon reshaping
# hw_polygon                YES it can be uses for polygon reshaping