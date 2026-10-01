# Fixed flag mappings — no prompts. Edit FLAG_REPLACEMENTS for your project.
# Replicates Tools > Find and Replace Flags on the whole open network.

FLAG_REPLACEMENTS = {
  '01' => '#A',
  '02' => '#A',
  '07' => 'AS'
}

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

net = WSApplication.current_network
net.transaction_begin
rows_written, flags_replaced = replace_flags_in_network(net, FLAG_REPLACEMENTS, whole_network: true)
net.transaction_commit

summary = "Find and Replace Flags (whole network): #{flags_replaced} flag field(s) updated on #{rows_written} row(s)."
puts summary
WSApplication.message_box(summary, 'OK', nil, false)
