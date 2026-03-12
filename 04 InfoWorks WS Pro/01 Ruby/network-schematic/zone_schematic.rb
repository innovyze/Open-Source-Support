################################################################################
# Script Name: zone_schematic.rb
# Description: Main entry point for the area schematic generator.
#              Traces hydraulic areas, collects results, and produces an
#              interactive vis-network HTML page per network.
#              Run this script from the InfoWorks WS Pro UI.
# Requirements:
#              - Network must be open in the UI with results loaded
#              - Helper scripts must be in the same folder as this script
################################################################################

# Set OUTPUT_DIR to a path to skip the folder dialog each run, or leave nil
# to be prompted. Examples:
#   OUTPUT_DIR = 'D:\Zone Schematics'
#   OUTPUT_DIR = nil
OUTPUT_DIR = 'D:\temp'

# Set to true to update the 'area' field on every link and node in each
# traced area so the model matches the schematic. Boundary links, reservoirs,
# fixed head nodes, and transfer nodes are left untouched.
UPDATE_AREA_FIELDS = true

require 'json'
require_relative 'zone_schematic_helpers'
require_relative 'zone_schematic_network'
require_relative 'zone_schematic_html'

# --- Network and naming ---

net = WSApplication.current_network
table_names = net.table_names

network_name = begin
  net.network_model_object.name
rescue
  begin
    net.model_object.name
  rescue
    'Unknown'
  end
end
puts "Network: #{network_name}"

# --- Resolve output directory ---

output_dir = OUTPUT_DIR
if output_dir.nil? || !Dir.exist?(output_dir)
  output_dir = WSApplication.folder_dialog('Select folder for Area Schematic output files', false)
  if output_dir.nil?
    puts 'No output folder selected. Exiting.'
    exit
  end
end
Dir.mkdir(output_dir) unless Dir.exist?(output_dir)

safe_name = sanitize_filename(network_name)
html_path = File.join(output_dir, "#{safe_name}.html")
puts "Output folder: #{output_dir}"
puts "HTML: #{html_path}"

# --- Trace areas and build payload ---

data = trace_areas(net, table_names)

if data[:areas].empty?
  WSApplication.message_box('No areas found. Check boundary definitions or results loaded.', 'ok', '!', false)
  exit
end

# --- Optionally update area fields in the model ---

if UPDATE_AREA_FIELDS
  puts "Updating area fields in the model..."
  node_by_id = data[:node_by_id]
  update_count = 0
  net.transaction_begin
  begin
    data[:area_members].each do |area_name, members|
      next unless data[:areas].key?(area_name)
      members[:links].each do |link|
        begin
          current = link['area']
          if current.to_s.strip != area_name
            link['area'] = area_name
            link.write
            update_count += 1
          end
        rescue => e
          puts "  Could not update link #{link.id}: #{e.message}"
        end
      end
      members[:node_ids].each do |nid|
        node = node_by_id[nid]
        next if node.nil?
        begin
          current = node['area']
          if current.to_s.strip != area_name
            node['area'] = area_name
            node.write
            update_count += 1
          end
        rescue => e
          puts "  Could not update node #{nid}: #{e.message}"
        end
      end
    end
    net.transaction_commit
    puts "Updated #{update_count} objects."
  rescue => e
    puts "Error during area field update: #{e.message}"
    begin; net.transaction_rollback; rescue; end
  end
end

payload = build_vis_payload(
  data[:areas], data[:area_demands], data[:area_leakage], data[:area_pressures],
  data[:key_nodes], data[:reservoir_nodes],
  data[:fixed_head_nodes], data[:transfer_nodes], data[:edges]
)

nodes_payload = payload[:nodes_payload]
edges_payload = payload[:edges_payload]

# --- Extract saved layout from existing HTML (if present) ---

layout_preloaded = false
if File.exist?(html_path)
  begin
    existing_html = File.read(html_path)
    match = existing_html.match(/<script id="saved-layout" type="application\/json">(.*?)<\/script>/m)
    if match
      positions = JSON.parse(match[1])
      nodes_payload.each do |node|
        pos = positions[node[:id]]
        if pos
          node[:x] = pos['x']
          node[:y] = pos['y']
        end
      end
      layout_preloaded = true
      puts "Layout extracted from existing HTML (#{positions.size} positions)"
    end
  rescue => e
    puts "Could not read layout from existing HTML: #{e.message}"
  end
end

# --- Generate and write HTML ---

html_payload = { nodes: nodes_payload, edges: edges_payload }
html = generate_zone_html(html_payload, network_name, safe_name, layout_preloaded, nodes_payload)

File.write(html_path, html)
puts "HTML written to: #{html_path}"

begin
  system("start \"\" \"#{html_path}\"")
rescue StandardError => e
  puts "Launch failed: #{e.message}"
end
