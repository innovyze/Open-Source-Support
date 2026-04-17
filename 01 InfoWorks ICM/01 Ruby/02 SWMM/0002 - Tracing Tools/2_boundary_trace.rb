# We can't access control directly (yet) so we rely on this hack setting tags on them
#
# @param network [WSOpenNetwork]
def find_boundary_links(network)
  network.clear_selection
  network.run_SQL('_links', "SELECT WHERE joined.pipe_closed = true")
  network.run_SQL('Valve', "SELECT WHERE (joined.mode IS NOT NULL) AND NOT (joined.mode = 'THV' AND joined.opening <> 0)")
  network.row_objects_selection('_links').each { |link| link._boundary = true }
  network.clear_selection
end

# Trace out from a link, given some boundary conditions. Selects links and nodes as we go.
#
# @param link [WSLink]
# @param conditions [Hash]
# @return [Array<WSLink>] returns an array of newly selected links
def trace_out_link(link, conditions)
  links = []

  # Find all connected links, stop at boundary nodes
  [link.us_node, link.ds_node].each do |node|
    if conditions[:nodes].include?(node.table)
      node.selected = true if conditions[:trace_to_node]
      next
    else
      node.selected = true
      node.us_links.each { |link| links << link unless check_boundary_conditions(link, conditions) }
      node.ds_links.each { |link| links << link unless check_boundary_conditions(link, conditions) }
    end
  end

  links.each do |link|
    link._seen = true
    link.selected = true
  end

  return links
end

# Check the boundary conditions for a link.
#
# @param link [WSLink]
# @param conditions [Hash]
# @return [Boolean] whether to reject the link i.e. true means this is a boundary
def check_boundary_conditions(link, conditions)
  return true if link._seen
  return true if link._boundary
  return true if conditions[:links].include?(link.table)
  return true if link['area'] != conditions[:area]
  return false
end

# Open the current UI network
network = WSApplication.current_network

# Find the initial link we'll use to start the trace
initial_link = network.row_objects_selection('_links').first
raise "No link(s) selected for trace" if initial_link.nil?

# Boundary conditions
find_boundary_links(network)
conditions = {
  trace_to_node: true,
  nodes: ['wn_transfer_node', 'wn_fixed_head', 'wn_reservoir'],
  links: ['wn_pst', 'wn_meter'],
  area: initial_link['area']
}

# Trace
initial_link.selected = true
pending_links = [initial_link]
until pending_links.empty?
  working_link = pending_links.shift
  traced = trace_out_link(working_link, conditions)
  pending_links = pending_links.concat(traced)
end
