# INTERFACE SCRIPT
# ODEC shapefile export + optional ArcGIS Pro File Geodatabase ingest (ingest_shp_to_file_gdb_arcgis.py).
# QGIS/GDAL one-step variant: UI-odec_export_ex-SHP-for-GDB-sync-QGIS.rb
SCRIPT_DIR = File.dirname(WSApplication.script_file)
DEFAULT_CONFIG_FILE = File.join(SCRIPT_DIR, 'odec_export_ex-SHP.cfg')
DEFAULT_STAGING_FOLDER = File.join(SCRIPT_DIR, 'staging_shp')
DEFAULT_ERROR_FILE = File.join(DEFAULT_STAGING_FOLDER, 'odec_export_errors.txt')
DEFAULT_OUTPUT_GDB = 'C:\\Temp\\IAMFullSync.gdb'

PROPY_BAT = 'C:\\Program Files\\ArcGIS\\Pro\\bin\\Python\\Scripts\\propy.bat'
INGEST_SCRIPT = File.join(SCRIPT_DIR, 'ingest_shp_to_file_gdb_arcgis.py')

# [IAM ODEC table name, shapefile base name without extension]
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

def prompt_export_settings
  val = WSApplication.prompt(
    'ODEC export to shapefile (GDB sync staging)',
    [
      ['ODEC export config (.cfg, DBX002):', 'String', DEFAULT_CONFIG_FILE, nil, 'FILE', true, 'cfg', 'Select ODEC export config', false],
      ['Shapefile staging folder:', 'String', DEFAULT_STAGING_FOLDER, nil, 'FOLDER', 'Staging folder'],
      ['ODEC error log file:', 'String', DEFAULT_ERROR_FILE, nil, 'FILE', false, 'txt', 'ODEC error log', false],
      ['Units behaviour:', 'String', 'Native', nil, 'LIST', ['Native', 'User']],
      ['Export selection only', 'Boolean', false],
      ['Export as WGS84', 'Boolean', false],
      ['Run ArcGIS Pro ingest after export', 'Boolean', false],
      ['Output File Geodatabase (.gdb):', 'String', DEFAULT_OUTPUT_GDB]
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
  prompt_cancel('Output .gdb path is required when ArcGIS Pro ingest is enabled') if run_ingest && output_gdb.empty?

  {
    config_file: config_file,
    staging_folder: staging_folder,
    options: options,
    run_arcpy_ingest: run_ingest,
    output_gdb: output_gdb
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

if settings[:run_arcpy_ingest]
  unless File.file?(PROPY_BAT)
    raise "ArcGIS Pro propy.bat not found: #{PROPY_BAT}"
  end
  unless File.file?(INGEST_SCRIPT)
    raise "Ingest script not found: #{INGEST_SCRIPT}"
  end

  puts "Starting ArcGIS Pro ingest -> #{settings[:output_gdb]}"
  ok = system(
    PROPY_BAT,
    INGEST_SCRIPT,
    '--staging', settings[:staging_folder],
    '--gdb', settings[:output_gdb]
  )
  exit_code = $?.exitstatus
  unless ok && exit_code == 0
    raise "ArcPy ingest failed (exit #{exit_code.inspect})"
  end
  puts "Geodatabase ingest complete: #{settings[:output_gdb]}"
end
