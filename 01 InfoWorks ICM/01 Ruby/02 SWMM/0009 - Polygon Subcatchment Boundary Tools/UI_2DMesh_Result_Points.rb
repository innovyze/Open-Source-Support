# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Function to generate points inside a polygon with a given number of points
def generate_polygon_1D_Results(boundary_array, points, polygon_id)
  net = WSApplication.current_network
  # Calculate the minimum and maximum x and y coordinates
  min_x = boundary_array.each_slice(2).map(&:first).min
  max_x = boundary_array.each_slice(2).map(&:first).max
  min_y = boundary_array.each_slice(2).map(&:last).min
  max_y = boundary_array.each_slice(2).map(&:last).max

  # Calculate the width and height
  width = max_x - min_x
  height = max_y - min_y

  # Calculate the distance between points
  x_step = width / (points - 1)
  y_step = height / (points - 1)

  # Generate the points
  polygon_points = []
  point_id = 0
  points.times do |i|
      points.times do |j|
          x = min_x + i * x_step
          y = min_y + j * y_step
          point_id += 1
          point = net.new_row_object('hw_2d_results_point')
          point['point_id'] = "#{polygon_id}_#{point_id}"
          point['point_x'] = x
          point['point_y'] = y
          point.write
          polygon_points << point
      end
  end
  polygon_points
end

# Define the types of polygons that can be reshaped
polygon_types = ['hw_2d_infiltration_zone', 'hw_2d_permeable_zone', 'hw_mesh_zone', 'hw_2d_results_polygon','hw_roughness_zone', 'hw_porous_polygon', 'hw_polygon']

# Iterate over each type of polygon
polygon_types.each do |polygon_type|
  # Iterate over all polygon objects of the current type in the network
  net.row_object_collection(polygon_type).each do |polygon|

  if polygon.selected?
    # Get the boundary array of the polygon
    boundary_array = polygon.boundary_array
    # Generate the points and create hw_2d_results_point objects
    generate_polygon_1D_Results(boundary_array, 100, polygon.id)  # Change the number of points here
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
# hw_polygon                YES it can be uses for polygon reshaping`