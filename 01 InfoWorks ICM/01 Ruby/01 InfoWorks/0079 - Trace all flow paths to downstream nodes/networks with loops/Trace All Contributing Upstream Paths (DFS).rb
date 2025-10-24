# Trace ALL contributing upstream paths to selected downstream node(s)
# 
# This script identifies the complete contributing upstream area by finding ALL possible 
# paths (not just shortest path) using Depth-First Search. Perfect for networks with 
# loops/bifurcations where multiple upstream flow routes converge at your selected point.
#
# How it works:
# 1. You select one or more downstream nodes (e.g., outfalls, monitoring points)
# 2. Script automatically finds all terminal upstream nodes (sources with no upstream links)
# 3. For each terminal→downstream pair, traces ALL paths downstream to your selected node
# 4. Combines all paths into ONE comprehensive selection list showing complete contributing area
#
# Instructions:
# 1. Select one or more downstream nodes (hold Ctrl to select multiple)
# 2. Run this script
# 3. Script finds all terminal upstream nodes automatically
# 4. Each selection list shows ALL nodes/links in the complete contributing upstream area
#
# Selection lists will be named: "AllPaths_<upstream_node_id>_to_<downstream_node_id>"
#
# Safety limits: max_depth=256 nodes, max_paths=16 paths per terminal-downstream pair

class AllPathsTracer
  def initialize
    @net = WSApplication.current_network
    @db = WSApplication.current_database
    @max_depth = 256  # Maximum path length to prevent infinite loops
    @max_paths = 16   # Maximum number of paths to find per terminal-downstream pair
  end

  # Find the Model Group for storing selection lists
  def get_parent_group
    current_network_object = @net.model_object
    parent_id = current_network_object.parent_id
    
    begin
      # Try to get parent as Model Group
      parent_object = @db.model_object_from_type_and_id('Model Group', parent_id)
    rescue
      # If that fails, parent is Model Network, get its parent
      parent_object = @db.model_object_from_type_and_id('Model Network', parent_id)
      parent_id = parent_object.parent_id
      parent_object = @db.model_object_from_type_and_id('Model Group', parent_id)
    end
    
    parent_object
  end

  # Find ALL paths between two nodes using Depth-First Search
  # Returns array of paths, where each path is an array of [node, link] pairs
  def find_all_paths(start_node, end_node)
    all_paths = []
    current_path = []
    visited_in_path = {}
    
    explore_paths(start_node, end_node, current_path, visited_in_path, all_paths, 0)
    
    all_paths
  end

  # Recursive DFS to explore all paths
  def explore_paths(node, end_node, current_path, visited, all_paths, depth)
    # Safety checks
    return if depth > @max_depth
    return if all_paths.size >= @max_paths
    return if visited.has_key?(node.id)  # Cycle detection
    
    # Mark node as visited in this path
    visited[node.id] = true
    current_path << { node: node, link: nil }
    
    # Check if we reached the destination
    if node.id == end_node.id
      # Found a complete path - save a copy
      all_paths << deep_copy_path(current_path)
    else
      # Continue exploring downstream links
      node.ds_links.each do |link|
        next if link.ds_node.nil?
        
        # Store the link for this step
        current_path[-1][:link] = link
        
        # Recursively explore
        explore_paths(link.ds_node, end_node, current_path, visited, all_paths, depth + 1)
      end
    end
    
    # Backtrack - remove this node from current path
    current_path.pop
    visited.delete(node.id)
  end

  # Deep copy a path
  def deep_copy_path(path)
    path.map { |step| { node: step[:node], link: step[:link] } }
  end

  # Select all nodes and links from multiple paths
  # Combines all paths into a single selection
  def select_all_paths(paths)
    return [0, 0] if paths.empty?
    
    nodes_set = {}
    links_set = {}
    
    # Collect all unique nodes and links from all paths
    paths.each do |path|
      path.each do |step|
        nodes_set[step[:node].id] = step[:node]
        if !step[:link].nil?
          links_set[step[:link].id] = step[:link]
        end
      end
    end
    
    # Select all collected nodes and links
    nodes_set.values.each { |node| node.selected = true }
    links_set.values.each { |link| link.selected = true }
    
    [nodes_set.size, links_set.size]
  end

  # Find all terminal upstream nodes (nodes with no upstream links)
  def find_terminal_upstream_nodes
    terminal_nodes = Array.new
    
    @net.row_objects('_nodes').each do |node|
      # Terminal node = has downstream links but no upstream links
      # Count links by iterating (WSRowObjectCollection doesn't have .size or .length)
      us_count = 0
      ds_count = 0
      
      node.us_links.each { us_count += 1 }
      node.ds_links.each { ds_count += 1 }
      
      if us_count == 0 && ds_count > 0
        terminal_nodes << node
      end
    end
    
    terminal_nodes
  end

  # Clean up temporary flags
  def cleanup_flags
    @net.row_objects('_nodes').each do |node|
      node._seen = false
      node._val = nil
      node._from = nil
      node._link = nil
    end
  end

  # Create unique selection list name
  def create_unique_name(group, base_name)
    list_name = base_name
    counter = 1
    
    # Build a set of existing names for O(1) lookup
    existing_names = {}
    group.children.each do |child|
      existing_names[child.name] = true
    end
    
    # Find unique name
    while existing_names.has_key?(list_name)
      list_name = "#{base_name}_#{counter}"
      counter += 1
    end
    
    list_name
  end

  # Main processing
  def process
    # Get selected downstream nodes
    downstream_nodes = @net.row_objects_selection('_nodes')
    
    if downstream_nodes.size == 0
      puts "ERROR: Please select one or more downstream nodes"
      puts "Hold Ctrl key to select multiple nodes"
      return
    end
    
    puts "Selected #{downstream_nodes.size} downstream node(s):"
    downstream_nodes.each { |o| puts "  - #{o.node_id}" }
    puts ""
    
    # Get parent group for storing selection lists
    begin
      group = get_parent_group
      unless group
        puts "ERROR: No valid Model Group found. Selection lists cannot be created."
        return
      end
      puts "Selection lists will be saved to Model Group: #{group.name}"
      puts ""
    rescue => e
      puts "ERROR: Failed to get Model Group: #{e.message}"
      return
    end
    
    # Find all terminal upstream nodes
    puts "Finding terminal upstream nodes..."
    terminal_nodes = find_terminal_upstream_nodes
    puts "Found #{terminal_nodes.size} terminal upstream node(s)"
    puts ""
    
    if terminal_nodes.size == 0
      puts "WARNING: No terminal upstream nodes found in the network"
      cleanup_flags
      return
    end
    
    # Display safety limits
    puts "Safety limits: max_depth=#{@max_depth}, max_paths=#{@max_paths}"
    puts ""
    
    # Process each combination of terminal node and downstream node
    total_combinations = 0
    successful_lists = 0
    total_paths_found = 0
    paths_limited = 0
    
    begin
      terminal_nodes.each do |terminal_node|
        downstream_nodes.each do |downstream_node|
          total_combinations += 1
          
          puts "Processing: #{terminal_node.node_id} -> #{downstream_node.node_id}"
          
          # Clear selection
          @net.clear_selection
          
          # Clean up flags from previous trace
          cleanup_flags
          
          # Find ALL paths
          paths = find_all_paths(terminal_node, downstream_node)
          
          if paths.empty?
            puts "  WARNING: No path found"
            next
          end
          
          # Check if we hit the path limit
          if paths.size >= @max_paths
            puts "  Found #{paths.size} paths (limited by max_paths=#{@max_paths})"
            paths_limited += 1
          else
            puts "  Found #{paths.size} path(s)"
          end
          
          total_paths_found += paths.size
          
          # Select all nodes/links from all paths (combined)
          counts = select_all_paths(paths)
          puts "  Combined selection: #{counts[0]} nodes, #{counts[1]} links"
          
          # Create selection list name
          base_name = "AllPaths_#{terminal_node.node_id}_to_#{downstream_node.node_id}"
          list_name = create_unique_name(group, base_name)
          
          # Create and save selection list
          begin
            sl = group.new_model_object('Selection List', list_name)
            @net.save_selection(sl)
            puts "  Created selection list: '#{list_name}'"
            successful_lists += 1
          rescue => e
            puts "  ERROR: Failed to create selection list: #{e.message}"
          end
          
          puts ""
        end
      end
      
    rescue => e
      puts "ERROR: Processing failed: #{e.message}"
      puts e.backtrace.join("\n") if e.backtrace
    ensure
      cleanup_flags
      @net.clear_selection
    end
    
    # Summary
    puts "=" * 60
    puts "SUMMARY"
    puts "=" * 60
    puts "Terminal upstream nodes: #{terminal_nodes.size}"
    puts "Selected downstream nodes: #{downstream_nodes.size}"
    puts "Total combinations processed: #{total_combinations}"
    puts "Total individual paths found: #{total_paths_found}"
    puts "Combinations hitting path limit: #{paths_limited}"
    puts "Successfully created selection lists: #{successful_lists}"
    puts ""
    if paths_limited > 0
      puts "NOTE: #{paths_limited} combination(s) hit the max_paths limit."
      puts "Some paths may not be included. Consider increasing @max_paths if needed."
      puts ""
    end
    puts "Refresh the database tree to view the new selection lists."
    puts "=" * 60
  end
end

# Run the script
begin
  tracer = AllPathsTracer.new
  tracer.process
rescue => e
  puts "FATAL ERROR: #{e.message}"
  puts e.backtrace.join("\n") if e.backtrace
end
