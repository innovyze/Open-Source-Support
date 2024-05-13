# Initialize the current network
cn = WSApplication.current_network

# Clear any existing selection
cn.clear_selection

# Initialize an array to store subcatchment areas
subcatchment_areas = []

# Loop through each subcatchment in the network
cn.row_objects('hw_subcatchment').each do |ro|
  # Add the total area of the subcatchment to the array if it exists
  subcatchment_areas << ro.total_area if ro.total_area
end

# Calculate the threshold area for the lowest ten percent
# This is done by adding 10% of the range of areas to the minimum area
threshold_area = subcatchment_areas.min + (subcatchment_areas.max - subcatchment_areas.min) * 0.1

# Calculate the median area (50th percentile)
# This is done by sorting the areas and selecting the middle one
sorted_areas = subcatchment_areas.sort
median_area = sorted_areas[sorted_areas.length / 2]

# Initialize an array to store the selected subcatchments
selected_subcatchments = []

# Loop through each subcatchment in the network again
cn.row_objects('hw_subcatchment').each do |ro|
  # If the total area of the subcatchment is below the threshold or median, select it
  if ro.total_area && (ro.total_area < threshold_area || ro.total_area < median_area)
    ro.selected = true
    selected_subcatchments << ro
  end
end

# Calculate the total number of subcatchments
total_subcatchments = subcatchment_areas.length

# If any subcatchments were selected, print the statistics
if selected_subcatchments.any?
  puts "Subcatchment Parameter Statistics for ICM InfoWorks Network"
  printf("%44s: %10.2f\n", "Minimum subcatchment area", subcatchment_areas.min)
  printf("%44s: %10.2f\n", "Maximum subcatchment area", subcatchment_areas.max)
  printf("%44s: %10.2f\n", "Threshold area for lowest 10%", threshold_area)
  printf("%44s: %10.2f\n", "Median subcatchment area (50th percentile)", median_area)
  printf("%44s: %10d\n", "Number of subcatchments below threshold", selected_subcatchments.length)
  printf("%44s: %10d\n", "Total number of subcatchments", total_subcatchments)  
else
  puts "No subcatchments were selected."
end
#==================================================================
# Initialize the current network
bn = WSApplication.background_network

# Clear any existing selection
bn.clear_selection

# Initialize an array to store subcatchment areas
subcatchment_areas = []

# Loop through each subcatchment in the network
bn.row_objects('sw_subcatchment').each do |ro|
  # Add the total area of the subcatchment to the array if it exists
  subcatchment_areas << ro.area if ro.area
end

# Calculate the threshold area for the lowest ten percent
# This is done by adding 10% of the range of areas to the minimum area
threshold_area = subcatchment_areas.min + (subcatchment_areas.max - subcatchment_areas.min) * 0.1

# Calculate the median area (50th percentile)
# This is done by sorting the areas and selecting the middle one
sorted_areas = subcatchment_areas.sort
median_area = sorted_areas[sorted_areas.length / 2]

# Initialize an array to store the selected subcatchments
selected_subcatchments = []

# Loop through each subcatchment in the network again
bn.row_objects('sw_subcatchment').each do |ro|
  # If the total area of the subcatchment is below the threshold or median, select it
  if ro.area && (ro.area < threshold_area || ro.area < median_area)
    ro.selected = true
    selected_subcatchments << ro
  end
end

# Calculate the total number of subcatchments
total_subcatchments = subcatchment_areas.length

# If any subcatchments were selected, print the statistics
if selected_subcatchments.any?
  puts ""
  puts "Subcatchment Parameter Statistics for ICM SWMM Network"
  printf("%44s: %10.2f\n", "Minimum subcatchment area", subcatchment_areas.min)
  printf("%44s: %10.2f\n", "Maximum subcatchment area", subcatchment_areas.max)
  printf("%44s: %10.2f\n", "Threshold area for lowest 10%", threshold_area)
  printf("%44s: %10.2f\n", "Median subcatchment area (50th percentile)", median_area)
  printf("%44s: %10d\n", "Number of subcatchments below threshold", selected_subcatchments.length)
  printf("%44s: %10d\n", "Total number of subcatchments", total_subcatchments)  
else
  puts "No subcatchments were selected."
end
