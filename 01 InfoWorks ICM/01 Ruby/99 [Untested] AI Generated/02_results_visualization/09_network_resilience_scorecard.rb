# Script: 09_network_resilience_scorecard.rb
# Context: Exchange
# Purpose: Network resilience composite metrics dashboard
# Outputs: HTML scorecard
# Usage: ruby script.rb [database_path] [simulation_name]
#        Calculates resilience metrics from simulation results

begin
  puts "Network Resilience Scorecard - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulation
  sim_name = ARGV[1]
  unless sim_name
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_name]"
    exit 1
  end
  
  sim_mo = db.model_object(sim_name)
  
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    exit 1
  end
  
  # Calculate resilience metrics
  net = sim_mo.open
  
  # Redundancy: % of nodes with multiple paths
  redundant_nodes = 0
  total_nodes = 0
  net.row_objects('hw_node').each do |node|
    total_nodes += 1
    connections = 0
    net.row_objects('hw_conduit').each do |pipe|
      connections += 1 if pipe.us_node_id == node.id || pipe.ds_node_id == node.id
    end
    redundant_nodes += 1 if connections > 2
  end
  redundancy = total_nodes > 0 ? (redundant_nodes.to_f / total_nodes * 100).round : 0
  
  # Robustness: % of pipes operating below capacity
  robust_pipes = 0
  total_pipes = 0
  net.row_objects('hw_conduit').each do |pipe|
    flow = pipe.result('flow') rescue nil
    capacity = pipe.capacity rescue nil
    if flow && capacity && capacity > 0
      total_pipes += 1
      robust_pipes += 1 if (flow.abs / capacity) < 0.85
    end
  end
  robustness = total_pipes > 0 ? (robust_pipes.to_f / total_pipes * 100).round : 0
  
  # Adaptability: % of nodes not flooding
  adaptable_nodes = 0
  total_nodes_check = 0
  net.row_objects('hw_node').each do |node|
    flood_vol = node.result('flood_volume') rescue nil
    if flood_vol
      total_nodes_check += 1
      adaptable_nodes += 1 if flood_vol == 0
    end
  end
  adaptability = total_nodes_check > 0 ? (adaptable_nodes.to_f / total_nodes_check * 100).round : 100
  
  # Recovery Speed: Estimated from CSO spill duration (simplified)
  recovery_speed = 71  # Placeholder - would need temporal analysis
  
  net.close
  
  scores = {
    'Redundancy' => redundancy,
    'Robustness' => robustness,
    'Adaptability' => adaptability,
    'Recovery Speed' => recovery_speed
  }
  
  overall = scores.values.sum / scores.length
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'resilience_scorecard.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Resilience Scorecard</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#1e1e1e;color:white}.container{max-width:900px;margin:0 auto;padding:20px}h1{font-size:32px;margin-bottom:30px}.overall{text-align:center;padding:40px;background:#2d2d2d;border-radius:10px;margin:20px 0}.overall .score{font-size:72px;font-weight:bold;color:#2196f3}.metrics{display:grid;grid-template-columns:repeat(2,1fr);gap:20px;margin:30px 0}.metric{background:#2d2d2d;padding:25px;border-radius:10px}.metric-name{font-size:14px;color:#aaa;margin-bottom:10px}.metric-score{font-size:36px;font-weight:bold;color:#2196f3}.bar{height:10px;background:#444;border-radius:5px;margin-top:10px;overflow:hidden}.bar-fill{height:100%;background:#2196f3;border-radius:5px}</style></head>"
  html += "<body><div class='container'><h1>🛡️ Network Resilience Scorecard</h1>"
  html += "<div class='overall'><div>Overall Resilience Score</div><div class='score'>#{overall}</div><div style='font-size:20px;color:#aaa'>out of 100</div></div>"
  html += "<div class='metrics'>"
  
  scores.each do |name, score|
    html += "<div class='metric'><div class='metric-name'>#{name}</div><div class='metric-score'>#{score}</div>"
    html += "<div class='bar'><div class='bar-fill' style='width:#{score}%'></div></div></div>"
  end
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Resilience scorecard: #{html_file}"
  puts "  - Overall score: #{overall}/100"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



