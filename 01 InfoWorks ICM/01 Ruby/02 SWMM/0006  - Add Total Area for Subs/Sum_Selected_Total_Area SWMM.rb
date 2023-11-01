def calculate_total_selected_subcatchment_area
  begin
    net = WSApplication.current_network
    total_area = 0

    net.transaction_begin
    net.row_object_collection('sw_subcatchment').each do |subcatchment|
      total_area += subcatchment.area if subcatchment.selected?
    end

    return total_area
  rescue StandardError => e
    puts "An error occurred: #{e.message}"
  end
end

def print_total_area
  total_area = calculate_total_selected_subcatchment_area
  puts "Total Area: #{total_area}"
  puts 'Thank you for using Ruby in ICM SWMM'

  manholes=net.row_objects('sw_subcatchment')
  puts 'Number of Total Subs',manholes.length


end

print_total_area

WSApplication.message_box(
'Thank you for using Ruby in ICM SWMM','YesNoCancel','?',false)
