net = WSApplication.current_network

# Ask the user for the number of copies they want to create
number_of_copies = 5

# Loops through all subcatchment objects
net.row_objects('sw_subcatchment').each do |subcatchment|
    
    # Check if the catchment is selected
    if subcatchment.selected?
        
        # Loop as per the number of copies
        (1..number_of_copies).each do |copy_number|
            
            # Start a 'transaction'
            net.transaction_begin
            
            # Create a new subcatchment object
            new_object = net.new_row_object('sw_subcatchment')
            
            # Name it with '_copy_<number>' suffix
            new_object['subcatchment_id'] = "#{subcatchment['subcatchment_id']}_c_#{copy_number}"
            
            # Loop through each column
            new_object.table_info.fields.each do |field|
                
                # Copy across the field value if it's not the subcatchment name
                if field.name != 'subcatchment_id'
                    new_object[field.name] = subcatchment[field.name]
                end
            end
                       
            # Write changes
            new_object.write
            
            # End the 'transaction'
            net.transaction_commit
        end
    end
end
