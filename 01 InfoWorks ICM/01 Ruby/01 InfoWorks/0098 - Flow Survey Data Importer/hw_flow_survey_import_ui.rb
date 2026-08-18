# hw_flow_survey_import_ui.rb — UI-mode script
# Runs inside InfoWorks ICM UI. Parses .std files, generates ICM-format CSVs,
# then launches the Exchange script via system() for database import.
#
# Usage: Open in ICM > Network > Run Ruby Script (UI mode)

# ─── STD PARSER ──────────────────────────────────────────────────────────────

def decode_d10(s)
  # D10 = YYMMDDHHMM → Time
  s = s.strip
  yy = s[0, 2].to_i
  mm = s[2, 2].to_i
  dd = s[4, 2].to_i
  hh = s[6, 2].to_i
  mi = s[8, 2].to_i
  year = (yy < 70) ? 2000 + yy : 1900 + yy
  Time.new(year, mm, dd, hh, mi, 0)
end

def format_ts(t)
  # → "dd/mm/yyyy hh:mm:ss"
  sprintf('%02d/%02d/%04d %02d:%02d:%02d', t.day, t.month, t.year, t.hour, t.min, t.sec)
end

class StdSensor
  attr_accessor :id, :sensor_type, :filename, :height, :min_vel
  attr_accessor :manhole_no, :logger_type
  attr_accessor :start_time, :end_time, :interval_min
  attr_accessor :location, :o_ant_rain, :ant_rain_days
  attr_accessor :flow, :depth, :velocity, :intensity

  def initialize
    @flow = []
    @depth = []
    @velocity = []
    @intensity = []
    @ant_rain_days = []
  end

  def record_count
    ((end_time - start_time) / (interval_min * 60)).to_i + 1
  end

  def interval_sec
    interval_min * 60
  end
end

def parse_std_file(filepath)
  sensor = StdSensor.new
  sensor.filename = File.basename(filepath)
  prefix = sensor.filename[0, 1].upcase

  case prefix
  when 'F' then sensor.sensor_type = :flow
  when 'D' then sensor.sensor_type = :depth
  when 'R' then sensor.sensor_type = :rain
  else
    return nil
  end

  lines = File.readlines(filepath)

  # Parse header for IDENTIFIER
  lines.each do |line|
    if line =~ /\*\*IDENTIFIER:\s+\d+,(.*)/
      sensor.id = $1.strip
      break
    end
  end

  # Find CSTART / CEND
  cstart_idx = nil
  cend_idx = nil
  lines.each_with_index do |line, i|
    if line.strip == '*CSTART'
      cstart_idx = i
    elsif line.strip == '*CEND'
      cend_idx = i
      break
    end
  end

  return nil unless cstart_idx && cend_idx

  const_lines = []
  (cstart_idx + 1).upto(cend_idx - 1) { |i| const_lines << lines[i] }

  if sensor.sensor_type == :rain
    # Rain: line1=location+ant_rain, line2=days1-15, line3=days16-30, line4=start/end/interval
    loc_line = const_lines[0]
    sensor.location = loc_line[0, 13].strip
    sensor.o_ant_rain = loc_line[15, 5].strip.to_f

    # Days 1-15
    day_line1 = const_lines[1]
    (0...15).each { |j| sensor.ant_rain_days << day_line1[j * 5, 5].strip.to_f }
    # Days 16-30
    day_line2 = const_lines[2]
    (0...15).each { |j| sensor.ant_rain_days << day_line2[j * 5, 5].strip.to_f }

    time_line = const_lines[3]
    sensor.start_time = decode_d10(time_line[0, 10])
    sensor.end_time   = decode_d10(time_line[11, 10])
    sensor.interval_min = time_line[22, 2].strip.to_i
  else
    # F/D: line1=height+min_vel+manhole+logger, line2=start/end/interval
    meta_line = const_lines[0]
    sensor.height     = meta_line[0, 5].strip.to_i
    sensor.min_vel    = meta_line[6, 5].strip.to_f
    sensor.manhole_no = meta_line[12, 20].strip
    sensor.logger_type = meta_line[33, 3].strip

    time_line = const_lines[1]
    sensor.start_time = decode_d10(time_line[0, 10])
    sensor.end_time   = decode_d10(time_line[11, 10])
    sensor.interval_min = time_line[22, 2].strip.to_i
  end

  # Parse data block (skip trailing */ comment lines)
  data_lines = []
  (cend_idx + 1).upto(lines.length - 1) do |i|
    ln = lines[i]
    next if ln.nil? || ln.strip.empty?
    break if ln =~ /^\s*\*\//
    data_lines << ln
  end

  expected = sensor.record_count

  if sensor.sensor_type == :rain
    # Rain: 5 records per line, each 15 chars (10X + F5)
    rec_idx = 0
    data_lines.each do |line|
      # Pad line to 75 chars
      padded = line.chomp.ljust(75)
      (0...5).each do |j|
        break if rec_idx >= expected
        chunk = padded[j * 15, 15]
        val = chunk[10, 5].strip.to_f
        sensor.intensity << val
        rec_idx += 1
      end
    end
  else
    # F/D: 5 records per line, each 15 chars (I5 I5 F5)
    rec_idx = 0
    data_lines.each do |line|
      padded = line.chomp.ljust(75)
      (0...5).each do |j|
        break if rec_idx >= expected
        chunk = padded[j * 15, 15]
        f = chunk[0, 5].strip.to_i   # FLOW (L/s)
        d = chunk[5, 5].strip.to_i   # DEPTH (mm)
        v = chunk[10, 5].strip.to_f  # VELOCITY (m/s)
        sensor.flow << f
        sensor.depth << d
        sensor.velocity << v
        rec_idx += 1
      end
    end
  end

  sensor
end

# ─── CSV WRITERS ─────────────────────────────────────────────────────────────

def time_at_index(start_time, interval_sec, idx)
  start_time + (idx * interval_sec)
end

def indices_for_window(sensor, win_start, win_end)
  # Return [first_idx, last_idx] (inclusive) for the time window
  dt = sensor.interval_sec
  first = ((win_start - sensor.start_time) / dt).round
  last  = ((win_end   - sensor.start_time) / dt).round
  first = 0 if first < 0
  max_idx = sensor.record_count - 1
  last = max_idx if last > max_idx
  [first, last]
end

def write_flow_csv(filepath, sensors, win_start, win_end, interval_sec)
  # HYQ format — all F and D sensors, flow in m³/s
  # D-sensors contribute 0 flow; sort order: D first, then F (matching reference)
  sorted = sensors.sort_by { |s| s.id }
  n = sorted.length
  first_s = sorted[0]
  fi, li = indices_for_window(first_s, win_start, win_end)
  nrows = li - fi + 1

  File.open(filepath, 'w') do |f|
    f.puts "!Version=1,type=HYQ,encoding=MBCS"
    f.puts "UserSettings,U_VALUES,U_DATETIME"
    f.puts "UserSettingsValues,m3/s,dd-mm-yyyy hh:mm"
    f.puts "G_START,G_TS,G_NPROFILES"
    ts_start = time_at_index(first_s.start_time, first_s.interval_sec, fi)
    f.puts "#{format_ts(ts_start)},#{interval_sec},#{n}"
    f.puts "L_LINKID,L_CONDCAPACITY,L_PTITLE"
    sorted.each do |s|
      f.puts "     #{s.id},0,#{s.filename}"
    end
    cols = (1..n).to_a.join(',')
    f.puts "P_DATETIME,#{cols}"

    fi.upto(li) do |idx|
      ts = time_at_index(first_s.start_time, first_s.interval_sec, idx)
      vals = sorted.map { |s|
        raw = s.flow[idx] || 0
        sprintf('%f', raw / 1000.0)  # L/s → m³/s
      }
      f.puts "#{format_ts(ts)},#{vals.join(',')}"
    end
  end
end

def write_depth_csv(filepath, sensors, win_start, win_end, interval_sec)
  # HYD format — depth in metres
  sorted = sensors.sort_by { |s| s.id }
  n = sorted.length
  first_s = sorted[0]
  fi, li = indices_for_window(first_s, win_start, win_end)

  File.open(filepath, 'w') do |f|
    f.puts "!Version=1,type=HYD,encoding=MBCS"
    f.puts "UserSettings,U_LEVEL,U_CONDHEIGHT,U_VALUES,U_DATETIME"
    f.puts "UserSettingsValues,m AD,mm,m,dd-mm-yyyy hh:mm"
    f.puts "G_START,G_TS,G_NPROFILES"
    ts_start = time_at_index(first_s.start_time, first_s.interval_sec, fi)
    f.puts "#{format_ts(ts_start)},#{interval_sec},#{n}"
    f.puts "L_LINKID,L_INVERTLEVEL,L_CONDHEIGHT,L_GROUNDLEVEL,L_PTITLE"
    sorted.each do |s|
      f.puts "     #{s.id},0,    0,0,#{s.filename}"
    end
    cols = (1..n).to_a.join(',')
    f.puts "P_DATETIME,#{cols}"

    fi.upto(li) do |idx|
      ts = time_at_index(first_s.start_time, first_s.interval_sec, idx)
      vals = sorted.map { |s|
        raw = s.depth[idx] || 0
        sprintf('%f', raw / 1000.0)  # mm → m
      }
      f.puts "#{format_ts(ts)},#{vals.join(',')}"
    end
  end
end

def write_velocity_csv(filepath, sensors, win_start, win_end, interval_sec)
  # HYV format — velocity in m/s (already in m/s in .std)
  sorted = sensors.sort_by { |s| s.id }
  n = sorted.length
  first_s = sorted[0]
  fi, li = indices_for_window(first_s, win_start, win_end)

  File.open(filepath, 'w') do |f|
    f.puts "!Version=1,type=HYV,encoding=MBCS"
    f.puts "UserSettings,U_VALUES,U_DATETIME"
    f.puts "UserSettingsValues,m/s,dd-mm-yyyy hh:mm"
    f.puts "G_START,G_TS,G_NPROFILES"
    ts_start = time_at_index(first_s.start_time, first_s.interval_sec, fi)
    f.puts "#{format_ts(ts_start)},#{interval_sec},#{n}"
    f.puts "L_LINKID,L_PTITLE"
    sorted.each do |s|
      f.puts "     #{s.id},#{s.filename}"
    end
    cols = (1..n).to_a.join(',')
    f.puts "P_DATETIME,#{cols}"

    fi.upto(li) do |idx|
      ts = time_at_index(first_s.start_time, first_s.interval_sec, idx)
      vals = sorted.map { |s|
        v = s.velocity[idx] || 0.0
        sprintf('%f', v)
      }
      f.puts "#{format_ts(ts)},#{vals.join(',')}"
    end
  end
end

def write_rain_csv(filepath, sensors, win_start, win_end, interval_sec)
  # RED format — rainfall intensity in mm/hr
  sorted = sensors.sort_by { |s| s.id }
  n = sorted.length
  first_s = sorted[0]
  fi, li = indices_for_window(first_s, win_start, win_end)

  now_str = Time.now.strftime('%d-%m-%y %H:%M')

  File.open(filepath, 'w') do |f|
    f.puts "!Version=2,type=RED,encoding=MBCS"
    f.puts "FILECONT, TITLE"
    f.puts "0,#{now_str}"
    f.puts "UserSettings,U_RD,U_EVAP,U_FLOW,U_VALUES,U_DATETIME"
    f.puts "UserSettingsValues,mm,mm/day,m3/s,mm/hr,dd-mm-yyyy hh:mm"
    f.puts "G_START,G_TS,G_NPROFILES,G_ARD,G_EVAP,G_UCWI,G_API30,G_SMS,G_SMD,G_WI,G_CINI,G_BF0,G_RP,G_DUR,G_RPT"
    ts_start = time_at_index(first_s.start_time, first_s.interval_sec, fi)
    f.puts "#{format_ts(ts_start)},#{interval_sec},#{n},         0,    0,,         0,         0,,,         0,         0,    0.0000,       0.0,POT  "

    # Per-gauge metadata: header once, then one data row per gauge
    f.puts "L_ARF,L_ARD,L_EVAP,L_UCWI,L_API30,L_SMS,L_SMD,L_WI,L_CINI,L_BF0"
    sorted.each do |s|
      f.puts "      1.00,0,0,         0,0,0,,,0,0"
    end
    f.puts "L_PTITLE,L_PDESC,L_GAUGE_DATA"
    sorted.each_with_index do |s, gi|
      f.puts "#{gi + 1},#{s.filename},"
    end
    f.puts "L_ACF,L_SCF"
    sorted.each do |s|
      f.puts "     0.000,     0.000"
    end

    cols = (1..n).to_a.join(',')
    f.puts "P_DATETIME,#{cols}"

    fi.upto(li) do |idx|
      ts = time_at_index(first_s.start_time, first_s.interval_sec, idx)
      vals = sorted.map { |s|
        v = s.intensity[idx] || 0.0
        sprintf('%f', v)
      }
      f.puts "#{format_ts(ts)},#{vals.join(',')}"
    end
  end
end

# ─── TIME PARSING HELPER ────────────────────────────────────────────────────

def parse_user_datetime(str)
  # Accept "DD/MM/YYYY HH:MM" or "DD/MM/YYYY HH:MM:SS"
  str = str.strip
  if str =~ %r{^(\d{1,2})/(\d{1,2})/(\d{4})\s+(\d{1,2}):(\d{2})(?::(\d{2}))?$}
    dd = $1.to_i; mm = $2.to_i; yyyy = $3.to_i
    hh = $4.to_i; mi = $5.to_i; ss = ($6 || '0').to_i
    Time.new(yyyy, mm, dd, hh, mi, ss)
  else
    nil
  end
end

def format_user_date(t)
  # → "DD/MM/YYYY HH:MM" (no seconds — matches expected input format)
  sprintf('%02d/%02d/%04d %02d:%02d', t.day, t.month, t.year, t.hour, t.min)
end

# ─── MAIN ────────────────────────────────────────────────────────────────────

begin  # wrap main — ICM UI does not support exit (throws SystemExit)

# Step 1: Select folder
std_folder = WSApplication.folder_dialog('Select folder containing .std files', true)
if std_folder.nil? || std_folder.empty?
  WSApplication.message_box('No folder selected. Aborting.', 'OK', 'Information', false)
  raise 'abort'
end

# Normalise path — Dir.glob treats backslashes as escape chars on Windows
std_folder = std_folder.gsub('\\', '/')

# Step 2: Scan and parse all .std files
std_files = Dir.glob("#{std_folder}/*.std") + Dir.glob("#{std_folder}/*.STD")
std_files.uniq! { |f| f.downcase }

if std_files.empty?
  WSApplication.message_box("No .std files found in:\n#{std_folder}", 'OK', 'Stop', false)
  raise 'abort'
end

sensors = []
errors = []

std_files.each do |fp|
  begin
    s = parse_std_file(fp)
    if s
      sensors << s
    else
      errors << "SKIP: #{File.basename(fp)} — could not parse"
    end
  rescue => e
    errors << "ERROR: #{File.basename(fp)} — #{e.message}"
  end
end

if sensors.empty?
  WSApplication.message_box("No sensors parsed successfully.\n#{errors.join("\n")}", 'OK', 'Stop', false)
  raise 'abort'
end

# Classify sensors
f_sensors = sensors.select { |s| s.sensor_type == :flow }
d_sensors = sensors.select { |s| s.sensor_type == :depth }
r_sensors = sensors.select { |s| s.sensor_type == :rain }

# Step 3: Auto-detect full survey period
global_start = sensors.map { |s| s.start_time }.min
global_end   = sensors.map { |s| s.end_time }.max

# Get common interval (should all be same)
intervals = sensors.map { |s| s.interval_sec }.uniq
if intervals.length > 1
  WSApplication.message_box(
    "WARNING: Mixed intervals found (#{intervals.map { |i| "#{i}s" }.join(', ')}). Using smallest.",
    'OK', '!', false
  )
end
common_interval = intervals.min

# Summary
summary = "Parsed #{sensors.length} sensors:\n" \
          "  F (flow): #{f_sensors.length}\n" \
          "  D (depth): #{d_sensors.length}\n" \
          "  R (rain): #{r_sensors.length}\n\n" \
          "Full period: #{format_ts(global_start)} to #{format_ts(global_end)}\n" \
          "Interval: #{common_interval}s (#{common_interval / 60}min)\n"

unless errors.empty?
  summary += "\nWarnings:\n#{errors.join("\n")}\n"
end

WSApplication.message_box(summary, 'OK', 'Information', false)

# Step 4: Collect events
# Events have :name, :start, :end, :type (:full, :dry, :storm)
events = []

# Always import Full Period
events << { :name => 'Full Period', :start => global_start, :end => global_end, :type => :full }

answer = WSApplication.message_box(
  "The full survey period will be imported automatically.\n\n" \
  "Do you wish to specify individual dry day and storm events?",
  'YesNo', '?', false
)

if answer == 'Yes'
  date_range_hint = "Survey period: #{format_user_date(global_start)} to #{format_user_date(global_end)}"
  example_start = format_user_date(global_start)
  example_end   = format_user_date(global_start + 24 * 3600)

  # ── Phase 2: Dry Days (one at a time) ──
  dry_count = 0
  dry_done = false
  next_dry_start = example_start
  until dry_done
    name_default  = "Dry Day #{dry_count + 1}"
    start_default = next_dry_start

    loop do  # validation retry loop
      fields = [
        ["Event Name", 'String', name_default],
        ["Start (DD/MM/YYYY HH:MM)", 'String', start_default]
      ]

      result = WSApplication.prompt(
        "Define Dry Day Event\n#{date_range_hint}\n\n" \
        "Duration: 24 hours from start. Rainfall NOT included.\n" \
        "Press Cancel to skip or finish adding dry days.",
        fields, true
      )

      unless result
        dry_done = true
        break
      end

      name_default  = result[0] || ''
      start_default = result[1] || ''
      name_val  = name_default.strip
      start_val = start_default.strip

      if name_val.empty?
        WSApplication.message_box("Event name cannot be blank.", 'OK', '!', false)
        next
      end

      ev_start = parse_user_datetime(start_val)
      unless ev_start
        WSApplication.message_box(
          "Invalid date: '#{start_val}'\n\nExpected format: DD/MM/YYYY HH:MM",
          'OK', '!', false
        )
        next
      end

      ev_end = ev_start + (24 * 3600)
      events << { :name => name_val, :start => ev_start, :end => ev_end, :type => :dry }
      dry_count += 1
      next_dry_start = format_user_date(ev_end)

      more = WSApplication.message_box(
        "'#{name_val}' added (#{dry_count} total).\n\nAdd another dry day event?",
        'YesNo', '?', false
      )
      dry_done = true if more != 'Yes'
      break
    end
  end

  # ── Phase 3: Storm Events (one at a time) ──
  storm_count = 0
  storm_done = false
  next_storm_start = example_start
  next_storm_end   = example_end
  until storm_done
    name_default  = "Storm #{storm_count + 1}"
    start_default = next_storm_start
    end_default   = next_storm_end

    loop do  # validation retry loop
      fields = [
        ["Event Name", 'String', name_default],
        ["Start (DD/MM/YYYY HH:MM)", 'String', start_default],
        ["End (DD/MM/YYYY HH:MM)", 'String', end_default]
      ]

      result = WSApplication.prompt(
        "Define Storm Event\n#{date_range_hint}\n\n" \
        "Rainfall data WILL be included.\n" \
        "Press Cancel to skip or finish adding storms.",
        fields, true
      )

      unless result
        storm_done = true
        break
      end

      name_default  = result[0] || ''
      start_default = result[1] || ''
      end_default   = result[2] || ''
      name_val  = name_default.strip
      start_val = start_default.strip
      end_val   = end_default.strip

      if name_val.empty?
        WSApplication.message_box("Event name cannot be blank.", 'OK', '!', false)
        next
      end

      ev_start = parse_user_datetime(start_val)
      unless ev_start
        WSApplication.message_box(
          "Invalid start date: '#{start_val}'\n\nExpected format: DD/MM/YYYY HH:MM",
          'OK', '!', false
        )
        next
      end

      ev_end = parse_user_datetime(end_val)
      unless ev_end
        WSApplication.message_box(
          "Invalid end date: '#{end_val}'\n\nExpected format: DD/MM/YYYY HH:MM",
          'OK', '!', false
        )
        next
      end

      if ev_end <= ev_start
        WSApplication.message_box("End date must be after start date.", 'OK', '!', false)
        next
      end

      events << { :name => name_val, :start => ev_start, :end => ev_end, :type => :storm }
      storm_count += 1
      next_storm_start = format_user_date(ev_end)
      next_storm_end   = format_user_date(ev_end + 24 * 3600)

      more = WSApplication.message_box(
        "'#{name_val}' added (#{storm_count} total).\n\nAdd another storm event?",
        'YesNo', '?', false
      )
      storm_done = true if more != 'Yes'
      break
    end
  end
end

# Summary of events
ev_summary = events.map { |e| "  #{e[:type].to_s.upcase}: #{e[:name]}" }.join("\n")
WSApplication.message_box("Events to process:\n#{ev_summary}", 'OK', 'Information', false)

# Step 5: Create output folder
output_folder = File.join(std_folder, 'csv_output')
Dir.mkdir(output_folder) unless File.exist?(output_folder)

# Step 6: Generate CSVs for each event + write manifest
manifest_rows = []

events.each do |ev|
  safe_name = ev[:name].gsub(/[^a-zA-Z0-9_\- ]/, '').gsub(' ', '_')

  flow_csv = nil
  depth_csv = nil
  depth_only_csv = nil
  velocity_csv = nil
  rain_csv = nil

  # Flow CSV — F-sensors only (flow monitors)
  unless f_sensors.empty?
    flow_csv = "#{safe_name}_Flow.csv"
    write_flow_csv(
      File.join(output_folder, flow_csv),
      f_sensors, ev[:start], ev[:end], common_interval
    )
  end

  # Depth CSV — F-sensors only (flow monitor depth)
  unless f_sensors.empty?
    depth_csv = "#{safe_name}_Depth.csv"
    write_depth_csv(
      File.join(output_folder, depth_csv),
      f_sensors, ev[:start], ev[:end], common_interval
    )
  end

  # Depth Only CSV — D-sensors only (depth-only monitor depth)
  unless d_sensors.empty?
    depth_only_csv = "#{safe_name}_DepthOnly.csv"
    write_depth_csv(
      File.join(output_folder, depth_only_csv),
      d_sensors, ev[:start], ev[:end], common_interval
    )
  end

  # Velocity CSV — F-sensors only (flow monitors)
  unless f_sensors.empty?
    velocity_csv = "#{safe_name}_Velocity.csv"
    write_velocity_csv(
      File.join(output_folder, velocity_csv),
      f_sensors, ev[:start], ev[:end], common_interval
    )
  end

  # Rain CSV — R-sensors only (skip for dry day events)
  if ev[:type] != :dry && !r_sensors.empty?
    rain_csv = "#{safe_name}_Rain.csv"
    write_rain_csv(
      File.join(output_folder, rain_csv),
      r_sensors, ev[:start], ev[:end], common_interval
    )
  end

  manifest_rows << {
    :event_name     => ev[:name],
    :flow_csv       => flow_csv || '',
    :depth_csv      => depth_csv || '',
    :depth_only_csv => depth_only_csv || '',
    :velocity_csv   => velocity_csv || '',
    :rain_csv       => rain_csv || ''
  }
end

# Write manifest
manifest_path = File.join(output_folder, 'manifest.csv')
File.open(manifest_path, 'w') do |f|
  f.puts 'event_name,flow_csv,depth_csv,depth_only_csv,velocity_csv,rain_csv'
  manifest_rows.each do |row|
    f.puts [
      row[:event_name],
      row[:flow_csv],
      row[:depth_csv],
      row[:depth_only_csv],
      row[:velocity_csv],
      row[:rain_csv]
    ].join(',')
  end
end

# Step 7: Confirm and optionally launch Exchange
answer = WSApplication.message_box(
  "CSV generation complete.\n\n" \
  "Events: #{events.length}\n" \
  "Output: #{output_folder}\n" \
  "Manifest: #{manifest_path}\n\n" \
  "Launch Exchange import now?",
  'YesNo', '?', false
)

if answer == 'Yes'
  # Step 8: Launch Exchange script
  exchange_script = File.join(File.dirname(File.expand_path(__FILE__)),
                              'hw_flow_survey_import_exchange.rb')
  unless File.exist?(exchange_script)
    WSApplication.message_box(
      "Exchange script not found:\n#{exchange_script}\n\nRun it manually.",
      'OK', 'Stop', false
    )
    raise 'abort'
  end

  # Write config for Exchange to pick up
  config_path = File.join(output_folder, 'exchange_config.txt')
  File.open(config_path, 'w') do |f|
    f.puts output_folder
  end

  result = system('ICMExchange.exe', exchange_script)
  if result
    # Clean up CSV output folder after successful import
    begin
      Dir.glob(File.join(output_folder, '*')).each { |f| File.delete(f) }
      Dir.rmdir(output_folder)
    rescue => cleanup_err
      WSApplication.message_box(
        "Import succeeded but CSV cleanup failed:\n#{cleanup_err.message}\n\n" \
        "You may manually delete:\n#{output_folder}",
        'OK', '!', false
      )
    end
    WSApplication.message_box("Exchange import completed successfully.\nTemporary CSV files have been removed.", 'OK', 'Information', false)
  else
    WSApplication.message_box(
      "Exchange launch failed (exit=#{$?.exitstatus}).\n" \
      "Run hw_flow_survey_import_exchange.rb manually in ICMExchange.",
      'OK', '!', false
    )
  end
else
  WSApplication.message_box(
    "CSVs saved to:\n#{output_folder}\n\n" \
    "Run hw_flow_survey_import_exchange.rb in ICMExchange\n" \
    "when ready to import into the database.",
    'OK', 'Information', false
  )
end

rescue => e
  # Silently end on our own 'abort' raises; show real errors
  if e.message != 'abort'
    WSApplication.message_box("Unexpected error:\n#{e.class}: #{e.message}", 'OK', 'Stop', false)
  end
end
