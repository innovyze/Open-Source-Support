################################################################################
# zone_schematic_network.rb
# Network tracing, area statistics, reservoir data, and vis-network payload.
# Loaded via require_relative from zone_schematic.rb
# Depends on: zone_schematic_helpers.rb (must be loaded first)
################################################################################

VALVE_BOUNDARY_MODES = %w[PRV PSV PCV TCV FCV FRV PFV FMV PRSV THV].freeze

def valve_label_for_mode(mode_str)
  m = mode_str.to_s.strip.upcase
  return 'Closed Valve' if m == 'THV'
  VALVE_BOUNDARY_MODES.include?(m) ? "#{m} Valve" : nil
end

def mark_boundary_links(network, table_names)
  # Select valves via SQL — marks all selected as boundaries with a generic label.
  # The per-table loop below overwrites with the specific mode label.
  begin
    network.run_SQL('Valve', "SELECT WHERE (joined.mode IS NOT NULL) AND NOT (joined.mode = 'THV' AND joined.opening <> 0)")
    network.row_objects_selection('_links').each do |link|
      link._boundary = true
      link._key = true
      link._key_label = 'Valve'
      link._key_type = 'valve'
    end
  rescue
  ensure
    network.clear_selection
  end

  if table_names.include?('wn_pst')
    network.row_objects('wn_pst').each do |link|
      link._boundary = true
      link._key = true
      link._key_label = 'Pump Station'
      link._key_type = 'pump'
    end
  end

  if table_names.include?('wn_meter')
    begin
      network.run_SQL('wn_meter', "SELECT WHERE joined.live_data_point_id IS NOT NULL")
      network.row_objects_selection('wn_meter').each do |link|
        link._boundary = true
        link._key = true
        link._key_label = 'Meter'
        link._key_type = 'meter'
      end
    rescue
      nil
    ensure
      network.clear_selection
    end
  end

  %w[wn_ctl_valve wn_valve wn_non_return_valve wn_float_valve].each do |table|
    next unless table_names.include?(table)
    network.row_objects(table).each do |link|
      next unless has_field?(link, 'mode')
      mode = link['mode']
      next if mode.nil?
      opening = has_field?(link, 'opening') ? link['opening'] : nil
      next if mode.to_s.strip.upcase == 'THV' && !opening.nil? && opening.to_f != 0.0
      label = valve_label_for_mode(mode)
      next if label.nil?
      link._boundary = true
      link._key = true
      link._key_label = label
      link._key_type = 'valve'
    end
  end
end

# Determine the area name for a traced group from the link 'area' field values.
# Returns the most common non-blank value, or nil if all blank.
def determine_area_name(link_objects)
  values = link_objects.map do |link|
    begin
      v = link['area']
      (v.nil? || v.to_s.strip.empty?) ? nil : v.to_s.strip
    rescue
      nil
    end
  end.compact

  return nil if values.empty?

  freq = values.group_by { |v| v }.transform_values(&:size)
  freq.max_by { |_, count| count }.first
end

# Trace the network into areas and collect all data needed for the schematic.
# Returns a Hash with keys:
#   :areas, :area_demands, :area_pressures, :area_by_node_id,
#   :edges, :key_nodes, :reservoir_nodes, :fixed_head_nodes, :transfer_nodes,
#   :area_members (for field update: area_name => { links: [...], node_ids: [...] })
def trace_areas(net, table_names)
  all_links = net.row_objects('_links')
  all_links.each do |link|
    link._seen = nil
    link._boundary = nil
    link._key = nil
    link._key_label = nil
    link._key_type = nil
  end

  mark_boundary_links(net, table_names)

  # Phase 1: trace zones with temporary IDs, collecting link objects per zone
  temp_zone_by_node_id = {}
  temp_zone_node_counts = Hash.new(0)
  temp_zone_link_counts = Hash.new(0)
  temp_zone_nodes = {}
  temp_zone_links = {}

  zone_index = 0
  all_links.each do |start_link|
    next if start_link._boundary || start_link._seen
    zone_index += 1
    tmp_id = "__zone_#{zone_index}"
    temp_zone_nodes[tmp_id] ||= {}
    temp_zone_links[tmp_id] ||= []
    pending_links = [start_link]

    until pending_links.empty?
      link = pending_links.shift
      next if link._boundary || link._seen
      link._seen = true
      temp_zone_link_counts[tmp_id] += 1
      temp_zone_links[tmp_id] << link

      [link.us_node, link.ds_node].each do |node|
        next if node.nil?
        node_id = node.id.to_s
        temp_zone_by_node_id[node_id] = tmp_id
        unless temp_zone_nodes[tmp_id].key?(node_id)
          temp_zone_nodes[tmp_id][node_id] = true
          temp_zone_node_counts[tmp_id] += 1
        end
        node.us_links.each { |l| pending_links << l unless l._boundary || l._seen }
        node.ds_links.each { |l| pending_links << l unless l._boundary || l._seen }
      end
    end
  end

  # Phase 2: determine area names from link 'area' field values
  name_for_tmp = {}
  used_names = {}

  temp_zone_links.each do |tmp_id, links|
    area_name = determine_area_name(links)
    if area_name
      used_names[area_name] ||= []
      used_names[area_name] << tmp_id
    end
    name_for_tmp[tmp_id] = area_name
  end

  # Handle duplicate area names by appending a suffix
  used_names.each do |area_name, tmp_ids|
    next if tmp_ids.size <= 1
    tmp_ids.sort_by { |t| -(temp_zone_node_counts[t] || 0) }.each_with_index do |t, i|
      name_for_tmp[t] = i == 0 ? area_name : "#{area_name} (#{i + 1})"
    end
  end

  # Assign default names to zones without an area field value
  final_names = {}
  default_index = 0
  all_used = name_for_tmp.values.compact.to_a
  temp_zone_links.keys.each do |tmp_id|
    if name_for_tmp[tmp_id]
      final_names[tmp_id] = name_for_tmp[tmp_id]
    else
      default_index += 1
      candidate = "Area #{default_index}"
      while all_used.include?(candidate)
        default_index += 1
        candidate = "Area #{default_index}"
      end
      final_names[tmp_id] = candidate
      all_used << candidate
    end
  end

  # Phase 3: remap everything from temp IDs to final area names
  area_by_node_id = {}
  temp_zone_by_node_id.each { |node_id, tmp_id| area_by_node_id[node_id] = final_names[tmp_id] }

  areas = {}
  temp_zone_node_counts.each do |tmp_id, count|
    area_name = final_names[tmp_id]
    areas[area_name] = { node_count: count, link_count: temp_zone_link_counts[tmp_id] }
  end

  area_nodes = {}
  temp_zone_nodes.each do |tmp_id, ids|
    area_nodes[final_names[tmp_id]] = ids
  end

  area_members = {}
  temp_zone_links.each do |tmp_id, links|
    area_name = final_names[tmp_id]
    area_members[area_name] = {
      links: links,
      node_ids: (temp_zone_nodes[tmp_id] || {}).keys
    }
  end

  final_names.each do |tmp_id, area_name|
    src = determine_area_name(temp_zone_links[tmp_id] || [])
    if src
      puts "Area '#{area_name}' — from field value '#{src}' (#{areas[area_name][:node_count]} nodes, #{areas[area_name][:link_count]} links)"
    else
      puts "Area '#{area_name}' — default name (#{areas[area_name][:node_count]} nodes, #{areas[area_name][:link_count]} links)"
    end
  end

  # Collect node references for demand/pressure calculation
  node_by_id = {}
  if table_names.include?('wn_node')
    net.row_objects('wn_node').each { |node| node_by_id[node.id.to_s] = node }
  end
  if table_names.include?('wn_reservoir')
    net.row_objects('wn_reservoir').each { |node| node_by_id[node.id.to_s] = node }
  end

  area_demands = Hash.new(0.0)
  area_leakage = Hash.new(0.0)
  area_pressures = {}
  area_nodes.each do |area_name, ids|
    min_p = nil
    max_p = nil
    sum_p = 0.0
    count_p = 0
    sum_head = 0.0
    count_head = 0
    ids.keys.each do |node_id|
      node = node_by_id[node_id]
      next if node.nil?
      demand = safe_result_any(node, %w[demand actual_demand])
      area_demands[area_name] += demand.to_f unless demand.nil?
      leakage = safe_result_any(node, %w[leakage Leakage])
      area_leakage[area_name] += leakage.to_f unless leakage.nil?
      pressure = safe_result_any(node, %w[pressure Pressure])
      unless pressure.nil?
        p = pressure.to_f
        min_p = p if min_p.nil? || p < min_p
        max_p = p if max_p.nil? || p > max_p
        sum_p += p
        count_p += 1
      end
      head = safe_result_any(node, %w[head Head])
      unless head.nil?
        sum_head += head.to_f
        count_head += 1
      end
    end
    avg_p = count_p > 0 ? sum_p / count_p : nil
    avg_h = count_head > 0 ? sum_head / count_head : nil
    area_pressures[area_name] = { min: min_p, max: max_p, avg: avg_p, avg_head: avg_h }
  end

  # Boundary edges and key nodes
  edges = []
  key_nodes = {}
  all_links.each do |link|
    next unless link._boundary && link._key
    us = link.us_node
    ds = link.ds_node
    next if us.nil? || ds.nil?
    us_area = area_by_node_id[us.id.to_s] || 'Unzoned'
    ds_area = area_by_node_id[ds.id.to_s] || 'Unzoned'
    next if us_area == ds_area
    areas[us_area] ||= { node_count: 0, link_count: 0 }
    areas[ds_area] ||= { node_count: 0, link_count: 0 }
    type_label = link._key_label || link.table
    key_id = "#{link._key_type || 'link'}:#{link.id}"
    flow = safe_result(link, 'flow')
    open_state = link_open_state(link)

    tooltip_parts = ["<b>#{type_label}: #{link.id}</b>"]
    if link._key_type == 'valve'
      tooltip_parts << "Flow: #{format_value(flow)}"
      pressure = safe_result_any(link, %w[pressure Pressure ds_pressure])
      tooltip_parts << "Pressure: #{format_value(pressure)}" unless pressure.nil?
      headloss = safe_result_any(link, %w[headloss head_loss Headloss])
      tooltip_parts << "Headloss: #{format_value(headloss)}" unless headloss.nil?
    elsif link._key_type == 'pump'
      tooltip_parts << "Flow: #{format_value(flow)}"
      head = safe_result_any(link, %w[head pump_head Head])
      tooltip_parts << "Head: #{format_value(head)}" unless head.nil?
      pumps_on = safe_result_any(link, %w[pumps_on number_on pumps_running])
      tooltip_parts << "Pumps On: #{format_value(pumps_on, 0)}" unless pumps_on.nil?
      energy = safe_result_any(link, %w[energy power Energy Power])
      tooltip_parts << "Energy: #{format_value(energy)}" unless energy.nil?
    else
      tooltip_parts << "Flow: #{format_value(flow)}"
    end

    flow_label = flow.nil? ? nil : format_value(flow)
    key_nodes[key_id] = {
      type: (link._key_type || 'link'),
      tooltip: tooltip_parts.join('<br>'),
      open: open_state,
      objectId: link.id.to_s,
      flowLabel: flow_label,
    }
    edge_color = if open_state.nil? then '#888888' elsif open_state then '#2E7D32' else '#C62828' end
    edges << { from: us_area, to: key_id, link_color: edge_color }
    edges << { from: key_id, to: ds_area, link_color: edge_color }
  end

  # Reservoir data
  reservoir_nodes = {}
  if table_names.include?('wn_reservoir')
    first_res = true
    net.row_objects('wn_reservoir').each do |res|
      area = area_by_node_id[res.id.to_s] || 'Unzoned'
      areas[area] ||= { node_count: 0, link_count: 0 }

      if first_res
        first_res = false
        puts "--- Reservoir diagnostic for #{res.id} ---"
        begin
          info = JSON.parse(net.table('wn_reservoir').tableinfo_json)
          fields = (info['fields'] || info['Fields'] || [])
          field_names = fields.map { |f| f['name'] || f['Name'] }.compact
          puts "  Input fields: #{field_names.join(', ')}"
        rescue => e
          puts "  tableinfo_json: #{e.message}"
        end
        probe_results = %w[depth head level Level Head Depth flow Flow
                           volume Volume pctfull pctvol pct_vol percent_full _Load]
        found = []
        probe_results.each do |f|
          v = safe_result(res, f)
          found << "#{f}=#{v}" unless v.nil?
        end
        puts "  Available results: #{found.join(', ')}"
        %w[depth_volume tank_curve volume_curve].each do |m|
          begin
            s = res.send(m.to_sym)
            if s
              puts "  #{m}: size=#{s.size}"
              if s.size > 0
                row = s[0]
                row_keys = []
                %w[depth Depth level Level volume Volume area Area].each do |k|
                  begin
                    v = row[k]
                    row_keys << "#{k}=#{v}" unless v.nil?
                  rescue
                  end
                end
                puts "  #{m}[0] keys: #{row_keys.join(', ')}"
              end
            end
          rescue => e
            puts "  #{m}: #{e.message}"
          end
        end
      end

      depth = safe_result_any(res, %w[depth head level])

      pct_vol = safe_result_any(res, [
        '% Volume', 'pctvol', 'pct_vol', 'percent_volume',
        'vol_pct', 'pctfull', 'percent_full', 'PercentFull'
      ])

      if pct_vol.nil?
        level_val = safe_result_any(res, %w[Level level depth head])
        if level_val
          max_depth = nil
          %w[depth_volume tank_curve volume_curve].each do |method_name|
            break unless max_depth.nil?
            begin
              dv = res.send(method_name.to_sym)
              next if dv.nil? || dv.size < 1
              (0...dv.size).each do |i|
                %w[depth Depth level Level].each do |fn|
                  begin
                    d = dv[i][fn].to_f
                    max_depth = d if d > 0 && (max_depth.nil? || d > max_depth)
                  rescue
                  end
                end
              end
            rescue
            end
          end

          if max_depth.nil?
            %w[chamber_roof top_level max_level max_depth].each do |f|
              begin
                v = res[f]
                if v && v.to_f > 0
                  max_depth = v.to_f
                  break
                end
              rescue
              end
            end
          end

          if max_depth && max_depth > 0
            min_depth = 0.0
            %w[chamber_floor base_level min_level min_depth].each do |f|
              begin
                v = res[f]
                if v
                  min_depth = v.to_f
                  break
                end
              rescue
              end
            end
            range = max_depth - min_depth
            if range > 0
              pct_vol = ((level_val.to_f - min_depth) / range * 100.0)
              pct_vol = [[pct_vol, 0.0].max, 100.0].min
            end
          end
        end
      end

      load_val = safe_result_any(res, %w[_Load])
      load_abs_label = nil
      if load_val && load_val.to_f.abs > 1.0e-6
        load_abs_label = format_value(load_val.to_f.abs)
      end

      puts "Reservoir #{res.id}: pct_vol=#{pct_vol.inspect}, depth=#{depth.inspect}, load=#{load_val.inspect}"

      tooltip_parts = ["<b>Reservoir #{res.id}</b>"]
      tooltip_parts << "Depth: #{format_value(depth)}" unless depth.nil?
      tooltip_parts << "#{format_value(pct_vol, 1)}% Full" unless pct_vol.nil?
      tooltip_parts << "Load: #{format_value(load_val)}" unless load_val.nil?

      node_id = "reservoir:#{res.id}"
      reservoir_nodes[node_id] = {
        name: "Reservoir #{res.id}",
        tooltip: tooltip_parts.join('<br>'),
        percent_full: pct_vol.nil? ? nil : pct_vol.to_f,
        depth: depth,
        objectId: res.id.to_s,
        loadLabel: load_abs_label
      }

      if load_val && load_val.to_f < 0
        edges << { from: node_id, to: area, style: 'dashed', flow_label: load_abs_label }
      else
        edges << { from: area, to: node_id, style: 'dashed', flow_label: load_abs_label }
      end
    end
  end

  # Fixed Head nodes — derive flow from connecting links
  fixed_head_nodes = {}
  if table_names.include?('wn_fixed_head')
    net.row_objects('wn_fixed_head').each do |fh|
      area = area_by_node_id[fh.id.to_s] || 'Unzoned'
      areas[area] ||= { node_count: 0, link_count: 0 }
      head = safe_result_any(fh, %w[head level pressure Head Level Pressure])

      fh_id_str = fh.id.to_s
      net_outflow = 0.0
      all_links.each do |link|
        us = link.us_node
        ds = link.ds_node
        next if us.nil? || ds.nil?
        flow = nil
        if us.id.to_s == fh_id_str
          flow = safe_result(link, 'flow')
          net_outflow += flow.to_f if flow
        elsif ds.id.to_s == fh_id_str
          flow = safe_result(link, 'flow')
          net_outflow -= flow.to_f if flow
        end
      end

      flow_abs_label = nil
      if net_outflow.abs > 1.0e-6
        flow_abs_label = format_value(net_outflow.abs)
      end

      tooltip_parts = ["<b>Fixed Head: #{fh.id}</b>"]
      tooltip_parts << "Head: #{format_value(head)}" unless head.nil?
      tooltip_parts << "Flow: #{format_value(net_outflow)}" if net_outflow.abs > 1.0e-6
      node_id = "fixedhead:#{fh.id}"
      fixed_head_nodes[node_id] = {
        name: "Fixed Head #{fh.id}",
        tooltip: tooltip_parts.join('<br>'),
        objectId: fh.id.to_s,
        loadLabel: flow_abs_label
      }

      if net_outflow > 1.0e-6
        edges << { from: node_id, to: area, style: 'dashed', flow_label: flow_abs_label }
      else
        edges << { from: area, to: node_id, style: 'dashed', flow_label: flow_abs_label }
      end
    end
  end

  # Transfer Nodes
  transfer_nodes = {}
  if table_names.include?('wn_transfer_node')
    net.row_objects('wn_transfer_node').each do |tn|
      area = area_by_node_id[tn.id.to_s] || 'Unzoned'
      areas[area] ||= { node_count: 0, link_count: 0 }
      head = safe_result_any(tn, %w[head level pressure Head Level Pressure])
      demand_val = safe_result_any(tn, %w[demand actual_demand])
      demand_abs_label = nil
      if demand_val && demand_val.to_f.abs > 1.0e-6
        demand_abs_label = format_value(demand_val.to_f.abs)
      end
      tooltip_parts = ["<b>Transfer Node: #{tn.id}</b>"]
      tooltip_parts << "Head: #{format_value(head)}" unless head.nil?
      tooltip_parts << "Demand: #{format_value(demand_val)}" unless demand_val.nil?
      node_id = "transfer:#{tn.id}"
      transfer_nodes[node_id] = {
        name: "Transfer #{tn.id}",
        tooltip: tooltip_parts.join('<br>'),
        objectId: tn.id.to_s,
        loadLabel: demand_abs_label
      }

      if demand_val && demand_val.to_f < 0
        edges << { from: node_id, to: area, style: 'dashed', flow_label: demand_abs_label }
      else
        edges << { from: area, to: node_id, style: 'dashed', flow_label: demand_abs_label }
      end
    end
  end

  # --- Area consolidation ---
  # Remove tiny areas (no demand, <5 links) attached to a special node.
  special_node_ids = {}
  reservoir_nodes.each { |nid, _| special_node_ids[nid] = true }
  fixed_head_nodes.each { |nid, _| special_node_ids[nid] = true }
  transfer_nodes.each { |nid, _| special_node_ids[nid] = true }

  areas_to_remove = []
  areas.each do |area_name, attrs|
    has_demand = area_demands[area_name] && area_demands[area_name].abs > 1.0e-6
    next if has_demand
    next if attrs[:link_count].to_i >= 5
    attached_special = edges.select { |e| (e[:from] == area_name || e[:to] == area_name) && (special_node_ids[e[:from]] || special_node_ids[e[:to]]) }
    next if attached_special.empty?
    replacement_id = attached_special.first[:from] == area_name ? attached_special.first[:to] : attached_special.first[:from]
    areas_to_remove << { area_name: area_name, replacement_id: replacement_id }
  end

  areas_to_remove.each do |info|
    aid = info[:area_name]
    rid = info[:replacement_id]
    puts "Consolidating '#{aid}' into #{rid}"
    areas.delete(aid)
    area_demands.delete(aid)
    area_leakage.delete(aid)
    area_pressures.delete(aid)
    area_members.delete(aid)
    edges.reject! { |e| (e[:from] == aid && e[:to] == rid) || (e[:from] == rid && e[:to] == aid) }
    edges.each do |e|
      e[:from] = rid if e[:from] == aid
      e[:to] = rid if e[:to] == aid
    end
  end

  {
    areas: areas,
    area_demands: area_demands,
    area_leakage: area_leakage,
    area_pressures: area_pressures,
    area_by_node_id: area_by_node_id,
    edges: edges,
    key_nodes: key_nodes,
    reservoir_nodes: reservoir_nodes,
    fixed_head_nodes: fixed_head_nodes,
    transfer_nodes: transfer_nodes,
    area_members: area_members,
    node_by_id: node_by_id
  }
end

# Build the vis-network nodes and edges arrays from traced data.
# Returns: { nodes_payload: [...], edges_payload: [...] }
def build_vis_payload(areas, area_demands, area_leakage, area_pressures, key_nodes,
                      reservoir_nodes, fixed_head_nodes, transfer_nodes, edges)
  nodes_payload = []
  areas.keys.sort.each do |area_name|
    attrs = areas[area_name] || {}
    has_demand = area_demands[area_name] && area_demands[area_name].abs > 1.0e-6
    pressures = area_pressures[area_name] || {}
    leak = area_leakage[area_name]

    # Compact label for the box
    label_lines = [area_name]
    label_lines << "Nodes: #{attrs[:node_count]}" if attrs[:node_count].is_a?(Integer)
    label_lines << "Avg Pressure: #{format_value(pressures[:avg])}" unless pressures[:avg].nil?
    label_lines << "Total Demand: #{format_value(area_demands[area_name])}" if has_demand

    # Detailed tooltip on hover
    tip = ["<b>#{area_name}</b>"]
    tip << "Nodes: #{attrs[:node_count]}" if attrs[:node_count].is_a?(Integer)
    tip << "Links: #{attrs[:link_count]}" if attrs[:link_count].is_a?(Integer)
    tip << "Min Pressure: #{format_value(pressures[:min])}" unless pressures[:min].nil?
    tip << "Max Pressure: #{format_value(pressures[:max])}" unless pressures[:max].nil?
    tip << "Avg Pressure: #{format_value(pressures[:avg])}" unless pressures[:avg].nil?
    tip << "Avg Head: #{format_value(pressures[:avg_head])}" unless pressures[:avg_head].nil?
    tip << "Total Demand: #{format_value(area_demands[area_name])}" if has_demand
    tip << "Total Leakage: #{format_value(leak)}" if leak && leak.abs > 1.0e-6

    node_count = attrs[:node_count].to_i
    scale = Math.sqrt([node_count, 1].max / 10.0)
    scale = [[scale, 0.8].max, 2.4].min
    size = (16 * scale).round(2)
    bg_color = has_demand ? '#E8F5E9' : '#F2F2F2'
    border_color = has_demand ? '#4CAF50' : '#666666'
    nodes_payload << {
      id: area_name,
      label: label_lines.join("\n"),
      title: tip.join('<br>'),
      shape: 'box',
      color: { background: bg_color, border: border_color },
      font: { multi: true, align: 'left' },
      margin: 10,
      size: size,
      nodeType: 'area'
    }
  end

  reservoir_nodes.each do |node_id, data|
    nodes_payload << {
      id: node_id,
      label: data[:name],
      title: data[:tooltip],
      shape: 'database',
      color: { background: '#DDEEFF', border: '#4466AA' },
      font: { multi: true, align: 'left' },
      margin: 10,
      nodeType: 'reservoir',
      percentFull: data[:percent_full],
      objectId: data[:objectId]
    }
  end

  # Fixed Head nodes — hexagon shape, orange
  fixed_head_nodes.each do |node_id, data|
    nodes_payload << {
      id: node_id,
      label: data[:name],
      title: data[:tooltip],
      shape: 'hexagon',
      size: 20,
      color: { background: '#FFF3E0', border: '#E65100' },
      font: { size: 10, color: '#333' },
      nodeType: 'fixedhead',
      objectId: data[:objectId]
    }
  end

  # Transfer Nodes — star shape, purple
  transfer_nodes.each do |node_id, data|
    nodes_payload << {
      id: node_id,
      label: data[:name],
      title: data[:tooltip],
      shape: 'star',
      size: 20,
      color: { background: '#F3E5F5', border: '#7B1FA2' },
      font: { size: 10, color: '#333' },
      nodeType: 'transfer',
      objectId: data[:objectId]
    }
  end

  key_nodes.each do |node_id, data|
    shape = data[:type] == 'pump' ? 'triangle' : (data[:type] == 'meter' ? 'square' : 'diamond')
    fill = if data[:open].nil?
             '#FFFFFF'
           elsif data[:open]
             '#4CAF50'
           else
             '#E53935'
           end
    border = data[:open].nil? ? '#888888' : (data[:open] ? '#1B5E20' : '#B71C1C')
    is_open = data[:open].nil? ? nil : data[:open]
    flow_val = data[:flowLabel]
    flow_str = if flow_val.nil? || flow_val.to_f.abs < 1.0e-6
                 ''
               else
                 flow_val
               end
    nodes_payload << {
      id: node_id,
      label: flow_str,
      title: data[:tooltip],
      shape: shape,
      size: 14,
      color: { background: fill, border: border },
      font: { size: 9, color: '#333', strokeWidth: 2, strokeColor: '#fff' },
      margin: 0,
      nodeType: 'boundary',
      linkType: data[:type],
      isOpen: is_open,
      objectId: data[:objectId]
    }
  end

  edges_payload = edges.map do |edge|
    item = { from: edge[:from], to: edge[:to] }
    item[:dashes] = true if edge[:style] == 'dashed'
    if edge[:link_color]
      item[:color] = { color: edge[:link_color], highlight: edge[:link_color] }
      item[:width] = 2
    end
    if edge[:flow_label]
      item[:label] = edge[:flow_label]
      item[:font] = { size: 9, color: '#555', strokeWidth: 2, strokeColor: '#fff' }
    end
    item
  end

  { nodes_payload: nodes_payload, edges_payload: edges_payload }
end
