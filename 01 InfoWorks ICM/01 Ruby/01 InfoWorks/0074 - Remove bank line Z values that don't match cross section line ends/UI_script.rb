net = WSApplication.current_network
net.transaction_begin

# Check if any bank lines are selected
selected_bank_lines = net.row_objects('hw_bank_survey').select(&:selected?)

if selected_bank_lines.empty?
  WSApplication.message_box('No bank lines are selected. Running on all bank lines...', 'OKCancel', 'Information',nil)
  bank_lines_to_process = net.row_objects('hw_bank_survey')
else
  bank_lines_to_process = selected_bank_lines
end

# Collect all bank line points into bank_points_blob
bank_points_blob = []
bank_lines_to_process.each do |bank_line|
  bank_line.bank_array.each do |coord|  # Assuming bank_array is the array containing X, Y, Z values
    bank_points_blob << { id: bank_line.id, x: coord['X'], y: coord['Y'], z: coord['Z'], bank_line: bank_line }
  end
end

# Collect all cross section line points into xs_points_blob
xs_points_blob = []
net.row_objects('hw_cross_section_survey').each do |xs_line|
  xs_line.section_array.each do |coord|  # Assuming section_array is the array containing X, Y values
    xs_points_blob << { x: coord['X'], y: coord['Y'] }
  end
end

# Check for matches and update z values
bank_points_blob.each do |bank_point|
  match_found = false

  xs_points_blob.each do |xs_point|
    if bank_point[:x] == xs_point[:x] && bank_point[:y] == xs_point[:y]
      match_found = true
      break
    end
  end

  # Set z value to zero if no match found
  unless match_found
    bank_line = bank_point[:bank_line]
    bank_line.bank_array.each do |coord|
      if coord['X'] == bank_point[:x] && coord['Y'] == bank_point[:y]
        coord['Z'] = ""
      end
    end
    bank_line.bank_array.write
    bank_line.write
  end
end

# Select all bank lines if none were selected initially
if selected_bank_lines.empty?
  net.row_objects('hw_bank_survey').each { |bank_line| bank_line.selected = true }
end

net.transaction_commit

# Display completion message
WSApplication.message_box('Bank line data cleaned. Only cross section end levels remain. Next step: Run the Model > Update from ground model... tool to populate missing values before building the River reaches.', 'OK', 'Information',nil)