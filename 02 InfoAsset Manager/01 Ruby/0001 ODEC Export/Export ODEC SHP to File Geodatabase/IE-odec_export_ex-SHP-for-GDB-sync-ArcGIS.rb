# EXCHANGE SCRIPT
# ODEC shapefile export + optional ArcGIS Pro File Geodatabase ingest (ingest_shp_to_file_gdb_arcgis.py).
# QGIS/GDAL one-step variant: IE-odec_export_ex-SHP-for-GDB-sync-QGIS.rb
begin
  SCRIPT_DIR = File.dirname(WSApplication.script_file)
  STAGING_FOLDER = File.join(SCRIPT_DIR, 'staging_shp')
  CONFIG_FILE = File.join(SCRIPT_DIR, 'odec_export_ex-SHP.cfg')

  # Edit for your database and network
  DB_URI = '//localhost:40000/IA_NEW'
  NETWORK_TYPE = 'Collection Network'
  NETWORK_ID = 4

  EXPORT_LAYERS = [
    ['node', 'node'],
    ['pipe', 'pipe']
  ]

  # Set true to run ingest_shp_to_file_gdb_arcgis.py after shapefile export (requires ArcGIS Pro on this machine).
  RUN_ARCPY_INGEST = false
  PROPY_BAT = 'C:\\Program Files\\ArcGIS\\Pro\\bin\\Python\\Scripts\\propy.bat'
  INGEST_SCRIPT = File.join(SCRIPT_DIR, 'ingest_shp_to_file_gdb_arcgis.py')
  OUTPUT_GDB = 'C:\\Temp\\IAMFullSync.gdb'

  unless File.file?(CONFIG_FILE)
    raise "Export config not found: #{CONFIG_FILE}. Save a DBX002 config from ODEC (File Geodatabase mapping) as this file."
  end

  Dir.mkdir(STAGING_FOLDER) unless Dir.exist?(STAGING_FOLDER)

  db = WSApplication.open(DB_URI, false)
  nw = db.model_object_from_type_and_id(NETWORK_TYPE, NETWORK_ID)

  current_commit_id = nw.current_commit_id
  latest_commit_id = nw.latest_commit_id
  if latest_commit_id > current_commit_id
    puts "Updating from commit #{current_commit_id} to #{latest_commit_id}"
    nw.update
  else
    puts 'Network is up to date'
  end

  net = nw.open

  options = Hash.new
  options['Error File'] = File.join(STAGING_FOLDER, 'odec_export_errors.txt')

  EXPORT_LAYERS.each do |table, base_name|
    dest = File.join(STAGING_FOLDER, "#{base_name}.SHP")
    puts "Exporting #{table} -> #{dest}"
    net.odec_export_ex('SHP', CONFIG_FILE, options, table, dest)
  end

  net.close
  puts "Shapefile staging complete: #{STAGING_FOLDER}"

  if RUN_ARCPY_INGEST
    unless File.file?(PROPY_BAT)
      raise "ArcGIS Pro propy.bat not found: #{PROPY_BAT}"
    end
    unless File.file?(INGEST_SCRIPT)
      raise "Ingest script not found: #{INGEST_SCRIPT}"
    end

    puts "Starting ArcGIS Pro ingest -> #{OUTPUT_GDB}"
    ok = system(
      PROPY_BAT,
      INGEST_SCRIPT,
      '--staging', STAGING_FOLDER,
      '--gdb', OUTPUT_GDB
    )
    exit_code = $?.exitstatus
    unless ok && exit_code == 0
      raise "ArcPy ingest failed (exit #{exit_code.inspect})"
    end
    puts "Geodatabase ingest complete: #{OUTPUT_GDB}"
  end

rescue Exception => e
  puts "[#{e.backtrace}] #{e.message}"
  exit!(1)
end
