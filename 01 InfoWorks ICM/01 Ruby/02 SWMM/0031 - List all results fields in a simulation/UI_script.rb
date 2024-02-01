# usage example
net = WSApplication.current_network
print_table_results(net)

require 'set'

def print_table_results(net)
  results_set = Set.new
  net.tables.each do |table|
    puts "Table: #{table.name.upcase}"
    net.row_object_collection(table.name).each do |row_object|
      if row_object.table_info.results_fields
        row_object.table_info.results_fields.each do |field|
          results_set << field.name
        end
      end
    end
    puts "Results fields: #{results_set.to_a}"
    puts "Total number of unique fields: #{results_set.size}"
    puts
  end
end

# usage example
net = WSApplication.current_network
print_table_results(net)