def print_table_results(net)
    net.tables.each do |table|
      puts "Table: #{table.name.upcase}"
      results_array = []
      net.row_object_collection(table.name).each do |row_object|
      if row_object.table_info.results_fields
        row_object.table_info.results_fields.each do |field|
            results_array << field.name
         end
       end
      end
      puts "Results fields: #{results_array}"
      puts
    end
  end
  
  # usage example
  net = WSApplication.current_network
  print_table_results(net)
  
