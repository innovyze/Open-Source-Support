# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Define a method to process row objects
    def process_row_objects(net, type)
        hash_map = Hash.new { |h, k| h[k] = [] }
        row_objects = net.row_objects(type)
        raise "Error: #{type} not found" if row_objects.nil?
        row_objects.each do |obj|
            hash_map[obj.id] << obj.id
        end   
        printf "%-20s \n", "Name"
        hash_map.each do |name, id|
            printf "#{type.capitalize} %-20s \n", name
        end
    end

    # Process nodes, links, subcatchments, and pumps
    process_row_objects(net, '_nodes')
    process_row_objects(net, '_links')
    process_row_objects(net, '_subcatchments')
    process_row_objects(net, 'hw_weirs')
    process_row_objects(net, 'hw_orifices')
    process_row_objects(net, 'hw_pump')

rescue => e
    puts "Error: #{e.message}"
end

