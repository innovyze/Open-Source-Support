net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length
    link_lengths << ro.length
  end
end

link_lengths.sort!

percentiles = [10, 20, 30, 40, 50, 60, 70, 80, 90]
threshold_lengths = percentiles.map do |p|
  index = (p / 100.0 * (link_lengths.size - 1)).round
  link_lengths[index]
end

selected_links_length = Array.new(9) { [] }

ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length
    threshold_lengths.each_with_index do |threshold, i|
      if ro.length < threshold
        ro.selected = true
        selected_links_length[i] << ro
      end
    end
  end
end

total_length = link_lengths.sum
total_links = net.row_objects('sw_conduit').size

if selected_links_length.any? { |links| links.any? }
  printf("%-50s %12.2f\n", "Minimum link length", link_lengths.min)
  printf("%-50s %12.2f\n", "Maximum link length", link_lengths.max)
  percentiles.each_with_index do |p, i|
    printf("%-50s %12.2f\n", "Threshold length for lowest #{p}%", threshold_lengths[i])
    printf("%-50s %12d\n", "Number of links below #{p}% threshold", selected_links_length[i].length)
  end
  printf("%-50s %12.2f\n", "Total length of links", total_length)
  printf("%-50s %12d\n", "Total number of links", total_links)
else
  puts "No links were selected."
end