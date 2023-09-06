require 'date'

# Options
TIME_FORMAT = "%F %T"
PRECISION = 2
TABLE = '_nodes' # e.g. _links, wn_node, wn_hydrant
RESULT = 'pressure' # e.g. flow

network = WSApplication.current_network
network_name = network.network_model_object.name

file = WSApplication.file_dialog(false, 'csv', 'Comma Seperated Value file', network_name, false, true)

output = "Time"

timesteps = network.list_timesteps
results = Array.new

# Get results for each object, and create the header at the same time
network.row_objects_selection(TABLE).each do |object|
  output << ",#{object.id}"
  results << object.results(RESULT)
end

output << "\n"

# Create a new row for each timestep
timesteps.each_with_index do |ts, i|
  output << ts.strftime(TIME_FORMAT)
  results.each { |r| output << ",#{r[i].round(PRECISION)}" }
  output << "\n"
end

File.write(file, output, mode: 'w')
