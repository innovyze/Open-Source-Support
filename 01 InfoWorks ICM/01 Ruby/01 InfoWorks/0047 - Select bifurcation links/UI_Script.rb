net=WSApplication.current_network
net.clear_selection
links_list_all=Array.new

# Record every link's us node, ds node and id (covers all link types)
net.row_objects('_links').each do |link|
  links_list_all << [link.us_node_id, link.ds_node_id, link.id]
end

# Group by us node - more than one link per group means that node branches
group_by_us = links_list_all.group_by { |us, ds, id| us }
bifurcating_groups = group_by_us.select { |us, links| links.length > 1 }

link_list_sel = Array.new

# Within each branching node, drop links that also share the same ds node
# (those are parallel/looped links, not true bifurcations)
bifurcating_groups.each do |us, links|
  links.group_by { |l| l[1] }.each do |ds, ds_links|
    link_list_sel.concat(ds_links.map { |l| l[2] }) if ds_links.length == 1
  end
end

# Select the true bifurcation links on the active network
net.row_objects('_links').each do |link|
  link.selected=true if link_list_sel.include?(link.id)
end
