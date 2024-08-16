# Database table names we want to expand - these are the most common
EXPAND_TABLES = ['wn_meter', 'wn_non_return_valve', 'wn_pst', 'wn_valve']

# Expand options, which are equivalent to those found in the user interface tool
EXPAND_OPTIONS = {
  'Expansion threshold' => 1.0,
  'Minimum resultant length' => 1.0,
  'Protect connection points' => false,
  'Recalculate Length' => true,
  'Use user flag' => true,
  'Tables' => EXPAND_TABLES,
  'Log file name' => nil, # Optional
  'Flag' => 'EX'
}

# Get the current network - this is the UI method
network = WSApplication.current_network()

# Expanding only works on selected objects, so select every object of each table
network.clear_selection
EXPAND_TABLES.each { |table| network.row_objects(table).each { |ro| ro.selected = true } }

# Expand short links within a transaction
network.transaction_begin
network.expand_short_links(EXPAND_OPTIONS)
network.transaction_commit

# Clear the selection to tidy up
network.clear_selection
