# EXCHANGE SCRIPT
# ODEC shapefile export + new File Geodatabase via QGIS/GDAL (no ArcGIS Pro).
# ArcGIS Pro ingest variant: IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb

begin
  SCRIPT_DIR = File.dirname(WSApplication.script_file)
  STAGING_FOLDER = File.join(SCRIPT_DIR, 'staging_shp')
  CONFIG_FILE = File.join(SCRIPT_DIR, 'odec_export_ex-SHP.cfg')

  DB_URI = '//localhost:40000/IA_NEW'
  NETWORK_TYPE = 'Collection Network'
  NETWORK_ID = 4

  EXPORT_LAYERS = [
    ['node', 'node'],
    ['pipe', 'pipe']
  ]

  RUN_QGIS_INGEST = true
  QGIS_ROOT = 'C:\\Program Files\\QGIS 4.0.3'
  INGEST_SCRIPT = File.join(SCRIPT_DIR, 'ingest_shp_to_file_gdb_ogr.py')
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

  if RUN_QGIS_INGEST
    ogr2ogr = File.join(QGIS_ROOT, 'bin', 'ogr2ogr.exe')
    python = File.join(QGIS_ROOT, 'bin', 'python.exe')
    unless File.file?(ogr2ogr)
      raise "QGIS ogr2ogr not found: #{ogr2ogr}. Edit QGIS_ROOT in this script."
    end
    unless File.file?(INGEST_SCRIPT)
      raise "Ingest script not found: #{INGEST_SCRIPT}"
    end

    puts "Starting QGIS/GDAL ingest -> #{OUTPUT_GDB}"
    if File.file?(python)
      ok = system(
        python,
        INGEST_SCRIPT,
        '--staging', STAGING_FOLDER,
        '--gdb', OUTPUT_GDB,
        '--ogr2ogr', ogr2ogr
      )
    else
      o4w_env = File.join(QGIS_ROOT, 'bin', 'o4w_env.bat')
      raise "QGIS python and o4w_env not found under #{QGIS_ROOT}" unless File.file?(o4w_env)

      node_shp = File.join(STAGING_FOLDER, 'node.shp')
      node_shp = File.join(STAGING_FOLDER, 'node.SHP') unless File.file?(node_shp)
      pipe_shp = File.join(STAGING_FOLDER, 'pipe.shp')
      pipe_shp = File.join(STAGING_FOLDER, 'pipe.SHP') unless File.file?(pipe_shp)
      cmd = "call \"#{o4w_env}\" && \"#{ogr2ogr}\" -f OpenFileGDB \"#{OUTPUT_GDB}\" \"#{node_shp}\" -nln Node -overwrite && \"#{ogr2ogr}\" -f OpenFileGDB -update \"#{OUTPUT_GDB}\" \"#{pipe_shp}\" -nln Pipe -overwrite"
      ok = system('cmd', '/c', cmd)
    end

    exit_code = $?.exitstatus
    unless ok && exit_code == 0
      raise "QGIS/GDAL ingest failed (exit #{exit_code.inspect})"
    end
    puts "Geodatabase ingest complete: #{OUTPUT_GDB}"
  end

rescue Exception => e
  puts "[#{e.backtrace}] #{e.message}"
  exit!(1)
end
