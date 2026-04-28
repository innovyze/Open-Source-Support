require 'csv'

# =====================================================================
# CONFIGURATION (Exchange mode only – ignored when run from the UI)
# =====================================================================
exchange_db_path    = 'C:/MyProject/project.icmm'  # path to .icmm or workgroup address
exchange_network_id = 1                             # integer ID of the Model Network
output_csv_path     = 'C:/temp/icm_schema.csv'     # output file path for Exchange mode
# =====================================================================

begin
  if WSApplication.ui?
    net = WSApplication.current_network
    raise 'No network is currently open.' unless net

    default_name = "#{net.model_object.name}_schema.csv" rescue 'network_schema.csv'
    out_path = WSApplication.file_dialog(
      false, 'csv', 'CSV Files (*.csv)|*.csv', default_name, false, false
    )
    unless out_path
      puts 'Export cancelled.'
      exit
    end
    out_path += '.csv' unless out_path.downcase.end_with?('.csv')
  else
    db       = WSApplication.open(exchange_db_path, false)
    mo       = db.model_object_from_type_and_id('Model Network', exchange_network_id)
    net      = mo.open
    out_path = output_csv_path
  end

  network_name = net.model_object.name rescue 'Unknown'
  table_count  = 0
  field_count  = 0

  CSV.open(out_path, 'w') do |csv|
    csv << %w[table_name field_name data_type]

    # net.tables returns an Array of WSTableInfo objects.
    # Each WSTableInfo has: .name (String), .fields (Array of WSFieldInfo).
    # Each WSFieldInfo has: .name (String), .data_type (String).
    # Results reflect the loaded network type: InfoWorks nets expose hw_* tables;
    # SWMM nets expose sw_* tables.
    
    tables_sorted = []
    net.tables.each { |t| tables_sorted << t }
    tables_sorted.sort_by! { |t| t.name }

    tables_sorted.each do |table|
      table_count += 1
      table.fields.each do |f|
        csv << [table.name, f.name, f.data_type]
        field_count += 1
      end
    end
  end

  summary = "Schema export complete.\n\nNetwork : #{network_name}\nTables  : #{table_count}\nFields  : #{field_count}\nOutput  : #{out_path}"
  puts summary

  if WSApplication.ui?
    WSApplication.message_box(
      "Schema export complete.\n\nTables : #{table_count}\nFields : #{field_count}\n\nSaved to:\n#{out_path}",
      nil, 'Information', false
    )
  end

  db.close if defined?(db) && db
rescue => e
  STDERR.puts "Error: #{e.message}"
  STDERR.puts e.backtrace.first(5).join("\n")
  raise
end
