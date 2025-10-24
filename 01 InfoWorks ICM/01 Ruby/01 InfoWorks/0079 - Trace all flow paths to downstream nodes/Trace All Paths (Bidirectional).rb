# Trace all paths (bidirectional) from terminal upstream nodes to selected node(s)
# 
# This version traces ALL possible paths, not just downstream flow paths.
# It can find paths that go upstream and then back downstream.
# 
# Instructions:
# 1. Select one or more target nodes (hold Ctrl to select multiple)
# 2. Run this script
# 3. The script will find all terminal upstream nodes
# 4. For each terminal node, traces ANY path to each selected target node
# 5. Each path will be saved as a separate Selection List
#
# Selection lists will be named: "Path_<upstream_node_id>_to_<target_node_id>"

class PathTracerBidirectional
  def initialize
    @net = WSApplication.current_network
    @db = WSApplication.current_database
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

  # Find shortest path between two nodes using Dijkstra's algorithm
  # Searches BIDIRECTIONALLY - follows both upstream and downstream links
  def find_path(start_node, end_node)
    working = Array.new
    working_hash = Hash.new
    calculated = Array.new
    calculated_hash = Hash.new
    
    start_node._val = 0.0
    start_node._from = nil
    start_node._link = nil
    working << start_node
    working_hash[start_node.id] = 0
    
    while working.size > 0
      # Find minimum value node
      min = nil
      min_index = -1
      (0...working.size).each do |i|
        if min.nil? || working[i]._val < min
          min = working[i]._val
          min_index = i
        end
      end
      
      if min_index < 0
        puts "  Index error in pathfinding"
        return nil
      end
      
      current = working.delete_at(min_index)
      
      # Check if we reached destination
      if current.id == end_node.id
        return current
      end
      
      working_hash.delete(current.id)
      calculated << current
      calculated_hash[current.id] = 0
      
      # Check both upstream and downstream links (bidirectional)
      (0..1).each do |direction|
        if direction == 0
          links = current.ds_links
        else
          links = current.us_links
        end
        
        links.each do |l|
          if direction == 0
            node = l.ds_node
          else
            node = l.us_node
          end
          
          next if node.nil?
          next if calculated_hash.has_key?(node.id)
          
          # Calculate new distance for this path
          new_val = if l.link_type == 'Cond'
            current._val + l.conduit_length
          else
            current._val + 5
          end
          
          if working_hash.has_key?(node.id)
            # Node already in working queue - check if new path is shorter
            index = -1
            (0...working.size).each do |i|
              if working[i].id == node.id
                index = i
                break
              end
            end
            
            if index == -1
              puts "  Working object #{node.id} in hash but not array"
              next
            end
            
            # Update only if new path is shorter
            if new_val < working[index]._val
              working[index]._val = new_val
              working[index]._from = current
              working[index]._link = l
            end
          else
            # New node - add to working queue
            node._val = new_val
            node._from = current
            node._link = l
            working << node
            working_hash[node.id] = 0
          end
        end
      end
    end
    
    nil  # No path found
  end

  # Select path from found node back to start
  def select_path(found_node)
    count_nodes = 0
    count_links = 0
    
    current = found_node
    while !current.nil?
      current.selected = true
      count_nodes += 1
      
      if !current._link.nil?
        current._link.selected = true
        count_links += 1
      end
      
      current = current._from
    end
    
    [count_nodes, count_links]
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
    # Get selected target nodes
    target_nodes = @net.row_objects_selection('_nodes')
    
    if target_nodes.size == 0
      puts "ERROR: Please select one or more target nodes"
      puts "Hold Ctrl key to select multiple nodes"
      return
    end
    
    puts "Selected #{target_nodes.size} target node(s):"
    target_nodes.each { |o| puts "  - #{o.node_id}" }
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
    
    # Process each combination of terminal node and target node
    total_paths = 0
    successful_paths = 0
    
    begin
      terminal_nodes.each do |terminal_node|
        target_nodes.each do |target_node|
          total_paths += 1
          
          puts "Processing path #{total_paths}: #{terminal_node.node_id} -> #{target_node.node_id}"
          
          # Clear selection
          @net.clear_selection
          
          # Clean up flags from previous trace
          cleanup_flags
          
          # Find path (bidirectional search)
          found = find_path(terminal_node, target_node)
          
          if found.nil?
            puts "  WARNING: No path found"
            next
          end
          
          # Select the path
          counts = select_path(found)
          puts "  Path found: #{counts[0]} nodes, #{counts[1]} links"
          
          # Create selection list name
          base_name = "Path_#{terminal_node.node_id}_to_#{target_node.node_id}"
          list_name = create_unique_name(group, base_name)
          
          # Create and save selection list
          begin
            sl = group.new_model_object('Selection List', list_name)
            @net.save_selection(sl)
            puts "  Created selection list: '#{list_name}'"
            successful_paths += 1
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
    puts "Selected target nodes: #{target_nodes.size}"
    puts "Total paths processed: #{total_paths}"
    puts "Successfully created selection lists: #{successful_paths}"
    puts ""
    puts "Refresh the database tree to view the new selection lists."
    puts "=" * 60
  end
end

# Run the script
begin
  tracer = PathTracerBidirectional.new
  tracer.process
rescue => e
  puts "FATAL ERROR: #{e.message}"
  puts e.backtrace.join("\n") if e.backtrace
end
