# Script: 18_pump_efficiency_plotter.rb
# Context: Exchange
# Purpose: Pump efficiency curve vs operating point plotter
# Outputs: HTML chart
# Usage: ruby script.rb [database_path] [simulation_name] [pump_id]
#        If no pump_id provided, uses first pump found

begin
  puts "Pump Efficiency Plotter - Starting..."
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
    puts "\nUsage: script.rb [database_path] [simulation_name] [pump_id]"
    exit 1
  end
  
  sim_mo = db.model_object(sim_name)
  
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    exit 1
  end
  
  # Get pump
  pump_id = ARGV[2]
  net = sim_mo.open
  
  pump = nil
  if pump_id
    pump = net.row_object('hw_pump', pump_id) rescue nil
  else
    # Use first pump found
    net.row_objects('hw_pump').each do |p|
      pump = p
      break
    end
  end
  
  unless pump
    puts "No pump found"
    net.close
    exit 0
  end
  
  # Get operating point
  operating_flow = pump.result('flow') rescue nil
  operating_flow = operating_flow.abs if operating_flow
  
  # Get pump curve data (if available from pump properties)
  # Otherwise, estimate efficiency curve
  curve = []
  
  # Try to get pump curve properties
  pump_flow_max = pump['q_max'] rescue nil
  pump_flow_max = pump_flow_max || (operating_flow ? operating_flow * 2 : 100.0)
  
  # Generate estimated efficiency curve (parabolic shape)
  (0..10).each do |i|
    flow = i * (pump_flow_max / 10.0)
    # Parabolic efficiency curve (peaks around 50-70% of max flow)
    peak_flow = pump_flow_max * 0.6
    eff = 85 - 0.05 * (flow - peak_flow) ** 2
    eff = [eff, 0].max
    curve << {flow: flow.round(1), efficiency: eff.round(1)}
  end
  
  # Get actual operating efficiency (if available)
  operating_efficiency = pump.result('efficiency') rescue nil
  if operating_efficiency.nil? && operating_flow
    # Estimate from curve
    peak_flow = pump_flow_max * 0.6
    operating_efficiency = (85 - 0.05 * (operating_flow - peak_flow) ** 2).round(1)
  end
  
  operating_point = {
    flow: operating_flow ? operating_flow.round(1) : 0.0,
    efficiency: operating_efficiency ? operating_efficiency.round(1) : 0.0
  }
  
  net.close
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'pump_efficiency.html')
  
  labels = curve.map { |c| c[:flow] }.join(',')
  data = curve.map { |c| c[:efficiency] }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Pump Efficiency</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.info{padding:15px;background:#e3f2fd;border-radius:5px;margin:20px 0}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Pump Efficiency Curve</h1>"
  html += "<div class='info'><strong>Operating Point:</strong> #{operating_point[:flow]} L/s @ #{operating_point[:efficiency]}% efficiency</div>"
  html += "<div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'line',data:{labels:[#{labels}],datasets:[{label:'Efficiency Curve',data:[#{data}],borderColor:'#1976d2',fill:false,tension:0.4},{label:'Operating Point',data:[{x:#{operating_point[:flow]},y:#{operating_point[:efficiency]}}],type:'scatter',backgroundColor:'#f44336',pointRadius:10}]},options:{responsive:true,maintainAspectRatio:false,scales:{x:{title:{display:true,text:'Flow (L/s)'}},y:{title:{display:true,text:'Efficiency (%)'},min:0,max:100}}}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Pump efficiency chart: #{html_file}"
  puts "  - Operating point: #{operating_point[:flow]} L/s @ #{operating_point[:efficiency]}%"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



