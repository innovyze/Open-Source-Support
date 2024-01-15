require_relative 'spatial'

DEFAULT_DISTANCE = 1.5
distance = DEFAULT_DISTANCE

# Prompt user for distance
# distance = WSApplication.input_box("Specify a distance", "Split Links Around Nodes", DEFAULT_DISTANCE.to_s)
# distance = distance.to_f

network = WSApplication.current_network()
network.transaction_begin

network.row_objects_selection('_nodes').each do |node|
  InnoSpatial.split_links_around_node(network, node, distance)
end

network.transaction_commit
