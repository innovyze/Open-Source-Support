def calculate_total_area
  net = WSApplication.current_network
  total_area = 0
  count = 0

  net.row_object_collection('hw_subcatchment').each do |s|
    if s.selected?
      total_area += s.total_area
      count += 1
    end
  end

  puts "Total Area: #{'%.3f' % total_area}"
  puts "Number of selected subcatchments: #{count}"
  if total_area == 0
    puts "Either you selected no subcatchments or you have no subcatchments with a non-zero area."
  end
end

# Call the method to calculate and print the total area
calculate_total_area
puts 'Thank you for using Ruby in ICM InfoWorks'