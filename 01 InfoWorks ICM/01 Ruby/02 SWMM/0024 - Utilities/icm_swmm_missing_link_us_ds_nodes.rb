# Ruby script to find upstream and downstream nodes for all selected links in the current ICM SWMM network
# Run this within InfoWorks ICM's Ruby scripting environment

# Access the current network in InfoWorks ICM
network = WSApplication.current_network

# Check if a network is loaded
if network.nil?
  puts "Error: No current network loaded in InfoWorks ICM."
  exit
end

# Class to handle SWMM network analysis
class SwmmNetworkAnalyzer
  def initialize(network)
    @network = network
    @nodes = {}
    @links = {}
    load_network_data
  end

  # Load node and link data from the current network
  def load_network_data
    # Get all nodes (e.g., junctions, storage, outfalls)
    @network.row_objects('_nodes').each do |node|
      @nodes[node.id] = { x: node.x, y: node.y }
    end

    # Get all conduits/links
    @network.row_objects('sw_conduit').each do |link|
      @links[link.id] = { from_node: link.us_node_id, to_node: link.ds_node_id }
    end
  end

  # Find upstream and downstream nodes for a given link
  def find_nodes_for_link(link_id)
    return { error: "Link '#{link_id}' not found" } unless @links.key?(link_id)

    link = @links[link_id]
    from_node = link[:from_node]
    to_node = link[:to_node]

    result = { link_id: link_id, upstream: from_node, downstream: to_node }

    # Check if nodes exist in the nodes hash
    result[:upstream_missing] = true unless @nodes.key?(from_node)
    result[:downstream_missing] = true unless @nodes.key?(to_node)

    # If a node is missing, try to infer it
    if result[:upstream_missing] || result[:downstream_missing]
      infer_missing_nodes(link_id, result)
    end

    result
  end

  private

  # Infer missing nodes by examining other links
  def infer_missing_nodes(link_id, result)
    @links.each do |other_link_id, other_link|
      next if other_link_id == link_id

      # If downstream node is missing, check if it appears as an upstream node elsewhere
      if result[:downstream_missing] && other_link[:from_node] == result[:downstream]
        result[:downstream] = other_link[:to_node]
        result[:downstream_inferred] = true
      end

      # If upstream node is missing, check if it appears as a downstream node elsewhere
      if result[:upstream_missing] && other_link[:to_node] == result[:upstream]
        result[:upstream] = other_link[:from_node]
        result[:upstream_inferred] = true
      end
    end
  end
end

# New method: Analyze all selected links
def analyze_selected_links
  analyzer = SwmmNetworkAnalyzer.new(WSApplication.current_network)
  WSApplication.current_network.each_selected do |sel|
    result = analyzer.find_nodes_for_link(sel.id)
    # Skip printing if the link is not found (error present)
    next if result[:error]
    puts "Analysis for Link: #{sel.id}"
    puts "Upstream Node: #{result[:upstream]}#{result[:upstream_inferred] ? ' (inferred)' : ''}"
    puts "Downstream Node: #{result[:downstream]}#{result[:downstream_inferred] ? ' (inferred)' : ''}"
    puts "Upstream Missing: #{result[:upstream_missing] || false}"
    puts "Downstream Missing: #{result[:downstream_missing] || false}"
    puts "-----------------------"
  end
end

# Main Execution: Analyze all selected links
analyze_selected_links