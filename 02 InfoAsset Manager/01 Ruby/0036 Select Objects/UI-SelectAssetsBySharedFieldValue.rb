# Select objects from multiple CAMS asset tables where a field matches a value.
# Run from InfoAsset Manager: Network -> Run Ruby Script...

net = WSApplication.current_network

ASSET_TABLES = %w[
  cams_channel
  cams_connection_node
  cams_connection_pipe
  cams_data_logger
  cams_defence_area
  cams_defence_structure
  cams_flume
  cams_general_asset
  cams_general_line
  cams_generator
  cams_manhole
  cams_orifice
  cams_outlet
  cams_pipe
  cams_pump
  cams_pump_station
  cams_screen
  cams_siphon
  cams_sluice
  cams_storage
  cams_wtw
  cams_ancillary
  cams_valve
  cams_vortex
  cams_weir
].freeze

def prompt_true?(value)
  value == true || value.to_s.downcase == 'true'
end

def resolve_top_level_field(net, table_name, field_name)
  net.table(table_name).fields.find { |f| f.name.casecmp?(field_name) }
end

def value_matches?(actual, search_value, wildcard: false)
  if search_value.empty?
    return actual.nil? || actual.to_s.strip.empty?
  end
  return false if actual.nil?

  actual_str = actual.to_s.strip

  if wildcard
    File.fnmatch?(search_value.downcase, actual_str.downcase)
  else
    actual_str.casecmp?(search_value) == true
  end
end

network_table_names = {}
net.tables.each { |t| network_table_names[t.name] = true }

present_tables = ASSET_TABLES.select { |name| network_table_names.key?(name) }
missing_tables = ASSET_TABLES - present_tables

unless missing_tables.empty?
  puts "Note: #{missing_tables.size} asset table(s) are not present in this network:"
  missing_tables.each { |t| puts "  #{t}" }
  puts ''
end

if present_tables.empty?
  WSApplication.message_box(
    'No CAMS asset tables were found in the current network.',
    'OK', '!', false
  )
  exit
end

# ---------------------------------------------------------------------------
# Prompt 1: select asset tables to search
# ---------------------------------------------------------------------------
table_prompt = [['Select / deselect all asset tables', 'Boolean', false]]
present_tables.each { |table| table_prompt << [table, 'Boolean', false] }

table_val = WSApplication.prompt('Select Asset Tables', table_prompt, false)

if table_val.nil?
  puts 'Script cancelled by user (table selection).'
  exit
end

select_all = table_val[0]
selected_tables = []
present_tables.each_with_index do |table, idx|
  selected_tables << table if prompt_true?(select_all) || prompt_true?(table_val[idx + 1])
end

if selected_tables.empty?
  WSApplication.message_box('No asset tables were selected.', 'OK', '!', false)
  puts 'Script cancelled - no tables selected.'
  exit
end

puts "Selected #{selected_tables.size} asset table(s): #{selected_tables.join(', ')}"
puts ''

# ---------------------------------------------------------------------------
# Prompt 2: field name and value to match
# ---------------------------------------------------------------------------
search_val = WSApplication.prompt(
  'Search Criteria',
  [
    ['Field name', 'String', ''],
    ['Value to match', 'String', ''],
    ['Use wildcard search (*, ?)?', 'Boolean', false],
    ['When wildcard enabled, value to match uses:', 'Readonly', '* matches any characters; ? matches one character'],
    ['Append to existing selection?', 'Boolean', false]
  ],
  false
)

if search_val.nil?
  puts 'Script cancelled by user (search criteria).'
  exit
end

field_name = search_val[0].to_s.strip
search_value = search_val[1].to_s.strip
append_selection = prompt_true?(search_val[2])
wildcard_search = prompt_true?(search_val[3])

if field_name.empty?
  WSApplication.message_box('Field name cannot be empty.', 'OK', '!', false)
  puts 'Script cancelled - field name is empty.'
  exit
end

match_label = wildcard_search ? "matches '#{search_value}' (wildcard)" : "= '#{search_value}'"
puts "Searching for field '#{field_name}' #{match_label}"
puts append_selection ? 'Mode: append to existing selection' : 'Mode: replace existing selection'
puts ''

net.clear_selection unless append_selection

total_selected = 0
searched_tables = 0
skipped_tables = []

selected_tables.each do |table|
  field = resolve_top_level_field(net, table, field_name)

  unless field
    skipped_tables << table
    puts "SKIPPED: #{table} - field '#{field_name}' not found"
    next
  end

  searched_tables += 1
  resolved_name = field.name
  count = 0

  net.row_objects(table).each do |ro|
    next unless value_matches?(ro[resolved_name], search_value, wildcard: wildcard_search)

    ro.selected = true
    count += 1
  end

  total_selected += count
  puts "#{table}: selected #{count} object(s) where #{resolved_name} #{match_label}"
end

puts ''
puts "Summary: #{total_selected} object(s) selected across #{searched_tables} table(s)."

unless skipped_tables.empty?
  puts "Skipped #{skipped_tables.size} table(s) (field not present): #{skipped_tables.join(', ')}"
end
