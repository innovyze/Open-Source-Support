def get_tables_hash(network)
    tables_hash = {}
  
    network.tables.each do |table|
      puts table.name
      tables_hash[table.name] = table
    end  
    tables_hash
  end

  on = WSApplication.current_network
  on_tables = get_tables_hash(on)
  
  bn = WSApplication.background_network
  bn_tables = get_tables_hash(bn)
  
