# Initialize the current network
cn = WSApplication.current_network

# Initialize an array to store subcatchment variables
subcatchment_variables = []

# Loop through each subcatchment in the network
cn.row_objects('hw_subcatchment').each do |subcatchment|
  # Add the subcatchment variables to the array
  # Each subcatchment is represented as a hash with keys corresponding to variable names and values corresponding to variable values
  subcatchment_variables << {
    'Subcatchment ID' => subcatchment.subcatchment_id,
    'Land use ID' => subcatchment.land_use_id,
    'Total area' => subcatchment.total_area,
    'Contributed_area' => subcatchment.contributing_area,
    'Area measurement type' => subcatchment.area_measurement_type,
    'Runoff area 1 absolute' => subcatchment.area_absolute_1,
    'Runoff area 2 absolute' => subcatchment.area_absolute_2,
    'Runoff area 3 absolute' => subcatchment.area_absolute_3,
    'Runoff area 4 absolute' => subcatchment.area_absolute_4,
    'Runoff area 5 absolute' => subcatchment.area_absolute_5,
    'Runoff area 6 absolute' => subcatchment.area_absolute_6,
    'Runoff area 7 absolute' => subcatchment.area_absolute_7,
    'Runoff area 8 absolute' => subcatchment.area_absolute_8,
    'Runoff area 9 absolute' => subcatchment.area_absolute_9,
    'Runoff area 10 absolute' => subcatchment.area_absolute_10,
    'Runoff area 11 absolute' => subcatchment.area_absolute_11,
    'Runoff area 12 absolute' => subcatchment.area_absolute_12,
    'Runoff area 1 (%)' => subcatchment.area_percent_1,
    'Runoff area 2 (%)' => subcatchment.area_percent_2,
    'Runoff area 3 (%)' => subcatchment.area_percent_3,
    'Runoff area 4 (%)' => subcatchment.area_percent_4,
    'Runoff area 5 (%)' => subcatchment.area_percent_5,
    'Runoff area 6 (%)' => subcatchment.area_percent_6,
    'Runoff area 7 (%)' => subcatchment.area_percent_7,
    'Runoff area 8 (%)' => subcatchment.area_percent_8,
    'Runoff area 9 (%)' => subcatchment.area_percent_9,
    'Runoff area 10 (%)' => subcatchment.area_percent_10,
    'Runoff area 11 (%)' => subcatchment.area_percent_11,
    'Runoff area 12 (%)' => subcatchment.area_percent_12
  }
end

puts subcatchment_variables.first.keys.each_with_index.map { |key, index| 
key = key.gsub('Runoff ', '').gsub('absolute', '').gsub('area', 'A')
  if index < 1
    key[0, 20].ljust(20)
  else
    key[0, 8].ljust(8)
  end
}.join(", ")

subcatchment_variables.each do |variables|
  row = variables.values.each_with_index.map { |value, index| 
    if index < 1
      value.to_s[0, 20].ljust(20)
    else
      value.to_s[0, 8].ljust(8)
    end
  }.join(", ")
  puts row
end