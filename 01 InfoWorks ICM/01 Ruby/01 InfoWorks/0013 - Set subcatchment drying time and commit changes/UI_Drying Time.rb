# Access the currently open network in the application
cn= WSApplication.current_network

# Set drying_time = 1 for all subcatchments within hw_subcatchment table
cn.transaction_begin
cn.row_objects('hw_subcatchment').each do |ro|
    ro.drying_time = 1
    ro.write
end
cn.transaction_commit

# Commit that change to the database with a comment
cn.commit 'Drying time was set to 1 day for all subcatchments'

puts "Drying time was set to 1 day for all subcatchments. You are ready to update to latest and rerun simulations."