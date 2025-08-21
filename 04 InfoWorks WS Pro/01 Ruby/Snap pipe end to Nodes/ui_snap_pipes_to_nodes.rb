# Search from the end point of any pipe without a valid node ID, and assign the nearest Node ID found within a prescribed search radius.

def set_node_id(network, link, direction, search_radius)
  node_id_key = direction == :upstream ? "us_node_id" : "ds_node_id"
  end_vertex = direction == :upstream ? link["bends"][0, 2] : link["bends"].last(2)

  radius = 0.1
  loop do
    break if radius > search_radius
    roc = network.search_at_point(end_vertex[0], end_vertex[1], radius, 'wn_node')
    
    if roc
      updated = false  # Variable to check if the node id was updated

      roc.each do |ro|
        unless ro.node_id == link["us_node_id"] || ro.node_id == link["ds_node_id"] # Ensure not snapping pipe to its other endpoint.
          puts "Setting link #{node_id_key} to #{ro.node_id}"
          link[node_id_key] = ro.node_id
          updated = true
          break
        end
      end

      break if updated  # If node id was updated, exit the outer loop
    end

    radius += 0.1 # Expand search radius
  end

  link.write
end

network = WSApplication.current_network()

search_radius = 2; # Enter maximum search range for snapping pipes.

valid_ids = []
network.row_objects("_nodes").each do |node|
	valid_ids << node.node_id
end

network.transaction_begin()

network.row_objects("_links").each do |link|

  if !valid_ids.include?(link.us_node_id)
    # upstream node ID does not match a valid Node
	set_node_id(network, link, :upstream, search_radius)
	
  elsif !valid_ids.include?(link.ds_node_id)
    # downstream node ID does not match a valid Node
	set_node_id(network, link, :downstream, search_radius)
	
  end
end

network.transaction_commit()
