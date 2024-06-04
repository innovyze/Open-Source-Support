require 'csv'
require 'pathname'

def select_file

result = WSApplication.prompt "InfoSWMM RPT file",
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

 # Process the file
  # Initialize an empty hash
  lines_hash = {}

  # Read the file line by line
  File.readlines(file_path).each_with_index do |line, index|
    # Store each line in the hash with the line number as the key
    lines_hash[index] = line.strip
  end

# Print the first 99 characters of each line in the hash
lines_hash.each do |index, line|
    puts line.slice(0, 99)
  end

# Process the hash to only include lines that contain the word "summary"
summary_lines = lines_hash.select { |index, line| line.include?("Summary") }

# Print the first 80 characters of each line in the new hash
summary_lines.each do |index, line|
  puts line.slice(0, 99)
end

# Initialize a new hash for lines that start with "Cross Section Summary"
cross_section_summary_lines = {}

# Process the hash
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
        extracted_tokens = [tokens[0], tokens[2], tokens[3], tokens[4], tokens[5], tokens[7]]
    
        # Store the extracted tokens in the new hash
        cross_section_summary_lines[start_index] = extracted_tokens
    
        # Move to the next line
        start_index += 1
    end

    # Stop processing the hash
    break
  end
end

# Print the new hash
cross_section_summary_lines.each do |index, tokens|
  puts "Line #{index}: #{tokens.join(' ')}"
end

end
select_file