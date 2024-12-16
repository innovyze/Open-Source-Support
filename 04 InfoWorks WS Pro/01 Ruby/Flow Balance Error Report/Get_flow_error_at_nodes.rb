# Get maximum allowed flow tolerance from user:
user_input=WSApplication.prompt "Max allowed flow tolerance",
[['Max allowed flow tolerance','NUMBER',0.1]],false
user_tolerance = user_input[0]

net=WSApplication.current_network

# Sample selection to restrict search to nodes adjacent to pumps only
#net.run_SQL('wn_node','CLEAR SELECTION; SELECT WHERE COUNT( us_links.pumps.*)+ COUNT( ds_links.pumps.*)>0')

#ro=net.row_objects_selection('wn_node')
ro=net.row_objects('wn_node')
total_flow = Array.new(net.timestep_count,0)
summary_table = []

# For each Node: 
# max_flow_error = max( Inflows - Outflows - Demand)
ro.each do | node |
	node.us_links.each do | link |
		total_flow = [total_flow, link.results('flow')].transpose.map {|x| x.reduce(:+)}
	end
	node.ds_links.each do | link |
		total_flow = [total_flow, link.results('flow')].transpose.map {|x| x.reduce(:-)}
	end
	total_flow = [total_flow, node.results('demand')].transpose.map {|x| x.reduce(:-)}
	max_flow_error = total_flow.max
	
	# Adding node to the summary table if max_flow_error is above user_tolerance
	if max_flow_error > user_tolerance
		summary_table << { id: node.id, max_flow_error: max_flow_error }
	end
	
	total_flow.fill(0)
end

# Outputting the summary table to the console
puts "Node ID\tMax Flow Error"
summary_table.each do |entry|
	puts "#{entry[:id]}\t#{entry[:max_flow_error]}"
end
