# Select objects from any object table in the open network where a field matches a value.
# Run from InfoAsset Manager: Network -> Run Ruby Script...

net = WSApplication.current_network

def prompt_true?(value)
  value == true || value.to_s.downcase == 'true'
end

def resolve_top_level_field(net, table_name, field_name)
  net.table(table_name).fields.find { |f| f.name.casecmp?(field_name) }
end

def numeric_field?(field)
  return false unless field

  %w[double long integer float].include?(field.data_type.to_s.downcase)
end

def numeric_equal?(actual, search_value)
  Float(actual.to_s.strip) == Float(search_value.to_s.strip)
rescue ArgumentError, TypeError
  false
end

def value_matches?(actual, search_value, field: nil, wildcard: false)
  if search_value.empty?
    return actual.nil? || actual.to_s.strip.empty?
  end
  return false if actual.nil?

  actual_str = actual.to_s.strip

  if wildcard
    File.fnmatch?(search_value.downcase, actual_str.downcase)
  elsif actual_str.casecmp?(search_value) == true
    true
  elsif numeric_field?(field) && numeric_equal?(actual, search_value)
    true
  else
    false
  end
end

def table_display_name(table)
  table.description.to_s.strip
end

def table_prompt_label(table)
  description = table_display_name(table)
  description.empty? ? table.name : "#{description} (#{table.name})"
end

def table_sort_key(table)
  description = table_display_name(table)
  (description.empty? ? table.name : description).downcase
end

present_tables = net.tables.sort_by { |t| table_sort_key(t) }

if present_tables.empty?
  WSApplication.message_box(
    'No object tables were found in the current network.',
    'OK', '!', false
  )
  exit
end

puts "#{present_tables.size} object table(s) available in this network."
puts ''

# ---------------------------------------------------------------------------
# Prompt 1: select object tables to search
# ---------------------------------------------------------------------------
table_prompt = [['Select / deselect all object tables', 'Boolean', false]]
present_tables.each { |table| table_prompt << [table_prompt_label(table), 'Boolean', false] }

table_val = WSApplication.prompt('Select Object Tables', table_prompt, false)

if table_val.nil?
  puts 'Script cancelled by user (table selection).'
  exit
end

select_all = table_val[0]
selected_tables = []
present_tables.each_with_index do |table, idx|
  selected_tables << table.name if prompt_true?(select_all) || prompt_true?(table_val[idx + 1])
end

if selected_tables.empty?
  WSApplication.message_box('No object tables were selected.', 'OK', '!', false)
  puts 'Script cancelled - no tables selected.'
  exit
end

puts "Selected #{selected_tables.size} object table(s): #{selected_tables.join(', ')}"
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
wildcard_search = prompt_true?(search_val[2])
append_selection = prompt_true?(search_val[4])

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
    next unless value_matches?(ro[resolved_name], search_value, field: field, wildcard: wildcard_search)

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
