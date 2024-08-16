# Accessing current network
net = WSApplication.WSApplication.current_network 
raise "Error: current network not found" if net.nil?

tables = [
  "hw_node",
  "hw_conduit",
  "hw_subcatchment"
]

begin
  nodes_hash_map = Hash.new { |h, k| h[k] = [] }
  
  tables.each do |table|
    nodes_ro = net.row_objects(table)
    raise "Error: #{table} not found" if nodes_ro.nil?
    number_nodes = nodes_ro.size
    printf "%-50s %-d\n", "Number of #{table.upcase}", number_nodes

    # Initialize totals for parameters
    total_length = 0.0
    total_area = 0.0
    total_volume = 0.0

    # Iterate over each row object and sum up the parameters
    nodes_ro.each do |node|
      node.
      total_length += node.length.to_f if node.respond_to?(:length)
      total_area += node.area.to_f if node.respond_to?(:area)
      total_volume += node.volume.to_f if node.respond_to?(:volume)
    end

    # Print totals for parameters
    puts "Total length for #{table.upcase}: #{total_length}"
    puts "Total area for #{table.upcase}: #{total_area}"
    puts "Total volume for #{table.upcase}: #{total_volume}"
  end

rescue => e
  puts "Error: #{e.message}"
end


