# Find the smallet 10 percent of pipes

net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('sw_conduit').each do |ro|
  link_lengths << ro.length if ro.length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.1

# Select the links whose length is below the threshold
selected_links = []
ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length && ro.length < threshold_length
    ro.selected = true
    selected_links << ro
  end
end
total_links = link_lengths.length

if selected_links.any?
  printf("%-40s %-0.2f\n", "Minimum link length", link_lengths.min)
  printf("%-40s %-0.2f\n", "Maximum link length", link_lengths.max)
  printf("%-40s %-0.2f\n", "Threshold length for lowest 10%", threshold_length)
  printf("%-40s %-d\n", "Number of links below threshold", selected_links.length)
  printf("%-40s %-d\n", "Total number of links", total_links)  
else
  puts "No links were selected."
end


