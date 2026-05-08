# =============================================================================
# Export 2D ICM Results - InfoWorks ICM Exchange Script
# =============================================================================
#
# WORKFLOW POSITION: Step 3 of 4 in the daily simulation pipeline
#   (1) Download_NWS_Rainfall.rb -> (2) Create and Run Simulations.rb -> (3) THIS SCRIPT -> (4) Publish_Shapefiles_to_AGOL.py
#
# PURPOSE:
#   Exports maximum (peak) simulation results from the most recent 24h and 48h runs to shapefiles.
#   Outputs: 24h.zip and 48h.zip in the output folder, each containing nodes, links, 2D mesh, subcatchments.
#   Each run overwrites the previous export. Exports use results_GIS_export (ExportMaxima).
#
# PREREQUISITES:
#   - Completed 24h and 48h simulation runs must exist in the Model Group (from Create and Run Simulations.rb).
#   - InfoWorks ICM with ICMExchange.exe (results_GIS_export is Exchange-only; cannot run from ICM UI).
#
# RUN METHODS:
#   - ICMExchange.exe "path\to\Export 2D ICM Results.rb" /ICM
#   - Export_2D_ICM_Results.bat (in same folder)
#   - Run_All_Daily_Workflow.bat (runs full pipeline)
#
# CUSTOMIZATION FOR YOUR SITE:
#   Edit db_path, MODEL_GROUP_ID, OUTPUT_BASE, and CONVERT_SI_TO_CUSTOM below.
#   Run naming must match Create and Run Simulations: 24h = MM/DD/YYYY, 48h = MM/DD-DD/YYYY.
#   Optional: add add_icm_type_to_shapefiles.py alongside this script to add ICM_Type field to shapefiles.
#
# GETTING STARTED (NEW USERS)
#   1. Edit the CONFIGURATION section below with YOUR values.
#   2. db_path: Your ICM cloud database path. Format: cloud://DatabaseName@orgId/region
#   3. MODEL_GROUP_ID: Right-click your Model Group in ICM Explorer > Properties > Object ID.
#   4. OUTPUT_BASE: Folder where 24h.zip and 48h.zip will be created. Must match Publish_Shapefiles_to_AGOL.py SHAPEFILE_EXPORT_DIR.
#   5. Run Create and Run Simulations.rb first so 24h and 48h runs exist.
#   6. Execute via ICMExchange.exe (Exchange-only; cannot run from ICM UI).
#
# EXPORT TABLES (EXPORT_TABLES constant):
#   hw_node, _links, _2DElements, hw_subcatchment - adjust if your model uses different tables.
#
# API REFERENCES:
#   @https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Classes_ICM_wsapplication_html
#   @https://help.autodesk.com/view/IWICMS/2026/ENU/?guid=Innovyze_Exchange_Classes_ICM_wssimobject_html
#
# =============================================================================

require 'fileutils'
require 'json'

# --- CONFIGURATION ---
# REPLACE: Your ICM cloud database path. Format: cloud://DatabaseName@orgId/region
db_path = nil  # e.g. 'cloud://My Database ICM@abc123def456/namer'

# REPLACE: Model Group ID containing your 24h/48h runs. Find in ICM: right-click Model Group > Properties > Object ID
MODEL_GROUP_ID = 0  # e.g. 12316

# REPLACE: Folder where 24h.zip and 48h.zip will be created. Use path relative to script or absolute path.
OUTPUT_BASE = File.join(File.dirname(__FILE__), 'shapefile_exports')  # e.g. 'D:\\MyProject\\Shapefile Exports'

# Optional: convert specific SI fields to custom units (e.g. ft, cfs).
# Set to path of JSON config (field_name => factor), or true to use built-in defaults. nil = no conversion.
# Uses pure Ruby - no Python required.
CONVERT_SI_TO_CUSTOM = true

# --- END CONFIGURATION ---

EXPORT_TABLES = ['hw_node', '_links', '_2DElements', 'hw_subcatchment'].freeze

def collect_objects(mo, type_filter, acc = [])
  return acc if mo.nil?
  mo.children.each do |c|
    acc << c if type_filter.nil? || c.type == type_filter
    collect_objects(c, type_filter, acc)
  end
  acc
end

# Get the best sim for export. Exports even if run had errors or failed to complete - any partial
# results are exported. Prefers Succeeded with tables, then any sim with tables, then most recent sim.
def get_sim_for_export(run_obj)
  sims = []
  run_obj.children.each { |c| sims << c if c.type == 'Sim' || c.type == 'Risk Analysis Sim' }
  return nil if sims.empty?
  # Prefer Succeeded with export tables, then any sim with export tables (including failed/partial)
  succeeded = sims.find { |s| s.respond_to?(:status) && s.status == 'Succeeded' }
  return succeeded if succeeded && sim_has_export_tables?(succeeded)
  with_tables = sims.select { |s| sim_has_export_tables?(s) }.max_by { |s| s.id }
  return with_tables if with_tables
  # Fall back: most recent sim regardless of status or tables - attempt export of whatever exists
  sims.max_by { |s| s.id }
end

def sim_has_export_tables?(sim)
  return false if sim.nil?
  tables = sim.list_results_GIS_export_tables rescue []
  EXPORT_TABLES.any? { |t| tables.include?(t) }
end

def zip_folder(folder_path, zip_path)
  return unless Dir.exist?(folder_path)
  # PowerShell Compress-Archive - use single quotes so paths with spaces are preserved
  folder_path = folder_path.tr('/', '\\')
  zip_path = zip_path.tr('/', '\\')
  system('powershell', '-NoProfile', '-Command',
    "Compress-Archive -LiteralPath '#{folder_path}' -DestinationPath '#{zip_path}' -Force")
end

# 24h runs: single date name (e.g. 3/10/2026) - same as Create_48hr_Forecast_Run / Download_OpenMeteo_Rainfall
def run_name_is_24h?(name)
  return false if name.nil? || !name.is_a?(String)
  name =~ /^\d{1,2}\/\d{1,2}\/\d{4}$/ && !name.include?('-')
end

# 48h runs: date range name (e.g. 3/11-12/2026 or 3/31-4/1/2026)
def run_name_is_48h?(name)
  return false if name.nil? || !name.is_a?(String)
  name.include?('-') && (name =~ /^\d{1,2}\/\d{1,2}-\d{1,2}\/\d{4}$/ || name =~ /^\d{1,2}\/\d{1,2}-\d{1,2}\/\d{1,2}\/\d{4}$/)
end

# Default field conversion factors: SI -> US (m->ft: 3.28084, m3/s->cfs: 35.3147, m2->ft2: 10.7639)
def default_convert_factors
  m2ft = 3.28084
  m3s2cfs = 35.3147
  m2_2ft2 = 10.7639
  {
    'DEPTH2D' => m2ft, 'MINDEPTH2' => m2ft, 'MAXHAZDEPT' => m2ft,
    'SPEED2D' => m2ft, 'MINSPD2' => m2ft, 'MAXHAZSPD2' => m2ft,
    'AREA2D' => m2_2ft2, 'GNDLEV2D' => m2ft, 'elevation2' => m2ft,
    'MAXUNFL2D' => m2_2ft2, 'minunitflo' => m2_2ft2, 'VOLERR2d' => m3s2cfs,
    'ds_DEPTH' => m2ft, 'us_DEPTH' => m2ft,
    'ds_BC_DEPT' => m2ft, 'ds_BC_LEVE' => m2ft, 'ds_BD_DEPT' => m2ft,
    'ds_BD_LEVE' => m2ft, 'ds_BE_DEPT' => m2ft, 'ds_BE_LEVE' => m2ft,
    'us_BC_DEPT' => m2ft, 'us_BC_LEVE' => m2ft, 'us_BD_DEPT' => m2ft,
    'us_BD_LEVE' => m2ft, 'us_BE_DEPT' => m2ft, 'us_BE_LEVE' => m2ft,
    'ds_FLOW' => m3s2cfs, 'us_FLOW' => m3s2cfs,
    'ds_BC_FLOW' => m3s2cfs, 'ds_BD_FLOW' => m3s2cfs, 'ds_BE_FLOW' => m3s2cfs,
    'us_BC_FLOW' => m3s2cfs, 'us_BD_FLOW' => m3s2cfs, 'us_BE_FLOW' => m3s2cfs,
    'ds_VEL' => m2ft, 'us_VEL' => m2ft,
    'ds_BC_VEL' => m2ft, 'ds_BD_VEL' => m2ft, 'ds_BE_VEL' => m2ft,
    'us_BC_VEL' => m2ft, 'us_BD_VEL' => m2ft, 'us_BE_VEL' => m2ft,
    'ds_QCUM' => m3s2cfs, 'us_QCUM' => m3s2cfs,
    'ds_inv' => m2ft, 'us_inv' => m2ft, 'rr_inv' => m2ft,
    'dsBCTOTHEA' => m2ft, 'dsBDTOTHEA' => m2ft, 'dsBETOTHEA' => m2ft,
    'usBCTOTHEA' => m2ft, 'usBDTOTHEA' => m2ft, 'usBETOTHEA' => m2ft,
    'dsTOTHEAD' => m2ft, 'usTOTHEAD' => m2ft,
    'len' => m2ft, 'hgt' => m2ft,
    'PFC' => m3s2cfs, 'LateralInf' => m3s2cfs, 'QLICUM' => m3s2cfs,
    'Infiltrati' => m3s2cfs,
    'DEPNOD' => m2ft, 'fld_lvl' => m2ft, 'FloodDepth' => m2ft,
    'FloodVol' => m3s2cfs, 'DirectRuno' => m3s2cfs, 'QNODE' => m3s2cfs,
    'QINCUM' => m3s2cfs, 'QINFNOD' => m3s2cfs,
    'TWODDEPNOD' => m2ft, 'TwodFlFlow' => m3s2cfs, 'TwodFlow' => m3s2cfs,
    'TwodQCum' => m3s2cfs, 'TwodQCumFl' => m3s2cfs,
    'Vflood' => m3s2cfs, 'Vground' => m3s2cfs, 'VolBal' => m3s2cfs,
    'VOLUME' => m3s2cfs, 'FLVOL' => m3s2cfs, 'Q_TOT_LV' => m3s2cfs,
    'EffRain' => m2ft, 'Runoff' => m3s2cfs, 'Rainfall' => m2ft,
    'QBASE' => m3s2cfs, 'QCATCH' => m3s2cfs, 'QFOUL' => m3s2cfs,
    'QSURF01' => m3s2cfs, 'QSURF02' => m3s2cfs, 'QSURF03' => m3s2cfs
  }
end

# Convert specific shapefile fields from SI to custom units. Pure Ruby - no Python required.
# Modifies .dbf files in place using DBF binary format.
def convert_shapefile_units(dir, config_path = nil)
  return unless CONVERT_SI_TO_CUSTOM
  factors = if config_path && File.exist?(config_path)
    JSON.parse(File.read(config_path))
  elsif CONVERT_SI_TO_CUSTOM == true
    default_convert_factors
  else
    {}
  end
  return if factors.empty?

  Dir.glob(File.join(dir, '*.dbf')).each do |dbf_path|
    convert_dbf_fields(dbf_path, factors)
  end
rescue => e
  puts "WARNING: Could not convert shapefile units: #{e.message}"
end

# Parse and modify DBF file - multiply specified numeric fields by factors.
# DBF format: 32-byte header, field descriptors (32 bytes each, ends 0x0D), records.
def convert_dbf_fields(dbf_path, factors)
  data = File.binread(dbf_path)
  return if data.bytesize < 32

  header_size = data.getbyte(8) | (data.getbyte(9) << 8)
  record_size = data.getbyte(10) | (data.getbyte(11) << 8)
  num_records = data.getbyte(4) | (data.getbyte(5) << 8) | (data.getbyte(6) << 16) | (data.getbyte(7) << 24)

  # Parse field descriptors (start at 32, each 32 bytes, until 0x0D)
  fields = []
  offset = 1  # Skip 1-byte delete flag in each record
  pos = 32
  while pos + 32 <= data.bytesize && data.getbyte(pos) != 0x0D
    name = data[pos, 11].to_s.unpack1('a*').to_s.split("\0").first.to_s.strip
    ftype = data.getbyte(pos + 11).chr
    flen = data.getbyte(pos + 16)
    fdec = data.getbyte(pos + 17)
    fields << { name: name, type: ftype, len: flen, dec: fdec, offset: offset }
    offset += flen
    pos += 32
  end

  to_convert = fields.each_with_index.select { |f, _| factors.key?(f[:name]) && %w[N F].include?(f[:type]) }

  return if to_convert.empty?

  records_start = header_size
  modified = data.dup.force_encoding('ASCII-8BIT')
  num_records.times do |i|
    rec_start = records_start + i * record_size
    next if rec_start + record_size > modified.bytesize

    to_convert.each do |field, _|
      foff = rec_start + field[:offset]
      raw = modified[foff, field[:len]].to_s.strip
      next if raw.empty?

      begin
        val = Float(raw)
        new_val = (val * factors[field[:name]]).round(6)
        formatted = format("%#{field[:len]}.#{field[:dec]}f", new_val)
        formatted = formatted[-field[:len], field[:len]] if formatted.bytesize > field[:len]
        modified[foff, field[:len]] = formatted.ljust(field[:len])
      rescue ArgumentError
        nil
      end
    end
  end

  File.binwrite(dbf_path, modified)
  puts "Converted: #{File.basename(dbf_path)}"
end

# Run a Python script; tries 'python' then 'py -3' (Windows launcher).
def run_python(script_path, *args)
  cmd = ['python', script_path, *args]
  return true if system(*cmd)
  system('py', '-3', script_path, *args) if Gem.win_platform?
end

# Add ICM_Type field to Links and Nodes shapefiles using type from network.
# Uses Python + pyshp (pip install pyshp) to modify shapefiles.
def add_icm_type_to_shapefiles(sim, dir)
  net = sim.open rescue nil
  return if net.nil?
  link_types = {}
  node_types = {}
  net.row_objects('_links').each { |ro| link_types[ro.id.to_s] = (ro['link_type'] || ro['type'] || '').to_s }
  net.row_objects('hw_node').each { |ro| node_types[ro.id.to_s] = (ro['node_type'] || ro['type'] || '').to_s }
  net.close rescue nil

  json_path = File.join(dir, '_icm_type_map.json')
  File.open(json_path, 'w') { |f| f.write({ 'links' => link_types, 'nodes' => node_types }.to_json) }

  py_script = File.join(File.dirname(__FILE__), 'add_icm_type_to_shapefiles.py')
  if File.exist?(py_script)
    run_python(py_script, dir, json_path)
  else
    puts "WARNING: add_icm_type_to_shapefiles.py not found - skipping ICM_Type field."
  end
  File.delete(json_path) rescue nil
rescue => e
  puts "WARNING: Could not add ICM_Type: #{e.message}"
end

# Export all tables via results_GIS_export (ExportMaxima) to shapefiles. Native units.
def export_via_gis_maxima(sim, dir, tables)
  return false if tables.nil? || tables.empty?

  exp_params = { 'Tables' => tables, 'ExportMaxima' => true, 'Threshold' => 0.05 }
  sim.results_GIS_export 'SHP', 'Max', exp_params, "#{dir}/"
  true
end

if db_path.nil? || db_path.to_s.strip.empty?
  puts "ERROR: Set db_path in the script configuration."
  exit 1
end

if MODEL_GROUP_ID.nil? || (MODEL_GROUP_ID.respond_to?(:to_i) && MODEL_GROUP_ID.to_i == 0)
  puts "ERROR: Set MODEL_GROUP_ID in the script configuration (integer > 0)."
  exit 1
end

db = WSApplication.open db_path, false

model_group = db.model_object_from_type_and_id 'Model Group', MODEL_GROUP_ID
if model_group.nil?
  puts "ERROR: Model Group not found (ID #{MODEL_GROUP_ID})."
  exit 1
end

# Find the most recent 24h and 48h runs in Model Group 12316.
# 24h: single date (e.g. 3/10/2026). 48h: date range (e.g. 3/11-12/2026).
all_runs = collect_objects(model_group, 'Run')
runs_with_sims = all_runs.map do |r|
  sim = get_sim_for_export(r)
  [r, sim] if sim
end.compact

runs_24h = runs_with_sims.select { |r, _s| run_name_is_24h?(r.name) }.sort_by { |r, _s| -r.id }
runs_48h = runs_with_sims.select { |r, _s| run_name_is_48h?(r.name) }.sort_by { |r, _s| -r.id }

run_24h, sim_24h = runs_24h.first
run_48h, sim_48h = runs_48h.first

if run_24h.nil? || run_48h.nil?
  puts "ERROR: Need the most recent 24h run AND the most recent 48h run in Model Group #{MODEL_GROUP_ID}."
  puts "Found: 24h runs=#{runs_24h.size}, 48h runs=#{runs_48h.size}"
  exit 1
end

puts "Exporting 24h run (most recent): #{run_24h.path}"
puts "Exporting 48h run (most recent): #{run_48h.path}"

FileUtils.mkdir_p OUTPUT_BASE

dir_24h = File.join(OUTPUT_BASE, '24h')
dir_48h = File.join(OUTPUT_BASE, '48h')
FileUtils.rm_rf dir_24h
FileUtils.rm_rf dir_48h
FileUtils.mkdir_p dir_24h
FileUtils.mkdir_p dir_48h

# Export 24h run via results_GIS_export (ExportMaxima) to shapefiles and zipped files.
available_24 = sim_24h.list_results_GIS_export_tables rescue []
tables_24 = EXPORT_TABLES.select { |t| available_24.include?(t) }
if tables_24.any?
  export_via_gis_maxima(sim_24h, dir_24h, tables_24)
  puts "Exported 24h via results_GIS_export (Max): #{tables_24.join(', ')}"
  subdirs_24 = Dir.children(dir_24h).map { |c| File.join(dir_24h, c) }.select { |p| File.directory?(p) }
  subdirs_24.each do |sd|
    config_path = CONVERT_SI_TO_CUSTOM.is_a?(String) ? CONVERT_SI_TO_CUSTOM : nil
    convert_shapefile_units(sd, config_path)
    add_icm_type_to_shapefiles(sim_24h, sd)
  end
  zip_folder(dir_24h, File.join(OUTPUT_BASE, '24h.zip'))
  puts "Created 24h.zip"
else
  puts "WARNING: No export tables for 24h run"
end

# Export 48h run via results_GIS_export (ExportMaxima) to shapefiles and zipped files.
available_48 = sim_48h.list_results_GIS_export_tables rescue []
tables_48 = EXPORT_TABLES.select { |t| available_48.include?(t) }
if tables_48.any?
  export_via_gis_maxima(sim_48h, dir_48h, tables_48)
  puts "Exported 48h via results_GIS_export (Max): #{tables_48.join(', ')}"
  subdirs_48 = Dir.children(dir_48h).map { |c| File.join(dir_48h, c) }.select { |p| File.directory?(p) }
  subdirs_48.each do |sd|
    config_path = CONVERT_SI_TO_CUSTOM.is_a?(String) ? CONVERT_SI_TO_CUSTOM : nil
    convert_shapefile_units(sd, config_path)
    add_icm_type_to_shapefiles(sim_48h, sd)
  end
  zip_folder(dir_48h, File.join(OUTPUT_BASE, '48h.zip'))
  puts "Created 48h.zip"
else
  puts "WARNING: No export tables for 48h run"
end

puts "Export complete at #{Time.now}"
