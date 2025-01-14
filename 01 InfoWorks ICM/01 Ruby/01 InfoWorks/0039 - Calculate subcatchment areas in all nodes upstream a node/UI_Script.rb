# variables
$net = WSApplication.current_network
$net.clear_selection
$ro = $net.row_object('hw_node', '44628801')

# Error handling for non-existent node ID
if $ro.nil?
  puts "Error: Node ID '44628801' does not exist in the network."
  return
end

$unprocessed_links = Array.new
$seen_objects = Array.new

# Marks the given object as selected and seen, and adds it to the seen objects list
def mark(object)
  if object
    object.selected = true
    object._seen = true
    $seen_objects << object
  end
end

# Unmarks all seen objects as seen and clears the seen objects list
def unsee_all
  $seen_objects.each { |object| object._seen = false }
  $seen_objects = Array.new
end

# Adds all upstream links of the given node that have not been seen to the unprocessed links list and marks them as seen
def unprocessed_links(node)
  node.us_links.each do |link|
    if !link._seen
      $unprocessed_links << link
      mark(link)
    end
  end
end

# Calculates the total subcatchment area for the given object and marks all subcatchments as seen
def tot_sub_area(object)
  tot_sub_area = 0
  if object
    object.navigate('subcatchments').each do |subs|
      tot_sub_area += subs.total_area
      mark(subs)
    end
  end
  tot_sub_area
end

# Traces upstream from the given node, calculating total subcatchment area and returning the list of upstream nodes and total area
def trace_us(node)
  mark(node)
  total_area = tot_sub_area(node)
  unprocessed_links(node)
  nodes_us = Array.new
  nodes_us << node
  while $unprocessed_links.size > 0
    working_link = $unprocessed_links.shift
    working_node = working_link.us_node
    total_area += tot_sub_area(working_link)
    if working_node && !working_node._seen
      total_area += tot_sub_area(working_node)
      unprocessed_links(working_node)
      mark(working_node)
      nodes_us << working_node
    end
  end
  unsee_all
  [nodes_us, total_area]
end

# Executes the trace_us function on the initial node and prints the node ID and total subcatchment area for each upstream node
trace_us($ro)[0].each do |node|
  puts "%s: %s" % [node.node_id, trace_us(node)[1]]
end