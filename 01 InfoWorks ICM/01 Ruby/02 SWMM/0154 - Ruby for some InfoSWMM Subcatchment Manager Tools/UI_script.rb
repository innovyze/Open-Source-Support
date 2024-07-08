# Usage example
cn = WSApplication.current_network

val = WSApplication.prompt "Choose USA or SI Units SWMM5 Subcatchment Width Calculation Method",
[
  ['USA Units','Boolean',false],
  ['SI  Units','Boolean',true],
  ['Width = 1.7 * Max(Height, Width)', 'Boolean',false],
  ['Width = K * SQRT(Area)', 'Boolean',false],
  ['Width = K * Perimeter', 'Boolean',false],
  ['Width = Area / Flow Length', 'Boolean',false],
  ['K value 0.2 to 5 default of 1', 'String'],
  ['Choose the Unit type and Width Option', 'String']
], false
USA = val[0]
SI  = val[1]
K   = val[6].to_f
K   = K.to_f
K   = 1.0 if K.nil? || K == 0
MaxHeight = val[2]
SQRT_Area = val[3]
Width_Perimeter = val[4]
Flow_Length = val[5]

cn.transaction_begin

# Initialize a hash to store perimeter, max_height, and max_width for each subcatchment
subcatchment_measurements = {}

cn.row_object_collection('hw_subcatchment').each do |polygon|
  boundary_array = polygon.boundary_array
  perimeter = 0.0
  max_height = 0.0
  max_width = 0.0

  if boundary_array.any?
    points = boundary_array.each_slice(2).to_a
    min_x = points.map(&:first).min
    max_x = points.map(&:first).max
    min_y = points.map(&:last).min
    max_y = points.map(&:last).max
    max_width = max_x - min_x
    max_height = max_y - min_y

    points.each_with_index do |point, index|
      next_point = points[(index + 1) % points.size]
      distance = Math.sqrt((next_point[0] - point[0])**2 + (next_point[1] - point[1])**2)
      perimeter += distance
    end
  end

  # Store the measurements in the hash with subcatchment ID as the key
  subcatchment_measurements[polygon.subcatchment_id] = {
    perimeter: perimeter,
    max_height: max_height,
    max_width: max_width
  }
end

# Output the measurements for each subcatchment
subcatchment_measurements.each do |id, measurements|
  puts "Subcatchment ID: #{id}, Perimeter: #{'%.4f' % measurements[:perimeter]}, Max Height: #{'%.4f' % measurements[:max_height]}, Max Width: #{'%.4f' % measurements[:max_width]}"
end

total_before = 0
total_after = 0
cn.row_objects('hw_subcatchment').each do |ro|
  if ro.total_area && ro.catchment_dimension
    total_before += ro.catchment_dimension
    if MaxHeight  
      ro.catchment_dimension = 1.7 * [subcatchment_measurements[ro.subcatchment_id][:max_width], subcatchment_measurements[ro.subcatchment_id][:max_height]].max
    end 
    if SQRT_Area 
      ro.catchment_dimension = K * Math.sqrt(ro.total_area * (USA ? 43560.0 : 10000.0))
    end  
    if Width_Perimeter  
      ro.catchment_dimension = K * subcatchment_measurements[ro.subcatchment_id][:perimeter]
    end 
    if Flow_Length 
      ro.catchment_dimension = (ro.total_area * (USA ? 43560.0 : 10000.0)) / ([subcatchment_measurements[ro.subcatchment_id][:max_width], subcatchment_measurements[ro.subcatchment_id][:max_height]].max)
    end
    total_after += ro.catchment_dimension
    ro.write
  end
end

puts "Total SWMM5 Width or dimension before update: #{'%.4f' % total_before}"
puts "Total SWMM5 Width or dimension after update:  #{'%.4f' % total_after}"
puts "Total SWMM5 Width or dimension change:        #{'%.4f' % (total_after - total_before)}"
if SQRT_Area 
  puts K == 1 ? "Width = K * SQRT(Area) with K = 1" : "Width = K * SQRT(Area) with K = #{K}"
end
if Width_Perimeter 
  puts K == 1 ? "Width = K * Perimeter with K = 1" : "Width = K * Perimeter with K = #{K}"
end

cn.transaction_commit


