net = WSApplication.current_network
net.clear_selection
links_list_all = []

# Creates an array of arrays containing the unique link id and the upstream and downstream nodes of each link.
net.row_objects('_links').each do |link|
  usds = "#{link.us_node_id}-#{link.ds_node_id}"
  links_list_all << [usds, link.id]
end

# Groups all links by their respective us/ds node ids
group_by_usds = links_list_all.group_by { |usds, id| usds }.transform_values { |values| values.map { |usds, id| id } }

# Filters groups with us/ds showing more than once and converts hash to a flattened array of links
link_list_sel = group_by_usds.select { |usds, ids| ids.length > 1 }.values.flatten

# Selects only links from the list above on the active network
net.row_objects('_links').each do |link|
  link.selected = true if link_list_sel.include?(link.id)
end
