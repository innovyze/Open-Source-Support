# Access the current open network in the application
cn = WSApplication.current_network

# Ensure a network is open
unless cn
  raise 'No network is currently open. Please open a network and try again.'
end

# Define constants for object types
OBJECT_TYPES = {
  'Nodes' => 'hw_node',
  'Links' => 'hw_conduit',
  'Subcatchments' => 'hw_subcatchment',
  'Land Uses' => 'hw_land_use',
  'Runoff Surfaces' => 'hw_runoff_surface',
  'SuDS Controls' => 'hw_suds_control'
}

# Dynamically get the count of each object type in the network
object_counts = OBJECT_TYPES.transform_values { |type| cn.row_objects(type).size }

# Define the layout for the prompt
layout = [
  ['ICM InfoWorks Version', 'READONLY', WSApplication.version],
  *object_counts.map { |name, count| ["Number of #{name} in the Network", 'NUMBER', count] },
  ['Description of the Network', 'STRING', 'Urban drainage system'],
  ['Include Rainfall Data', 'BOOLEAN', true],
  ['Include Infiltration Data', 'BOOLEAN', false]
]

# Display the prompt and get user input
begin
  user_input = WSApplication.prompt('ICM InfoWorks Network Information', layout, true)
rescue StandardError => e
  puts "An error occurred while displaying the prompt: #{e.message}"
  exit
end

# Output the user input
puts "User Input: #{user_input}"