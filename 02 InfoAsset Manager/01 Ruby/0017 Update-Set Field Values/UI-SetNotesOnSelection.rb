# Set notes (or another text field) on the current GeoPlan selection.
# Run from InfoAsset Manager: Network -> Run Ruby Script... or saved to the database as a Ruby script.
#
# Prompts for object tables that have a current GeoPlan selection. 
# Only selected objects in the chosen tables are updated.

DEFAULT_NOTES_TEXT = "Operator 1:\r\nDate/Time:\r\nNotes:\r\n\r\n" \
                     "Operator 2:\r\nDate/Time:\r\nNotes:\r\n\r\n" \
                     "Operator 3:\r\nDate/Time:\r\nNotes:\r\n"

DEFAULT_FIELD_NAME = 'notes'
UPDATE_MODES = ['Fill blanks only', 'Overwrite existing', 'Append to existing'].freeze

def prompt_true?(value)
  value == true || value.to_s.downcase == 'true'
end

def field_blank?(value)
  value.nil? || value.to_s.strip.empty?
end

def resolve_field_value(current_value, value_to_set, update_mode)
  case update_mode
  when 'Overwrite existing'
    value_to_set
  when 'Append to existing'
    if field_blank?(current_value)
      value_to_set
    elsif field_blank?(value_to_set)
      current_value.to_s
    else
      current_value.to_s + "\r\n\r\n" + value_to_set
    end
  when 'Fill blanks only'
    return nil unless field_blank?(current_value)

    value_to_set
  else
    nil
  end
end

def table_profile(table_name)
  return :cams if table_name.start_with?('cams__') || table_name.start_with?('cams_')
  return :wams if table_name.start_with?('wams__') || table_name.start_with?('wams_')
  return :ams if table_name.start_with?('ams__') || table_name.start_with?('ams_')

  nil
end

def detect_network_profile(table_names)
  counts = { cams: 0, wams: 0, ams: 0 }

  table_names.each do |name|
    profile = table_profile(name)
    counts[profile] += 1 if profile
  end

  best = counts.max_by { |_profile, count| count }
  return best[0] if best[1] > 0

  :cams
end

def network_profile_label(profile)
  case profile
  when :wams then 'Distribution (WAMS)'
  when :ams then 'Asset (AMS)'
  else 'Collection (CAMS)'
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

def selection_count(net, table_name)
  net.row_objects_selection(table_name).length
rescue StandardError
  0
end

def table_prompt_label_with_selection(net, table)
  count = selection_count(net, table.name)
  "#{table_prompt_label(table)} [#{count} selected]"
end

def resolve_top_level_field(net, table_name, field_name)
  net.table(table_name).fields.find { |f| f.name.casecmp?(field_name) }
end

net = WSApplication.current_network
if net.nil?
  WSApplication.message_box('No network is open. Open a network on the GeoPlan and run the script again.', 'OK', '!', false)
  raise 'abort'
end

present_tables = net.tables.sort_by { |t| table_sort_key(t) }
tables_with_selection = present_tables.select { |table| selection_count(net, table.name) > 0 }

if tables_with_selection.empty?
  WSApplication.message_box('No selected objects were found on the open network.', 'OK', '!', false)
  raise 'abort'
end

present_table_names = present_tables.map(&:name)
network_profile = detect_network_profile(present_table_names)

puts "Network profile: #{network_profile_label(network_profile)}"
puts "#{tables_with_selection.size} table(s) with a current selection."
puts ''

# ---------------------------------------------------------------------------
# Prompt 1: select object tables to update
# ---------------------------------------------------------------------------
table_prompt = [
  ['Only tables with selected objects are shown.', 'Readonly', '']
]
tables_with_selection.each do |table|
  table_prompt << [table_prompt_label_with_selection(net, table), 'Boolean', true]
end

table_val = WSApplication.prompt('Set Field Value - Select Object Tables', table_prompt, false)

if table_val.nil?
  puts 'Script cancelled by user (table selection).'
  raise 'abort'
end

selected_tables = []
tables_with_selection.each_with_index do |table, idx|
  selected_tables << table.name if prompt_true?(table_val[idx + 1])
end

if selected_tables.empty?
  WSApplication.message_box('No object tables were selected.', 'OK', '!', false)
  puts 'Script cancelled - no tables selected.'
  raise 'abort'
end

# ---------------------------------------------------------------------------
# Prompt 2: field and update options
# ---------------------------------------------------------------------------
options_val = WSApplication.prompt(
  'Set Field Value - Options',
  [
    ['Field to update', 'String', DEFAULT_FIELD_NAME],
    ['Value to set', 'String', DEFAULT_NOTES_TEXT],
    ['Update mode', 'String', 'Fill blanks only', nil, 'LIST', UPDATE_MODES],
    ['Fill blanks only: updates empty fields.', 'Readonly', ''],
    ['Append: adds after existing text.', 'Readonly', '']
  ],
  false
)

if options_val.nil?
  puts 'Script cancelled by user (options).'
  raise 'abort'
end

field_name = options_val[0].to_s.strip
value_to_set = options_val[1].to_s
update_mode = options_val[2].to_s
update_mode = 'Fill blanks only' unless UPDATE_MODES.include?(update_mode)

if field_name.empty?
  WSApplication.message_box('Field name cannot be empty.', 'OK', '!', false)
  raise 'abort'
end

puts "Field: #{field_name}"
puts "Value length: #{value_to_set.length} character(s)"
puts "Mode: #{update_mode}"
puts "Selected tables: #{selected_tables.join(', ')}"
puts ''

total_updated = 0
skipped_no_field = []
skipped_existing_value = []

net.transaction_begin

selected_tables.each do |table_name|
  field = resolve_top_level_field(net, table_name, field_name)
  unless field
    skipped_no_field << table_name
    puts "SKIPPED: #{table_name} - field '#{field_name}' not found"
    next
  end

  resolved_field = field.name
  selected_rows = net.row_objects_selection(table_name)
  next if selected_rows.empty?

  count = 0
  selected_rows.each do |ro|
    current_value = ro[resolved_field]
    new_value = resolve_field_value(current_value, value_to_set, update_mode)

    if new_value.nil?
      skipped_existing_value << "#{table_name}:#{ro.id}" if update_mode == 'Fill blanks only'
      next
    end

    next if new_value.to_s == current_value.to_s

    ro[resolved_field] = new_value
    ro.write
    count += 1
  end

  total_updated += count
  puts "#{table_name}: updated #{count} selected object(s)"
end

net.transaction_commit

puts ''
puts "Summary: #{total_updated} object(s) updated."

unless skipped_no_field.empty?
  puts "Skipped #{skipped_no_field.size} table(s) without field '#{field_name}': #{skipped_no_field.join(', ')}"
end

unless skipped_existing_value.empty?
  puts "Skipped #{skipped_existing_value.size} selected object(s) that already had a value (Fill blanks only mode)."
end

WSApplication.message_box(
  "#{total_updated} selected object(s) updated in field '#{field_name}'.",
  'OK',
  'Information',
  false
)
