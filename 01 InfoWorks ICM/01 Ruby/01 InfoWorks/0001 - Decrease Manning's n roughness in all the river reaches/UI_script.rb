net=WSApplication.current_network
net.current_scenario='Roughness -20%'
puts net.current_scenario

net.clear_selection
net.transaction_begin
net.row_objects('hw_river_reach').each do |ro|
    ro.sections.each do |d|
        d.roughness_N = d.roughness_N * 0.8
    end
    ro.sections.write
    ro.write
end
net.transaction_commit

puts '2D Roughness has been decreased by 20%'
net.commit '2D Roughness has been decreased by 20%'
