cn = WSApplication.current_network
bn = WSApplication.background_network

# Retrieve hw_subcatchments from cn
cn_subcatchments = cn.row_object_collection('hw_subcatchment')
cn.transaction_begin

# Retrieve sw_node from bn
bn_nodes = bn.row_object_collection('sw_node')

val = WSApplication.prompt "Compare Infoworks HW Subcatchments to SWMM SW Nodes for Inflow",
[
  ['Set trade_flow to base_flow', 'Boolean', false],
  ['Make ICM Subcatchments from ICM SWMM Nodes', 'Boolean', false],
  ["This tool compares selected attributes between", 'String'],
  ["InfoWorks HW Subcatchments and SWMM SW Nodes.", 'String'],
  ["Select the attributes you want to compare", 'String'],
  ["The comparison will be based on Node IDs.", 'String'],
  ["Results will show the values from both networks", 'String'],
  ["and their differences.", 'String']
], false

# Remember the flags
set_trade_flow_to_base_flow = val[0]
make_subcatchments_from_nodes = val[1]

# Create a hash map for bn base_flow by node_id
bn_base_flows = {}
bn_nodes.each do |node|
  bn_base_flows[node.node_id] = node.base_flow
end

# Initialize totals for trade_flow (from CN) and base_flow (from BN)
total_trade_flow = 0.0
total_base_flow = 0.0

# Initialize totals for non-zero values only (sums)
nonzero_trade_flow = 0.0
nonzero_base_flow = 0.0

# Initialize counters for non-zero trade_flow/base_flow occurrences
nonzero_trade_count = 0
nonzero_base_count = 0

# ----- NEW ACCUMULATORS FOR CN FIELDS -----
# Totals for CN subcatchments "base_flow" and "additional_foul_flow"
total_cn_base_flow = 0.0
total_cn_add_foul_flow = 0.0

# Non-zero sums for CN base_flow and additional_foul_flow
nonzero_cn_base_flow = 0.0
nonzero_cn_add_foul_flow = 0.0

# Counters for non-zero occurrences in CN base_flow and additional_foul_flow
nonzero_cn_base_count = 0
nonzero_cn_add_count = 0
# -----------------------------------------

# ----- NEW ACCUMULATORS FOR CN POPULATION -----
total_population = 0.0
nonzero_population = 0.0
nonzero_population_count = 0
# ----------------------------------------------

# ----- NEW ACCUMULATORS FOR CN POPULATION FLOW -----
# population_flow = 1440 * population / 1e06
total_population_flow = 0.0
nonzero_population_flow = 0.0
nonzero_population_flow_count = 0
# --------------------------------------------------

# Compare trade_flow from CN to base_flow from BN using node_id, and also sum CN base_flow,
# additional_foul_flow, population, and population_flow
cn_subcatchments.each do |subcatchment|
  node_id = subcatchment.node_id
  trade_flow = subcatchment.trade_flow
  # Retrieve CN base_flow, additional_foul_flow, and population if they exist
  cn_base_flow = subcatchment.base_flow
  add_foul_flow = subcatchment.additional_foul_flow
  population = subcatchment.population
  
  if bn_base_flows.key?(node_id)
    base_flow = bn_base_flows[node_id]
    # Ensure values are not nil
    trade_flow = trade_flow.nil? ? 0.0 : trade_flow
    base_flow = base_flow.nil? ? 0.0 : base_flow
    cn_base_flow = cn_base_flow.nil? ? 0.0 : cn_base_flow
    add_foul_flow = add_foul_flow.nil? ? 0.0 : add_foul_flow
    population = population.nil? ? 0.0 : population

    # Calculate population flow from CN: 1440 * population / 1e06
    population_flow = 1440.0 * population / 1e06

    # Set trade_flow to base_flow if the flag is set
    if set_trade_flow_to_base_flow
      subcatchment.trade_flow = base_flow
      subcatchment.write
    end

   # Print only if the sum of base_flow and trade_flow is not zero
    if base_flow + trade_flow != 0.0
      puts "Node ID: #{node_id.slice(0, 25).ljust(20)} Trade Flow: #{format('%10.5f', trade_flow)}, BN Base Flow: #{format('%10.5f', base_flow)}, CN Base Flow: #{format('%10.5f', cn_base_flow)}, Additional Foul Flow: #{format('%10.5f', add_foul_flow)}, Population: #{format('%.0f', population)}"
      # Add to non-zero totals and counts (trade_flow and BN base_flow)
      nonzero_trade_flow += trade_flow
      nonzero_base_flow += base_flow
      nonzero_trade_count += 1 if trade_flow != 0.0
      nonzero_base_count += 1 if base_flow != 0.0
    end      

    # Update overall totals for trade_flow and BN base_flow regardless of non-zero check
    total_trade_flow += trade_flow
    total_base_flow += base_flow

    # --- Update CN stats for base_flow and additional_foul_flow ---
    total_cn_base_flow += cn_base_flow
    total_cn_add_foul_flow += add_foul_flow

    # Update non-zero sums and counts for CN base_flow
    if cn_base_flow != 0.0
      nonzero_cn_base_flow += cn_base_flow
      nonzero_cn_base_count += 1
    end

    # Update non-zero sums and counts for additional_foul_flow
    if add_foul_flow != 0.0
      nonzero_cn_add_foul_flow += add_foul_flow
      nonzero_cn_add_count += 1
    end
    
    # --- Update CN population stats ---
    total_population += population
    if population != 0.0
      nonzero_population += population
      nonzero_population_count += 1
    end

    # --- Update CN population flow stats ---
    total_population_flow += population_flow
    if population_flow != 0.0
      nonzero_population_flow += population_flow
      nonzero_population_flow_count += 1
    end

  else
    puts "Node ID: #{node_id} not found in BN"
  end
end

# Commit changes if trade_flow was set to base_flow
if set_trade_flow_to_base_flow
  cn.transaction_commit
end

# Print counts for non-zero values
puts "Non-Zero Count for CN subcatchment.trade_flow           : #{nonzero_trade_count}"
puts "Non-Zero Count for BN node.base_flow                    : #{nonzero_base_count}"
puts "Non-Zero Count for CN subcatchment.base_flow            : #{nonzero_cn_base_count}"
puts "Non-Zero Count for CN subcatchment.additional_foul_flow : #{nonzero_cn_add_count}"
puts "Non-Zero Count for CN subcatchment.population           : #{nonzero_population_count}"
puts "Non-Zero Count for CN subcatchment.population_flow      : #{nonzero_population_flow_count}"

# Print totals for non-zero sums (if desired)
puts "Non-Zero CN subcatchment.trade_flow (sum)               : #{format('%.4f', nonzero_trade_flow)}"
puts "Non-Zero BN node.base_flow (sum)                        : #{format('%.4f', nonzero_base_flow)}"
puts "Non-Zero CN subcatchment.base_flow (sum)                : #{format('%.4f', nonzero_cn_base_flow)}"
puts "Non-Zero CN subcatchment.additional_foul_flow (sum)     : #{format('%.4f', nonzero_cn_add_foul_flow)}"
puts "Non-Zero CN subcatchment.population (sum)               : #{format('%.0f', nonzero_population)}"
puts "Non-Zero CN subcatchment.population_flow (sum)          : #{format('%.4f', nonzero_population_flow)}"

# Make ICM Subcatchments from ICM SWMM Nodes if the flag is set
if make_subcatchments_from_nodes
  cn.transaction_begin
  bn_nodes.each do |node|
    if node.node_type == "Junction"
      # Create new subcatchment
      new_subcatchment = cn.new_row_object('hw_subcatchment')
      new_subcatchment.subcatchment_id = node.node_id
      new_subcatchment.node_id = node.node_id
      new_subcatchment.trade_flow = node.base_flow
      new_subcatchment.x = node.x
      new_subcatchment.y = node.y
      # Set a meaningful default area or calculate based on actual data
      new_subcatchment.total_area = 1.0 # Replace with actual area calculation if possible
      new_subcatchment.write
      puts "Created subcatchment for Node ID: #{node.node_id}"
    end
  end
  cn.transaction_commit
end