# =============================================================================
# Drain-Down Time Calculator for InfoWorks WS Pro
# =============================================================================
#
# Calculates the gravity drain-down time for an isolated section of water
# distribution network, modelling the coupled hydraulics of:
#   - Water draining through a washout/hydrant valve (orifice equation)
#   - Air entering through ARV nodes to relieve sub-atmospheric pressure
#
# The script uses a quasi-steady time-step simulation with a bisection solver
# to find the pressure deficit (vacuum) at each step such that the air
# admission rate through the ARV(s) equals the water drain rate.
#
# Usage:
#   1. Select one or more pipes in the section to drain
#   2. Run this script from the InfoWorks WS Pro UI
#   3. Follow prompts to confirm washout hydrant, ARV nodes, and enter
#      hydraulic properties for the valves
#   4. A CSV time-series and summary message box are produced
#
# ARV nodes are identified by: user_text_1 = 'ARV' on wn_node
# Washout candidates are wn_hydrant objects in the isolated section
#
# Physics assumptions:
#   - Orifice equation for water flow (incompressible)
#   - Orifice equation for air flow (incompressible; valid for delta < ~0.8 m)
#   - Multiple ARVs act in parallel (combined orifice area)
#   - Volume-elevation curve built from pipe diameter, length, and node z
#   - Plug-flow drainage assumed (no partial-full pipe HGL modelling)
# =============================================================================

require 'date'

# =============================================================================
# PHYSICS CONSTANTS
# =============================================================================

GRAVITY = 9.81    # m/s^2
RHO_W   = 1000.0  # kg/m^3 — water density
RHO_A   = 1.2     # kg/m^3 — air density at ~20 deg C, sea level

# =============================================================================
# VOLUME-ELEVATION HELPERS
# =============================================================================

# Build array of pipe segments: [z_low, z_high, v_pipe]
# Each segment describes the elevation range and total volume of one pipe.
def build_segments(pipes)
  segments = []
  pipes.each do |pipe|
    d_mm = pipe['diameter'].to_f
    len  = pipe['length'].to_f
    next if d_mm <= 0 || len <= 0

    z_us = nil
    z_ds = nil
    begin; z_us = pipe.us_node['z'].to_f; rescue; end
    begin; z_ds = pipe.ds_node['z'].to_f; rescue; end
    next if z_us.nil? || z_ds.nil?

    d_m    = d_mm / 1000.0
    v_pipe = Math::PI / 4.0 * d_m**2 * len
    z_low  = [z_us, z_ds].min
    z_high = [z_us, z_ds].max
    # Near-horizontal pipes get a small artificial slope so the segment is valid
    z_high = z_low + 0.001 if (z_high - z_low) < 0.001

    segments << [z_low, z_high, v_pipe]
  end
  segments
end

# Total volume of all pipe segments
def total_volume(segments)
  segments.inject(0.0) { |sum, s| sum + s[2] }
end

# Volume of water in network when the air-water interface is at elevation z
def volume_at_elevation(segments, z)
  total = 0.0
  segments.each do |z_low, z_high, v_pipe|
    if z >= z_high
      total += v_pipe
    elsif z > z_low
      total += v_pipe * (z - z_low) / (z_high - z_low)
    end
  end
  total
end

# Find water-surface elevation corresponding to a remaining volume (bisection)
def elevation_from_volume(segments, v_remaining, z_min, z_max)
  return z_min if v_remaining <= 0.0
  v_tot = total_volume(segments)
  return z_max if v_remaining >= v_tot

  lo = z_min
  hi = z_max
  50.times do
    mid = (lo + hi) / 2.0
    volume_at_elevation(segments, mid) < v_remaining ? lo = mid : hi = mid
    break if (hi - lo) < 0.00005
  end
  (lo + hi) / 2.0
end

# =============================================================================
# BISECTION SOLVER — pressure deficit delta (m water head)
# =============================================================================
#
# At quasi-steady state within each time step:
#   Q_w = cd_w * A_w       * sqrt(2g * (h - delta))          [water out]
#   Q_a = cd_a * A_a_total * sqrt(2 * delta * rho_w * g / rho_a)  [air in]
#   Q_w = Q_a  (volume continuity)
#
# Finds delta in [0, h] that satisfies the equality.
# Returns 0 if the ARV can supply sufficient air with no vacuum build-up.
def solve_delta(h, cd_w, a_w, cd_a, a_a_total)
  return 0.0 if h <= 0.0

  f = lambda do |d|
    q_w = cd_w * a_w       * Math.sqrt(2.0 * GRAVITY * [h - d, 0.0].max)
    q_a = cd_a * a_a_total * Math.sqrt(2.0 * [d, 0.0].max * RHO_W * GRAVITY / RHO_A)
    q_w - q_a
  end

  # f(0)  > 0 : washout wants to drain faster than ARV can supply air
  # f(h)  < 0 : ARV more than sufficient (full vacuum stops washout first)
  return 0.0 if f.call(0.0) <= 0.0  # ARV more than adequate — no vacuum
  return h   if f.call(h)   >= 0.0  # Pathological: full vacuum, no flow

  lo = 0.0
  hi = h
  50.times do
    mid = (lo + hi) / 2.0
    f.call(mid) > 0.0 ? lo = mid : hi = mid
    break if (hi - lo) < 1.0e-7
  end
  (lo + hi) / 2.0
end

# =============================================================================
# MAIN
# =============================================================================

begin
  net = WSApplication.current_network
  if net.nil?
    WSApplication.message_box('No network is currently open.', 'ok', 'stop', false)
    exit
  end

  puts "Drain-Down Time Calculator"
  puts "=========================="

  # ---------------------------------------------------------------------------
  # PHASE 1 — Isolation trace from selected pipes
  # ---------------------------------------------------------------------------

  selected_pipes = net.row_objects_selection('wn_pipe')
  if selected_pipes.empty?
    WSApplication.message_box(
      'No pipes selected.' + "\n\n" +
      'Please select at least one pipe in the section to drain, then re-run.',
      'ok', '!', false
    )
    exit
  end

  puts "Selected #{selected_pipes.length} pipe(s). Running isolation trace..."

  isolate_list       = WSNetSelectionList.new
  isolate_list.from_row_objects(selected_pipes)
  closed_links       = WSNetSelectionList.new
  isolated_objects   = WSNetSelectionList.new
  isolated_customers = WSNetSelectionList.new

  net.isolation_trace(
    isolate_list, false, false, nil,
    closed_links, isolated_objects, isolated_customers, nil, nil
  )

  isolated_ros = isolated_objects.to_row_objects(net)
  if isolated_ros.empty?
    WSApplication.message_box(
      'Isolation trace returned no objects. Check your pipe selection.',
      'ok', '!', false
    )
    exit
  end

  # Collect isolated pipes and build set of node IDs
  isolated_pipes    = isolated_ros.select { |ro| ro.table == 'wn_pipe' }
  isolated_node_ids = {}
  isolated_ros.each { |ro| isolated_node_ids[ro.id.to_s] = true if ro.table == 'wn_node' }

  # Ensure pipe endpoint node IDs are captured (fallback if nodes not in result)
  isolated_pipes.each do |p|
    begin; isolated_node_ids[p['us_node_id'].to_s] = true; rescue; end
    begin; isolated_node_ids[p['ds_node_id'].to_s] = true; rescue; end
  end

  boundary_ids = closed_links.to_row_objects(net).map(&:id)
  puts "  Isolated: #{isolated_pipes.length} pipes, #{isolated_node_ids.length} nodes"
  puts "  Valves to close: #{boundary_ids.join(', ')}" unless boundary_ids.empty?

  # ---------------------------------------------------------------------------
  # PHASE 2 — Find washout hydrants and ARV-flagged nodes
  # ---------------------------------------------------------------------------

  washout_candidates = []
  net.row_objects('wn_hydrant').each do |h|
    washout_candidates << h if isolated_node_ids.key?(h['node_id'].to_s)
  end

  if washout_candidates.empty?
    WSApplication.message_box(
      'No hydrant/washout objects found in the isolated section.' + "\n\n" +
      'Washout candidates must be modelled as wn_hydrant objects connected to ' +
      'nodes within the selected pipe section.',
      'ok', '!', false
    )
    exit
  end

  arv_candidates = []
  begin
    net.clear_selection
    net.run_SQL('wn_node', "SELECT WHERE user_text_1 = 'ARV'")
    net.row_objects_selection('wn_node').each do |n|
      arv_candidates << n if isolated_node_ids.key?(n.id.to_s)
    end
  rescue => e
    puts "WARNING: Could not query user_text_1: #{e.message}"
  ensure
    net.clear_selection
  end

  if arv_candidates.empty?
    WSApplication.message_box(
      'No ARV-enabled nodes found in the isolated section.' + "\n\n" +
      'ARV locations must be flagged with user_text_1 = \'ARV\' on wn_node.',
      'ok', '!', false
    )
    exit
  end

  puts "  #{washout_candidates.length} washout hydrant(s) found"
  puts "  #{arv_candidates.length} ARV node(s) found"

  # ---------------------------------------------------------------------------
  # Select washout hydrant (prompt if multiple)
  # ---------------------------------------------------------------------------

  selected_washout = nil

  if washout_candidates.length == 1
    selected_washout = washout_candidates.first
  else
    sorted_washouts = washout_candidates.sort_by { |h| h['ground_level'].to_f }
    layout = sorted_washouts.map do |h|
      gl = h['ground_level'].to_f.round(2)
      ["Hydrant  #{h.id}  (ground level = #{gl} m)", 'BOOLEAN', false]
    end
    resp = WSApplication.prompt('Select Washout Hydrant  (choose exactly one)', layout, false)
    exit if resp.nil?

    chosen = []
    resp.each_with_index { |v, i| chosen << i if v == true }
    if chosen.length != 1
      WSApplication.message_box('Please select exactly one washout hydrant.', 'ok', '!', false)
      exit
    end
    selected_washout = sorted_washouts[chosen.first]
  end

  # Washout elevation: use pipe invert (z) at the hydrant's connected node
  washout_node = net.row_object('wn_node', selected_washout['node_id'].to_s)
  z_washout = washout_node ? washout_node['z'].to_f : selected_washout['ground_level'].to_f
  puts "  Washout: #{selected_washout.id}  node=#{selected_washout['node_id']}  z=#{z_washout.round(3)} m"

  # ---------------------------------------------------------------------------
  # Select ARV nodes — multi-select, sorted highest to lowest elevation
  # ---------------------------------------------------------------------------

  selected_arvs = []

  if arv_candidates.length == 1
    selected_arvs = arv_candidates.dup
  else
    arv_sorted = arv_candidates.sort_by { |n| -n['z'].to_f }
    layout = arv_sorted.map do |n|
      z = n['z'].to_f.round(2)
      ["Node  #{n.id}  (z = #{z} m)", 'BOOLEAN', true]
    end
    resp = WSApplication.prompt(
      'Select ARV Nodes to Include  (sorted highest elevation first)',
      layout, false
    )
    exit if resp.nil?

    resp.each_with_index { |v, i| selected_arvs << arv_sorted[i] if v == true }

    if selected_arvs.empty?
      WSApplication.message_box('No ARV nodes selected. Calculation cancelled.', 'ok', '!', false)
      exit
    end
  end

  selected_arvs.sort_by! { |n| -n['z'].to_f }
  selected_arvs.each { |n| puts "  ARV: #{n.id}  z=#{n['z'].to_f.round(3)} m" }

  # ---------------------------------------------------------------------------
  # PHASE 3 — Hydraulic properties prompt
  # ---------------------------------------------------------------------------

  params = WSApplication.prompt(
    'Drain-Down Hydraulic Parameters',
    [
      ['Washout valve diameter (mm)', 'NUMBER', 100],
      ['Washout valve Cd',            'NUMBER', 0.61],
      ['ARV orifice diameter (mm)',   'NUMBER', 25],
      ['ARV Cd',                      'NUMBER', 0.61],
      ['Simulation time step (s)',    'NUMBER', 10],
    ],
    false
  )
  exit if params.nil?

  washout_d_mm = params[0].to_f
  washout_cd   = params[1].to_f
  arv_d_mm     = params[2].to_f
  arv_cd       = params[3].to_f
  dt           = params[4].to_f

  if [washout_d_mm, washout_cd, arv_d_mm, arv_cd, dt].any? { |v| v <= 0 }
    WSApplication.message_box('All parameter values must be greater than zero.', 'ok', '!', false)
    exit
  end

  # Orifice areas in m^2
  a_w      = Math::PI / 4.0 * (washout_d_mm / 1000.0)**2
  a_a_each = Math::PI / 4.0 * (arv_d_mm    / 1000.0)**2
  # All selected ARVs act in parallel — sum their orifice areas
  a_a_total = a_a_each * selected_arvs.length

  puts "\nWashout: D=#{washout_d_mm.round(0)}mm  Cd=#{washout_cd}  A=#{(a_w * 1.0e6).round(2)} mm^2"
  puts "ARV:     D=#{arv_d_mm.round(0)}mm  Cd=#{arv_cd}  x#{selected_arvs.length}  A_total=#{(a_a_total * 1.0e6).round(2)} mm^2"
  puts "dt=#{dt} s"

  # ---------------------------------------------------------------------------
  # PHASE 4 — Build volume-elevation curve from pipe geometry
  # ---------------------------------------------------------------------------

  segments = build_segments(isolated_pipes)

  if segments.empty?
    WSApplication.message_box(
      'Could not build volume-elevation curve.' + "\n\n" +
      'Check that isolated pipes have valid diameter, length, and node z elevations.',
      'ok', '!', false
    )
    exit
  end

  v_total = total_volume(segments)
  z_min   = segments.map { |s| s[0] }.min
  z_max   = segments.map { |s| s[1] }.max

  puts "\nPipe network: #{isolated_pipes.length} pipes"
  puts "  Total volume : #{(v_total * 1000.0).round(0)} L  (#{v_total.round(4)} m^3)"
  puts "  Elev range   : #{z_min.round(3)} m  to  #{z_max.round(3)} m"
  puts "  Washout z    : #{z_washout.round(3)} m"
  puts "  Top ARV z    : #{selected_arvs.first['z'].to_f.round(3)} m"

  if z_washout >= z_max
    WSApplication.message_box(
      "The washout elevation (#{z_washout.round(2)} m) is at or above the highest pipe " +
      "invert (#{z_max.round(2)} m)." + "\n\n" +
      'No gravity drainage is possible. Check the washout node elevation.',
      'ok', '!', false
    )
    exit
  end

  # ---------------------------------------------------------------------------
  # PHASE 5 — Quasi-steady time-step simulation
  # ---------------------------------------------------------------------------

  puts "\nRunning simulation..."

  v        = v_total
  t        = 0.0
  max_iter = 500_000

  # Record every N steps — targets ~2000 output rows regardless of dt
  target_rows  = 2000
  est_steps    = (v_total / (washout_cd * a_w * Math.sqrt(2.0 * GRAVITY * (z_max - z_washout)) * dt * 0.5)).ceil
  record_every = [1, (est_steps / target_rows).floor].max

  results = [%w[time_s volume_m3 volume_pct water_surface_m effective_head_m
                flow_rate_Ls pressure_deficit_m pressure_deficit_kPa]]

  iter     = 0
  last_q_w = 0.0

  loop do
    iter += 1
    break if iter > max_iter

    # Current water-surface elevation from remaining volume
    z_w = elevation_from_volume(segments, v, z_min, z_max)

    # Driving head: water surface above washout outlet
    h = z_w - z_washout
    break if h < 0.001

    # Solve for pressure deficit delta
    # All selected ARVs contribute combined air admission area throughout
    delta = solve_delta(h, washout_cd, a_w, arv_cd, a_a_total)

    # Actual washout flow rate
    h_eff = [h - delta, 0.0].max
    q_w   = washout_cd * a_w * Math.sqrt(2.0 * GRAVITY * h_eff)
    last_q_w = q_w

    # Record time-series row
    if iter == 1 || (iter % record_every == 0) || q_w < 0.0001
      results << [
        t.round(1),
        v.round(5),
        (v / v_total * 100.0).round(2),
        z_w.round(4),
        h_eff.round(4),
        (q_w * 1000.0).round(5),
        delta.round(6),
        (delta * RHO_W * GRAVITY / 1000.0).round(5),
      ]
    end

    break if q_w < 0.0001 || v < 0.0001

    # Volume drained this step — adaptive cap prevents overshooting near empty
    dv = q_w * dt
    dv = [dv, v * 0.01].min
    v -= dv
    v  = 0.0 if v < 0.0
    t += dt
  end

  # Final row at t_drain
  results << [t.round(1), 0.0, 0.0, z_washout.round(4), 0.0, 0.0, 0.0, 0.0]

  drain_time_s   = t
  drain_time_min = t / 60.0
  drain_time_hr  = t / 3600.0

  data_rows       = results[1..]
  peak_flow_ls    = data_rows.map { |r| r[5].to_f }.max
  max_deficit_m   = data_rows.map { |r| r[6].to_f }.max
  max_deficit_kpa = max_deficit_m * RHO_W * GRAVITY / 1000.0

  puts "  Iterations    : #{iter}"
  puts "  Drain time    : #{drain_time_s.round(0)} s  (#{drain_time_min.round(1)} min)"
  puts "  Peak flow     : #{peak_flow_ls.round(3)} L/s"
  puts "  Max deficit   : #{max_deficit_m.round(4)} m head  (#{max_deficit_kpa.round(3)} kPa)"

  # ---------------------------------------------------------------------------
  # PHASE 6 — Interactive HTML dashboard and summary
  # ---------------------------------------------------------------------------

  require 'json'

  script_dir = begin
    File.dirname(WSApplication.script_file)
  rescue
    Dir.pwd
  end

  time_str = if drain_time_hr >= 1.0
    "#{drain_time_hr.round(2)} hours  (#{drain_time_min.round(0)} min)"
  else
    "#{drain_time_min.round(1)} minutes  (#{drain_time_s.round(0)} s)"
  end

  arv_list = selected_arvs.map { |n| "#{n.id} (z=#{n['z'].to_f.round(2)} m)" }.join(', ')

  # Build depth-vs-volume curve from pipe segments
  dv_steps = 200
  dv_elevations = (0..dv_steps).map { |i| z_min + (z_max - z_min) * i.to_f / dv_steps }
  dv_volumes = dv_elevations.map { |z| (volume_at_elevation(segments, z) * 1000.0).round(2) }
  dv_elevations = dv_elevations.map { |z| z.round(4) }

  # Time-series data (skip header row)
  ts_data = data_rows.map do |r|
    {
      t: r[0].to_f, vol: r[1].to_f, vol_pct: r[2].to_f,
      z_w: r[3].to_f, h_eff: r[4].to_f, q: r[5].to_f,
      deficit_m: r[6].to_f, deficit_kpa: r[7].to_f
    }
  end

  payload = {
    title: "Drain-Down Results",
    summary: {
      pipes: isolated_pipes.length,
      volume_L: (v_total * 1000.0).round(0),
      volume_m3: v_total.round(3),
      z_min: z_min.round(2), z_max: z_max.round(2),
      washout_id: selected_washout.id.to_s,
      z_washout: z_washout.round(2),
      arv_list: arv_list,
      washout_d_mm: washout_d_mm.round(0),
      washout_cd: washout_cd,
      arv_d_mm: arv_d_mm.round(0),
      arv_cd: arv_cd,
      arv_count: selected_arvs.length,
      drain_time: time_str,
      peak_flow_Ls: peak_flow_ls.round(2),
      max_deficit_m: max_deficit_m.round(3),
      max_deficit_kPa: max_deficit_kpa.round(2)
    },
    time: ts_data.map { |r| r[:t] },
    series: {
      volume_pct:     { label: 'Volume (%)',              unit: '%',    data: ts_data.map { |r| r[:vol_pct] } },
      volume_m3:      { label: 'Volume (m³)',             unit: 'm³',   data: ts_data.map { |r| r[:vol] } },
      water_surface:  { label: 'Water Surface (m)',       unit: 'm',    data: ts_data.map { |r| r[:z_w] } },
      effective_head: { label: 'Effective Head (m)',       unit: 'm',    data: ts_data.map { |r| r[:h_eff] } },
      flow_rate:      { label: 'Flow Rate (L/s)',         unit: 'L/s',  data: ts_data.map { |r| r[:q] } },
      deficit_m:      { label: 'Pressure Deficit (m)',    unit: 'm',    data: ts_data.map { |r| r[:deficit_m] } },
      deficit_kpa:    { label: 'Pressure Deficit (kPa)',  unit: 'kPa',  data: ts_data.map { |r| r[:deficit_kpa] } },
    },
    depth_volume: { elevations: dv_elevations, volumes_L: dv_volumes },
    csv_header: results.first,
    csv_rows: data_rows
  }

  html_path = File.join(script_dir, "drain_down_results.html")
  esc = payload[:title]

  html = <<~HTML
    <!doctype html><html><head><meta charset="utf-8">
    <title>#{esc}</title>
    <script src="https://cdn.plot.ly/plotly-2.30.0.min.js"></script>
    <style>
      *, *::before, *::after { box-sizing: border-box }
      body { font-family: Arial, sans-serif; margin: 0; padding: 16px 20px; background: #f0f2f5; color: #222 }
      h2 { margin: 0 0 6px; font-size: 1.2rem }
      .toolbar { display: flex; align-items: center; gap: 14px; margin-bottom: 12px; flex-wrap: wrap }
      .toolbar label { font-weight: 600; font-size: .88rem }
      .toolbar select { padding: 4px 8px; font-size: .88rem }
      .toolbar button { padding: 5px 12px; font-size: .82rem; cursor: pointer; border: 1px solid #aaa; border-radius: 4px; background: #fff }
      .toolbar button:hover { background: #e8e8e8 }
      .summary-box { background: #fff; border: 1px solid #ddd; border-radius: 6px; padding: 12px 16px; margin-bottom: 12px; font-size: .85rem; line-height: 1.6 }
      .summary-box b { color: #333 }
      .summary-box .val { font-family: monospace; color: #0057a8 }
      .chart-panel { background: #fff; border: 1px solid #ddd; border-radius: 6px; padding: 8px; margin-bottom: 12px }
      .chart-div { width: 100%; height: 400px }
      .two-col { display: grid; grid-template-columns: 1fr 1fr; gap: 12px }
      @media (max-width: 900px) { .two-col { grid-template-columns: 1fr } }
    </style></head><body>
    <h2 id="title"></h2>
    <div class="summary-box" id="summaryBox"></div>
    <div class="toolbar">
      <label>Output: <select id="seriesSelect"></select></label>
      <button id="csvBtn">Download CSV (all data)</button>
    </div>
    <div class="two-col">
      <div class="chart-panel"><div id="mainChart" class="chart-div"></div></div>
      <div class="chart-panel"><div id="dvChart" class="chart-div"></div></div>
    </div>
    <script>
    (function() {
      var P = #{JSON.generate(payload)};
      var S = P.summary;

      document.getElementById('title').textContent = P.title;

      var sb = document.getElementById('summaryBox');
      sb.innerHTML =
        '<b>Network:</b> ' + S.pipes + ' pipes &nbsp;|&nbsp; ' +
        'Volume: <span class="val">' + S.volume_L + ' L</span> (' + S.volume_m3 + ' m\\u00B3) &nbsp;|&nbsp; ' +
        'Elevation: <span class="val">' + S.z_min + '</span> to <span class="val">' + S.z_max + ' m</span><br>' +
        '<b>Washout:</b> ' + S.washout_id + ' at z = ' + S.z_washout + ' m &nbsp;|&nbsp; \\u00D8' + S.washout_d_mm + ' mm, Cd = ' + S.washout_cd + '<br>' +
        '<b>ARV:</b> ' + S.arv_list + ' &nbsp;|&nbsp; \\u00D8' + S.arv_d_mm + ' mm, Cd = ' + S.arv_cd + ', \\u00D7 ' + S.arv_count + '<br>' +
        '<b>Drain time:</b> <span class="val">' + S.drain_time + '</span> &nbsp;|&nbsp; ' +
        '<b>Peak flow:</b> <span class="val">' + S.peak_flow_Ls + ' L/s</span> &nbsp;|&nbsp; ' +
        '<b>Max deficit:</b> <span class="val">' + S.max_deficit_m + ' m</span> (' + S.max_deficit_kPa + ' kPa)';

      // Populate dropdown
      var sel = document.getElementById('seriesSelect');
      var keys = Object.keys(P.series);
      keys.forEach(function(k) {
        var opt = document.createElement('option');
        opt.value = k;
        opt.textContent = P.series[k].label;
        sel.appendChild(opt);
      });

      // Time axis in minutes
      var tMin = P.time.map(function(t) { return (t / 60.0); });
      var xLabel = 'Time (min)';

      function plotSeries(key) {
        var s = P.series[key];
        Plotly.react('mainChart', [{
          x: tMin, y: s.data, mode: 'lines',
          line: { color: '#0057a8', width: 2 },
          hovertemplate: '%{y:.3f} ' + s.unit + '<extra>%{x:.1f} min</extra>'
        }], {
          title: { text: s.label + ' vs Time', font: { size: 14 } },
          margin: { t: 44, r: 24, b: 50, l: 64 },
          xaxis: { title: xLabel },
          yaxis: { title: s.label },
          hovermode: 'x unified'
        }, { responsive: true });
      }

      sel.addEventListener('change', function() { plotSeries(this.value); });
      plotSeries(keys[0]);

      // Depth vs Volume curve
      Plotly.newPlot('dvChart', [{
        x: P.depth_volume.volumes_L,
        y: P.depth_volume.elevations,
        mode: 'lines',
        line: { color: '#4488CC', width: 2 },
        hovertemplate: '%{x:.1f} L at %{y:.2f} m<extra></extra>'
      }], {
        title: { text: 'Depth vs Volume Curve', font: { size: 14 } },
        margin: { t: 44, r: 24, b: 50, l: 64 },
        xaxis: { title: 'Volume (L)' },
        yaxis: { title: 'Elevation (m)' },
        hovermode: 'closest'
      }, { responsive: true });

      // CSV download — all columns for all time steps
      document.getElementById('csvBtn').addEventListener('click', function() {
        var hdr = P.csv_header.join(',');
        var lines = [hdr];
        P.csv_rows.forEach(function(row) { lines.push(row.join(',')); });
        var blob = new Blob([lines.join('\\n')], { type: 'text/csv;charset=utf-8;' });
        var a = document.createElement('a');
        a.href = URL.createObjectURL(blob);
        a.download = 'drain_down_results.csv';
        a.click();
        URL.revokeObjectURL(a.href);
      });
    })();
    </script></body></html>
  HTML

  File.write(html_path, html)
  puts "  HTML dashboard: #{html_path}"

  begin
    system("start \"\" \"#{html_path}\"")
  rescue StandardError => e
    puts "Launch failed: #{e.message}"
  end

  arv_list_msg = selected_arvs.map { |n| "#{n.id} (z=#{n['z'].to_f.round(2)} m)" }.join(', ')

  summary =
    "DRAIN-DOWN CALCULATION COMPLETE\n" +
    "================================\n\n" +
    "Network section:\n" +
    "  Pipes:         #{isolated_pipes.length}\n" +
    "  Total volume:  #{(v_total * 1000.0).round(0)} L  (#{v_total.round(3)} m^3)\n" +
    "  Elevation:     #{z_min.round(2)} m  to  #{z_max.round(2)} m\n\n" +
    "Washout:  #{selected_washout.id}  at z = #{z_washout.round(2)} m\n" +
    "ARV(s):   #{arv_list_msg}\n\n" +
    "RESULTS:\n" +
    "  Estimated drain time:    #{time_str}\n" +
    "  Peak flow rate:          #{peak_flow_ls.round(2)} L/s\n" +
    "  Max pressure deficit:    #{max_deficit_m.round(3)} m head  (#{max_deficit_kpa.round(2)} kPa)\n\n" +
    "Dashboard: #{html_path}"

  WSApplication.message_box(summary, 'ok', 'information', false)

rescue => e
  puts "ERROR: #{e.message}"
  puts e.backtrace.join("\n")
  begin
    WSApplication.message_box(
      "Drain-Down Calculator Error:\n\n#{e.message}",
      'ok', 'stop', false
    )
  rescue
  end
end
