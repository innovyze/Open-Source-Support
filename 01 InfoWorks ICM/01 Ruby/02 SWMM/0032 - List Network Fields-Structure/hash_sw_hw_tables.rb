def get_tables_hash(network)
    tables_hash = {}
  
    network.tables.each do |table|
      tables_hash[table.name] = table
    end
  
    tables_hash
  end


def print_fields(network)
    fields_hash = {}
  
    network.tables.each do |table|
      table.fields.each do |field|
        next unless field.name.start_with?('sw', 'hw')
  
        prefix, suffix = field.name.split('_', 2)
        fields_hash[suffix] ||= { 'sw' => [], 'hw' => [] }
        fields_hash[suffix][prefix] << field.name
      end
    end
  
    fields_hash.each do |suffix, prefixes|
      puts "Suffix: #{suffix}"
      puts "SW Fields: #{prefixes['sw'].join(', ')}"
      puts "HW Fields: #{prefixes['hw'].join(', ')}"
      puts
    end
  end

  on = WSApplication.current_network
  on_tables = get_tables_hash(on)
  
  bn = WSApplication.background_network
  bn_tables = get_tables_hash(bn)
  
  on = WSApplication.current_network
  print_fields(on)
  
  on = WSApplication.background_network
  print_fields(on)