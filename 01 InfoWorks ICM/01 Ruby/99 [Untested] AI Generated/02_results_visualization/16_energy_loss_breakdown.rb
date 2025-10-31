# Script: 16_energy_loss_breakdown.rb
# Context: Exchange
# Purpose: Energy loss breakdown pie chart (friction, minor, form losses)
# Outputs: HTML pie chart
# Usage: ruby script.rb [database_path] [simulation_name]
#        Estimates energy losses from simulation results

begin
  puts "Energy Loss Breakdown - Starting..."
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
  
  # Estimate energy losses
  net = sim_mo.open
  
  total_friction = 0.0
  total_minor = 0.0
  total_form = 0.0
  
  net.row_objects('hw_conduit').each do |pipe|
    # Estimate friction loss (simplified)
    flow = pipe.result('flow') rescue nil
    length = pipe.length rescue nil
    roughness = pipe.roughness rescue 0.013
    
    if flow && length && flow.abs > 0
      # Simplified friction loss estimate
      friction_loss = (flow.abs ** 1.85 * length * roughness ** 0.85) / 1000.0
      total_friction += friction_loss
    end
    
    # Estimate minor losses (from structures)
    # Simplified: assume 10% of friction loss
    total_minor += total_friction * 0.1 if total_friction > 0
  end
  
  # Form losses (from expansions/contractions) - simplified
  total_form = total_friction * 0.15
  
  total_losses = total_friction + total_minor + total_form
  
  if total_losses == 0
    puts "No energy loss data calculated"
    net.close
    exit 0
  end
  
  losses = {
    'Friction Loss' => (total_friction / total_losses * 100).round(1),
    'Minor Losses' => (total_minor / total_losses * 100).round(1),
    'Form Losses' => (total_form / total_losses * 100).round(1),
    'Other' => (100 - (total_friction / total_losses * 100 + total_minor / total_losses * 100 + total_form / total_losses * 100)).round(1)
  }
  
  net.close
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'energy_loss.html')
  
  labels = losses.keys.map { |k| "'#{k}'" }.join(',')
  data = losses.values.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Energy Loss</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:800px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Energy Loss Breakdown</h1><div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'pie',data:{labels:[#{labels}],datasets:[{data:[#{data}],backgroundColor:['#1976d2','#2196f3','#42a5f5','#90caf9']}]},options:{responsive:true,maintainAspectRatio:false,plugins:{legend:{position:'right'}}}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Energy loss breakdown: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



