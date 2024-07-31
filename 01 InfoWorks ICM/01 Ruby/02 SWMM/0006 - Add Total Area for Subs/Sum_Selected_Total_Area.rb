def calculate_total_area
  net = WSApplication.current_network
  total_area = 0

  net.row_object_collection('hw_subcatchment').each do |s|
    total_area += s.total_area if s.selected?
  end

  puts "Total Area: #{total_area}"
  if total_area == 0
    puts "Either you selected no subcatchments or you have no subcatchments with a non-zero area."
  end
end

# Call the method to calculate and print the total area
calculate_total_area
puts 'Thank you for using Ruby in ICM InfoWorks'

net=WSApplication.current_network
manholes=net.row   objects ('hw_subcatchment')
puts 'Number of Total Subs',manholes.length

