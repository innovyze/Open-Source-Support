net = WSApplication.current_network
net.each do |table|
    tables_array = Array.New
    tables_array |= net.row_object_collection(table)
    puts tables_array
    # if !row_object.table_info.results_fields.nil?
    #     row_object.table_info.results_fields.each do |field|
    #         puts field.name
    #     end
    # end
end