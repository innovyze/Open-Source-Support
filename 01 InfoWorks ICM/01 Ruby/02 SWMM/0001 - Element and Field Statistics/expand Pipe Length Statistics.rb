# Find the smallest 1 percent of link lengths

net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('sw_conduit').each do |ro|
  link_lengths << ro.length if ro.length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.01

# Calculate the median length (50th percentile)
sorted_lengths = link_lengths.sort
median_length = sorted_lengths[sorted_lengths.length / 2]

# Select the links whose length is below the threshold or median length
selected_links = []
ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length && (ro.length < threshold_length || ro.length < median_length)
    ro.selected = true
    selected_links << ro
  end
end

total_links = link_lengths.length

if selected_links.any?
  puts("| ------------------------------------ | ------ |")
  puts("| Description                          | Value  |")
  puts("| ------------------------------------ | ------ |")
  puts("| Minimum link length                  | #{'%.2f' % link_lengths.min} |")
  puts("| Maximum link length                  | #{'%.2f' % link_lengths.max} |")
  puts("| Threshold length for lowest 1%       | #{'%.2f' % threshold_length} |")
  puts("| Median link length (50th percentile) | #{'%.2f' % median_length} |")
  puts("| Number of links below threshold      | #{selected_links.length} |")
  puts("| Total number of links                | #{total_links} |")
  puts("| ------------------------------------ | ------ |")
else
puts "No links were selected."
end


