# Script: 08_velocity_distribution.rb
# Context: Exchange
# Purpose: Velocity distribution histogram by pipe material/diameter
# Outputs: HTML histogram
# Usage: ruby script.rb [database_path] [simulation_name]

begin
  puts "Velocity Distribution Histogram - Starting..."
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
  
  # Extract velocities from simulation results
  net = sim_mo.open
  velocities = []
  
  net.row_objects('hw_conduit').each do |pipe|
    max_velocity = pipe.result('velocity') rescue nil
    if max_velocity && max_velocity > 0
      velocities << max_velocity.abs.round(2)
    end
  end
  
  net.close
  
  if velocities.empty?
    puts "No velocity data found"
    exit 0
  end
  
  # Create bins
  bins = [0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 5.0]
  counts = bins[0..-2].map.with_index { |b, i| velocities.count { |v| v >= b && v < bins[i+1] } }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'velocity_distribution.html')
  
  labels = bins[0..-2].map.with_index { |b, i| "'#{b}-#{bins[i+1]}m/s'" }.join(',')
  data = counts.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Velocity Distribution</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.chart-container{height:400px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Velocity Distribution</h1><div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'bar',data:{labels:[#{labels}],datasets:[{label:'Pipe Count',data:[#{data}],backgroundColor:'#1976d2'}]},options:{responsive:true,maintainAspectRatio:false,scales:{y:{beginAtZero:true}}}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Velocity histogram: #{html_file}"
  puts "  - Pipes analyzed: #{velocities.length}"
  puts "  - Max velocity: #{velocities.max.round(2)} m/s"
  puts "  - Min velocity: #{velocities.min.round(2)} m/s"
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end




