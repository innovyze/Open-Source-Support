  # Source: https://github.com/chaitanyalakeshri/ruby_scripts 
begin
  # Accessing the current network (ICM InfoWorks Only) 
  net = WSApplication.current_network
  raise "Error: current network not found" if net.nil?

  net.transaction_begin

  # Define function to update IDs for a given set of row objects
  def update_ids(row_objects, prefix)
    number = 1
    row_objects.each do |obj|
      obj.id = "#{prefix}#{number}"
      number += 1
      obj.write
    end
    number
  end

  # Get all nodes, links, and subcatchments as arrays and update their IDs
  nodes_ro = net.row_objects('_nodes')
  links_ro = net.row_objects('_links')
  subs_ro = net.row_objects('_subcatchments')
  raise "Error: objects not found" if nodes_ro.nil? || links_ro.nil? || subs_ro.nil?
  
  # Update IDs for nodes, links, and subcatchments
  puts "Node IDs Changed", update_ids(nodes_ro, "N_")
  #puts "Link IDs Changed", update_ids(links_ro, "L_")
  puts "Sub  IDs Changed", update_ids(subs_ro, "S_")

  net.transaction_commit    

rescue => e
  puts "Error: #{e.message}"
end
