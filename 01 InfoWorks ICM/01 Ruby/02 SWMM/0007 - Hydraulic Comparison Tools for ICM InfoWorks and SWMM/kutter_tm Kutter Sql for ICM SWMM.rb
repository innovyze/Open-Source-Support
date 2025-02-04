# Kutter's Formula Calculation in Ruby

# Access the current network
net = WSApplication.current_network

# Loop over all links in the network
net.row_objects('_links').each do |link|
  # Retrieve the necessary properties from the link
  conduit_height = link.conduit_height # Replace with actual method to get conduit height in inches
  gradient = link.gradient # Replace with actual method to get slope (ft/ft * 100)
  roughness_n = link.bottom_roughness_N # Replace with actual method to get Manning's n

  # Calculate capacities
  full_capacity = (((conduit_height/12)**2) * 0.78539)*((41.65+0.00281/(gradient/100)+1.811/roughness_n) /
                    (1+(41.65+0.00281/(gradient/100))*roughness_n/((conduit_height/48)**0.5)))*(((conduit_height/48)*gradient/100)**0.5)
  three_quarter_capacity = ((((conduit_height/12)**2) * 0.78539)-((conduit_height/24)**2)*((2.0944-Math.sin(2.0944))/2))*
                    ((41.65+0.00281/(gradient/100)+1.811/roughness_n)/(1+(41.65+0.00281/(gradient/100))*roughness_n/((conduit_height/39.78)**0.5)))*(((conduit_height/39.78)*gradient/100)**0.5)
  half_capacity = 0.5*full_capacity
  pfc = link.Capacity # Replace with actual method to get PFC

# Print the title line
puts "%-10s %-20s %-15s %-25s %-30s %-25s %-25s %-25s" % ['Link ID', 'Diameter (inches)', 'Slope (ft/ft)', "Manning's N Roughness", 'ICM Calculated Capacity (CFS)', "Kutter's Full Capacity (CFS)", "Kutter's 3/4 Capacity (CFS)", "Kutter's 1/2 Capacity (CFS)"]

# Output the results
puts "%-10s %-20.4f %-15.4f %-25.4f %-30.4f %-25.4f %-25.4f %-25.4f" % [link.id, conduit_height, gradient / 100.0, roughness_n, pfc, full_capacity, three_quarter_capacity, half_capacity]
end