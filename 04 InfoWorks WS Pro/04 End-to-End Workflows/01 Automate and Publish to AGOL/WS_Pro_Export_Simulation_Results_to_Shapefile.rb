# =============================================================================
# WS Pro — Step 2: Export simulation results to shapefiles (Exchange script)
# =============================================================================
#
# PURPOSE
#   Finds the most recent successful simulation under a Wesnet Run Group, exports
#   maximum (peak) results for all available WS network tables to shapefiles, and
#   packages them into a flat ZIP ready for ArcGIS Online.
#
# WORKFLOW
#   Step 1  →  WS_Pro_Create_and_Run_Weekly_Simulation.rb
#   Step 2  →  this script
#   Step 3  →  Publish_WS_Pro_Weekly_Shapefiles_to_AGOL.py
#   Orchestrate all three with Run_All_Weekly_WS_Pro_Workflow.bat
#
# QUICK START
#   1. Set DB_PATH to your InfoWorks WS Pro database connection string.
#   2. Set RUN_GROUP_ID to the Model Object ID of your Wesnet Run Group.
#   3. Set OUTPUT_BASE to a local folder where shapefiles and the ZIP will be saved.
#   4. Run via:
#        WSProExchange.exe "<path>\WS_Pro_Export_Simulation_Results_to_Shapefile.rb" /WS
#
# HOW THE RUN IS FOUND
#   Step 1 writes the new run's ID to OUTPUT_BASE\last_export_run_id.txt.
#   This script reads that marker first. If the marker is missing or invalid,
#   it falls back to the newest run in the group that has a completed simulation.
#
# OUTPUT
#   OUTPUT_BASE\EXPORT_SUBDIR\  — raw shapefile components (one set per table)
#   OUTPUT_BASE\ZIP_NAME        — flat ZIP with all files at root (AGOL requirement)
#
# NOTES
#   - ExportMaxima = true  →  peak values across the full simulation, not a timestep
#   - Coordinates are exported in the model's native unit (set in WS Pro preferences)
#   - .prj files are left as WS Pro writes them; Step 3 applies a named CRS for AGOL
#   - DBF fields with empty names are stripped (AGOL rejects null-named columns)
#   - WS Pro 2026 may require an active ArcGIS Portal session for the export. Set
#     AGOL_USERNAME and AGOL_PASSWORD as environment variables in your .bat file;
#     this script will attempt to establish a session automatically.
#
# =============================================================================

require 'fileutils'

# ===========================================================================
# CONFIGURATION — fill in every value below before running
# ===========================================================================

# InfoWorks WS Pro database path.
# Local file example:   'C:\WS Pro Models\MyProject.iws'
# Cloud example:        'cloud://Organisation Name@orgid/database'
DB_PATH = 'cloud://YOUR_ORG_NAME@YOUR_ORG_ID/YOUR_DATABASE'

# Model Object ID of the Wesnet Run Group containing the simulations to export.
RUN_GROUP_ID = 0  # e.g. 1234

# Root output folder — shapefiles and the final ZIP are written here.
OUTPUT_BASE = 'C:\\WS Pro Results'

# Subfolder name for the raw shapefile files.
EXPORT_SUBDIR = 'weekly_ws_pro'

# Filename for the ZIP passed to Step 3.
ZIP_NAME = 'weekly_ws_pro.zip'

# All WS network tables that may appear in results; unavailable ones are skipped automatically.
# Table names sourced from: https://help2.innovyze.com/infoworkswspro/Content/HTML/WS/data_field_information/WSeng/r_data_fields_network.htm
# Note: wn_pst = Pump Station (link object); wn_pump = individual Pump Curve (link object) — both are included.
# Add or remove entries here to match the asset types in your model.
EXPORT_TABLE_CANDIDATES = %w[
  wn_node          wn_pipe            wn_valve          wn_reservoir
  wn_fixed_head    wn_hydrant         wn_well           wn_transfer_node
  wn_pst           wn_pump            wn_non_return_valve
  wn_meter         wn_adp             wn_filter
].freeze

# WS Pro type strings tried in order when looking up model objects by ID.
RUN_GROUP_TYPES = ['Wesnet Run Group', 'Run Group'].freeze
RUN_TYPES       = ['Wesnet Run',       'Run'      ].freeze

# ===========================================================================
# END CONFIGURATION
# ===========================================================================


# ---------------------------------------------------------------------------
# Helper methods
# ---------------------------------------------------------------------------

# Recursively collect all model objects of a given type under a parent object.
def collect_objects(mo, type_filter, acc = [])
  return acc if mo.nil?
  mo.children.each do |c|
    acc << c if type_filter.nil? || c.type == type_filter
    collect_objects(c, type_filter, acc)
  end
  acc
end

# Look up the Wesnet Run Group by ID, trying each known type string.
def resolve_run_group(db)
  RUN_GROUP_TYPES.each do |t|
    mo = db.model_object_from_type_and_id(t, RUN_GROUP_ID) rescue nil
    return mo if mo
  end
  nil
end

# Look up any run by ID, trying each known type string.
def find_run_by_id(db, run_id)
  RUN_TYPES.each do |t|
    mo = db.model_object_from_type_and_id(t, run_id) rescue nil
    return mo if mo
  end
  nil
end

# Recursively collect every descendant of a model object.
def collect_descendants(mo, acc = [])
  return acc if mo.nil?
  mo.children.each { |c| acc << c; collect_descendants(c, acc) }
  acc
end

# Return true if the object is a simulation (not a Run or Run Group) that can export.
def exportable_sim?(mo)
  return false if mo.nil? || !mo.respond_to?(:results_GIS_export)
  t = mo.type.to_s
  t != 'Wesnet Run' && t != 'Run' && t !~ /Run Group/i
end

# Return true if a simulation has finished successfully.
def sim_completed?(sim)
  return false unless sim.respond_to?(:status)
  st = sim.status.to_s.strip.downcase
  return false if %w[pending running queued fail failed error cancelled canceled aborted].include?(st)
  st.include?('success') || st.include?('succeed') || st.include?('complete') || st == 'ok' || st == 'done'
end

# Return the best completed simulation under a run, or nil if none exist.
# Logs all candidates when no completed sim is found (aids diagnosis).
def best_sim_for_export(run_obj)
  sims = collect_descendants(run_obj).select { |c| exportable_sim?(c) }
  return nil if sims.empty?
  completed = sims.select { |s| sim_completed?(s) }
  return completed.max_by { |s| s.id } unless completed.empty?
  sims.each { |s| puts "  Sim candidate: id=#{s.id} type=#{s.type} status=#{s.respond_to?(:status) ? s.status.inspect : 'n/a'}" }
  nil
end

# Strip DBF field descriptors with empty/null names and rebuild the file.
# ArcGIS Online rejects shapefiles containing null-named attribute columns.
def fix_dbf_files(folder_path)
  Dir.glob(File.join(folder_path, '**', '*.dbf')).each do |path|
    data = File.binread(path)
    next if data.size < 33

    num_records = data[4,  4].unpack1('V')
    hdr_bytes   = data[8,  2].unpack1('v')
    record_size = data[10, 2].unpack1('v')

    # Parse 32-byte field descriptors starting at offset 32; stop at 0x0D terminator
    all_fields = []
    offset = 32
    while offset + 32 <= hdr_bytes && data.getbyte(offset) != 0x0D
      name = data[offset, 11].split("\x00".b).first.to_s.strip
      flen = data.getbyte(offset + 16)
      all_fields << { name: name, len: flen, raw: data[offset, 32] }
      offset += 32
    end

    valid_fields = all_fields.select { |f| !f[:name].empty? }
    next if valid_fields.size == all_fields.size  # nothing to strip

    puts "  Fixing DBF #{File.basename(path)}: removing #{all_fields.size - valid_fields.size} empty-name field(s)"

    # Map old field byte positions within a record (byte 0 is deletion flag)
    old_offsets = []
    pos = 1
    all_fields.each { |f| old_offsets << [pos, f[:len]]; pos += f[:len] }
    valid_idx = all_fields.each_index.select { |i| !all_fields[i][:name].empty? }

    new_hdr_bytes   = 32 + valid_fields.size * 32 + 1
    new_record_size = 1 + valid_fields.sum { |f| f[:len] }

    hdr = data[0, 32].b
    hdr[8,  2] = [new_hdr_bytes].pack('v')
    hdr[10, 2] = [new_record_size].pack('v')

    field_block = valid_fields.map { |f| f[:raw] }.join.b + "\x0D".b
    field_block << "\x00".b * (new_hdr_bytes - 32 - field_block.size) if field_block.size < new_hdr_bytes - 32

    records = ''.b
    num_records.times do |r|
      old_rec = data[hdr_bytes + r * record_size, record_size] || ''
      break if old_rec.empty?
      new_rec = old_rec[0].b
      valid_idx.each { |i| s, l = old_offsets[i]; new_rec << (old_rec[s, l] || "\x00".b * l).b }
      records << new_rec
    end

    File.binwrite(path, hdr + field_block + records)
  end
end

# Zip all files under folder_path into a flat ZIP (files at root, no subdirectories).
# Uses .NET ZipFile via PowerShell — required for ArcGIS Online compatibility.
def zip_files_flat(folder_path, zip_path)
  folder_path = folder_path.tr('/', '\\')
  zip_path    = zip_path.tr('/', '\\')
  ps = <<~PS
    Add-Type -Assembly 'System.IO.Compression.FileSystem'
    if (Test-Path '#{zip_path}') { Remove-Item '#{zip_path}' -Force }
    $zip = [System.IO.Compression.ZipFile]::Open('#{zip_path}', 'Create')
    Get-ChildItem -Path '#{folder_path}' -Recurse -File | ForEach-Object {
      [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $_.FullName, $_.Name) | Out-Null
    }
    $zip.Dispose()
  PS
  system('powershell', '-NoProfile', '-Command', ps)
end

# ---------------------------------------------------------------------------
# Start-up validation
# ---------------------------------------------------------------------------
if RUN_GROUP_ID == 0
  puts 'ERROR: RUN_GROUP_ID is still 0. Set it to your Wesnet Run Group Model Object ID.'
  exit 1
end

if DB_PATH.include?('YOUR_')
  puts 'ERROR: DB_PATH has not been configured. Set it to your WS Pro database connection string.'
  exit 1
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
db = WSApplication.open(DB_PATH, false)

run_group = resolve_run_group(db)
if run_group.nil?
  puts "ERROR: Run Group ID #{RUN_GROUP_ID} not found."
  exit 1
end

# Step 1 writes the run ID here so we export the correct simulation
marker_path  = File.join(OUTPUT_BASE, 'last_export_run_id.txt')
preferred_id = File.exist?(marker_path) ? File.read(marker_path).strip.to_i : nil
preferred_id = nil if preferred_id.nil? || preferred_id <= 0

run_obj = preferred_id ? find_run_by_id(db, preferred_id) : nil
if run_obj.nil? && preferred_id
  puts "WARNING: Marker run id=#{preferred_id} not found; falling back to newest run in group."
end

# Fallback: find the newest run in the group that has a completed simulation
if run_obj.nil?
  all_runs   = collect_objects(run_group, 'Wesnet Run')
  all_runs  |= collect_objects(run_group, 'Run')
  candidates = all_runs.map { |r| [r, best_sim_for_export(r)] }.select { |_r, s| s }
  if candidates.empty?
    puts "ERROR: No runs with a completed simulation under #{run_group.path}."
    exit 1
  end
  run_obj, = candidates.max_by { |r, _| r.id }
end

sim = best_sim_for_export(run_obj)
if sim.nil?
  puts "ERROR: No completed simulation found under run #{run_obj.path}."
  exit 1
end

puts "Exporting run : #{run_obj.path} (id=#{run_obj.id})"
puts "Simulation    : #{sim.path} (status=#{sim.respond_to?(:status) ? sim.status : 'n/a'})"

# Filter the candidate table list to only those the simulation can actually export
available = sim.list_results_GIS_export_tables rescue []
tables    = EXPORT_TABLE_CANDIDATES.select { |t| available.include?(t) }
if tables.empty?
  puts "ERROR: No exportable tables found. Available: #{available.inspect}"
  exit 1
end
puts "Tables        : #{tables.join(', ')}"

# ---------------------------------------------------------------------------
# Optional: attempt ArcGIS Portal login before export.
# WS Pro 2026 routes results_GIS_export through the ODEC/ArcGIS pipeline.
# Credentials come from environment variables set in the .bat file.
# ---------------------------------------------------------------------------
agol_pass = ENV.fetch('AGOL_PASSWORD', '')
unless agol_pass.empty?
  agol_url  = ENV.fetch('AGOL_URL',      'https://www.arcgis.com')
  agol_user = ENV.fetch('AGOL_USERNAME', '')
  connected = false
  [:connect_to_gis_portal, :connect_to_portal, :arcgis_connect, :connect_to_gis].each do |meth|
    next unless WSApplication.respond_to?(meth)
    begin
      WSApplication.send(meth, agol_url, agol_user, agol_pass)
      puts "ArcGIS Portal session established via WSApplication.#{meth}"
      connected = true
      break
    rescue => e
      puts "Note: WSApplication.#{meth} — #{e.message}"
    end
  end
  puts 'Note: No ArcGIS Portal connect method found; continuing anyway.' unless connected
end

# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------
FileUtils.mkdir_p(OUTPUT_BASE)
export_dir = File.join(OUTPUT_BASE, EXPORT_SUBDIR)
FileUtils.rm_rf(export_dir)
FileUtils.mkdir_p(export_dir)

# ExportMaxima = true  →  peak values across the full simulation, not a single timestep
exp_params = { 'Tables' => tables, 'ExportMaxima' => true, 'Threshold' => 0.05 }
begin
  sim.results_GIS_export('SHP', 'Max', exp_params, "#{export_dir}/")
  puts 'Export complete.'
rescue RuntimeError => e
  # WS Pro 2026 may throw an ArcGIS auth error after the files have been written.
  # If shapefiles exist we treat this as a non-fatal warning and continue.
  if e.message.include?('ArcGIS') || e.message.include?('ODEC') || e.message.include?('logged in')
    shp_count = Dir.glob(File.join(export_dir, '**', '*.shp')).size
    if shp_count > 0
      puts "WARNING: ArcGIS auth error after export (#{e.message.lines.first.strip})."
      puts "  #{shp_count} SHP file(s) were written — continuing with post-processing."
    else
      puts "ERROR: Export failed and no SHP files were created: #{e.message}"
      exit 1
    end
  else
    raise
  end
end

# Strip empty-name DBF columns (AGOL publish will fail otherwise)
fix_dbf_files(export_dir)

# Package into a flat ZIP (all files at root — AGOL requires this structure)
zip_path = File.join(OUTPUT_BASE, ZIP_NAME)
zip_files_flat(export_dir, zip_path)

if File.exist?(zip_path)
  puts "ZIP created : #{zip_path}"
else
  puts 'WARNING: ZIP was not created; check the PowerShell output above.'
end

puts "Finished at #{Time.now}"
