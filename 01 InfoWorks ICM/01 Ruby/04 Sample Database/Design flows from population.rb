# Design Flow Calculator — ICM. EFF = c1+((c2+m1*P^e1)/(c3+m2*P^e2)). Upstream fill for nil/0 design_flow.
net = WSApplication.current_network
unless net
  WSApplication.message_box("ERROR: No network open.", "OK", "!", false)
  return
end

FORMULA_PRESETS = {
  'Harmon (Traditional US)' => { c1: 1.0, c2: 14.0, c3: 0.0, e1: 0.0, e2: 0.5, m1: 0.0, m2: 1.0 },
  'Modified Harmon (Ten States)' => { c1: 1.0, c2: 14.0, c3: 4.0, e1: 0.0, e2: 0.5, m1: 0.0, m2: 1.0 },
  'Babbitt (Small Communities)' => { c1: 0.0, c2: 5.0, c3: 0.0, e1: 0.0, e2: 0.2, m1: 0.0, m2: 1.0 },
  'Custom Babbitt' => { c1: 0.0, c2: 5.0, c3: 0.0, e1: 0.0, e2: 0.2, m1: 0.0, m2: 1.0 }
}

layout1 = [
  ['Formula?', 'STRING', 'Babbitt (Small Communities)', nil, 'LIST', FORMULA_PRESETS.keys],
  ['', 'READONLY', ''],
  ['Output units', 'STRING', 'L/s', nil, 'LIST', ['Metric (m3/s)', 'L/s']],
  ['', 'READONLY', ''],
  ['Flow per capita per day', 'NUMBER', 200.0, 2],
  ['', 'READONLY', ''],
  ['Min peaking factor', 'NUMBER', 1.0, 2],
  ['', 'READONLY', ''],
  ['Max peaking factor (cutoff)', 'NUMBER', 6.0, 2],
  ['', 'READONLY', '']
]
result1 = WSApplication.prompt('Design Flow Calculator', layout1, false)
if result1.nil?
  WSApplication.message_box("Cancelled.", "OK", "Information", false)
  return
end

selected_preset = result1[0]
unit_system_input = result1[2]
q_per_capita = result1[4]
min_eff = result1[6]
cutoff = result1[8]
preset = FORMULA_PRESETS[selected_preset]

if selected_preset == 'Custom Babbitt'
  layout2 = [
    ['EFF = c1 + ((c2 + m1*P^e1) / (c3 + m2*P^e2))', 'READONLY', ''],
    ['c1', 'NUMBER', preset[:c1], 4], ['c2', 'NUMBER', preset[:c2], 4], ['c3', 'NUMBER', preset[:c3], 4],
    ['e1', 'NUMBER', preset[:e1], 4], ['e2', 'NUMBER', preset[:e2], 4],
    ['m1', 'NUMBER', preset[:m1], 4], ['m2', 'NUMBER', preset[:m2], 4]
  ]
  result2 = WSApplication.prompt('Custom Babbitt (edit formula)', layout2, false)
  if result2.nil?
    WSApplication.message_box("Cancelled.", "OK", "Information", false)
    return
  end
  c1 = result2[1]
  c2 = result2[2]
  c3 = result2[3]
  e1 = result2[4]
  e2 = result2[5]
  m1 = result2[6]
  m2 = result2[7]
else
  c1 = preset[:c1]
  c2 = preset[:c2]
  c3 = preset[:c3]
  e1 = preset[:e1]
  e2 = preset[:e2]
  m1 = preset[:m1]
  m2 = preset[:m2]
end

# q = L/person/day -> L/day = EFF*P*q. L/s = /86400, m3/s = /(86400*1000).
case unit_system_input.to_s
when 'Metric (m3/s)'
  output_units = 'm3/s'
  input_units = 'L/person/day'
  conversion_factor = 86400.0 * 1000.0
else
  output_units = 'L/s'
  input_units = 'L/person/day'
  conversion_factor = 86400.0
end

validation_errors = []
validation_errors << "Flow per capita must be > 0" if q_per_capita.nil? || q_per_capita <= 0
validation_errors << "Min peaking factor must be > 0" if min_eff.nil? || min_eff <= 0
validation_errors << "Cutoff must be > 0" if cutoff.nil? || cutoff <= 0
validation_errors << "ERROR: Min cannot be > Max" if min_eff && cutoff && min_eff > cutoff
validation_errors << "ERROR: c3 and m2 cannot both be zero" if c3 == 0 && m2 == 0
if validation_errors.size > 0
  WSApplication.message_box(validation_errors.join("\n"), "OK", "!", false)
  return if validation_errors.any? { |e| e.start_with?("ERROR:") }
end

puts "\nDESIGN FLOW CALCULATOR\n" + selected_preset.to_s + "\nQ: " + q_per_capita.to_s + " " + input_units + ", EFF " + min_eff.to_s + "-" + cutoff.to_s + ", out: " + output_units

all_subs = net.row_object_collection('hw_subcatchment')
node_population_map = Hash.new(0.0)
all_subs.each do |sub|
  next if sub.population.nil? || sub.population <= 0
  if sub.node_id && !sub.node_id.empty?
    node_population_map[sub.node_id] += sub.population
  else
    begin
      lateral_links = []
      link_weights = {}
      total_weight = 0.0
      sub.lateral_links.each do |link|
        next if link.node_id.nil? || link.node_id.empty?
        lateral_links << link
        weight = 1.0
        begin
          weight = link['weight'].to_f if link['weight']
        rescue
          weight = 1.0
        end
        link_weights[link.node_id] = weight
        total_weight += weight
      end
      if lateral_links.size > 0 && total_weight > 0
        lateral_links.each do |link|
          nid = link.node_id
          node_population_map[nid] += sub.population * (link_weights[nid] / total_weight)
        end
      end
    rescue
    end
  end
end

subs_with_population = 0
total_population = 0.0
all_subs.each do |sub|
  if sub.population && sub.population > 0
    subs_with_population += 1
    total_population += sub.population
  end
end
if subs_with_population == 0
  WSApplication.message_box("ERROR: No subcatchments have population.", "OK", "!", false)
  return
end
puts "Subs with population: " + subs_with_population.to_s + ", total pop " + total_population.round(0).to_s

def get_conduit_flow_area(conduit)
  begin
    width = conduit.conduit_width
    height = conduit.conduit_height
    return 1.0 if width.nil? || width <= 0
    if !height.nil? && height > 0 && (height - width).abs > 0.001
      area = width * height
      return area > 0 ? area : 1.0
    end
    r = width / 2.0
    a = Math::PI * r * r
    return a > 0 ? a : 1.0
  rescue
    return 1.0
  end
end

def trace_upstream_population(conduit, node_population_map)
  unprocessed_links = [[conduit, 1.0]]
  seen_links = {}
  seen_nodes = {}
  node_contributions = Hash.new(0.0)
  seen_links[conduit.id] = true
  max_iterations = 10000
  iteration_count = 0
  while unprocessed_links.size > 0 && iteration_count < max_iterations
    iteration_count += 1
    working_link, current_weight = unprocessed_links.shift
    begin
      us_node = working_link.us_node
    rescue
      next
    end
    next if us_node.nil?
    node_id = us_node.id rescue nil
    next if node_id.nil?
    adjusted_weight = current_weight
    downstream_conduits = []
    begin
      us_node.ds_links.each do |dl|
        downstream_conduits << dl if dl.table == 'hw_conduit'
      end
    rescue
    end
    if downstream_conduits.size > 1
      total_area = 0.0
      areas = {}
      downstream_conduits.each do |dc|
        ar = get_conduit_flow_area(dc)
        areas[dc.id] = ar
        total_area += ar
      end
      wid = working_link.id rescue nil
      is_ds = false
      downstream_conduits.each do |dc|
        if dc.id == wid
          is_ds = true
          break
        end
      end
      if is_ds && total_area > 0 && areas[wid]
        adjusted_weight = current_weight * (areas[wid] / total_area)
      elsif is_ds && downstream_conduits.size > 0
        adjusted_weight = current_weight * (1.0 / downstream_conduits.size)
      end
    end
    if !seen_nodes[node_id] && node_population_map[node_id] > 0
      node_contributions[node_id] += node_population_map[node_id] * adjusted_weight
      seen_nodes[node_id] = true
    end
    begin
      us_node.us_links.each do |ul|
        uid = ul.id rescue nil
        next if uid.nil?
        if !seen_links[uid]
          unprocessed_links << [ul, adjusted_weight]
          seen_links[uid] = true
        end
      end
    rescue
    end
  end
  node_contributions.values.sum
end

def compute_conduit_design_flow(conduit, opts)
  population = trace_upstream_population(conduit, opts[:node_population_map])
  return [nil, :skip] if population.nil? || population <= 0
  return [nil, :error] if population.infinite? || population.nan?
  num = opts[:c2] + (opts[:m1] * (population ** opts[:e1]))
  den = opts[:c3] + (opts[:m2] * (population ** opts[:e2]))
  return [nil, :skip] if den == 0
  eff = opts[:c1] + (num / den)
  return [nil, :error] if eff.nil? || eff.infinite? || eff.nan?
  eff = opts[:min_eff] if eff < opts[:min_eff]
  eff = opts[:cutoff] if eff > opts[:cutoff]
  daily = eff * population * opts[:q_per_capita]
  design_flow = daily / opts[:conversion_factor]
  return [nil, :error] if design_flow.infinite? || design_flow.nan? || design_flow < 0
  [design_flow, :updated]
rescue
  [nil, :error]
end

all_conduits = net.row_object_collection('hw_conduit')
total_conduits = 0
all_conduits.each { total_conduits += 1 }
processed_conduits = 0
updated_conduits = 0
skipped_no_population = 0
calculation_errors = 0
transaction_started = false
begin
  net.transaction_begin
  transaction_started = true
rescue
  transaction_started = false
end

design_flow_opts = {}
design_flow_opts[:node_population_map] = node_population_map
design_flow_opts[:c1] = c1
design_flow_opts[:c2] = c2
design_flow_opts[:c3] = c3
design_flow_opts[:e1] = e1
design_flow_opts[:e2] = e2
design_flow_opts[:m1] = m1
design_flow_opts[:m2] = m2
design_flow_opts[:min_eff] = min_eff
design_flow_opts[:cutoff] = cutoff
design_flow_opts[:q_per_capita] = q_per_capita
design_flow_opts[:conversion_factor] = conversion_factor

filled_from_upstream = 0
begin
  all_conduits.each do |conduit|
    processed_conduits += 1
    df_result = compute_conduit_design_flow(conduit, design_flow_opts)
    design_flow = df_result[0]
    status = df_result[1]
    if status == :skip
      skipped_no_population += 1
    elsif status == :error
      calculation_errors += 1
    elsif status == :updated and design_flow
      conduit.design_flow = design_flow
      conduit.write
      updated_conduits += 1
    end
  end
  max_fill_passes = total_conduits + 1
  pass = 0
  loop do
    pass += 1
    break if pass > max_fill_passes
    changed = false
    all_conduits.each do |conduit|
      df = conduit.design_flow
      next unless df.nil? || df.to_f == 0.0
      us_node_id = nil
      begin
        un = conduit.us_node
        us_node_id = un.id if un
      rescue
      end
      next if us_node_id.nil? || us_node_id.to_s.empty?
      upstream_flow = 0.0
      all_conduits.each do |up|
        next if up.id == conduit.id
        begin
          next unless up.ds_node_id == us_node_id
          uf = up.design_flow
          next if uf.nil?
          uf = uf.to_f
          upstream_flow += uf if uf > 0
        rescue
        end
      end
      if upstream_flow > 0
        conduit.design_flow = upstream_flow
        conduit.write
        filled_from_upstream += 1
        changed = true
      end
    end
    break unless changed
  end
  if filled_from_upstream > 0
    puts "Filled from upstream: " + filled_from_upstream.to_s
  end
  net.transaction_commit if transaction_started
  puts "Updated: " + updated_conduits.to_s + ", filled: " + filled_from_upstream.to_s + ", skipped: " + skipped_no_population.to_s + ", errors: " + calculation_errors.to_s
  all_nodes = net.row_object_collection('hw_node')
  outfall_flows = {}
  all_nodes.each do |node|
    is_outfall = false
    is_outfall = true if node.respond_to?(:node_type) && node.node_type && node.node_type.to_s.downcase.include?('outfall')
    if !is_outfall
      n = 0
      node.ds_links.each { n += 1 }
      is_outfall = true if n == 0
    end
    next unless is_outfall
    tf = 0.0
    all_conduits.each do |conduit|
      tf += conduit.design_flow if conduit.ds_node_id == node.id && conduit.design_flow
    end
    outfall_flows[node.id] = tf if tf > 0
  end
  if outfall_flows.size > 0
    puts "Outfalls: " + outfall_flows.size.to_s + ", total " + outfall_flows.values.sum.round(3).to_s + " " + output_units
  end
rescue => e
  net.transaction_rollback if transaction_started
  WSApplication.message_box("ERROR: " + e.message.to_s, "OK", "!", false)
  return
end

summary = "Done. " + selected_preset.to_s + ". Updated " + updated_conduits.to_s + ", filled " + filled_from_upstream.to_s + ". " + output_units
WSApplication.message_box(summary, "OK", "Information", false)
