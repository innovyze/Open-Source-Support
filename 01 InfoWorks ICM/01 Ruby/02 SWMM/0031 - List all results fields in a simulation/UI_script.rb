require 'set'

def print_table_results(net,bn)
  
  net.tables.each do |table|
    results_set = Set.new
    puts "Table: #{table.name.upcase}"
    net.row_object_collection(table.name).each do |row_object|
      next unless row_object.table_info.results_fields

      row_object.table_info.fields.each do |field|
        results_set << field.name
      end
    end
    puts "DB fields: #{results_set.to_a}"
    puts "Total number of unique fields: #{results_set.size}"
    puts
  end
  
  bn.tables.each do |table|
    results_set = Set.new
    puts "Table: #{table.name.upcase}"
    bn.row_object_collection(table.name).each do |row_object|
      next unless row_object.table_info.results_fields

      row_object.table_info.fields.each do |field|
        results_set << field.name
      end
    end
    puts "DB fields: #{results_set.to_a}"
    puts "Total number of unique fields: #{results_set.size}"
    puts
  end

end

# usage example
net = WSApplication.current_network
bn = WSApplication.background_network

# Print the table results
print_table_results(net,bn)