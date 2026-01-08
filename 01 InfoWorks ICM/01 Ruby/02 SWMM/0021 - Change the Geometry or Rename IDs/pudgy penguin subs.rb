# --- Universal Polygon Geometry and ID Changer ---
# This script modifies the boundary and ID of any selected subcatchment.
# It automatically detects the network type (SW or HW).
#
# It can reshape selected subcatchments into:
#  - A RECTANGLE that fits the original shape's extents.
#  - A regular POLYGON (triangle, pentagon, circle, etc.).
#  - A pre-defined CUSTOM shape (default is a penguin).

# --- USER CONFIGURATION ---

# 1. SHAPE AND ID SETTINGS:
#    - NEW_BASE_ID: The prefix for renaming selected subcatchments. A number will be appended (e.g., "Penguin_1", "Penguin_2").
#    - SHAPE_TYPE:  'RECTANGLE', 'POLYGON', or 'CUSTOM'.
NEW_BASE_ID = 'Penguin'
SHAPE_TYPE = 'CUSTOM'

# 2. POLYGON SETTINGS (only if SHAPE_TYPE is 'POLYGON'):
#    - For a triangle: 3, pentagon: 5, circle: 50, etc.
NUMBER_OF_SIDES = 6

# 3. CUSTOM SHAPE SETTINGS (only if SHAPE_TYPE is 'CUSTOM'):
#    - PRESERVE_AREA: If true, scales the shape to match the original subcatchment area
#    - SCALE: Base scale for the shape (used if PRESERVE_AREA is false)
#    - CUSTOM_SHAPE_POINTS: An array of [x, y] coordinates defining the shape.
#      - The origin [0,0] is the shape's center.
#      - For symmetrical shapes, you can define one half and the script will mirror it.
#        To do this, start and end the points list on the centerline (x=0).
PRESERVE_AREA = true
SCALE = 15.0
CUSTOM_SHAPE_POINTS = [
  # Detailed cute penguin shape (right half only - will be mirrored)
  # Head and hair tuft
  [0.0, 20.0],      # Top of head
  [0.5, 19.8],      # Hair tuft start
  [0.3, 20.3],      # Hair spike 1
  [0.8, 20.1],      # Hair spike 2
  [0.6, 20.5],      # Hair spike 3
  [1.2, 20.0],      # Hair tuft end
  [3.0, 19.5],      # Head curve
  [4.5, 18.5],      # Head side
  [5.5, 17.0],      # Head to body
  [6.0, 15.0],      # Upper body
  
  # Wing
  [6.2, 13.0],      # Wing attachment
  [7.5, 11.0],      # Wing upper
  [8.0, 8.0],       # Wing mid
  [7.8, 5.0],       # Wing lower
  [7.0, 3.0],       # Wing tip
  [6.5, 3.5],       # Wing return
  
  # Body
  [6.0, 6.0],       # Body side
  [5.8, 3.0],       # Lower body
  [5.0, 1.0],       # Body to feet
  
  # Feet
  [5.5, 0.0],       # Foot outer
  [4.5, -0.5],      # Foot middle
  [3.0, -0.3],      # Foot inner
  [2.0, 0.0],       # Between feet
  [0.0, 0.0]        # Center bottom
]

# --- END OF CONFIGURATION ---

# Get the current network object from the application
net = WSApplication.current_network

# --- SHAPE GENERATION FUNCTIONS ---

# Calculate the area of a polygon using the Shoelace formula
def calculate_polygon_area(boundary_array)
  n = boundary_array.length / 2
  area = 0.0
  
  (0...n-1).each do |i|
    x1 = boundary_array[i * 2]
    y1 = boundary_array[i * 2 + 1]
    x2 = boundary_array[(i + 1) * 2]
    y2 = boundary_array[(i + 1) * 2 + 1]
    area += (x1 * y2 - x2 * y1)
  end
  
  area.abs / 2.0
end

# Calculate the area of a shape defined by points
def calculate_shape_area(shape_points)
  area = 0.0
  n = shape_points.length
  
  (0...n-1).each do |i|
    x1 = shape_points[i][0]
    y1 = shape_points[i][1]
    x2 = shape_points[i + 1][0]
    y2 = shape_points[i + 1][1]
    area += (x1 * y2 - x2 * y1)
  end
  
  # Close the polygon if not closed
  if shape_points[0] != shape_points[-1]
    x1 = shape_points[-1][0]
    y1 = shape_points[-1][1]
    x2 = shape_points[0][0]
    y2 = shape_points[0][1]
    area += (x1 * y2 - x2 * y1)
  end
  
  area.abs / 2.0
end

# Generates a boundary for a pre-defined custom shape
def generate_custom_shape_boundary(center_x, center_y, scale, shape_points, original_area = nil, preserve_area = false)
  full_shape_points = []

  # Check if the shape is a symmetrical half that needs mirroring
  # We assume it is if the first and last x-coordinates are 0
  if shape_points.first[0] == 0 && shape_points.last[0] == 0 && shape_points.size > 2
    # Mirror the points to create the full symmetrical shape
    right_side = shape_points
    left_side = right_side[1...-1].map { |p| [-p[0], p[1]] }.reverse
    full_shape_points = right_side + left_side
  else
    # Use the points as they are for an asymmetrical shape
    full_shape_points = shape_points
  end
  
  # Calculate scale factor if preserving area
  actual_scale = scale
  if preserve_area && original_area
    # Calculate the area of the template shape at scale 1.0
    template_area = calculate_shape_area(full_shape_points)
    # Calculate required scale to match original area
    actual_scale = Math.sqrt(original_area / template_area)
  end
  
  new_boundary = []
  full_shape_points.each do |point|
    # Apply scaling and translate the point relative to the polygon's center
    scaled_x = center_x + (point[0] * actual_scale)
    scaled_y = center_y + (point[1] * actual_scale)
    new_boundary << scaled_x << scaled_y
  end
  
  # Close the polygon if it isn't already
  if new_boundary[0] != new_boundary[-2] || new_boundary[1] != new_boundary[-1]
    new_boundary << new_boundary[0] << new_boundary[1]
  end

  return new_boundary
end

# Generates a regular polygon (triangle, pentagon, etc.)
def generate_regular_polygon_boundary(boundary_array, sides)
  sides = 3 if sides < 3
  min_x, max_x = boundary_array.each_slice(2).map(&:first).minmax
  min_y, max_y = boundary_array.each_slice(2).map(&:last).minmax
  width = max_x - min_x
  height = max_y - min_y
  center_x = min_x + width / 2.0
  center_y = min_y + height / 2.0
  radius_x = width / 2.0
  radius_y = height / 2.0
  
  new_boundary = []
  sides.times do |i|
    angle = 2 * Math::PI / sides * i - (Math::PI / 2)
    x = center_x + radius_x * Math.cos(angle)
    y = center_y + radius_y * Math.sin(angle)
    new_boundary << x << y
  end
  new_boundary << new_boundary[0] << new_boundary[1]
  return new_boundary
end

# Generates a rectangle boundary
def generate_rectangle_boundary(boundary_array)
  min_x, max_x = boundary_array.each_slice(2).map(&:first).minmax
  min_y, max_y = boundary_array.each_slice(2).map(&:last).minmax
  return [min_x, min_y, max_x, min_y, max_x, max_y, min_x, max_y, min_x, min_y]
end

# --- SCRIPT EXECUTION ---

# 1. Automatically Detect Network Type
network_type_prefix = nil
table_name = nil
table_names = net.table_names

table_names.each do |name|
  if name.start_with?('hw_')
    network_type_prefix = 'hw'
    table_name = 'hw_subcatchment'
    puts "InfoWorks Network detected."
    break
  elsif name.start_with?('sw_')
    network_type_prefix = 'sw'
    table_name = 'sw_subcatchment'
    puts "SWMM Network detected."
    break
  end
end

# 2. Process the subcatchments
if table_name.nil?
  puts "Error: No 'hw_subcatchment' or 'sw_subcatchment' table found in the network."
else
  # Begin a transaction. This groups all database changes into a single operation.
  net.transaction_begin
  
  begin
    puts "Detected '#{table_name}' table. Processing selected subcatchments..."
    objects = net.row_object_collection(table_name)
    id_counter = 0

    objects.each do |polygon|
      if polygon.selected?
        id_counter += 1
        old_id = polygon.id
        new_id = "#{NEW_BASE_ID}_#{id_counter}"
        
        # Rename the subcatchment
        polygon.id = new_id
        
        new_boundary = nil
        
        # Generate the new boundary based on the chosen SHAPE_TYPE
        case SHAPE_TYPE.upcase
        when 'RECTANGLE'
          new_boundary = generate_rectangle_boundary(polygon.boundary_array)
        when 'POLYGON'
          new_boundary = generate_regular_polygon_boundary(polygon.boundary_array, NUMBER_OF_SIDES)
        when 'CUSTOM'
          # For custom shapes, we use the polygon's existing center point
          # Calculate original area if preserving area
          original_area = nil
          if PRESERVE_AREA
            original_area = calculate_polygon_area(polygon.boundary_array)
          end
          new_boundary = generate_custom_shape_boundary(
            polygon.x, 
            polygon.y, 
            SCALE, 
            CUSTOM_SHAPE_POINTS,
            original_area,
            PRESERVE_AREA
          )
        else
          puts "Warning: Invalid SHAPE_TYPE '#{SHAPE_TYPE}' for polygon '#{old_id}'. Skipping geometry change."
        end
        
        # Apply the new geometry if it was generated
        if new_boundary
          polygon.boundary_array = new_boundary
        end
        
        polygon.write # Save the changes (ID and geometry)
        puts "Updated '#{old_id}' to '#{new_id}' with new shape."
      end
    end
    
    if id_counter == 0
      puts "No subcatchments were selected. Nothing to do."
      net.transaction_rollback
    else
      # Commit the transaction, making all the changes permanent
      net.transaction_commit
      puts "Successfully updated #{id_counter} subcatchment(s)."
    end
    
  rescue => e
    # If any error occurs, roll back the transaction
    net.transaction_rollback
    puts "Error occurred: #{e.message}"
    puts "Transaction rolled back. No changes were made."
  end
end

puts "Script finished."