net = WSApplication.current_network
net.tables.each do |table|
    puts "=> #{table.name.upcase}"
    results_array = Array.new
    net.row_object_collection(table.name).each do |row_object|
        if !row_object.table_info.results_fields.nil?
            row_object.table_info.results_fields.each do |field|
                results_array |= [field.name]
            end
        end
    end
    puts results_array
    puts ""
end