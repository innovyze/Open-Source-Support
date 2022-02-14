net=WSApplication.current_network
net.clear_selection
links_list_all=Array.new

# Creates an array of arrays containing the unique link id and the upstream and downstream nodes of each link.
net.row_objects('_links').each do |link|
  link_uid = link.us_node_id+'.'+link.link_suffix
  usds = link.us_node_id+link.ds_node_id
  links_list_all << [usds, link_uid]
end

# Groups the array by us/ds node id 
group_by_usds = links_list_all.group_by { |usds| usds.shift }.transform_values { |values| values.flatten }

# Filters groups with us/ds showing more than once and converts hash to a flattened array of links
link_list_sel = group_by_usds.select { |key, value| value.length > 1 }.values.flatten

# Selects only links from the list above from the active network
net.row_objects('_links').each do |link|
  link.selected=true if link_list_sel.include?(link.us_node_id+'.'+link.link_suffix)
end
