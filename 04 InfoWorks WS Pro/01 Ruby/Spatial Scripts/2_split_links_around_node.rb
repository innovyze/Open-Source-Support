require_relative 'spatial'

distance = 1.5

# Prompt user for distance
# distance = WSApplication.input_box("Specify a distance", "Split Links Around Nodes", distance.to_s)&.to_f

network = WSApplication.current_network()
network.transaction_begin

network.row_objects_selection('_nodes').each do |node|
  AdskSpatial.split_links_around_node(network, node, distance)
end

network.transaction_commit
