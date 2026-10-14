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
    wrapper = File.join(SCRIPT_DIR, 'invoke_qgis_ingest.bat')
    unless File.file?(wrapper)
      raise "QGIS ingest helper not found: #{wrapper}"
    end

    puts "Starting QGIS/GDAL ingest -> #{OUTPUT_GDB}"
    cmd = 'cmd /c ""' + wrapper + '" "' + STAGING_FOLDER + '" "' + OUTPUT_GDB + '" "' + QGIS_ROOT + '""'
    system(cmd)
    exit_code = $?.exitstatus

    log_path = File.join(STAGING_FOLDER, 'qgis_ingest.log')
    if exit_code != 0
      detail = ''
      if File.file?(log_path)
        lines = File.read(log_path).strip.split(/\r?\n/)
        detail = lines.last([8, lines.length].min).join("\n")
      end
      msg = "QGIS/GDAL ingest failed (exit #{exit_code}). See #{log_path}"
      msg = msg + "\n" + detail unless detail.empty?
      raise msg
    end
    puts "Geodatabase ingest complete: #{OUTPUT_GDB}"
  end

rescue Exception => e
  puts "[#{e.backtrace}] #{e.message}"
  exit!(1)
end
