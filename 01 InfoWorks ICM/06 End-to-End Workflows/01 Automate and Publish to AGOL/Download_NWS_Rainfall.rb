# =============================================================================
# Download_NWS_Rainfall.rb
# =============================================================================
#
# OVERVIEW
#   Downloads rainfall data from the NOAA NWS Weather.gov API and converts it to
#   InfoWorks ICM-compatible rain gauge CSV format. Produces two files:
#   - 24h historical: Station observations (past 24 hours)
#   - 48h forecast: Grid QPF (quantitative precipitation forecast)
#   Optionally imports the CSVs as Rainfall Events into an ICM cloud database.
#
# WORKFLOW CONTEXT
#   This script is Step 1 of a typical daily pipeline:
#   1. Download_NWS_Rainfall.rb  -> Fetches rainfall, creates CSVs, optionally imports to ICM
#   2. Create and Run Simulations.rb -> Runs 24h and 48h simulations using the new rainfall
#   3. Export 2D ICM Results.rb  -> Exports simulation results to shapefiles
#   4. Publish_Shapefiles_to_AGOL.py -> Publishes shapefiles to ArcGIS Online
#
# GETTING STARTED (NEW USERS)
#   1. Edit the CONFIGURATION section below with YOUR values.
#   2. LATITUDE, LONGITUDE: Use decimal degrees for your study area center.
#      Find coordinates: https://www.latlong.net/ or Google Maps right-click.
#   3. USER_AGENT: NWS API requires this. Use format: "ICM Rainfall (Ruby), your@email.com"
#   4. HISTORICAL_FILENAME, FORECAST_FILENAME: Rename to match your project (e.g. YourCity).
#   5. ICM_DB_PATH: Set to nil to skip automatic import; or use your cloud DB path.
#      Format: cloud://YourDatabaseName@your-org-id/region (from ICM connection string).
#   6. MODEL_GROUP_ID: The numeric ID of your Model Group in ICM. Find in ICM Explorer.
#   7. Run via ICMExchange.exe or create a .bat file (see REQUIREMENTS below).
#
# REQUIREMENTS
#   - InfoWorks ICM with ICMExchange.exe (embedded Ruby)
#   - Run: ICMExchange.exe "path\to\Download_NWS_Rainfall.rb" /ICM
#   - Internet access (NWS API, no API key)
#   - US locations only (NWS covers US territories)
#
# API REFERENCE: https://www.weather.gov/documentation/services-web-api
#
# =============================================================================

require 'net/http'
require 'json'
require 'date'
require 'time'
require 'fileutils'

# --- CONFIGURATION ---
# REQUIRED: Set these for your project location.

LATITUDE = 0.0   # TODO: Decimal degrees (e.g. 41.7859). Negative longitude = West.
LONGITUDE = 0.0  # TODO: Decimal degrees (e.g. -88.1473)

# REQUIRED: User-Agent required by NWS API. Use your contact email.
USER_AGENT = 'ICM Rainfall (Ruby), your-email@example.com'

# Output folder (relative to script). CSV filenames - customize for your project.
OUTPUT_FOLDER = File.join(File.dirname(__FILE__), 'rainfall_data')
HISTORICAL_FILENAME = 'Past 24 hours rainfall_YourCity.csv'   # TODO: Replace YourCity
FORECAST_FILENAME = 'Forecast 48 hours rainfall_YourCity.csv' # TODO: Replace YourCity

HISTORICAL_HOURS = 24
FORECAST_HOURS = 48

# :historical, :forecast, or :both
DATA_MODE = :both

# OPTIONAL: ICM cloud database for automatic import. Set to nil to skip.
# Format: cloud://DatabaseName@orgId/region (from ICM Connect to Database)
ICM_DB_PATH = nil  # e.g. 'cloud://My Database ICM@abc123def456/namer'

# OPTIONAL: Model Group ID where rainfall events will be imported. Find in ICM Explorer.
MODEL_GROUP_ID = 0  # e.g. 12316

# mm to inches
MM_TO_INCH = 1.0 / 25.4

# --- END CONFIGURATION ---

def nws_get(url, user_agent)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req['User-Agent'] = user_agent
  req['Accept'] = 'application/geo+json, application/json'
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30) { |http| http.request(req) }
  raise "NWS API error #{res.code}: #{res.message}" unless res.is_a?(Net::HTTPSuccess)
  JSON.parse(res.body)
end

def format_datetime_mmddyyyy(t)
  t.strftime('%m/%d/%Y %H:%M')
end

def parse_valid_time(vt)
  return nil unless vt.is_a?(String) && vt.include?('/')
  start_str, duration_str = vt.split('/', 2)
  start_time = Time.parse(start_str)
  duration_hours = 1
  if duration_str && duration_str =~ /PT(\d+)H/
    duration_hours = $1.to_i
  elsif duration_str && duration_str =~ /PT(\d+)D/
    duration_hours = $1.to_i * 24
  end
  [start_time, duration_hours]
end

def fetch_station_obs(lat, lon, start_local, end_local, user_agent)
  points = nws_get("https://api.weather.gov/points/#{lat},#{lon}", user_agent)
  stations_url = points.dig('properties', 'observationStations')
  raise 'No observationStations' if stations_url.to_s.empty?
  stations = nws_get(stations_url, user_agent)
  features = stations['features'] || []
  raise 'No stations found' if features.empty?
  station_id = features.first.dig('properties', 'stationIdentifier')
  raise 'No station ID' if station_id.to_s.empty?

  obs_start = start_local + 3600
  obs_end = end_local + 3600
  hour_slots = {}
  t = start_local
  while t < end_local
    key = t.strftime('%Y-%m-%dT%H:00')
    hour_slots[key] = [format_datetime_mmddyyyy(t), 0.0]
    t += 3600
  end

  obs_url = "https://api.weather.gov/stations/#{station_id}/observations?limit=500"
  all_obs = []
  loop do
    obs_data = nws_get(obs_url, user_agent)
    obs = obs_data['features'] || []
    break if obs.empty?
    obs.each do |feat|
      ts = feat.dig('properties', 'timestamp')
      next if ts.to_s.empty?
      t = Time.parse(ts)
      break if t < obs_start
      next if t >= obs_end
      all_obs << [t, feat['properties']]
    end
    next_link = obs_data.dig('pagination', 'next')
    break if next_link.to_s.empty?
    obs_url = next_link
  end

  all_obs.each do |t, props|
    val = props.dig('precipitationLastHour', 'value')
    next if val.nil?
    hour_key = (t - 3600).getlocal.strftime('%Y-%m-%dT%H:00')
    slot = hour_slots[hour_key]
    if slot
      inch_val = (val.to_f * MM_TO_INCH).round(6)
      slot[1] = inch_val
    end
  end

  rows = []
  t = start_local
  while t < end_local
    key = t.strftime('%Y-%m-%dT%H:00')
    slot = hour_slots[key] || [format_datetime_mmddyyyy(t), 0.0]
    rows << [slot[0], format('%.6f', slot[1])]
    t += 3600
  end
  rows
end

def fetch_forecast_qpf(lat, lon, start_local, end_local, user_agent)
  points = nws_get("https://api.weather.gov/points/#{lat},#{lon}", user_agent)
  grid_url = points.dig('properties', 'forecastGridData')
  raise 'No forecastGridData' if grid_url.to_s.empty?
  grid = nws_get(grid_url, user_agent)
  qpf = grid.dig('properties', 'quantitativePrecipitation')
  raise 'No quantitativePrecipitation' if qpf.nil?
  values = qpf['values'] || []

  start_utc = start_local.getutc
  end_utc = end_local.getutc
  hour_precip = {}

  values.each do |v|
    vt = v['validTime']
    val = v['value']
    parsed = parse_valid_time(vt)
    next unless parsed
    start_t, dur_h = parsed
    next if start_t >= end_utc
    next if start_t + (dur_h * 3600) <= start_utc
    inch_per_hour = (val.to_f * MM_TO_INCH) / dur_h
    dur_h.times do |i|
      hour_t = start_t + (i * 3600)
      next if hour_t < start_utc || hour_t >= end_utc
      key = hour_t.getlocal.strftime('%Y-%m-%dT%H:00')
      hour_precip[key] ||= 0.0
      hour_precip[key] += inch_per_hour
    end
  end

  rows = []
  t = start_local
  while t < end_local
    key = t.strftime('%Y-%m-%dT%H:00')
    depth = hour_precip[key] || 0.0
    rows << [format_datetime_mmddyyyy(t), format('%.6f', depth)]
    t += 3600
  end
  rows
end

def write_infoworks_rain_csv(rows, filepath)
  return if rows.empty?
  FileUtils.mkdir_p File.dirname(filepath)
  first_datetime = rows[0][0]
  g_ts = 3600
  File.open(filepath, 'w') do |f|
    f.puts '!Version=2,type=RED,encoding=MBCS,,,,,,,,,,,,'.strip
    f.puts 'FILECONT, TITLE,,,,,,,,,,,,,'
    f.puts '0,1,,,,,,,,,,,,,'
    f.puts 'UserSettings,U_RD,U_EVAP,U_FLOW,U_VALUES,U_DATETIME,,,,,,,,,'
    f.puts 'UserSettingsValues,in,in/day,ft3/s,in/hr,mm-dd-yyyy hh:mm,,,,,,,,,'
    f.puts 'G_START,G_TS,G_NPROFILES,G_ARD,G_EVAP,G_UCWI,G_API30,G_SMS,G_SMD,G_WI,G_CINI,G_BF0,G_RP,G_DUR,G_RPT'
    f.puts "#{first_datetime},#{g_ts},1,0,0,0,0,0,0,0,0,0,0,0,POT"
    f.puts 'L_ARF,L_ARD,L_EVAP,L_UCWI,L_API30,L_SMS,L_SMD,L_WI,L_CINI,L_BF0,,,,,'
    f.puts '          ,0,0,          ,0,0,          ,     ,0,0,,,,,'
    f.puts 'L_PTITLE,L_PDESC,L_GAUGE_DATA,,,,,,,,,,,'
    f.puts '1,,,,,,,,,,,,,'
    f.puts 'L_ACF,L_SCF,,,,,,,,,,,,'
    f.puts '1,1,,,,,,,,,,,,'
    f.puts 'P_DATETIME,1,,,,,,,,,,,,,'
    rows.each { |dt, depth| f.puts "#{dt},#{depth}" }
  end
end

OUTPUT_FOLDER_ABS = File.expand_path(OUTPUT_FOLDER, File.dirname(__FILE__))
FileUtils.mkdir_p OUTPUT_FOLDER_ABS

begin
  today = Date.today
  yesterday = today - 1
  tomorrow = today + 1

  # 24h historical: yesterday 00:00 - 23:00
  start_24h = Time.local(yesterday.year, yesterday.mon, yesterday.day, 0, 0, 0)
  end_24h = start_24h + (HISTORICAL_HOURS * 3600)

  # 48h forecast: today 00:00 through tomorrow 23:00
  start_48h = Time.local(today.year, today.mon, today.day, 0, 0, 0)
  end_48h = start_48h + (FORECAST_HOURS * 3600)

  now_local = Time.now
  historical_rows = []
  forecast_rows = []

  if (DATA_MODE == :historical || DATA_MODE == :both) && end_24h > now_local - (4 * 24 * 3600)
    obs_end = end_24h < now_local ? end_24h : Time.local(now_local.year, now_local.mon, now_local.day, now_local.hour, 0, 0)
    historical_rows = fetch_station_obs(LATITUDE, LONGITUDE, start_24h, obs_end, USER_AGENT)
  end

  if (DATA_MODE == :forecast || DATA_MODE == :both) && start_48h < now_local + (7 * 24 * 3600)
    fc_start = start_48h > now_local ? start_48h : Time.local(now_local.year, now_local.mon, now_local.day, now_local.hour, 0, 0) + 3600
    forecast_rows = fetch_forecast_qpf(LATITUDE, LONGITUDE, fc_start, end_48h, USER_AGENT)
  end

  if (DATA_MODE == :historical || DATA_MODE == :both) && historical_rows.any?
    out_path = File.join(OUTPUT_FOLDER_ABS, HISTORICAL_FILENAME)
    write_infoworks_rain_csv(historical_rows, out_path)
    puts "  Wrote #{historical_rows.size} hourly records to #{out_path}"
  end

  if (DATA_MODE == :forecast || DATA_MODE == :both) && forecast_rows.any?
    out_path = File.join(OUTPUT_FOLDER_ABS, FORECAST_FILENAME)
    write_infoworks_rain_csv(forecast_rows, out_path)
    puts "  Wrote #{forecast_rows.size} hourly records to #{out_path}"
  end

  if ((DATA_MODE == :historical || DATA_MODE == :both) && historical_rows.any?) ||
     ((DATA_MODE == :forecast || DATA_MODE == :both) && forecast_rows.any?)
    if ICM_DB_PATH && MODEL_GROUP_ID && MODEL_GROUP_ID > 0
      db = WSApplication.open ICM_DB_PATH, false
      model_group = db.model_object_from_type_and_id 'Model Group', MODEL_GROUP_ID

      if model_group.nil?
        puts "  WARNING: Model group ID #{MODEL_GROUP_ID} not found, skip ICM import"
      else
        if (DATA_MODE == :historical || DATA_MODE == :both) && historical_rows.any?
          past_csv = File.join(OUTPUT_FOLDER_ABS, HISTORICAL_FILENAME)
          if File.exist?(past_csv)
            name_24h = "#{yesterday.mon}/#{yesterday.day}/#{yesterday.year}"
            model_group.import_new_model_object 'Rainfall Event', name_24h, 'CSV', past_csv, 0
            puts "  Imported #{HISTORICAL_FILENAME} → new Rainfall Event '#{name_24h}'"
          end
        end

        if (DATA_MODE == :forecast || DATA_MODE == :both) && forecast_rows.any?
          forecast_csv = File.join(OUTPUT_FOLDER_ABS, FORECAST_FILENAME)
          if File.exist?(forecast_csv)
            name_48h = today.mon == tomorrow.mon ?
              "#{today.mon}/#{today.day}-#{tomorrow.day}/#{today.year}" :
              "#{today.mon}/#{today.day}-#{tomorrow.mon}/#{tomorrow.day}/#{today.year}"
            model_group.import_new_model_object 'Rainfall Event', name_48h, 'CSV', forecast_csv, 0
            puts "  Imported #{FORECAST_FILENAME} → new Rainfall Event '#{name_48h}'"
          end
        end
      end
    else
      puts "  ICM import skipped (ICM_DB_PATH or MODEL_GROUP_ID not set)"
    end
  end

  puts "Done at #{Time.now}"
rescue StandardError => e
  puts "ERROR: #{e.message}"
  exit 1
end
