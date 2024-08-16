net = WSApplication.current_network

# Ask the user for the list of suffixes they want to use
suffixes = ["Horton", "GreenAmpt", "Constant"] # Change this to the list of your suffixes

# Initialize counters
original_selected_count = 0
new_subcatchments_added = 0

# Loops through all subcatchment objects
net.row_objects('hw_subcatchment').each do |subcatchment|
    
    # Check if the catchment is selected
    if subcatchment.selected?
        
        # Increment the counter for original selected subcatchments
        original_selected_count += 1
        
        # Loop through the list of suffixes
        suffixes.each do |suffix|
            
            # Start a 'transaction'
            net.transaction_begin
            
            # Create a new subcatchment object
            new_object = net.new_row_object('hw_subcatchment')
            
            # Name it with '_<suffix>' suffix
            new_object['subcatchment_id'] = "#{subcatchment['subcatchment_id']}_#{suffix}"
            
            # Loop through each column
            new_object.table_info.fields.each do |field|
                
                # Copy across the field value if it's not the subcatchment name
                if field.name != 'subcatchment_id'
                    new_object[field.name] = subcatchment[field.name]
                end
            end
            
            # Increment the counter for new subcatchments added
            new_subcatchments_added += 1
            
            # Write changes
            new_object.write
            
            # End the 'transaction'
            net.transaction_commit
        end
    end
end

# Output the count of original selected subcatchments and new subcatchments added
puts "Number of original selected subcatchments: #{original_selected_count}"
puts "Number of new subcatchments added: #{new_subcatchments_added}"
