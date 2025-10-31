# Script: 05_cso_spill_aggregator.rb
# Context: Exchange
# Purpose: Aggregate CSO spill volumes from simulation results
# Outputs: HTML + CSV
# Usage: ruby script.rb [database_path] [simulation_name]
#        If no args, uses most recent database and lists available simulations

begin
  puts "CSO Spill Aggregator - Starting..."
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
  
  # Check simulation status
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    puts "       Status must be 'Success' to access results"
    exit 1
  end
  
  # Open simulation results
  net = sim_mo.open
  
  # Find CSO nodes (overflow nodes) - look for nodes with spill/overflow results
  csos = []
  
  net.row_objects('hw_node').each do |node|
    # Check if this node has overflow/spill results
    # CSOs typically have 'flood_volume' or 'flooded_area' results
    flood_vol = node.result('flood_volume') rescue nil
    
    if flood_vol && flood_vol > 0
      # Count overflow events by iterating timesteps
      events = 0
      prev_overflow = false
      
      timesteps = sim_mo.list_timesteps rescue []
      if timesteps && timesteps.length > 0
        # Sample timesteps for performance (every 10th)
        sample_timesteps = timesteps.select.with_index { |_, i| i % 10 == 0 }
        sample_timesteps.each do |ts|
          net.current_timestep = ts
          overflow = node.results('flood_volume') rescue nil
          
          if overflow && overflow > 0 && !prev_overflow
            events += 1
          end
          prev_overflow = (overflow && overflow > 0)
        end
      end
      
      csos << {
        id: node.id,
        volume_m3: flood_vol.round(2),
        events: events
      }
    end
  end
  
  net.close
  
  if csos.empty?
    puts "No CSO spills found in simulation results"
    puts "Note: CSOs must have 'flood_volume' results available"
    exit 0
  end
  
  total_vol = csos.map { |c| c[:volume_m3] }.sum
  total_events = csos.map { |c| c[:events] }.sum
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'cso_spills.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "CSO_ID,Volume_m3,Events"
    csos.each { |c| f.puts "#{c[:id]},#{c[:volume_m3]},#{c[:events]}" }
  end
  
  html_file = File.join(output_dir, 'cso_spills.html')
  labels = csos.map { |c| "'#{c[:id]}'" }.join(',')
  data = csos.map { |c| c[:volume_m3] }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>CSO Spills</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid #f44336}.summary{display:flex;gap:20px;margin:20px 0}.stat{flex:1;padding:15px;background:#ffebee;border-radius:5px;text-align:center}.stat .value{font-size:28px;font-weight:bold;color:#c62828}.chart-container{height:400px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>CSO Spill Analysis</h1>"
  html += "<p><strong>Simulation:</strong> #{sim_name}</p>"
  html += "<div class='summary'><div class='stat'><div class='value'>#{total_vol.round(1)}</div><div>Total Volume (m³)</div></div>"
  html += "<div class='stat'><div class='value'>#{total_events}</div><div>Total Events</div></div></div>"
  html += "<div class='chart-container'><canvas id='chart'></canvas></div>"
  html += "<p><strong>CSV:</strong> cso_spills.csv</p></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'bar',data:{labels:[#{labels}],datasets:[{label:'Spill Volume (m³)',data:[#{data}],backgroundColor:'#f44336'}]},options:{responsive:true,maintainAspectRatio:false}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ CSO analysis complete: #{html_file}"
  puts "  - CSOs found: #{csos.length}"
  puts "  - Total volume: #{total_vol.round(1)} m³"
  puts "  - Total events: #{total_events}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end




