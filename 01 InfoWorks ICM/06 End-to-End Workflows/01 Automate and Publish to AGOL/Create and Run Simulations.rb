# =============================================================================
# Create and Run Simulations - InfoWorks ICM Exchange Script
# =============================================================================
#
# WORKFLOW POSITION: Step 2 of 4 in the daily simulation pipeline
#   (1) Download_NWS_Rainfall.rb -> (2) THIS SCRIPT -> (3) Export 2D ICM Results.rb -> (4) Publish_Shapefiles_to_AGOL.py
#
# PURPOSE:
#   Creates two simulation runs in a Model Group and executes them:
#   - Run 1 (24h): Yesterday's date - uses second most recent 24h rainfall, copies settings from template.
#   - Run 2 (48h): Today-tomorrow date range - uses most recent 48h rainfall, copies settings from template.
#
# PREREQUISITES:
#   - Rainfall events must exist in the Model Group (typically created by Download_NWS_Rainfall.rb).
#   - Template runs must exist: 24 Hour Yesterday Template and 48 Hour Forecast Template.
#   - InfoWorks ICM with ICMExchange.exe (run headless; cannot run from ICM UI).
#
# RUN METHODS:
#   - ICMExchange.exe "path\to\Create and Run Simulations.rb" /ICM
#   - Create and Run Simulations.bat (in same folder)
#   - Run_All_Daily_Workflow.bat (runs full pipeline)
#
# CUSTOMIZATION FOR YOUR SITE:
#   Edit db_path, MODEL_GROUP_ID, RUN_TEMPLATE_24H_ID, RUN_TEMPLATE_48H_ID, and optionally NETWORK_ID below.
#   Run naming: 24h = single date (MM/DD/YYYY), 48h = date range (MM/DD-DD/YYYY or MM/DD-DD/MM/YYYY).
#
# API REFERENCES:
#   @https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Classes_ICM_wsapplication_html
#   @https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Classes_ICM_wsmodelobject_html
#
# =============================================================================
#
# GETTING STARTED - NEW USERS
# ---------------------------
# 1. In InfoWorks ICM, open your cloud database and navigate to the Model Group
#    that contains your simulation network and templates.
# 2. Create TWO template runs in that Model Group:
#    - "24 Hour Yesterday Template": A run configured for 24h historical simulation
#    - "48 Hour Forecast Template": A run configured for 48h forecast simulation
# 3. Right-click each template run and note its Object ID (or use the Properties panel).
# 4. Set RUN_TEMPLATE_24H_ID and RUN_TEMPLATE_48H_ID to those IDs.
# 5. Get your database path: In ICM, the cloud DB path format is
#    cloud://DatabaseDisplayName@organizationId/region
# 6. Run Download_NWS_Rainfall.rb first so rainfall events exist in the Model Group.
#
# =============================================================================

# --- CONFIGURATION ---
# REPLACE: Your ICM cloud database path. Format: cloud://DatabaseName@orgId/region
db_path = nil

# REPLACE: The Model Group ID that contains your templates and rainfall. Find in ICM: right-click Model Group > Properties > Object ID
MODEL_GROUP_ID = nil

# REPLACE: Object IDs of your template runs. Find in ICM: right-click the Run > Properties > Object ID
RUN_TEMPLATE_24H_ID = nil   # 24 Hour Yesterday Template
RUN_TEMPLATE_48H_ID = nil   # 48 Hour Forecast Template

# OPTIONAL: If the script cannot resolve the network automatically, set the Network object ID here
NETWORK_ID = nil
# --- END CONFIGURATION ---

# 24h rainfall: single date MM/DD/YYYY (e.g. 3/12/2026)
def rainfall_name_is_24h?(name)
  return false if name.nil? || !name.is_a?(String)
  name =~ /^\d{1,2}\/\d{1,2}\/\d{4}$/ && !name.include?('-')
end

# 48h rainfall: date range MM/DD-DD/YYYY or MM/DD-DD/MM/YYYY (e.g. 3/13-14/2026)
def rainfall_name_is_48h?(name)
  return false if name.nil? || !name.is_a?(String)
  name.include?('-') && (name =~ /^\d{1,2}\/\d{1,2}-\d{1,2}\/\d{4}$/ || name =~ /^\d{1,2}\/\d{1,2}-\d{1,2}\/\d{1,2}\/\d{4}$/)
end

def find_all_rainfall_events(mo)
  return [] if mo.nil?
  rain = []
  rain << mo if (mo.type == 'Rainfall Event' || mo.type == 'RAIN')
  mo.children.each { |c| rain.concat(find_all_rainfall_events(c)) }
  rain
end

def find_all_runs(mo)
  return [] if mo.nil?
  runs = []
  runs << mo if mo.type == 'Run'
  mo.children.each { |c| runs.concat(find_all_runs(c)) }
  runs
end

NETWORK_TYPES = ['Model Network', 'NNET', 'Network', 'InfoWorks Model'].freeze

def find_network_in_group(mo)
  return nil if mo.nil?
  mo.children.each do |c|
    return c if NETWORK_TYPES.include?(c.type.to_s)
    n = find_network_in_group(c)
    return n unless n.nil?
  end
  nil
end

def resolve_network_id(run_obj, model_group)
  raw = run_obj['Network'] || run_obj['network'] || run_obj['Network ID'] || run_obj['network_id'] rescue nil
  if (raw.nil? || !int_like?(raw)) && run_obj.respond_to?(:children)
    run_obj.children.each do |c|
      next unless c.type == 'Sim' || c.type == 'Risk Analysis Sim'
      nw_ref = c['Network'] || c['network'] || c['Network ID'] rescue nil
      raw = nw_ref if int_like?(nw_ref)
      break if int_like?(raw)
    end
  end
  return raw if int_like?(raw)
  net = find_network_in_group(model_group)
  return net.id if net && net.respond_to?(:id) && net.id.to_i != 0
  return NETWORK_ID if defined?(NETWORK_ID) && NETWORK_ID && NETWORK_ID.to_i > 0
  nil
end

def int_like?(v)
  return false if v.nil?
  return v.to_i != 0 if v.respond_to?(:to_i)
  false
end

def params_from_run(db, template_run, exclude_keys = [])
  params = {}
  db.list_read_write_run_fields.each do |f|
    next if exclude_keys.include?(f)
    next if f.to_s == 'Initial Conditions 1D/2D'
    v = template_run[f] rescue nil
    params[f] = v unless v.nil?
  end
  params
end

def create_run_and_execute(model_group, run_name, network, commit_id, rainfall, scenarios, params)
  new_run = model_group.new_run(run_name, network, commit_id, rainfall, scenarios, params)
  puts "Created run: #{new_run.path}"

  new_run.children.each do |child|
    next unless child.type == 'Sim' || child.type == 'Risk Analysis Sim'
    puts "Running simulation: #{child.path}"
    child.run
    puts "Simulation finished: #{child.respond_to?(:status) ? child.status : 'done'}"
    return child
  end
  nil
end

# --- Main ---
if db_path.nil? || db_path.to_s.strip.empty?
  puts "ERROR: Set db_path in the script configuration."
  exit 1
end

if MODEL_GROUP_ID.nil? || (MODEL_GROUP_ID.respond_to?(:to_i) && MODEL_GROUP_ID.to_i == 0)
  puts "ERROR: Set MODEL_GROUP_ID in the script configuration."
  exit 1
end

if RUN_TEMPLATE_24H_ID.nil? || RUN_TEMPLATE_48H_ID.nil?
  puts "ERROR: Set RUN_TEMPLATE_24H_ID and RUN_TEMPLATE_48H_ID in the script configuration."
  exit 1
end

db = WSApplication.open db_path, false

model_group = db.model_object_from_type_and_id 'Model Group', MODEL_GROUP_ID
if model_group.nil?
  puts "ERROR: Model Group not found (ID #{MODEL_GROUP_ID})."
  exit 1
end

all_runs = find_all_runs(model_group)
template_24h = all_runs.find { |r| r.id == RUN_TEMPLATE_24H_ID }
template_48h = all_runs.find { |r| r.id == RUN_TEMPLATE_48H_ID }

if template_24h.nil?
  puts "ERROR: 24 Hour Yesterday Template (ID #{RUN_TEMPLATE_24H_ID}) not found in Model Group #{MODEL_GROUP_ID}."
  exit 1
end
if template_48h.nil?
  puts "ERROR: 48 Hour Forecast Template (ID #{RUN_TEMPLATE_48H_ID}) not found in Model Group #{MODEL_GROUP_ID}."
  exit 1
end

puts "Template 24hr run: #{template_24h.path}"
puts "Template 48hr run: #{template_48h.path}"

# Date strings: yesterday (MM/DD/YYYY), today-tomorrow (MM/DD-DD/YYYY)
now = Time.now
yesterday = now - 86400
tomorrow = now + 86400
yesterday_str = "#{yesterday.mon}/#{yesterday.day}/#{yesterday.year}"
if tomorrow.mon == now.mon && tomorrow.year == now.year
  today_tomorrow_str = "#{now.mon}/#{now.day}-#{tomorrow.day}/#{now.year}"
else
  today_tomorrow_str = "#{now.mon}/#{now.day}-#{tomorrow.mon}/#{tomorrow.day}/#{now.year}"
end

puts "Yesterday (Run 1): #{yesterday_str}"
puts "Today-tomorrow (Run 2): #{today_tomorrow_str}"

all_rain = find_all_rainfall_events(model_group).sort_by { |r| -r.id }

# Run 1: second most recent 24h rainfall (name should match yesterday's date)
rain_24h = all_rain.select { |r| rainfall_name_is_24h?(r.name) }
rainfall_yesterday = rain_24h.find { |r| r.name == yesterday_str } || rain_24h[1]
if rainfall_yesterday.nil?
  puts "ERROR: No 24h rainfall for yesterday (#{yesterday_str}) in Model Group #{MODEL_GROUP_ID}. Need at least 2 events."
  exit 1
end

# Run 2: most recent 48h rainfall
rain_48h = all_rain.select { |r| rainfall_name_is_48h?(r.name) }
rainfall_today_tomorrow = rain_48h[0]
if rainfall_today_tomorrow.nil?
  puts "ERROR: No 48h rainfall event (MM/DD-DD/YYYY format) in Model Group #{MODEL_GROUP_ID}."
  exit 1
end

puts "Rainfall Run 1: #{rainfall_yesterday.name} (#{rainfall_yesterday.path})"
puts "Rainfall Run 2: #{rainfall_today_tomorrow.name} (#{rainfall_today_tomorrow.path})"

# Resolve network
network_24h = resolve_network_id(template_24h, model_group)
network_48h = resolve_network_id(template_48h, model_group)
if network_24h.nil? || network_24h.to_i == 0
  puts "ERROR: Could not resolve network for 24h run. Set NETWORK_ID in config."
  exit 1
end
if network_48h.nil? || network_48h.to_i == 0
  puts "ERROR: Could not resolve network for 48h run. Set NETWORK_ID in config."
  exit 1
end

commit_24h = template_24h['Commit ID'] || template_24h['CommitId'] rescue nil
commit_48h = template_48h['Commit ID'] || template_48h['CommitId'] rescue nil
scenarios_24h = template_24h['Scenarios'] || template_24h['Scenario'] rescue nil
scenarios_48h = template_48h['Scenarios'] || template_48h['Scenario'] rescue nil

puts ""
puts "=== Step 1: Run 1 - #{yesterday_str} (24h) ==="
params_24h = params_from_run(db, template_24h, ['Sim'])
sim_24h = create_run_and_execute(
  model_group,
  yesterday_str,
  network_24h,
  commit_24h,
  rainfall_yesterday,
  scenarios_24h,
  params_24h
)

if sim_24h.nil?
  puts "ERROR: Run 1 simulation did not produce a result."
  exit 1
end

puts ""
puts "=== Step 2: Run 2 - #{today_tomorrow_str} (48h) ==="
params_48h = params_from_run(db, template_48h, ['Sim'])
sim_48h = create_run_and_execute(
  model_group,
  today_tomorrow_str,
  network_48h,
  commit_48h,
  rainfall_today_tomorrow,
  scenarios_48h,
  params_48h
)

if sim_48h.nil?
  puts "ERROR: Run 2 simulation did not produce a result."
  exit 1
end

puts ""
puts "Done. Both runs completed."
