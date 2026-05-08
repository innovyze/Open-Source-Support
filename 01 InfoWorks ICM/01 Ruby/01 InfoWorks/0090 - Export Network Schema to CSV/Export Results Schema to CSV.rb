require 'csv'

# =====================================================================
# CONFIGURATION (Exchange mode only – ignored when run from the UI)
# =====================================================================
exchange_db_path    = 'C:/MyProject/project.icmm'  # path to .icmm or workgroup address
exchange_network_id = 1                             # integer ID of the Model Network
output_csv_path     = 'C:/temp/icm_results_schema.csv'
# =====================================================================
# REQUIREMENT: A simulation must be loaded (dragged) onto the network
# before running this script, otherwise results_fields will be empty.
# =====================================================================

begin
  if WSApplication.ui?
    net = WSApplication.current_network
    raise 'No network is currently open.' unless net

    default_name = "#{net.model_object.name}_results_schema.csv" rescue 'results_schema.csv'
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
    csv << %w[table_name field_name]

    # results_fields on WSTableInfo is populated when a simulation is loaded AND the table has objects present in the network. 
    # Tables whose object type does not exist in this network return nil/empty — even if that table type theoretically supports results.
    # Output therefore covers all result fields for object types that exist in this specific network.
    
    tables_sorted = []
    net.tables.each { |t| tables_sorted << t }
    tables_sorted.sort_by! { |t| t.name }

    tables_sorted.each do |table|
      rf = table.results_fields
      next if rf.nil? || rf.empty?

      table_count += 1
      rf.each do |f|
        csv << [table.name, f.name]
        field_count += 1
      end
    end
  end

  summary = "Results schema export complete.\n\nNetwork : #{network_name}\nTables with results : #{table_count}\nResults fields      : #{field_count}\nOutput  : #{out_path}"
  puts summary

  if WSApplication.ui?
    WSApplication.message_box(
      "Results schema export complete.\n\nTables with results : #{table_count}\nResults fields      : #{field_count}\n\nSaved to:\n#{out_path}",
      nil, 'Information', false
    )
  end

  db.close if defined?(db) && db
rescue => e
  STDERR.puts "Error: #{e.message}"
  STDERR.puts e.backtrace.first(5).join("\n")
  raise
end
