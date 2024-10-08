NETWORK_ID = 1517
PIPES_TO_ISOLATE = ['ST27367901.ST27368901.1']
REPORT_FILE_NAME = 'result.html'  # Optional - set to nil to disable

# Open the database and network
database = WSApplication.open()
network = database.model_object_from_type_and_id('Geometry', NETWORK_ID)
network = network.open()

# Select the pipes to isolate
isolate_ros = []
PIPES_TO_ISOLATE.each { |id| isolate_ros << network.row_object('wn_pipe', id) }
isolate_ros.reject! # reject nil values (i.e. any pipes not found)
raise "no pipes selected in network" if isolate_ros.empty?

# Create a new WSNetSelectionList from the current selection
isolate_list = WSNetSelectionList.new()
isolate_list.from_row_objects(isolate_ros)

# Optional - create a temporary HTML report file
tmp_report_file = File.join(__dir__, REPORT_FILE_NAME) if REPORT_FILE_NAME

# Optional - create a new WSNetSelectionList to ignore valves. You could also pass nil to the isolation_trace method.
# Because isolation_trace does not expose the UI options for ignoring valve types, you must create the
# selection manually - the upside is that this gives you finer control over which valves to ignore.
ignore_valves = WSNetSelectionList.new()

# Create new WSNetSelectionLists which will be populated with the results of the isolation trace
closed_links = WSNetSelectionList.new()
isolated_objects = WSNetSelectionList.new()
isolated_customers = WSNetSelectionList.new()

# Run isolation trace
# @param selection_to_be_isolated [WSNetSelectionList]
# @param close_downstream [Boolean]
# @param assume_valve_at_meter [Boolean]
# @param selection_ignore_valves [WSNetSelectionList]
# @param selection_closed_links [WSNetSelectionList] selection list to update with closed links
# @param selection_isolated [WSNetSelectionList] selection list of isolated objects
# @param selection_customer_points [WSNetSelectionList] selection list to update with customer points isolated
# @param selection_spatial_data [WSNetSelectionList] selection list to update with spatial data points isolated
# @param report [String] path to write the HTML report
network.isolation_trace(isolate_list, false, false, ignore_valves, closed_links, isolated_objects, isolated_customers, nil, tmp_report_file)

# Print the row objects in a selection list
# @param prefix [String] prefix to print before the list e.g. 'Requested Isolation: '
# @param selection_list [WSNetSelectionList]
# @param network [WSOpenNetwork]
def print_selection_list(prefix, selection_list, network)
  ros = selection_list.to_row_objects(network)
  return if ros.empty?
  
  list_ids = ros.map { |ro| "#{ro.id} (#{ro.table})" }
  puts prefix + list_ids.join(',')
end

print_selection_list('Requested Isolation: ', isolate_list, network)
print_selection_list('Ignored Valves: ', ignore_valves, network)
print_selection_list('Closed Links required for Isolation: ', closed_links, network)
print_selection_list('Isolated Objects: ', isolated_objects, network)
print_selection_list('Isolated Customers: ', isolated_customers, network)