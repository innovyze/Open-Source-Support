# Script: 10_network_complexity_scorer.rb
# Context: Exchange
# Purpose: Calculate complexity metrics across network portfolio
# Outputs: HTML scorecard + CSV
# Usage: ruby script.rb [database_path] [network_name1] [network_name2] ...
#        If no args, analyzes all networks in database

begin
  puts "Network Complexity Scorer - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get networks to analyze
  if ARGV.length > 1
    network_names = ARGV[1..-1]
  else
    nets = db.model_object_collection('Model Network')
    if nets.empty?
      puts "ERROR: No networks found in database"
      exit 1
    end
    network_names = nets.map(&:name)
    puts "Analyzing all #{network_names.length} networks in database..."
  end
  
  networks = []
  
  network_names.each do |net_name|
    begin
      net_mo = db.model_object(net_name)
      net = net_mo.open
      
      # Count nodes
      node_count = 0
      net.row_objects('hw_node').each { |_| node_count += 1 }
      
      # Count links
      link_count = 0
      net.row_objects('hw_conduit').each { |_| link_count += 1 }
      
      # Estimate loops (simplified: difference between links and nodes)
      loops = [link_count - node_count + 1, 0].max
      
      # Count structures (pumps, storage, etc.)
      structures = 0
      net.row_objects('hw_pump').each { |_| structures += 1 }
      net.row_objects('hw_storage').each { |_| structures += 1 }
      net.row_objects('hw_orifice').each { |_| structures += 1 }
      net.row_objects('hw_weir').each { |_| structures += 1 }
      
      # Calculate composite score
      complexity = (node_count * 0.1 + loops * 2 + structures * 1.5).round(0)
      rating = complexity < 40 ? 'Simple' : (complexity < 70 ? 'Moderate' : 'Complex')
      
      networks << {
        name: net_name,
        nodes: node_count,
        loops: loops,
        structures: structures,
        complexity: complexity,
        rating: rating
      }
      
      net.close
      
    rescue => e
      puts "  ✗ Error processing #{net_name}: #{e.message}"
    end
  end
  
  if networks.empty?
    puts "No networks processed"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'complexity_scores.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Nodes,Loops,Structures,ComplexityScore,Rating"
    networks.each { |n| f.puts "#{n[:name]},#{n[:nodes]},#{n[:loops]},#{n[:structures]},#{n[:complexity]},#{n[:rating]}" }
  end
  
  html_file = File.join(output_dir, 'complexity_scorecard.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Complexity Scorecard</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#1976d2;color:white}.simple{background:#c8e6c9}.moderate{background:#fff9c4}.complex{background:#ffccbc}</style></head>"
  html += "<body><div class='container'><h1>Network Complexity Scorecard</h1><table><tr><th>Network</th><th>Nodes</th><th>Loops</th><th>Structures</th><th>Score</th><th>Rating</th></tr>"
  
  networks.each { |n| html += "<tr class='#{n[:rating].downcase}'><td>#{n[:name]}</td><td>#{n[:nodes]}</td><td>#{n[:loops]}</td><td>#{n[:structures]}</td><td><strong>#{n[:complexity]}</strong></td><td>#{n[:rating]}</td></tr>" }
  
  html += "</table><p><strong>CSV:</strong> complexity_scores.csv</p></div></body></html>"
  File.write(html_file, html)
  
  puts "✓ Complexity scoring complete:"
  puts "  - HTML: #{html_file}"
  puts "  - CSV: #{csv_file}"
  puts "  - Networks scored: #{networks.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



