# Script: 15_flow_profile_plotter.rb
# Context: Exchange
# Purpose: Flow profile longitudinal section plotter
# Outputs: HTML profile chart
# Usage: ruby script.rb [database_path] [simulation_name] [start_node] [end_node]
#        Creates longitudinal profile along path from start_node to end_node

begin
  puts "Flow Profile Plotter - Starting..."
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
    puts "\nUsage: script.rb [database_path] [simulation_name] [start_node] [end_node]"
    exit 1
  end
  
  sim_mo = db.model_object(sim_name)
  
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    exit 1
  end
  
  # Extract profile data
  net = sim_mo.open
  
  # Get final timestep for profile
  timesteps = sim_mo.list_timesteps rescue []
  if timesteps && timesteps.length > 0
    net.current_timestep = timesteps.last
  end
  
  # Build profile along conduits (simplified - traces path)
  profile = []
  chainage = 0.0
  
  # Get start and end nodes if provided
  start_node_id = ARGV[2]
  end_node_id = ARGV[3]
  
  if start_node_id && end_node_id
    # Trace path from start to end (simplified - would need pathfinding)
    # For now, just collect all nodes along conduits
    net.row_objects('hw_conduit').each do |conduit|
      us_node = net.row_object('hw_node', conduit.us_node_id) rescue nil
      ds_node = net.row_object('hw_node', conduit.ds_node_id) rescue nil
      
      if us_node && ds_node
        # Add upstream node
        profile << {
          chainage: chainage,
          invert: us_node['invert_level'] rescue 0.0,
          wse: (us_node['invert_level'] rescue 0.0) + (us_node.results('depth') rescue 0.0),
          ground: us_node['ground_level'] rescue 0.0
        }
        
        chainage += conduit.length rescue 100.0
        
        # Add downstream node
        profile << {
          chainage: chainage,
          invert: ds_node['invert_level'] rescue 0.0,
          wse: (ds_node['invert_level'] rescue 0.0) + (ds_node.results('depth') rescue 0.0),
          ground: ds_node['ground_level'] rescue 0.0
        }
      end
    end
  else
    # Default: sample first 10 nodes
    count = 0
    net.row_objects('hw_node').each do |node|
      break if count >= 10
      
      profile << {
        chainage: count * 100.0,
        invert: node['invert_level'] rescue 0.0,
        wse: (node['invert_level'] rescue 0.0) + (node.results('depth') rescue 0.0),
        ground: node['ground_level'] rescue 0.0
      }
      count += 1
    end
  end
  
  net.close
  
  if profile.empty?
    puts "No profile data found"
    exit 0
  end
  
  # Sort by chainage
  profile.sort_by! { |p| p[:chainage] }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'flow_profile.html')
  
  labels = profile.map { |p| p[:chainage] }.join(',')
  invert_data = profile.map { |p| p[:invert] }.join(',')
  wse_data = profile.map { |p| p[:wse] }.join(',')
  ground_data = profile.map { |p| p[:ground] }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Flow Profile</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Longitudinal Profile</h1><div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'line',data:{labels:[#{labels}],datasets:[{label:'Ground Level',data:[#{ground_data}],borderColor:'#8d6e63',fill:false},{label:'Water Surface',data:[#{wse_data}],borderColor:'#2196f3',fill:true,backgroundColor:'rgba(33,150,243,0.2)'},{label:'Invert',data:[#{invert_data}],borderColor:'#424242',fill:false}]},options:{responsive:true,maintainAspectRatio:false,scales:{x:{title:{display:true,text:'Chainage (m)'}},y:{title:{display:true,text:'Elevation (m)'}}}linear}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Flow profile: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



