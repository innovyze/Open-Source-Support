# Script: 04_surcharge_duration_heatmap.rb
# Context: Exchange
# Purpose: Generate surcharge duration heatmap by catchment
# Outputs: HTML heatmap
# Usage: ruby script.rb [database_path] [simulation_name]

begin
  puts "Surcharge Duration Heatmap - Starting..."
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
  
  # Calculate surcharge duration from results
  net = sim_mo.open
  timesteps = sim_mo.list_timesteps rescue []
  
  catchments = []
  
  # Get catchments
  net.row_objects('hw_subcatchment').each do |subcatch|
    catchment_id = subcatch.id
    surcharge_count = 0
    
    # Find connected nodes
    connected_nodes = []
    net.row_objects('hw_node').each do |node|
      # Check if node is connected to this catchment
      if node.subcatchment_id == catchment_id rescue false
        connected_nodes << node
      end
    end
    
    # Count timesteps with surcharge (depth > ground level)
    if timesteps && timesteps.length > 0
      sample_timesteps = timesteps.select.with_index { |_, i| i % 10 == 0 }  # Sample for performance
      
      sample_timesteps.each do |ts|
        net.current_timestep = ts
        connected_nodes.each do |node|
          depth = node.results('depth') rescue nil
          ground_level = node['ground_level'] rescue nil
          
          if depth && ground_level && depth > ground_level
            surcharge_count += 1
            break  # Count once per timestep
          end
        end
      end
      
      # Estimate total surcharge minutes (assuming timestep interval)
      surcharge_min = (surcharge_count.to_f / sample_timesteps.length * timesteps.length * 0.1).round  # Assuming 6-second timesteps
      
      severity = if surcharge_min > 60
        'Critical'
      elsif surcharge_min > 30
        'High'
      elsif surcharge_min > 15
        'Medium'
      else
        'Low'
      end
      
      catchments << {
        id: catchment_id,
        surcharge_min: surcharge_min,
        severity: severity
      }
    end
  end
  
  net.close
  
  if catchments.empty?
    puts "No catchment surcharge data found"
    exit 0
  end
  
  # Sort by surcharge duration
  catchments.sort_by! { |c| -c[:surcharge_min] }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'surcharge_heatmap.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Surcharge Heatmap</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:800px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid #f57c00}.heatmap{display:grid;grid-template-columns:repeat(3,1fr);gap:15px;margin:20px 0}.cell{padding:30px;border-radius:8px;text-align:center;font-size:18px;font-weight:bold}.critical{background:#ef5350;color:white}.high{background:#ff9800;color:white}.medium{background:#ffa726;color:white}.low{background:#66bb6a;color:white}</style></head>"
  html += "<body><div class='container'><h1>Surcharge Duration Heatmap</h1><div class='heatmap'>"
  
  catchments.each { |c| html += "<div class='cell #{c[:severity].downcase}'>#{c[:id]}<br>#{c[:surcharge_min]} min</div>" }
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Heatmap generated: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













