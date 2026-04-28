# Total Outflow Breakdown: overlay and cumulative graphs for a selected subcatchment.
# Run from ICM UI with one subcatchment selected and results loaded.
require 'date'
catch(:stop) do

net = WSApplication.current_network
selected = []
net.each_selected { |sel| selected << sel }

unless selected.size == 1
  msg = selected.empty? ? 'Please select one subcatchment.' : 'Please select only one subcatchment.'
  WSApplication.message_box(msg, 'OK', 'Information', false)
  throw :stop
end

sel = selected.first
ro = net.row_object('_subcatchments', sel.id)
if ro.nil?
  WSApplication.message_box("Object '#{sel.id}' is not a subcatchment.", 'OK', 'Stop', false)
  throw :stop
end

timesteps = net.list_timesteps
if timesteps.nil? || timesteps.count.zero?
  WSApplication.message_box('No timesteps found. Run a simulation and open results.', 'OK', 'Information', false)
  throw :stop
end

ts_count = timesteps.count

def fetch_series_values(ro, field_name, ts_count)
  vals = []

  begin
    res = ro.results(field_name)
    res.each { |v| vals << v.to_f } unless res.nil?
  rescue StandardError
    vals = []
  end

  if field_name == 'qbase'
    begin
      fixed_val = ro['base_flow']
      vals = Array.new(ts_count, fixed_val.to_f) unless fixed_val.nil?
    rescue StandardError
      nil
    end
  elsif vals.size == 1
    vals = Array.new(ts_count, vals[0])
  end

  return nil if vals.size != ts_count

  vals
end

def zero_series?(vals)
  vals.each do |v|
    return false if v.abs > 1.0e-12
  end
  true
end

fields = [
  ['qcatch',      'Total outflow (qcatch)',        WSApplication.colour(0, 0, 0)],
  ['qbase',       'Baseflow (qbase)',              WSApplication.colour(100, 100, 100)],
  ['qtrade',      'Trade flow (qtrade)',            WSApplication.colour(180, 100, 0)],
  ['qfoul',       'Foul flow (qfoul)',              WSApplication.colour(160, 0, 160)],
  ['qrdii',       'RDII (qrdii)',                   WSApplication.colour(0, 160, 160)],
  ['qground',     'Ground store inflow (qground)',  WSApplication.colour(0, 120, 200)],
  ['qsoil',       'Soil store inflow (qsoil)',      WSApplication.colour(220, 100, 0)],
  ['qsurf01',     'Surface runoff 1 (qsurf01)',     WSApplication.colour(200, 0, 0)],
  ['qsurf02',     'Surface runoff 2 (qsurf02)',     WSApplication.colour(220, 60, 60)],
  ['qsurf03',     'Surface runoff 3 (qsurf03)',     WSApplication.colour(240, 100, 100)],
  ['qsurf04',     'Surface runoff 4 (qsurf04)',     WSApplication.colour(255, 140, 140)],
  ['qsurf05',     'Surface runoff 5 (qsurf05)',     WSApplication.colour(0, 120, 0)],
  ['qsurf06',     'Surface runoff 6 (qsurf06)',     WSApplication.colour(60, 160, 60)],
  ['qsurf07',     'Surface runoff 7 (qsurf07)',     WSApplication.colour(100, 180, 100)],
  ['qsurf08',     'Surface runoff 8 (qsurf08)',     WSApplication.colour(140, 200, 140)],
  ['qsurf09',     'Surface runoff 9 (qsurf09)',     WSApplication.colour(0, 0, 180)],
  ['qsurf10',     'Surface runoff 10 (qsurf10)',    WSApplication.colour(60, 60, 200)],
  ['qsurf11',     'Surface runoff 11 (qsurf11)',    WSApplication.colour(100, 100, 220)],
  ['qsurf12',     'Surface runoff 12 (qsurf12)',    WSApplication.colour(140, 140, 240)],
  ['q_lid_in',    'LID inflow (q_lid_in)',          WSApplication.colour(180, 0, 180)],
  ['q_lid_out',   'LID outflow (q_lid_out)',        WSApplication.colour(200, 80, 200)],
  ['q_lid_drain', 'LID drain (q_lid_drain)',        WSApplication.colour(220, 120, 220)],
  ['q_exceedance','Exceedance (q_exceedance)',      WSApplication.colour(200, 200, 0)]
]

# Fetch results once for all fields, preserving field order
available_series = []
fields.each do |name, title, colour|
  vals = fetch_series_values(ro, name, ts_count)
  next if vals.nil?
  next if name != 'qcatch' && zero_series?(vals)
  available_series << { 'name' => name, 'title' => title, 'colour' => colour, 'vals' => vals }
end

if available_series.empty?
  WSApplication.message_box("No time series for subcatchment '#{sel.id}'. Load simulation results.", 'OK', 'Information', false)
  throw :stop
end

# Helper: try IsTime graph first; for design storms, fall back to timestep index
def show_graph(opts, timesteps, ts_count)
  begin
    WSApplication.graph(opts)
  rescue StandardError
    step_array = (0...ts_count).to_a
    interval_label = 'Timestep'
    begin
      if ts_count > 1
        t0 = timesteps[0].to_f
        t1 = timesteps[1].to_f
        step_seconds = (t1 - t0).abs
        if step_seconds > 0
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

# --- Graph 1: Overlay (each component as an independent trace) ---
overlay_traces = []
available_series.each do |s|
  overlay_traces << { 'Title' => s['title'], 'TraceColour' => s['colour'],
                      'LineType' => 'Solid', 'Marker' => 'None',
                      'XArray' => timesteps, 'YArray' => s['vals'] }
end

opts = { 'YAxisLabel' => 'Flow', 'XAxisLabel' => 'Time', 'IsTime' => true, 'Traces' => overlay_traces }
opts['WindowTitle'] = opts['GraphTitle'] = "Total outflow breakdown - #{sel.id}"
show_graph(opts, timesteps, ts_count)

# --- Graph 2: Cumulative over time (each line shown individually) ---
cumul_traces = []

available_series.each do |s|
  running_total = 0.0
  cumul_vals = []
  s['vals'].each do |v|
    running_total += v
    cumul_vals << running_total
  end

  cumul_traces << { 'Title' => s['title'], 'TraceColour' => s['colour'],
                    'LineType' => 'Solid', 'Marker' => 'None',
                    'XArray' => timesteps, 'YArray' => cumul_vals }
end

opts = { 'YAxisLabel' => 'Flow', 'XAxisLabel' => 'Time', 'IsTime' => true, 'Traces' => cumul_traces }
opts['WindowTitle'] = opts['GraphTitle'] = "Total outflow breakdown (cumulative over time) - #{sel.id}"
show_graph(opts, timesteps, ts_count)

end
