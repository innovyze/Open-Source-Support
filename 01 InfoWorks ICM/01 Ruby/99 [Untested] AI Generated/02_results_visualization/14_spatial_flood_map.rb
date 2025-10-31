# Script: 14_spatial_flood_map.rb
# Context: Exchange
# Purpose: Spatial flood map (node depths with color gradients)
# Outputs: HTML map
# Usage: ruby script.rb [database_path] [simulation_name]
#        Creates spatial map of flood depths at nodes

begin
  puts "Spatial Flood Map - Starting..."
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
  
  # Extract flood depths
  net = sim_mo.open
  
  # Get timestep with maximum flooding
  timesteps = sim_mo.list_timesteps rescue []
  max_flood_timestep = timesteps.last
  max_flood_depth = 0.0
  
  timesteps.each do |ts|
    net.current_timestep = ts
    net.row_objects('hw_node').each do |node|
      depth = node.results('depth') rescue nil
      if depth && depth > max_flood_depth
        max_flood_depth = depth
        max_flood_timestep = ts
      end
    end
  end
  
  net.current_timestep = max_flood_timestep
  
  nodes = []
  count = 0
  
  net.row_objects('hw_node').each do |node|
    break if count >= 20  # Limit display
    
    depth = node.results('depth') rescue nil
    if depth && depth > 0.05
      status = if depth > 2.0
        'Severe'
      elsif depth > 1.0
        'Major'
      elsif depth > 0.5
        'Moderate'
      else
        'Minor'
      end
      
      nodes << {
        id: node.id,
        depth: depth.round(2),
        status: status
      }
      count += 1
    end
  end
  
  net.close
  
  if nodes.empty?
    puts "No significant flooding detected"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'flood_map.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Flood Map</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#2196f3}.map{display:grid;grid-template-columns:repeat(4,1fr);gap:15px;margin:20px 0}.node{padding:25px;border-radius:8px;text-align:center;font-weight:bold;color:white}.minor{background:#4caf50}.moderate{background:#ff9800}.major{background:#f44336}.severe{background:#b71c1c}.legend{display:flex;gap:20px;margin:20px 0;justify-content:center}.legend-item{display:flex;align-items:center;gap:8px}.legend-box{width:30px;height:30px;border-radius:5px}</style></head>"
  html += "<body><div class='container'><h1>🌊 Spatial Flood Map</h1>"
  html += "<div class='legend'>"
  html += "<div class='legend-item'><div class='legend-box minor'></div><div>Minor (<0.5m)</div></div>"
  html += "<div class='legend-item'><div class='legend-box moderate'></div><div>Moderate (0.5-1.0m)</div></div>"
  html += "<div class='legend-item'><div class='legend-box major'></div><div>Major (1.0-2.0m)</div></div>"
  html += "<div class='legend-item'><div class='legend-box severe'></div><div>Severe (>2.0m)</div></div>"
  html += "</div><div class='map'>"
  
  nodes.each { |n| html += "<div class='node #{n[:status].downcase}'>#{n[:id]}<br>#{n[:depth]}m</div>" }
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Flood map: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



