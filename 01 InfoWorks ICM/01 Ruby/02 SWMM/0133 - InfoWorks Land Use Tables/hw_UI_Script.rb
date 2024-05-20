# Initialize the current network
cn = WSApplication.current_network

# Initialize an array to store land use variables
land_use_variables = []

# Loop through each land use in the network
cn.row_objects('hw_land_use').each do |ro|
  # Add the land use variables to the array
  # Each land use is represented as a hash with keys corresponding to variable names and values corresponding to variable values
  land_use_variables << {
    'Land use ID' => ro.land_use_id,
    'Population density' => ro.population_density,
    'Wastewater profile' => ro.wastewater_profile,
    'Connectivity (%)' => ro.connectivity,
    'Pollution index' => ro.pollution_index,
    'Description' => ro.land_use_description,
    'Runoff surface 1' => ro.runoff_index_1,
    'Default area 1 (%)' => ro.p_area_1,
    'Runoff surface 2' => ro.runoff_index_2,
    'Default area 2 (%)' => ro.p_area_2,
    'Runoff surface 3' => ro.runoff_index_3,
    'Default area 3 (%)' => ro.p_area_3,
    'Runoff surface 4' => ro.runoff_index_4,
    'Default area 4 (%)' => ro.p_area_4,
    'Runoff surface 5' => ro.runoff_index_5,
    'Default area 5 (%)' => ro.p_area_5,
    'Runoff surface 6' => ro.runoff_index_6,
    'Default area 6 (%)' => ro.p_area_6,
    'Runoff surface 7' => ro.runoff_index_7,
    'Default area 7 (%)' => ro.p_area_7,
    'Runoff surface 8' => ro.runoff_index_8,
    'Default area 8 (%)' => ro.p_area_8,
    'Runoff surface 9' => ro.runoff_index_9,
    'Default area 9 (%)' => ro.p_area_9,
    'Runoff surface 10' => ro.runoff_index_10,
    'Default area 10 (%)' => ro.p_area_10,
    'Runoff surface 11' => ro.runoff_index_11,
    'Default area 11 (%)' => ro.p_area_11,
    'Runoff surface 12' => ro.runoff_index_12,
    'Default area 12 (%)' => ro.p_area_12
  }
end

# Print the column labels
# The labels are the keys of the first hash in the land_use_variables array
# Each label is left-justified and padded with spaces on the right to a total width of 20 characters, except for the sixth label which has a width of 40 characters
puts land_use_variables.first.keys.each_with_index.map { |key, index| index == 5 ? key[0, 40].ljust(40) : key[0, 20].ljust(20) }.join(", ")

# Print the land use variables
# For each hash in the land_use_variables array, the values are printed as a single row
# Each value is left-justified and padded with spaces on the right to a total width of 20 characters, except for the sixth value which has a width of 40 characters
land_use_variables.each do |variables|
  row = variables.values.each_with_index.map { |value, index| index == 5 ? value.to_s[0, 40].ljust(40) : value.to_s[0, 20].ljust(20) }.join(", ")
  puts row
end
