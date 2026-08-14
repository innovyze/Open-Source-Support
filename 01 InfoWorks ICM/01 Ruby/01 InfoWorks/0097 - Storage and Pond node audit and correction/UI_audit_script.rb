# Storage and pond flood type audit (InfoWorks hw_* UI script)
#
# Compares ground level with the last storage-array level to derive the flood
# type the simulation engine applies to storage nodes and ponds:
#   top level > ground level  -> stored
#   top level = ground level  -> lost
#   top level < ground level  -> sealed
#
# Reference: Autodesk support article "Storage tank flood behavior in ICM"
#
# Run from the ICM UI with a network open. Optionally select storage nodes or
# ponds on the GeoPlan; otherwise all storage/pond nodes are scanned.

require 'time'

STORAGE_TYPE = 'storage'
POND_TYPE = 'pond'
EXPECTED_TYPES = %w[stored lost sealed].freeze

def node_category(node)
  node_type = node.node_type
  return nil if node_type.nil?

  type = node_type.to_s.downcase
  return STORAGE_TYPE if type == STORAGE_TYPE
  return POND_TYPE if type == POND_TYPE

  nil
end

def audited_node?(node)
  !node_category(node).nil?
end

def html_escape(text)
  text.to_s
      .gsub('&', '&amp;')
      .gsub('<', '&lt;')
      .gsub('>', '&gt;')
      .gsub('"', '&quot;')
end

def format_num(value, digits = 3)
  return '' if value.nil?

  format("%.#{digits}f", value.to_f)
rescue StandardError
  value.to_s
end

def last_storage_level(storage_array)
  return nil if storage_array.nil? || storage_array.length.zero?

  storage_array[storage_array.length - 1]['level']
end

def max_storage_level(storage_array)
  return nil if storage_array.nil? || storage_array.length.zero?

  max_level = nil
  storage_array.each do |row|
    level = row['level']
    next if level.nil?

    max_level = level if max_level.nil? || level > max_level
  end
  max_level
end

def expected_flood_type(ground_level, top_level)
  return 'unknown' if ground_level.nil? || top_level.nil?

  delta = top_level.to_f - ground_level.to_f
  if delta.positive?
    'stored'
  elsif delta.zero?
    'lost'
  else
    'sealed'
  end
end

def nodes_in_scope(net)
  selected = net.row_objects_selection('hw_node')
  nodes = selected.empty? ? net.row_objects('hw_node') : selected
  nodes.select { |node| audited_node?(node) }
end

def partition_rows(rows)
  storage_rows = []
  pond_rows = []
  rows.each do |row|
    case row[:node_type].to_s.downcase
    when STORAGE_TYPE
      storage_rows << row
    when POND_TYPE
      pond_rows << row
    end
  end
  [storage_rows, pond_rows]
end

def analyse_node(node)
  ground_level = node.ground_level
  storage_array = node.storage_array
  top_level = last_storage_level(storage_array)
  max_level = max_storage_level(storage_array)

  issues = []
  if storage_array.nil? || storage_array.length.zero?
    issues << 'No storage array'
  elsif top_level.nil?
    issues << 'Last storage-array level is blank'
  end
  issues << 'Ground level is blank' if ground_level.nil?

  if !top_level.nil? && !max_level.nil? && top_level.to_f != max_level.to_f
    issues << 'Last array level differs from maximum level (array may be unsorted)'
  end

  flood_type = expected_flood_type(ground_level, top_level)

  {
    node_id: node.id,
    node_type: node.node_type,
    ground_level: ground_level,
    top_storage_level: top_level,
    max_storage_level: max_level,
    delta_m: (top_level.nil? || ground_level.nil? ? nil : top_level.to_f - ground_level.to_f),
    flood_type: flood_type,
    issues: issues,
    row_count: storage_array.nil? ? 0 : storage_array.length
  }
end

def flood_type_counts(rows)
  EXPECTED_TYPES.each_with_object({}) { |t, h| h[t] = rows.count { |r| r[:flood_type] == t } }
end

def append_node_table(html, title, rows)
  html << "<h2>#{html_escape(title)} (#{rows.length})</h2>"
  if rows.empty?
    html << '<p>No nodes in this category.</p>'
    return
  end

  html << '<table>'
  html << '<tr>'
  html << '<th>Node ID</th><th>Ground level (m)</th><th>Last array level (m)</th>'
  html << '<th>Delta (m)</th><th>Flood type</th><th>Status</th><th>Notes</th>'
  html << '</tr>'

  rows.sort_by { |r| r[:node_id].to_s }.each do |r|
    row_class = r[:issues].empty? ? 'ok' : 'warn'
    status = r[:issues].empty? ? 'OK' : 'Data issue'

    html << "<tr class=\"#{row_class}\">"
    html << "<td>#{html_escape(r[:node_id])}</td>"
    html << "<td class=\"num\">#{format_num(r[:ground_level])}</td>"
    html << "<td class=\"num\">#{format_num(r[:top_storage_level])}</td>"
    html << "<td class=\"num\">#{format_num(r[:delta_m])}</td>"
    html << "<td>#{html_escape(r[:flood_type])}</td>"
    html << "<td>#{html_escape(status)}</td>"
    html << "<td>#{html_escape(r[:issues].join('; '))}</td>"
    html << '</tr>'
  end
  html << '</table>'
end

def build_html_report(network_name, storage_rows, pond_rows, run_time, scope_label)
  rows = storage_rows + pond_rows
  total = rows.length
  with_issues = rows.count { |r| !r[:issues].empty? }
  counts = flood_type_counts(rows)
  storage_counts = flood_type_counts(storage_rows)
  pond_counts = flood_type_counts(pond_rows)

  html = []
  html << '<!DOCTYPE html>'
  html << '<html lang="en">'
  html << '<head>'
  html << '<meta charset="utf-8">'
  html << '<title>Storage and Pond Flood Type Audit</title>'
  html << '<style>'
  html << 'body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222;}'
  html << 'h1,h2{color:#1a5276;border-bottom:1px solid #ccc;padding-bottom:4px;}'
  html << 'table{border-collapse:collapse;width:100%;margin:12px 0 24px;font-size:0.92em;}'
  html << 'th,td{border:1px solid #bbb;padding:6px 8px;text-align:left;vertical-align:top;}'
  html << 'th{background:#d6eaf8;position:sticky;top:0;}'
  html << 'tr:nth-child(even){background:#f9f9f9;}'
  html << '.summary{margin:12px 0;padding:12px;background:#eafaf1;border:1px solid #abebc6;}'
  html << '.note{margin:12px 0;padding:12px;background:#ebf5fb;border:1px solid #aed6f1;}'
  html << '.warn{background:#fdebd0;}'
  html << '.ok{background:#eafaf1;}'
  html << '.meta{color:#555;font-size:0.95em;}'
  html << '.num{text-align:right;font-variant-numeric:tabular-nums;}'
  html << '</style>'
  html << '</head>'
  html << '<body>'
  html << '<h1>Storage and Pond Flood Type Audit</h1>'
  html << '<p class="meta">'
  html << "Network: #{html_escape(network_name)}<br>"
  html << "Run time: #{html_escape(run_time)}<br>"
  html << "Scope: #{html_escape(scope_label)}<br>"
  html << 'Rule: last storage-array level vs ground level (engine behaviour for storage and pond nodes)'
  html << '</p>'

  html << '<div class="note">'
  html << '<strong>Engine rule</strong><br>'
  html << 'Last storage level &gt; ground level &rarr; <strong>stored</strong><br>'
  html << 'Last storage level = ground level &rarr; <strong>lost</strong><br>'
  html << 'Last storage level &lt; ground level &rarr; <strong>sealed</strong>'
  html << '</div>'

  html << '<div class="summary">'
  html << "<strong>Summary</strong><br>"
  html << "Storage nodes scanned: #{storage_rows.length}<br>"
  html << "Pond nodes scanned: #{pond_rows.length}<br>"
  html << "Total: #{total}<br>"
  html << "All nodes - stored: #{counts['stored']} | lost: #{counts['lost']} | sealed: #{counts['sealed']}<br>"
  html << "Storage - stored: #{storage_counts['stored']} | lost: #{storage_counts['lost']} | sealed: #{storage_counts['sealed']}<br>"
  html << "Pond - stored: #{pond_counts['stored']} | lost: #{pond_counts['lost']} | sealed: #{pond_counts['sealed']}<br>"
  html << "Nodes with data issues: #{with_issues}"
  html << '</div>'

  append_node_table(html, 'Storage nodes', storage_rows)
  append_node_table(html, 'Pond nodes', pond_rows)
  html << '</body></html>'
  html.join("\n")
end

catch(:stop) do
  net = WSApplication.current_network
  unless net
    WSApplication.message_box('No network is open. Open a network and run again.', 'OK', 'Stop', false)
    throw :stop
  end

  selected_count = net.row_objects_selection('hw_node').length
  scope_nodes = nodes_in_scope(net)
  scope_label =
    if selected_count.positive?
      "Selected storage / pond nodes (#{scope_nodes.length} of #{selected_count} selected nodes)"
    else
      "All storage / pond nodes (#{scope_nodes.length})"
    end

  if scope_nodes.empty?
    WSApplication.message_box(
      'No storage or pond nodes in scope. Select storage nodes on the GeoPlan, or ensure the network contains storage/pond nodes.',
      'OK', 'Information', false
    )
    throw :stop
  end

  rows = scope_nodes.map { |node| analyse_node(node) }
  storage_rows, pond_rows = partition_rows(rows)

  output_dir = WSApplication.folder_dialog('Select folder for HTML report', true)
  throw :stop if output_dir.nil? || output_dir.to_s.strip.empty?

  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  network_name = net.network_model_object.name rescue 'Current network'
  html_path = File.join(output_dir, "storage_flood_type_audit_#{timestamp}.html")
  run_time = Time.now.strftime('%Y-%m-%d %H:%M:%S')

  File.write(html_path, build_html_report(network_name, storage_rows, pond_rows, run_time, scope_label))

  issues = rows.count { |r| !r[:issues].empty? }

  puts '=' * 72
  puts 'Storage and pond flood type audit complete'
  puts "Storage nodes: #{storage_rows.length}"
  puts "Pond nodes: #{pond_rows.length}"
  puts "Total scanned: #{rows.length}"
  puts "Data issues: #{issues}"
  puts "HTML report: #{html_path}"
  puts '=' * 72

  WSApplication.message_box(
    "Audit complete.\n\nStorage nodes: #{storage_rows.length}\nPond nodes: #{pond_rows.length}\nData issues: #{issues}\n\nReport:\n#{html_path}",
    'OK', 'Information', false
  )
end
