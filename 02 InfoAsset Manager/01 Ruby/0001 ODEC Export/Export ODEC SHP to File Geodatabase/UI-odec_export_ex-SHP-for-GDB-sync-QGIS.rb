# INTERFACE SCRIPT
# ODEC shapefile export + new File Geodatabase via QGIS/GDAL (no ArcGIS Pro).
# ArcGIS Pro ingest variant: UI-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb

SCRIPT_DIR = File.dirname(WSApplication.script_file)
DEFAULT_CONFIG_FILE = File.join(SCRIPT_DIR, 'odec_export_ex-SHP.cfg')
DEFAULT_STAGING_FOLDER = File.join(SCRIPT_DIR, 'staging_shp')
DEFAULT_ERROR_FILE = File.join(DEFAULT_STAGING_FOLDER, 'odec_export_errors.txt')
DEFAULT_OUTPUT_GDB = 'C:\\Temp\\IAMFullSync.gdb'
DEFAULT_QGIS_ROOT = 'C:\\Program Files\\QGIS 4.0.3'

INGEST_SCRIPT = File.join(SCRIPT_DIR, 'ingest_shp_to_file_gdb_ogr.py')

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

def run_qgis_gdb_ingest(staging_folder, output_gdb, qgis_root, export_layers)
  ogr2ogr = File.join(qgis_root, 'bin', 'ogr2ogr.exe')
  python = File.join(qgis_root, 'bin', 'python.exe')
  unless File.file?(ogr2ogr)
    raise "QGIS ogr2ogr not found: #{ogr2ogr}. Check QGIS install folder in the prompt."
  end
  unless File.file?(INGEST_SCRIPT)
    raise "Ingest script not found: #{INGEST_SCRIPT}"
  end

  puts "Starting QGIS/GDAL ingest -> #{output_gdb}"

  if File.file?(python)
    ok = system(
      python,
      INGEST_SCRIPT,
      '--staging', staging_folder,
      '--gdb', output_gdb,
      '--ogr2ogr', ogr2ogr
    )
  else
    o4w_env = File.join(qgis_root, 'bin', 'o4w_env.bat')
    unless File.file?(o4w_env)
      raise "QGIS environment not found: #{o4w_env}"
    end
    shp_for = lambda do |base|
      path = File.join(staging_folder, "#{base}.shp")
      File.file?(path) ? path : File.join(staging_folder, "#{base}.SHP")
    end
    cmd = "call \"#{o4w_env}\" && \"#{ogr2ogr}\" -f OpenFileGDB \"#{output_gdb}\" \"#{shp_for.call(export_layers[0][1])}\" -nln Node -overwrite"
    export_layers[1..-1].each do |_table, base_name|
      fc = base_name.capitalize
      cmd << " && \"#{ogr2ogr}\" -f OpenFileGDB -update \"#{output_gdb}\" \"#{shp_for.call(base_name)}\" -nln #{fc} -overwrite"
    end
    ok = system('cmd', '/c', cmd)
  end

  exit_code = $?.exitstatus
  unless ok && exit_code == 0
    raise "QGIS/GDAL ingest failed (exit #{exit_code.inspect})"
  end
  puts "Geodatabase ingest complete: #{output_gdb}"
end

def prompt_export_settings
  val = WSApplication.prompt(
    'ODEC export + QGIS File Geodatabase',
    [
      ['ODEC export config (.cfg, DBX002):', 'String', DEFAULT_CONFIG_FILE, nil, 'FILE', false, 'cfg', 'Select ODEC export config', false],
      ['Shapefile staging folder:', 'String', DEFAULT_STAGING_FOLDER, nil, 'FOLDER', 'Staging folder'],
      ['ODEC error log file:', 'String', DEFAULT_ERROR_FILE, nil, 'FILE', true, 'txt', 'ODEC error log', false],
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
