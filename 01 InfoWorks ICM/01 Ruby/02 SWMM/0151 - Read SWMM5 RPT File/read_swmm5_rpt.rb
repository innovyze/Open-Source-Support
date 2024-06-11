require 'csv'
require 'pathname'

def select_file
  # Get the current network object
  cn = WSApplication.current_network

  # Prompt the user to select a file
  result = WSApplication.prompt "InfoSWMM, SWMM5 or ICM SWMM RPT file",
  [
    ['RPT File', 'String', nil, nil, 'FILE', true, '*.*', 'rpt', false]
  ], false
  file_path = result[0]
  puts file_path

  # Check if file path is given
  return unless file_path

  # Check if file exists
  unless File.exist?(file_path)
    puts "File does not exist. Please provide a valid file path."
    return
  end

  # Start a transaction
  cn.transaction_begin

  # Initialize an empty hash to store lines from the file
  lines_hash = {}

  # Create a hash of row objects by id for efficient lookup
  ro_hash = {}
  cn.row_objects('sw_conduit').each do |ro|
    ro_hash[ro.id] = ro
  end
    
  # Initialize a new hash to store lines that start with "Cross Section Summary"

    raingage_summary_lines = {}
    subcatchment_summary_lines = {}
    node_summary_lines = {}
    link_summary_lines = {}
    cross_section_summary_lines = {}
    link_flow_summary_lines = {}
    flow_classification_summary_lines = {}
    routing_time_step_summary_lines = {}
    subcatchment_runoff_summary_lines = {}
    node_depth_summary_lines = {}
    node_inflow_summary_lines = {}
    node_surcharge_summary_lines = {}
    node_flooding_summary_lines = {}
    storage_volume_summary_lines = {}
    outfall_loading_summary_lines = {}
    conduit_surcharge_summary_lines = {}
    pumping_summary_lines = {}

  # Read the file line by line
  File.readlines(file_path).each_with_index do |line, index|
    # Store each line in the hash with the line number as the key
    lines_hash[index] = line.strip
  end

  # Print the first 99 characters of each line in the hash
  lines_hash.each do |index, line|
    puts line.slice(0, 99)
  end

  lines_hash.each do |index, line|
    # Check if the line starts with "Cross Section Summary"
    if line.start_with?("Cross Section Summary")
      # Skip the next 5 lines
      start_index = index + 5

      # Process the next lines
      while start_index < lines_hash.size
        # Get the line
        line = lines_hash[start_index]
    
        # Split the line into tokens
        tokens = line.split
    
        # If no tokens are found, stop processing the hash
        break if tokens.empty?
    
        # Extract the 1, 3, 4, 5, 6, and 8 tokens
        extracted_tokens = [tokens[0],  tokens[1], tokens[2], tokens[3], tokens[4], tokens[5],  tokens[6], tokens[7]]
    
        # Store the extracted tokens in the new hash
        cross_section_summary_lines[start_index] = extracted_tokens
    
        # Move to the next line
        start_index += 1

        # Get the row object with the id from the first token
        ro = ro_hash[extracted_tokens[0]]
        if ro
          # Set the user_number properties and write the row object
          ro.user_number_1 = extracted_tokens[2].to_f  # convert to float Full depth
          ro.user_number_2 = extracted_tokens[7].to_f  # convert to float QFull
          ro.user_number_8 = extracted_tokens[3] # AREA Full
          ro.user_number_9 = extracted_tokens[4] # HRAD Full
          ro.write
        end
      end
      # Stop processing the hash after the first "Cross Section Summary" section
      break
    end
  end
  ##############################################################################


  lines_hash.each do |index, line|
    # Check if the line starts with "Link Summary"
    if line.start_with?("Link Summary")
      # Skip the next 4 lines
      start_index = index + 4

      # Process the next lines
      while start_index < lines_hash.size
        # Get the line
        line = lines_hash[start_index]
    
        # Split the line into tokens
        tokens = line.split
    
        # If no tokens are found, stop processing the hash
        break if tokens.empty?
    
        # Extract the 1, 3, 4, 5, 6, and 8 tokens
        extracted_tokens = [tokens[0],  tokens[1], tokens[2], tokens[3], tokens[4], tokens[5]]
    
        # Store the extracted tokens in the new hash
        link_summary_lines[start_index] = extracted_tokens
    
        # Move to the next line
        start_index += 1

        # Get the row object with the id from the first token
        ro = ro_hash[extracted_tokens[0]]
        if ro
          # Set the user_number properties and write the row object
          ro.user_number_3 = extracted_tokens[5].to_f  # slope peercent
          ro.write
        end
      end
      # Stop processing the hash after the first "Link Summary" section
      break
    end
  end
##############################################################################

lines_hash.each do |index, line|
    # Check if the line starts with "Link Flow Summary"
    if line.start_with?("Link Flow Summary")
      # Skip the next 8 lines
      start_index = index + 8

      # Process the next lines
      while start_index < lines_hash.size
        # Get the line
        line = lines_hash[start_index]
    
        # Split the line into tokens
        tokens = line.split
    
        # If no tokens are found, stop processing the hash
        break if tokens.empty?
                                                               
        # Extract the 1, 3, 4, 5, 6, and 8 tokens
        extracted_tokens = [tokens[0],  tokens[1], tokens[2], tokens[3], tokens[4], tokens[5],  tokens[6], tokens[7],  tokens[8], 
        tokens[9],  tokens[10], tokens[11], tokens[12]]
    
        # Store the extracted tokens in the new hash
        link_flow_summary_lines[start_index] = extracted_tokens
    
        # Move to the next line
        start_index += 1

        # Get the row object with the id from the first token
        ro = ro_hash[extracted_tokens[0]]
        if ro
          # Set the user_number properties and write the row object
          ro.user_number_4 = extracted_tokens[2].to_f   
          ro.user_text_1 = extracted_tokens[3].to_s + "   " + extracted_tokens[4].to_s 
          if extracted_tokens[9] == '>50.00'
             extracted_tokens[9] = '50.00'
          end
          ro.user_number_5 = extracted_tokens[9].to_f  
          ro.user_number_6 = extracted_tokens[8].to_f   
          ro.user_number_7 = extracted_tokens[12].to_f   
          ro.write
        end
      end
      # Stop processing the hash after the first Link Flow Summary" section
      break
    end
  end
##############################################################################

lines_hash.each do |index, line|
    # Check if the line starts with "Conduit Surcharge Summary"
    if line.start_with?("Conduit Surcharge Summary")
      # Skip the next 8 lines
      start_index = index + 8

      # Process the next lines
      while start_index < lines_hash.size
        # Get the line
        line = lines_hash[start_index]
    
        # Split the line into tokens
        tokens = line.split
    
        # If no tokens are found, stop processing the hash
        break if tokens.empty?
    
        # Extract the 1, 3, 4, 5, 6, and 8 tokens
        extracted_tokens = [tokens[0], tokens[1], tokens[2], tokens[3], tokens[4], tokens[5]]
    
        # Store the extracted tokens in the new hash
        conduit_surcharge_summary_lines[start_index] = extracted_tokens
    
        # Move to the next line
        start_index += 1

        # Get the row object with the id from the first token
        ro = ro_hash[extracted_tokens[0]]
        if ro
          # Set the user_number properties and write the row object
          ro.user_text_2 = extracted_tokens[1].to_s
          ro.user_text_3 = extracted_tokens[2].to_s
          ro.user_text_4 = extracted_tokens[3].to_s
          ro.user_text_5 = extracted_tokens[4].to_s
          ro.user_text_6 = extracted_tokens[5].to_s
          ro.write
        end
      end
      # Stop processing the hash after the first "Conduit Surcharge Summary" section
      break
    end
  end

  #############################################################################

lines_hash.each do |index, line|
    # Check if the line starts with "Flow Classification Summary"
    if line.start_with?("Flow Classification Summary")
      # Skip the next 8 lines
      start_index = index + 8

      # Process the next lines
      while start_index < lines_hash.size
        # Get the line
        line = lines_hash[start_index]
    
        # Split the line into tokens
        tokens = line.split
    
        # If no tokens are found, stop processing the hash
        break if tokens.empty?
    
        # Extract the 1, 3, 4, 5, 6, and 8 tokens
        extracted_tokens = [tokens[0], tokens[1], tokens[2], tokens[3], tokens[4], tokens[5], tokens[6], tokens[7], tokens[8], tokens[9]]
    
        # Store the extracted tokens in the new hash
        flow_classification_summary_lines[start_index] = extracted_tokens
    
        # Move to the next line
        start_index += 1

        # Get the row object with the id from the first token
        ro = ro_hash[extracted_tokens[0]]
        if ro
          # Set the user_number properties and write the row object
          ro.user_number_10 = extracted_tokens[1]
          ro.user_text_7 = extracted_tokens[2].to_s
          ro.user_text_8 = extracted_tokens[5].to_s
          ro.user_text_9 = extracted_tokens[6].to_s
          ro.user_text_10 = extracted_tokens[9].to_s
          ro.write
        end
      end
      # Stop processing the hash after the first "Flow Classification Summary" section
      break
    end
  end
##############################################################################

    link_summary_lines.each do |index, tokens|
    puts "link_summary #{index}: #{tokens.join(' ')}"
    end
    cross_section_summary_lines.each do |index, tokens|
    puts "cross_section_summary #{index}: #{tokens.join(' ')}"
    end
    link_flow_summary_lines.each do |index, tokens|
    puts "link_flow_summary_lines #{index}: #{tokens.join(' ')}"
    end
    conduit_surcharge_summary_lines.each do |index, tokens|
    puts "conduit_surcharge_summary #{index}: #{tokens.join(' ')}"
    end
    flow_classification_summary_lines.each do |index, tokens|
    puts "flow_classification_summary_lines #{index}: #{tokens.join(' ')}"
    end

    # Filter the lines to only include those that contain the word "Summary"
    summary_lines = lines_hash.select { |index, line| line.include?("Summary") }
    puts ""
    puts "Summary Lines: #{summary_lines.size}"
    # Print the first 80 characters of each line in the new hash
    summary_lines.each do |index, line|
        puts line.slice(0, 99)
    end  # End of Filter for Summary Lines

    # Commit the transaction
    cn.transaction_commit
    puts "Script finished successfully."
    end 
##############################################################################

# Call the select_file method
select_file

