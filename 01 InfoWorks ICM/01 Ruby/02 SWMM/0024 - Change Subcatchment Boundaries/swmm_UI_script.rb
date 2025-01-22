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
  polygon_boundary << polygon_boundary[0] << polygon_boundary[1]  # Close the shape

  polygon_boundary
end

# Prompt the user to select the network type and desired shape
parameters = WSApplication.prompt "Select the network type and desired shape for the polygons",
[
  ['Is this a SWMM network?', 'Boolean', true],
  ['Triangle (3-sided)', 'Boolean', false],
  ['Square (4-sided)', 'Boolean', false],
  ['Pentagon (5-sided)', 'Boolean', false],
  ['Hexagon (6-sided)', 'Boolean', false],
  ['Heptagon (7-sided)', 'Boolean', false],
  ['Octagon (8-sided)', 'Boolean', false],
  ['Nonagon (9-sided)', 'Boolean', false],
  ['Decagon (10-sided)', 'Boolean', false],
  ['Hendecagon (11-sided)', 'Boolean', false],
  ['Dodecagon (12-sided)', 'Boolean', false],
  ['Tridecagon (13-sided)', 'Boolean', false],
  ['Tetradecagon (14-sided)', 'Boolean', false],
  ['Pentadecagon (15-sided)', 'Boolean', true]
], false

is_swmm_network = parameters[0]
shape_selection = parameters[1..-1]

# Determine the prefix based on the network type
prefix = is_swmm_network ? 'sw' : 'hw'

# Determine the number of sides based on the user's selection
sides = if shape_selection[0]
          3
        elsif shape_selection[1]
          4
        elsif shape_selection[2]
          5
        elsif shape_selection[3]
          6
        elsif shape_selection[4]
          7
        elsif shape_selection[5]
          8
        elsif shape_selection[6]
          9
        elsif shape_selection[7]
          10
        elsif shape_selection[8]
          11
        elsif shape_selection[9]
          12
        elsif shape_selection[10]
          13
        elsif shape_selection[11]
          14
        else
          15  # Default to a 15-sided polygon
        end

# Iterate over all polygon objects in the network or subcatchments for the selected network type
net.row_object_collection("#{prefix}_subcatchment").each do |polygon|
  # Check if the polygon is selected  
  if polygon.selected?
    # Get the boundary array of the polygon
    boundary_array = polygon.boundary_array

    # Set the new boundary array based on the desired shape
    polygon.boundary_array = generate_polygon_boundary(boundary_array, sides)
    polygon.write
  end
end

# Commit the transaction, making all changes permanent
net.transaction_commit