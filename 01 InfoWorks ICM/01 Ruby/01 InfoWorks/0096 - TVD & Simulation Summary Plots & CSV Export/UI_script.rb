# Simulation summary validation for InfoWorks (hw_*) networks.
# Run from the ICM UI with simulation results loaded on the GeoPlan.
## Produces in-ICM graphs and one CSV file.
# Empty GeoPlan selection uses all subcatchments / nodes / links in scope.

require 'date'
require 'fileutils'

catch(:stop) do
  net = WSApplication.current_network

  timesteps = net.list_timesteps
  if timesteps.nil? || timesteps.count.zero?
    WSApplication.message_box('No timesteps found. Run a simulation and open results.', 'OK', 'Information', false)
    throw :stop
  end

  ts_count = timesteps.count

  def objects_in_scope(net, table)
    selected = net.row_objects_selection(table)
    selected.empty? ? net.row_objects(table) : selected
  end

  def fetch_series_values(ro, field_name, ts_count)
    vals = []
    begin
      res = ro.results(field_name)
      res.each { |v| vals << v.to_f } unless res.nil?
    rescue StandardError
      vals = []
    end
    vals = Array.new(ts_count, vals[0]) if vals.size == 1
    return nil if vals.size != ts_count
    vals
  end

  def sum_series(objects, field_name, ts_count)
    total = Array.new(ts_count, 0.0)
    objects.each do |obj|
      vals = fetch_series_values(obj, field_name, ts_count)
      next if vals.nil?
      ts_count.times { |i| total[i] += vals[i] }
    end
    total
  end

  def sum_positive_series(objects, field_name, ts_count)
    total = Array.new(ts_count, 0.0)
    objects.each do |obj|
      vals = fetch_series_values(obj, field_name, ts_count)
      next if vals.nil?
      ts_count.times do |i|
        v = vals[i].to_f
        total[i] += v if v > 0.0
      end
    end
    total
  end

  def timestep_durations_seconds(net, timesteps, ts_count)
    dts = []
    (0...ts_count).each do |i|
      if i < ts_count - 1
        begin
          t0 = net.timestep_time(i)
          t1 = net.timestep_time(i + 1)
          dts << (t1.to_time - t0.to_time).abs.to_f
        rescue StandardError
          t0 = timesteps[i]
          t1 = timesteps[i + 1]
          dt = if t0.is_a?(DateTime) && t1.is_a?(DateTime)
                 (t1.to_time - t0.to_time).abs.to_f
               else
                 (t1.to_f - t0.to_f).abs
               end
          dts << (dt < 120.0 ? dt * 60.0 : dt)
        end
      else
        dts << (i.positive? ? dts[i - 1] : 0.0)
      end
    end
    dts
  end

  def relative_minutes(net, timesteps, ts_count)
    begin
      t0 = net.timestep_time(0).to_time
      (0...ts_count).map { |i| (net.timestep_time(i).to_time - t0) / 60.0 }
    rescue StandardError
      if timesteps.first.is_a?(DateTime)
        t0 = timesteps.first.to_time
        timesteps.map { |t| (t.to_time - t0) / 60.0 }
      elsif timesteps.first.is_a?(Numeric)
        t0 = timesteps.first.to_f
        timesteps.map { |t| (t.to_f - t0).abs / 60.0 }
      else
        (0...ts_count).to_a.map(&:to_f)
      end
    end
  end

  # Match ICM SQL: INTEGRAL(flow) x 60 -> m3 (OSS 0051 / TVD Summary convention).
  def integrate_flow_to_volume_m3(flow_series, dts_sec)
    integral = 0.0
    flow_series.each_with_index.map do |flow, i|
      dt_min = dts_sec[i].to_f / 60.0
      integral += flow.to_f * dt_min if dt_min > 0.0
      integral * 60.0
    end
  end

  def to_display_ls(flow_m3s_series)
    flow_m3s_series.map { |v| v.to_f * 1000.0 }
  end

  def show_graph(opts, net, timesteps, ts_count)
    begin
      WSApplication.graph(opts)
    rescue StandardError
      step_array = (0...ts_count).to_a
      interval_label = 'Timestep'
      begin
        dts = timestep_durations_seconds(net, timesteps, ts_count)
        step_seconds = dts[0]
        if step_seconds && step_seconds > 0
          if (step_seconds % 3600).abs < 1.0e-9
            hours = (step_seconds / 3600).round
            interval_label = "Timestep (#{hours} hour intervals)"
          elsif (step_seconds % 60).abs < 1.0e-9
            mins = (step_seconds / 60).round
            interval_label = "Timestep (#{mins} minute intervals)"
          else
            interval_label = "Timestep (#{step_seconds.round(2)} second intervals)"
          end
        end
      rescue StandardError
        nil
      end
      opts['Traces'].each { |tr| tr['XArray'] = step_array }
      opts['IsTime'] = false
      opts['XAxisLabel'] = interval_label
      WSApplication.graph(opts)
    end
  end

  def build_trace(title, colour, x_array, y_array)
    {
      'Title' => title,
      'TraceColour' => colour,
      'LineType' => 'Solid',
      'Marker' => 'None',
      'XArray' => x_array,
      'YArray' => y_array
    }
  end

  def show_series_graph(title, y_label, net, timesteps, ts_count, traces)
    opts = {
      'YAxisLabel' => y_label,
      'XAxisLabel' => 'Time',
      'IsTime' => true,
      'Traces' => traces,
      'WindowTitle' => title,
      'GraphTitle' => title
    }
    show_graph(opts, net, timesteps, ts_count)
  end

  def csv_escape(val)
    s = val.to_s
    return s unless s.include?(',') || s.include?('"') || s.include?("\n")
    '"' + s.gsub('"', '""') + '"'
  end

  def write_csv(path, headers, rows)
    FileUtils.mkdir_p(File.dirname(path))
    lines = [headers.join(',')]
    rows.each { |row| lines << row.map { |v| csv_escape(v) }.join(',') }
    File.write(path, lines.join("\n") + "\n", mode: 'w')
  end

  subs = objects_in_scope(net, 'hw_subcatchment')
  if subs.empty?
    WSApplication.message_box('No subcatchments found in the network.', 'OK', 'Information', false)
    throw :stop
  end

  nodes = objects_in_scope(net, 'hw_node')
  lost_nodes = nodes.select { |n| n['flood_type'].to_s.downcase == 'lost' }

  sub_scope = net.row_objects_selection('hw_subcatchment').empty? ? "all #{subs.size} subcatchments" : "#{subs.size} selected subcatchments"
  node_scope = net.row_objects_selection('hw_node').empty? ? "all #{nodes.size} nodes" : "#{nodes.size} selected nodes"

  link_candidates = net.row_objects_selection('_links')
  link_candidates = net.row_objects('_links') if link_candidates.empty?

  outfall_links = []
  link_candidates.each do |lk|
    dn = lk.ds_node
    next if dn.nil?
    outfall_links << lk if dn['node_type'].to_s.downcase == 'outfall'
  end

  dts_sec = timestep_durations_seconds(net, timesteps, ts_count)
  ts_rel = relative_minutes(net, timesteps, ts_count)

  sub_fields = [
    ['qtrade', 'Trade flow (qtrade)', WSApplication.colour(180, 100, 0)],
    ['qfoul',  'Foul flow (qfoul)',   WSApplication.colour(160, 0, 160)],
    ['qrdii',  'RDII (qrdii)',        WSApplication.colour(0, 160, 160)],
    ['qcatch', 'Total outflow ref (qcatch)', WSApplication.colour(0, 0, 0)]
  ]

  series = {}
  sub_fields.each do |name, title, colour|
    vals = sum_series(subs, name, ts_count)
    next if vals.nil?
    series[name] = {
      'title' => title,
      'colour' => colour,
      'inst' => vals,
      'cum' => integrate_flow_to_volume_m3(vals, dts_sec)
    }
  end

  flood_positive = sum_positive_series(nodes, 'floodvolume', ts_count)
  flood_all = sum_series(nodes, 'floodvolume', ts_count)
  lost_total = sum_positive_series(lost_nodes, 'flvol', ts_count)
  outfall_inst = sum_series(outfall_links, 'ds_flow', ts_count)
  outfall_cum = integrate_flow_to_volume_m3(outfall_inst, dts_sec)

  if series.empty? && flood_positive.all? { |v| v.abs < 1.0e-12 } && outfall_inst.all? { |v| v.abs < 1.0e-12 }
    WSApplication.message_box('No time series found for the objects in scope.', 'OK', 'Information', false)
    throw :stop
  end

  series_inst_ls = {}
  series.each { |name, s| series_inst_ls[name] = to_display_ls(s['inst']) }
  outfall_inst_ls = to_display_ls(outfall_inst)

  csv_path = 'C:\\Temp\\simulation_summary.csv'
  csv_rows = []
  (0...ts_count).each do |i|
    three = 0.0
    if series.key?('qtrade') && series.key?('qfoul') && series.key?('qrdii')
      three = series_inst_ls['qtrade'][i] + series_inst_ls['qfoul'][i] + series_inst_ls['qrdii'][i]
    end
    delta = series.key?('qcatch') ? series_inst_ls['qcatch'][i] - three : nil
    csv_rows << [
      i + 1,
      ts_rel[i].round(4),
      series['qtrade'] ? series_inst_ls['qtrade'][i].round(6) : nil,
      series['qfoul'] ? series_inst_ls['qfoul'][i].round(6) : nil,
      series['qrdii'] ? series_inst_ls['qrdii'][i].round(6) : nil,
      series['qcatch'] ? series_inst_ls['qcatch'][i].round(6) : nil,
      delta ? delta.round(6) : nil,
      series['qtrade'] ? series['qtrade']['cum'][i].round(6) : nil,
      series['qfoul'] ? series['qfoul']['cum'][i].round(6) : nil,
      series['qrdii'] ? series['qrdii']['cum'][i].round(6) : nil,
      series['qcatch'] ? series['qcatch']['cum'][i].round(6) : nil,
      flood_positive[i].round(6),
      flood_all[i].round(6),
      lost_total[i].round(6),
      outfall_inst_ls[i].round(6),
      outfall_cum[i].round(6)
    ]
  end

  headers = [
    'timestep', 'rel_minutes',
    'qtrade_ls', 'qfoul_ls', 'qrdii_ls', 'qcatch_ls', 'delta_ls',
    'qtrade_m3', 'qfoul_m3', 'qrdii_m3', 'qcatch_m3',
    'flood_positive_m3', 'flood_all_m3', 'lost_m3', 'outfall_ls', 'outfall_m3'
  ]
  write_csv(csv_path, headers, csv_rows)

  unless series.empty?
    overlay = series.values.map { |s| build_trace(s['title'], s['colour'], timesteps, to_display_ls(s['inst'])) }
    show_series_graph("Wastewater/RDII totals (instantaneous) - #{sub_scope}", 'Flow (L/s)', net, timesteps, ts_count, overlay)

    cumul = series.values.map { |s| build_trace(s['title'], s['colour'], timesteps, s['cum']) }
    show_series_graph("Wastewater/RDII totals (cumulative) - #{sub_scope}", 'Volume (m3)', net, timesteps, ts_count, cumul)

    if series.key?('qtrade') && series.key?('qfoul') && series.key?('qrdii') && series.key?('qcatch')
      delta_inst = Array.new(ts_count, 0.0)
      ts_count.times do |i|
        delta_inst[i] = series['qcatch']['inst'][i] - series['qtrade']['inst'][i] - series['qfoul']['inst'][i] - series['qrdii']['inst'][i]
      end
      show_series_graph(
        "QCATCH minus QTRADE+QFOUL+QRDII - #{sub_scope}",
        'Flow (L/s)',
        net,
        timesteps,
        ts_count,
        [build_trace('QCATCH minus three-flow (informational)', WSApplication.colour(120, 120, 120), timesteps, to_display_ls(delta_inst))]
      )
    end
  end

  flood_traces = [
    build_trace('Positive flood storage (floodvolume > 0)', WSApplication.colour(200, 80, 0), timesteps, flood_positive),
    build_trace('Total lost volume (flvol, lost nodes)', WSApplication.colour(120, 0, 0), timesteps, lost_total)
  ]
  show_series_graph("Node flood storage and lost volume - #{node_scope}", 'Volume (m3)', net, timesteps, ts_count, flood_traces)

  show_series_graph(
    "Total floodvolume (all nodes) - #{node_scope}",
    'Volume (m3)',
    net,
    timesteps,
    ts_count,
    [build_trace('Total floodvolume (all)', WSApplication.colour(0, 100, 200), timesteps, flood_all)]
  )

  show_series_graph(
    "Outfall discharge (instantaneous) - #{outfall_links.size} outfall link(s)",
    'Flow (L/s)',
    net,
    timesteps,
    ts_count,
    [build_trace('Outfall discharge (ds_flow)', WSApplication.colour(0, 0, 180), timesteps, to_display_ls(outfall_inst))]
  )

  show_series_graph(
    "Outfall discharge (cumulative) - #{outfall_links.size} outfall link(s)",
    'Volume (m3)',
    net,
    timesteps,
    ts_count,
    [build_trace('Outfall discharge (ds_flow)', WSApplication.colour(0, 0, 180), timesteps, outfall_cum)]
  )

  WSApplication.message_box(
    "Graphs opened.\n\nCSV written to:\n#{csv_path}\n\n#{ts_count} timesteps, one row per timestep.\n\nCumulative volumes use INTEGRAL x 60.",
    'OK',
    'Information',
    false
  )
end
