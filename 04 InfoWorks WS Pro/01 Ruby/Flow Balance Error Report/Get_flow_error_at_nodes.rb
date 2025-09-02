#
# This script demonstrates how to identify the maximum flow balance error on each node explicitly. This can be useful in some cases when troubleshooting model stability.
#
# -----------------------------------------------------------------------

begin
	net = WSApplication.current_network
	sim = net.model_object

	if (!sim.type.eql? "Wesnet Sim")
	  raise "No results open"
	end

	# Get maximum allowed flow tolerance from user:
	user_input=WSApplication.prompt "Max allowed flow tolerance",
	[['Max allowed flow tolerance','NUMBER',0.1]],false
	if (user_input == nil)
		raise "Cancelled"
	end
	user_tolerance = user_input[0]

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

rescue => e
	WSApplication.message_box("#{e}",nil,'Stop',false)
end
