# Script: 02_batch_property_exporter.rb
# Context: Exchange
# Purpose: Export network properties to CSV (metadata, statistics)
# Outputs: CSV with network metadata
# Usage: ruby script.rb [database_path] [network_name1] [network_name2] ...
#        If no args, uses most recent database and all networks

begin
  puts "Batch Network Property Exporter - Starting..."
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
  
  networks = []
  
  network_names.each do |network_name|
    begin
      net_mo = db.model_object(network_name)
      net = net_mo.open
      
      # Count nodes and links
      node_count = 0
      link_count = 0
      area_ha = 0.0
      
      net.row_objects('hw_node').each { |_| node_count += 1 }
      net.row_objects('hw_conduit').each { |_| link_count += 1 }
      
      # Calculate area from catchments if available
      net.row_objects('hw_subcatchment').each do |sub|
        area = sub.area rescue 0.0
        area_ha += area if area && area > 0
      end
      area_ha = (area_ha / 10000.0).round(1)  # Convert m² to hectares
      
      # Get creation date
      created_date = net_mo.created_date rescue nil
      created_str = created_date ? created_date.strftime('%Y-%m-%d') : 'Unknown'
      
      networks << {
        name: network_name,
        nodes: node_count,
        links: link_count,
        area_ha: area_ha,
        created: created_str
      }
      
      puts "  ✓ #{network_name}: #{node_count} nodes, #{link_count} links, #{area_ha} ha"
      
      net.close
    rescue => e
      puts "  ✗ Error processing #{network_name}: #{e.message}"
    end
  end
  
  if networks.empty?
    puts "No networks processed"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'network_properties.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Nodes,Links,Area(ha),Created"
    networks.each { |n| f.puts "#{n[:name]},#{n[:nodes]},#{n[:links]},#{n[:area_ha]},#{n[:created]}" }
  end
  
  puts "✓ Properties exported: #{csv_file}"
  puts "  - Networks processed: #{networks.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.join("\n")
  $stdout.flush
  exit 1
end

