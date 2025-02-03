# Find the smallest 10 percent of conduit heights and widths
net = WSApplication.current_network
net.clear_selection

conduit_heights = []
conduit_widths = []
ro = net.row_objects('hw_conduit').each do |ro|
  conduit_heights << ro.conduit_height if ro.conduit_height
  conduit_widths << ro.conduit_width if ro.conduit_width
end

# Calculate the threshold height and width for the lowest ten percent
threshold_height = conduit_heights.min + (conduit_heights.max - conduit_heights.min) * 0.1
threshold_width = conduit_widths.min + (conduit_widths.max - conduit_widths.min) * 0.1

# Calculate the median height and width (50th percentile)
sorted_heights = conduit_heights.sort
median_height = sorted_heights[sorted_heights.length / 2]
sorted_widths = conduit_widths.sort
median_width = sorted_widths[sorted_widths.length / 2]

# Select the conduits whose height or width is below the threshold or median
selected_conduits = []
ro = net.row_objects('hw_conduit').each do |ro|
  if (ro.conduit_height && (ro.conduit_height < threshold_height || ro.conduit_height < median_height)) ||
     (ro.conduit_width && (ro.conduit_width < threshold_width || ro.conduit_width < median_width))
    ro.selected = true
    selected_conduits << ro
  end
end

total_conduits = [conduit_heights.length, conduit_widths.length].max

if selected_conduits.any?
  printf("%-44s %-0.2f\n", "Minimum conduit height", conduit_heights.min)
  printf("%-44s %-0.2f\n", "Maximum conduit height", conduit_heights.max)
  printf("%-44s %-0.2f\n", "Threshold height for lowest 10%", threshold_height)
  printf("%-44s %-0.2f\n", "Median conduit height (50th percentile)", median_height)
  printf("%-44s %-0.2f\n", "Minimum conduit width", conduit_widths.min)
  printf("%-44s %-0.2f\n", "Maximum conduit width", conduit_widths.max)
  printf("%-44s %-0.2f\n", "Threshold width for lowest 10%", threshold_width)
  printf("%-44s %-0.2f\n", "Median conduit width (50th percentile)", median_width)
  printf("%-44s %-d\n", "Number of conduits below threshold", selected_conduits.length)
  printf("%-44s %-d\n", "Total number of conduits", total_conduits)  
else
  puts "No conduits were selected."
end
