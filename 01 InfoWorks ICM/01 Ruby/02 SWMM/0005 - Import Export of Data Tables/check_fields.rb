# Make sure 'cn' is your current network object, loaded correctly.
cn = WSApplication.current_network

if cn.nil?
    puts "ERROR: 'cn' (current network) is nil. Please ensure it's loaded."
    exit
  end
  
  puts "Starting inspection of 'sw_conduit' objects..."
  
  # Attempt to get the collection of SWMM conduit row objects
  begin
    conduits = cn.row_objects('sw_conduit')
  rescue => e
    puts "ERROR: Failed to retrieve 'sw_conduit' objects from 'cn'."
    puts "Details: #{e.class} - #{e.message}"
    puts "Ensure 'cn' is a valid network object and 'sw_conduit' is the correct table name."
    exit
  end
  
  if conduits.nil?
    puts "No 'sw_conduit' objects collection returned (collection is nil)."
  elsif conduits.empty?
    puts "No 'sw_conduit' objects found in the network (collection is empty)."
  else
    puts "Found #{conduits.size} 'sw_conduit' object(s)." # Use .size for collections that support it
    puts "--- Inspecting the FIRST 'sw_conduit' object in detail ---"
  
    pipe = conduits.first # Get the first object for detailed inspection
  
    # Try to get a common identifier for logging purposes
    pipe_identifier_str = "N/A"
    if pipe.respond_to?(:id) && pipe.id
      pipe_identifier_str = "ID: #{pipe.id}"
    elsif pipe.respond_to?(:asset_id) && pipe.asset_id
      pipe_identifier_str = "Asset ID: #{pipe.asset_id}"
    else
      pipe_identifier_str = "Object at index 0"
    end
    puts "Inspecting: #{pipe_identifier_str}"
  
    # 1. Check for the '.fields' method (common in some Innovyze APIs)
    puts "\nChecking for '.fields' method:"
    if pipe.respond_to?(:fields)
      begin
        fields_output = pipe.fields
        if fields_output.nil?
          puts "  pipe.fields executed, but returned nil."
        else
          puts "  pipe.fields output: #{fields_output.inspect}"
          # If fields_output is an array of strings, these are likely your direct field names
          if fields_output.is_a?(Array) && !fields_output.empty? && fields_output.all? { |f| f.is_a?(String) }
            puts "  SUCCESS: These look like field names! You can likely use them as symbols (e.g., :#{fields_output.first}) to access data."
          elsif fields_output.is_a?(Array) && fields_output.empty?
            puts "  pipe.fields returned an empty array."
          else
            puts "  The output of pipe.fields is not an array of strings. Its type is: #{fields_output.class}"
          end
        end
      rescue => e
        puts "  Error occurred while calling pipe.fields: #{e.class} - #{e.message}"
      end
    else
      puts "  This object does not respond to the '.fields' method."
    end
  
    # 2. List all available methods (attributes are often exposed as methods)
    # This is a more general way to find out how to interact with the object.
    puts "\nChecking for '.methods' (to list all capabilities, including attribute accessors):"
    if pipe.respond_to?(:methods)
      all_methods = pipe.methods.sort
      puts "  Object responds to '.methods'. Total methods available: #{all_methods.length}"
      puts "  Sample of available methods (potential attribute names):"
      # Show some potentially relevant methods by looking for common patterns
      sample_methods = all_methods.grep(/id|node|link|value|user|geom|shape|length|width|height|invert|flow|setting/)
      sample_methods = all_methods.first(20) if sample_methods.empty? # if no matches, show first 20
  
      if sample_methods.empty? && !all_methods.empty? # If grep found nothing, but methods exist.
          puts "    #{all_methods.take(30).join(', ')}..." # show first 30
      elsif !sample_methods.empty?
          puts "    #{sample_methods.take(30).join(', ')}..." # show up to 30 relevant or sample methods
      else
          puts "    No methods found to sample (this is unusual for an object)."
      end
      puts "  (Hint: Look through this list for names like :us_node_id, :conduit_length, :user_roughness, etc.)"
      puts "  (To see ALL methods, you would print `all_methods.inspect` but it's very long.)"
    else
      puts "  This object does not respond to '.methods' (this is highly unusual for Ruby objects)."
    end
  
    puts "\n--- End of inspection for the first conduit object ---"
  end
  
  puts "\nNext Steps:"
  puts "1. Carefully review the output above from '.fields' or the list of methods."
  puts "2. Identify the names that correspond to the SWMM parameters you need (e.g., 'us_node_id', 'conduit_length', 'geom1')."
  puts "3. In your main script's `FIELDS_TO_EXPORT` array, use these exact names as symbols (e.g., if you see 'conduit_length', use `:conduit_length`)."