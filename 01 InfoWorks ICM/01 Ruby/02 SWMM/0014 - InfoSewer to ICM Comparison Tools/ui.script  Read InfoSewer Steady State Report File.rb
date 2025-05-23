require 'pathname' # Retained Pathname in case WSApplication uses/needs it implicitly, though not directly used.

# Get the current network object
# cn = WSApplication.current_network # This line requires the WSApplication environment

# Prompt the user to select a file and options
result = WSApplication.prompt "Reading the InfoSewer Steady State RPT File",
[
  ['RPT File', 'String', nil, nil, 'FILE', true, '*.*', 'rpt', false],
  ['[Summary]', 'Boolean', true], # result[1]
  ['[Loading Manholes]', 'Boolean', true], # result[2]
  ['[Pipes]', 'Boolean', true], # result[3]
  ['[Force Mains]', 'Boolean', true], # result[4]
  ['[Pumps]', 'Boolean', true] # result[5]
], false

# Exit if dialog was cancelled
unless result
  puts "User cancelled the dialog."
  return
end

file_path = result[0]
puts "Selected RPT File: #{file_path}"

# Check if file path is given
unless file_path && !file_path.empty?
  puts "No file path provided."
  return
end

# Check if file exists
unless File.exist?(file_path)
  puts "File does not exist: #{file_path}. Please provide a valid file path."
  return
end

# Store user choices for which sections to process
process_section_flags = {
  'Summary'          => result[1],
  'Loading Manholes' => result[2],
  'Pipes'            => result[3],
  'Force Mains'      => result[4],
  'Pumps'            => result[5]
}

sections = {}
current_section_name = nil
line_counter = 0

# Define headers for each section. Ensure these match the columns in your RPT file
# AFTER any initial columns are skipped (like ID and other specific shifts).
loading_manhole_headers = ['Base', 'Storm', 'Total']
pumps_headers = ['Pump Count', 'Pump Flow', 'Pump Head'] # After ID and 3 skipped columns
force_mains_headers = ['Pipe Diam', 'Pipe Flow', 'Pipe Vel.', 'Pipe Loss'] # After ID and 2 skipped columns
# Corrected pipe_headers with unique names for previously duplicated entries.
# Verify these against your RPT file structure. These are for columns AFTER ID and 2 skipped columns.
pipe_headers = [
  'Pipe Count', 'Pipe Slope', 'Pipe Diam', 'Pipe Flow 1', 'Pipe Load',
  'Pipe Flow 2', 'Pipe Flow 3', 'Pipe Flow 4', 'Pipe Flow 5', 'Pipe Veloc',
  'Pipe d/D', 'Pipe Depth 1', 'Pipe Number', 'Pipe Depth 2', 'Pipe Flow 6',
  'Cover Count'
]
# summary_headers would be needed if you wanted to process the 'Summary' section statistically.
# summary_headers = ['Summary Metric 1', 'Summary Metric 2'] # Example

File.readlines(file_path).each do |line|
  # Specific data cleaning for a known pattern that can break tokenization.
  line = line.gsub('Exponential 3-Point', 'Exponential3-Point') if line.include?('Exponential 3-Point')
  # puts line # Original line for debugging, uncomment if needed

  line.strip!
  next if line.empty? # Skip blank lines

  if line.start_with?('[') && line.end_with?(']')
    potential_section_name = line[1..-2]
    # Check if this section is selected for processing by the user
    if process_section_flags[potential_section_name]
      current_section_name = potential_section_name
      sections[current_section_name] = {}
    # Also parse 'Title' section if present, even if not in flags (it's skipped in output stats later)
    elsif potential_section_name == 'Title'
        current_section_name = potential_section_name
        sections[current_section_name] = {}
    else
      current_section_name = nil # This section is not selected for processing
    end
    line_counter = 0 # Reset line counter for the new section
  elsif current_section_name && sections.key?(current_section_name) && line_counter >= 3
    # Proceed only if current_section_name is active (selected) and we are past header lines
    
    tokens = line.split
    next if tokens.empty? # Should not happen if line.strip! was not empty, but good practice

    id = tokens.shift
    next unless id # Ensure there's an ID

    # Perform section-specific token shifts (discarding initial data columns after ID)
    # These shifts should correspond to data columns *before* those defined in header arrays.
    case current_section_name
    when 'Pipes'
      2.times { tokens.shift if !tokens.empty? }
    when 'Force Mains'
      2.times { tokens.shift if !tokens.empty? }
    when 'Pumps'
      3.times { tokens.shift if !tokens.empty? }
    end

    # Convert remaining tokens to floats, or nil if conversion fails
    numerical_values = tokens.map do |token|
      begin
        Float(token)
      rescue ArgumentError
        nil # Store nil for non-numeric values
      end
    end
    sections[current_section_name][id] = numerical_values
  end
  line_counter += 1 if current_section_name # Only increment if we are potentially inside a section block
end

puts "\n--- Statistical Summary ---"
sections.each do |section_name, ids_data|
  # Skip sections not intended for this type of statistical analysis,
  # or sections the user didn't select (they wouldn't have data rows in ids_data if not selected and parsed).
  if ['Title', 'Summary'].include?(section_name)
      # Note: 'Summary' is skipped here. If you want to process stats for the 'Summary' section
      # (and process_section_flags['Summary'] was true), you'd need to define summary_headers
      # and remove 'Summary' from this skip list.
      next
  end

  # Further check if the section was actually selected for processing and has data
  unless process_section_flags.fetch(section_name, false) && !ids_data.empty?
      next
  end

  puts "\nSection: #{section_name}"
  
  section_specific_headers = case section_name
                             when 'Loading Manholes' then loading_manhole_headers
                             when 'Pumps'            then pumps_headers
                             when 'Force Mains'      then force_mains_headers
                             when 'Pipes'            then pipe_headers
                             # when 'Summary' then summary_headers # If Summary stats were desired
                             else
                               nil
                             end

  unless section_specific_headers
    puts "  Warning: No headers defined for section '#{section_name}'. Skipping statistical analysis for it."
    next
  end

  section_specific_headers.each_with_index do |header, index|
    # Extract all values for the current column (header index), compacting nils from conversion failures or short rows
    all_numeric_tokens_for_column = ids_data.values.map do |row_values|
      row_values[index] if row_values && row_values.size > index && !row_values[index].nil?
    end.compact

    mean_val, max_val, min_val = 0.0, 0.0, 0.0 # Default to float
    count_val = all_numeric_tokens_for_column.size

    if count_val > 0
      mean_val = all_numeric_tokens_for_column.sum / count_val.to_f # Ensure float division
      max_val = all_numeric_tokens_for_column.max
      min_val = all_numeric_tokens_for_column.min
    else
      # Keep default 0.0 or set to "N/A" if preferred for display
      # mean_val, max_val, min_val = "N/A", "N/A", "N/A"
    end
    
    printf "  %-20s | Mean: %-15.3f | Max: %-15.3f | Min: %-15.3f | Count: %-10d\n",
           header, mean_val, max_val, min_val, count_val
  end
end

# CSV Output Section for Manholes
puts "\n--- CSV Output: Loading Manholes ---"
if process_section_flags['Loading Manholes'] && sections['Loading Manholes'] && !sections['Loading Manholes'].empty?
  # Print CSV header
  puts "ID,Base,Storm,Total"
  
  # Print each manhole's data
  sections['Loading Manholes'].each do |id, values|
    # Ensure we have enough values, pad with 0.0 if needed
    base_load = values[0] || 0.0
    storm_load = values[1] || 0.0
    total_load = values[2] || 0.0
    
    puts "#{id},#{base_load},#{storm_load},#{total_load}"
  end
else
  puts "No Loading Manholes data to display"
end

# CSV Output Section for Links (Pipes, Force Mains, Pumps)
puts "\n--- CSV Output: Links (Pipes, Force Mains, Pumps) ---"

# Combine all link types
link_data = []

# Add Pipes
if process_section_flags['Pipes'] && sections['Pipes'] && !sections['Pipes'].empty?
  sections['Pipes'].each do |id, values|
    link_data << {
      id: id,
      type: 'Pipe',
      diameter: values[2] || 0.0,
      flow: values[3] || 0.0,
      velocity: values[9] || 0.0,
      depth_ratio: values[10] || 0.0
    }
  end
end

# Add Force Mains
if process_section_flags['Force Mains'] && sections['Force Mains'] && !sections['Force Mains'].empty?
  sections['Force Mains'].each do |id, values|
    link_data << {
      id: id,
      type: 'Force Main',
      diameter: values[0] || 0.0,
      flow: values[1] || 0.0,
      velocity: values[2] || 0.0,
      depth_ratio: 1.0  # Force mains are always full
    }
  end
end

# Add Pumps
if process_section_flags['Pumps'] && sections['Pumps'] && !sections['Pumps'].empty?
  sections['Pumps'].each do |id, values|
    link_data << {
      id: id,
      type: 'Pump',
      diameter: 0.0,  # Pumps don't have diameter
      flow: values[1] || 0.0,
      velocity: 0.0,  # Pumps don't have velocity in the traditional sense
      depth_ratio: 0.0  # Not applicable for pumps
    }
  end
end

# Print CSV for links
if link_data.any?
  puts "ID,Type,Diameter,Flow,Velocity,Depth_Ratio"
  link_data.each do |link|
    puts "#{link[:id]},#{link[:type]},#{link[:diameter]},#{link[:flow]},#{link[:velocity]},#{link[:depth_ratio]}"
  end
else
  puts "No link data to display"
end

puts "\nProcessing complete."