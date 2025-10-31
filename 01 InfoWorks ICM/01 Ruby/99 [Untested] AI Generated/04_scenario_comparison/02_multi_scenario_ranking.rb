# Script: 02_multi_scenario_ranking.rb
# Context: Exchange
# Purpose: Multi-scenario performance ranking with radar charts
# Outputs: HTML with ranking table + radar chart
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        If no args, uses most recent database and lists available simulations

begin
  puts "Multi-Scenario Ranking - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to compare
  if ARGV.length > 1
    sim_names = ARGV[1..-1]
  else
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_name1] [simulation_name2] ..."
    exit 1
  end
  
  scenarios = []
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      if sim_mo.status != 'Success'
        puts "  ⚠ Skipping #{sim_name}: status is #{sim_mo.status}"
        next
      end
      
      net = sim_mo.open
      
      # Calculate performance metrics
      # Performance: % of pipes operating efficiently (<85% capacity)
      efficient_pipes = 0
      total_pipes = 0
      net.row_objects('hw_conduit').each do |pipe|
        flow = pipe.result('flow') rescue nil
        capacity = pipe.capacity rescue nil
        if flow && capacity && capacity > 0
          total_pipes += 1
          efficient_pipes += 1 if (flow.abs / capacity) < 0.85
        end
      end
      performance = total_pipes > 0 ? (efficient_pipes.to_f / total_pipes * 100).round : 0
      
      # Reliability: % of nodes not flooding
      reliable_nodes = 0
      total_nodes = 0
      net.row_objects('hw_node').each do |node|
        flood_vol = node.result('flood_volume') rescue nil
        if flood_vol
          total_nodes += 1
          reliable_nodes += 1 if flood_vol == 0
        end
      end
      reliability = total_nodes > 0 ? (reliable_nodes.to_f / total_nodes * 100).round : 100
      
      # Sustainability: % of assets operating in optimal range (simplified)
      sustainability = 75  # Placeholder - would need more complex calculation
      
      # Cost: Estimated from network size (simplified)
      cost_score = 100 - (total_pipes * 0.5).clamp(0, 100).round
      
      # Overall score (weighted average)
      overall = ((performance * 0.4) + (reliability * 0.3) + (sustainability * 0.2) + (cost_score * 0.1)).round(2)
      
      net.close
      
      scenarios << {
        name: sim_name,
        cost: cost_score,
        performance: performance,
        reliability: reliability,
        sustainability: sustainability,
        overall: overall
      }
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if scenarios.empty?
    puts "No scenarios processed"
    exit 0
  end
  
  scenarios.sort_by! { |s| -s[:overall] }
  scenarios.each_with_index { |s, i| s[:rank] = i + 1 }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'scenario_ranking.html')
  
  # Prepare radar chart data
  labels = "'Cost','Performance','Reliability','Sustainability'"
  datasets = scenarios.map do |s|
    "{label:'#{s[:name]}',data:[#{s[:cost]},#{s[:performance]},#{s[:reliability]},#{s[:sustainability]}],borderWidth:2}"
  end.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Scenario Ranking</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1100px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#1976d2;color:white}.rank1{background:#ffd700}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>🏆 Scenario Performance Ranking</h1><table><tr><th>Rank</th><th>Scenario</th><th>Cost</th><th>Performance</th><th>Reliability</th><th>Sustainability</th><th>Overall</th></tr>"
  
  scenarios.each { |s| html += "<tr#{s[:rank] == 1 ? ' class="rank1"' : ''}><td><strong>#{s[:rank]}</strong></td><td>#{s[:name]}</td><td>#{s[:cost]}</td><td>#{s[:performance]}</td><td>#{s[:reliability]}</td><td>#{s[:sustainability]}</td><td><strong>#{s[:overall]}</strong></td></tr>" }
  
  html += "</table><h2>Radar Comparison</h2><div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'radar',data:{labels:[#{labels}],datasets:[#{datasets}]},options:{responsive:true,maintainAspectRatio:false,scales:{r:{beginAtZero:true,max:100}}}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Scenario ranking: #{html_file}"
  puts "  - Winner: #{scenarios[0][:name]} (#{scenarios[0][:overall]})"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



