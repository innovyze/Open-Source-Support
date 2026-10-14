# INTERFACE SCRIPT
# ODEC shapefile export + new File Geodatabase via QGIS/GDAL (no ArcGIS Pro).
# ArcGIS Pro ingest variant: UI-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb

SCRIPT_DIR = File.dirname(WSApplication.script_file)
DEFAULT_CONFIG_FILE = File.join(SCRIPT_DIR, 'odec_export_ex-SHP.cfg')
DEFAULT_STAGING_FOLDER = File.join(SCRIPT_DIR, 'staging_shp')
DEFAULT_ERROR_FILE = File.join(DEFAULT_STAGING_FOLDER, 'odec_export_errors.txt')
DEFAULT_OUTPUT_GDB = 'C:\\Temp\\IAMFullSync.gdb'
DEFAULT_QGIS_ROOT = 'C:\\Program Files\\QGIS 4.0.3'

EXPORT_LAYERS = [
  ['node', 'node'],
  ['pipe', 'pipe']
]

def win_path(path)
  path.to_s.strip.gsub('/', '\\')
end

def prompt_cancel(message)
  WSApplication.message_box("#{message}\nScript cancelled", 'OK', '!', false)
  raise 'abort'
end

def shapefile_path(staging_folder, base_name)
  path = File.join(staging_folder, "#{base_name}.shp")
  return path if File.file?(path)

  path = File.join(staging_folder, "#{base_name}.SHP")
  return path if File.file?(path)

  raise "Shapefile not found for layer '#{base_name}' in #{staging_folder}"
end

def run_qgis_gdb_ingest(staging_folder, output_gdb, qgis_root, export_layers)
  wrapper = File.join(SCRIPT_DIR, 'invoke_qgis_ingest.bat')
  unless File.file?(wrapper)
    raise "QGIS ingest helper not found: #{wrapper}"
  end

  export_layers.each do |layer|
    _table, base_name = layer
    shapefile_path(staging_folder, base_name)
  end

  puts "Starting QGIS/GDAL ingest -> #{output_gdb}"
  cmd = 'cmd /c ""' + wrapper + '" "' + staging_folder + '" "' + output_gdb + '" "' + qgis_root + '""'
  system(cmd)
  exit_code = $?.exitstatus

  log_path = File.join(staging_folder, 'qgis_ingest.log')
  if exit_code != 0
    detail = ''
    if File.file?(log_path)
      lines = File.read(log_path).strip.split(/\r?\n/)
      detail = lines.last([8, lines.length].min).join("\n")
    end
    msg = "QGIS/GDAL ingest failed (exit #{exit_code}). See #{log_path}"
    msg = msg + ":\n\n" + detail unless detail.empty?
    raise msg
  end
  puts "Geodatabase ingest complete: #{output_gdb}"
end

def prompt_export_settings
  val = WSApplication.prompt(
    'ODEC export + QGIS File Geodatabase',
    [
      ['ODEC export config (.cfg, DBX002):', 'String', DEFAULT_CONFIG_FILE, nil, 'FILE', true, 'cfg', 'Select ODEC export config', false],
      ['Shapefile staging folder:', 'String', DEFAULT_STAGING_FOLDER, nil, 'FOLDER', 'Staging folder'],
      ['ODEC error log file:', 'String', DEFAULT_ERROR_FILE, nil, 'FILE', false, 'txt', 'ODEC error log', false],
      ['Units behaviour:', 'String', 'Native', nil, 'LIST', ['Native', 'User']],
      ['Export selection only', 'Boolean', false],
      ['Export as WGS84', 'Boolean', false],
      ['Build File Geodatabase with QGIS after export', 'Boolean', true],
      ['Output File Geodatabase (.gdb):', 'String', DEFAULT_OUTPUT_GDB],
      ['QGIS install folder (contains bin\\ogr2ogr.exe):', 'String', DEFAULT_QGIS_ROOT]
    ],
    false
  )
  prompt_cancel('Parameters dialog closed') if val.nil?

  config_file = win_path(val[0])
  prompt_cancel('ODEC config file is required') if config_file.empty?
  prompt_cancel("ODEC config not found:\n#{config_file}") unless File.file?(config_file)

  staging_folder = win_path(val[1])
  prompt_cancel('Staging folder is required') if staging_folder.empty?

  error_file = win_path(val[2])
  units = val[3].to_s.strip
  units = 'Native' if units.empty?

  options = Hash.new
  options['Error File'] = error_file unless error_file.empty?
  options['Units Behaviour'] = units
  options['Export Selection'] = true if val[4]
  options['WGS84'] = true if val[5]

  run_ingest = val[6] ? true : false
  output_gdb = win_path(val[7])
  qgis_root = win_path(val[8])
  prompt_cancel('Output .gdb path is required when QGIS ingest is enabled') if run_ingest && output_gdb.empty?
  prompt_cancel('QGIS install folder is required when QGIS ingest is enabled') if run_ingest && qgis_root.empty?

  {
    config_file: config_file,
    staging_folder: staging_folder,
    options: options,
    run_qgis_ingest: run_ingest,
    output_gdb: output_gdb,
    qgis_root: qgis_root
  }
end

settings = prompt_export_settings
nw = WSApplication.current_network
Dir.mkdir(settings[:staging_folder]) unless Dir.exist?(settings[:staging_folder])

EXPORT_LAYERS.each do |table, base_name|
  dest = File.join(settings[:staging_folder], "#{base_name}.SHP")
  puts "Exporting #{table} -> #{dest}"
  nw.odec_export_ex('SHP', settings[:config_file], settings[:options], table, dest)
end

puts "Shapefile staging complete: #{settings[:staging_folder]}"

if settings[:run_qgis_ingest]
  run_qgis_gdb_ingest(
    settings[:staging_folder],
    settings[:output_gdb],
    settings[:qgis_root],
    EXPORT_LAYERS
  )
end
