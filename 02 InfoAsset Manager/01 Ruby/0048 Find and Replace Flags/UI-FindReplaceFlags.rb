# Replicates Tools > Find and Replace Flags on the open network.
# Works on Collection, Distribution, and Asset networks.

# Set non-empty to apply these mappings without prompts (for migration / batch scripts).
# Example reverse-engineering mappings:
#   '01' => '#A', '02' => '#A', '07' => 'AS'
FLAG_REPLACEMENTS = {}

# When nil, the script prompts. When true/false, limits scope to whole network or GeoPlan selection only.
PROCESS_WHOLE_NETWORK = nil

MAX_PROMPTED_PAIRS = 10

def exit_on_invalid_input
  WSApplication.message_box(
    'Script stopped: The input was invalid.',
    'OK',
    'stop',
    false
  )
  exit
end

def prompt_flag_mappings
  flag_count = WSApplication.prompt(
    'How many flag codes do you want to replace?',
    [['Number of flags', 'Number', 0, 0, 'RANGE', 0, MAX_PROMPTED_PAIRS]],
    false
  )
  exit_on_invalid_input if flag_count.nil? || flag_count[0].to_i == 0

  layout = []
  (1..flag_count[0].to_i).each do |i|
    layout << ["Old flag ##{i}", 'String']
    layout << ["New flag ##{i}", 'String']
  end

  flags_array = WSApplication.prompt('Which flags do you want to replace?', layout, false)
  exit_on_invalid_input if flags_array.nil? || flags_array.any?(&:nil?)

  old_flags, new_flags = flags_array.partition.with_index { |_, i| i.even? }
  mapping = {}
  old_flags.each_with_index do |old_flag, i|
    old_key = old_flag.to_s.strip
    next if old_key.empty?

    mapping[old_key] = new_flags[i].to_s.strip
  end
  exit_on_invalid_input if mapping.empty?

  mapping
end

def prompt_whole_network
  answer = WSApplication.prompt(
    'Find and Replace Flags — scope',
    [
      ['Process whole network? (clear for GeoPlan selection only)', 'Boolean', true]
    ],
    false
  )
  exit_on_invalid_input if answer.nil?

  answer[0] == true
end

def rows_for_table(net, table_name, whole_network)
  if whole_network
    net.row_objects(table_name)
  elsif net.respond_to?(:row_objects_selection)
    net.row_objects_selection(table_name)
  else
    net.row_object_collection_selection(table_name)
  end
end

def replace_flags_in_network(net, mapping, whole_network: true)
  rows_written = 0
  flags_replaced = 0

  net.tables.each do |table|
    flag_fields = table.fields.select { |f| f.name.match?(/_flag/) }
    next if flag_fields.empty?

    rows_for_table(net, table.name, whole_network).each do |row|
      row_changed = false
      flag_fields.each do |field|
        current = row[field.name]
        next if current.nil? || current.to_s.empty?

        new_flag = mapping[current.to_s]
        next if new_flag.nil?

        row[field.name] = new_flag
        row_changed = true
        flags_replaced += 1
      end
      next unless row_changed

      row.write
      rows_written += 1
    end
  end

  [rows_written, flags_replaced]
end

begin
  net = WSApplication.current_network
  mapping = FLAG_REPLACEMENTS.empty? ? prompt_flag_mappings : FLAG_REPLACEMENTS.dup
  whole_network =
    if PROCESS_WHOLE_NETWORK.nil?
      prompt_whole_network
    else
      PROCESS_WHOLE_NETWORK
    end

  net.transaction_begin
  rows_written, flags_replaced = replace_flags_in_network(net, mapping, whole_network: whole_network)
  net.transaction_commit

  scope = whole_network ? 'whole network' : 'GeoPlan selection'
  summary = "Find and Replace Flags (#{scope}): #{flags_replaced} flag field(s) updated on #{rows_written} row(s)."
  puts summary
  WSApplication.message_box(summary, 'OK', nil, false)
rescue SystemExit
  # User dismissed an invalid-input message box; exit quietly.
end
