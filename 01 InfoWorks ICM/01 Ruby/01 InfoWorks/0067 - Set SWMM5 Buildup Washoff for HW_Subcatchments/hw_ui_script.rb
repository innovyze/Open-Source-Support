# Accessing current network
cn = WSApplication.current_network
# If the current network is not found, raise an error
raise "Error: current network not found" if cn.nil?

# Begin a transaction. This allows multiple changes to be made as a single operation.
cn.transaction_begin

# Initialize a counter for the number of subcatchments processed
subcatchment_number = 0

# Iterate over each subcatchment in the current network
cn.row_object_collection('hw_subcatchment').each do |s|
  begin
    # Iterate over each SWMM coverage of the subcatchment
    puts "Subcatchment ID: #{s.subcatchment_id}"
    s.swmm_coverage.size=1
    s.swmm_coverage.each do |swmm5|
      # Set the land use of the SWMM coverage to "SWMM5_BW"
      swmm5.land_use = 'SWMM5_BW'
      # Set the area of the SWMM coverage to 100
      swmm5.area = 100
      # Write the changes to the subcatchment
      s.write
      # Increment the counter for the number of subcatchments processed
      subcatchment_number += 1
    end
  end
end

# Commit the transaction. This applies all the changes made since the transaction began.
cn.transaction_commit  

# Print the number of subcatchments whose IDs were changed
puts "Subcatchment IDs Changed", subcatchment_number