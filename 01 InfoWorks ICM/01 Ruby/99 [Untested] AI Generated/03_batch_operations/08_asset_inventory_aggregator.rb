# Script: 08_asset_inventory_aggregator.rb
# Context: Exchange
# Purpose: Aggregate asset inventory across networks (global asset register)
# Outputs: CSV asset register
# Usage: ruby script.rb [database_path] [network_name1] [network_name2] ...
#        If no args, uses most recent database and all networks

begin
  puts "Asset Inventory Aggregator - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get networks to process
  if ARGV.length > 1
    network_names = ARGV[1..-1]
  else
    network_names = db.model_object_collection('Model Network').map { |mo| mo.name }
  end
  
  puts "Processing #{network_names.length} network(s)..."
  
  results = {}
  
  network_names.each do |network_name|
    begin
      net_mo = db.model_object(network_name)
      net = net_mo.open
      
      # Count real assets
      pipe_count = 0
      node_count = 0
      pump_count = 0
      tank_count = 0
      
      net.row_objects('hw_conduit').each { |_| pipe_count += 1 }
      net.row_objects('hw_node').each { |_| node_count += 1 }
      net.row_objects('hw_pump').each { |_| pump_count += 1 }
      net.row_objects('hw_storage').each { |_| tank_count += 1 }
      
      results[network_name] = {
        pipes: pipe_count,
        manholes: node_count,
        pumps: pump_count,
        tanks: tank_count
      }
      
      puts "  ✓ #{network_name}: #{pipe_count} pipes, #{node_count} nodes, #{pump_count} pumps, #{tank_count} tanks"
      
      net.close
    rescue => e
      puts "  ✗ Error processing #{network_name}: #{e.message}"
      results[network_name] = {pipes: 0, manholes: 0, pumps: 0, tanks: 0}
    end
  end
  
  totals = {pipes: 0, manholes: 0, pumps: 0, tanks: 0}
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'asset_inventory.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Pipes,Manholes,Pumps,Tanks,Total"
    results.each do |net, assets|
      total = assets.values.sum
      f.puts "#{net},#{assets[:pipes]},#{assets[:manholes]},#{assets[:pumps]},#{assets[:tanks]},#{total}"
      totals.each { |k, _| totals[k] += assets[k] }
    end
    f.puts "TOTAL,#{totals[:pipes]},#{totals[:manholes]},#{totals[:pumps]},#{totals[:tanks]},#{totals.values.sum}"
  end
  
  puts "✓ Asset inventory: #{csv_file}"
  puts "  - Networks processed: #{results.length}"
  puts "  - Total assets: #{totals.values.sum}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



