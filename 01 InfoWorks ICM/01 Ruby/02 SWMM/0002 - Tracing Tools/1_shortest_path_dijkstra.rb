def dijkstra(start, target)
  working = Array.new
  working_hash = Hash.new
  calculated = Array.new
  calculated_hash = Hash.new

  start._val = 0.0
  start._from = nil
  start._link = nil

  working << start
  working_hash[start.id] = 0

  until working.empty?
    min = nil
    min_index = -1

    (0...working.size).each do |i|
      if min.nil? || working[i]._val < min
        min = working[i]._val
        min_index = i
      end
    end

    raise 'Index error' if min_index < 0

    current = working.delete_at(min_index)
    return current if current.id == target

    working_hash.delete(current.id)

    calculated << current
    calculated_hash[current.id]=0

    (0..1).each do |dir|
      links = (dir == 0) ? current.ds_links : current.us_links

      links.each do |link|
        node = (dir == 0) ? link.ds_node : link.us_node
        next if node.nil? || calculated_hash.include?(node&.id)

        if working_hash.include?(node.id)
          index = -1

          (0...working.size).each do |i|
            if working[i].id == node.id
              index = i
              break
            end
          end

          raise "Working object #{node.id} in hash but not array" if index == -1
        else
          working << node
          working_hash[node.id] = 0
          index = working.size - 1
        end

        working[index]._val = current._val + link.conduit_length
        working[index]._from = current
        working[index]._link = link
      end
    end
  end
end

# Open the current UI network
network = WSApplication.current_network

# Get the selected nodes, we expect exactly 2
nodes = network.row_objects_selection('_nodes')
raise "Select exactly 2 nodes!" if nodes.size != 2

# Find the shortest path
found = dijkstra(nodes[0], nodes[1].id)

# Select the path
until found.nil?
  found.selected = true
  found._link.selected = true unless found._link.nil?
  found = found._from
end
