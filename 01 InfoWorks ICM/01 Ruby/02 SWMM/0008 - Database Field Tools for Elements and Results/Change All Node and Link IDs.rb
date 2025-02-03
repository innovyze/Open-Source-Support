# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
  # Accessing current network
  net = WSApplication.current_network
  raise "Error: current network not found" if net.nil?

  net.transaction_begin
  
  # Get all the nodes, links, and subcatchments as arrays
  nodes_ro = net.row_objects('_nodes')
  raise "Error: nodes not found" if nodes_ro.nil?
  links_ro = net.row_objects('_links')
  raise "Error: links not found" if links_ro.nil?
  subcatchments_ro = net.row_objects('_subcatchments')
  raise "Error: subcatchments not found" if subcatchments_ro.nil?
  
  node_number = 1
  nodes_ro.each do |node|
    begin
      node.node_id = "N#{node_number}"
      node.write
      node_number += 1
    rescue => e
      puts "Error changing node ID: #{e.message}"
    end
  end

  link_number = 1
  links_ro.each do |link|
    begin
      link.id = "L#{link_number}"
      link.write
      link_number += 1
    rescue => e
      puts "Error changing link ID: #{e.message}"
    end
  end  

  subcatchment_number = 1
  subcatchments_ro.each do |subcatchment|
    begin
      subcatchment.id = "S#{subcatchment_number}"
      subcatchment.write
      subcatchment_number += 1
    rescue => e
      puts "Error changing subcatchment ID: #{e.message}"
    end
  end
  
  puts "Node IDs Changed", node_number
  puts "Link IDs Changed", link_number
  puts "Subcatchment IDs Changed", subcatchment_number
  net.transaction_commit    

rescue => e
  puts "Error: #{e.message}"
end