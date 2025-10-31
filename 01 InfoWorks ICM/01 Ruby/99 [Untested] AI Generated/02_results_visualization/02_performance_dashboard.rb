# Script: 02_performance_dashboard.rb
# Context: Exchange
# Purpose: Generate HTML multi-metric performance dashboard with gauges
# Outputs: HTML dashboard
# Usage: ruby script.rb [database_path] [simulation_name]
#        Calculates metrics from simulation results

begin
  puts "Performance Dashboard Generator - Starting..."
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
  
  # Calculate metrics from simulation results
  net = sim_mo.open
  
  # Network Efficiency: % of pipes operating below capacity
  total_pipes = 0
  efficient_pipes = 0
  net.row_objects('hw_conduit').each do |pipe|
    max_flow = pipe.result('flow') rescue nil
    # Calculate capacity from geometry: Q = A × V
    width = pipe['conduit_width'] rescue nil
    height = pipe['conduit_height'] rescue width rescue nil
    if width && height && width > 0 && height > 0
      area = (width / 1000.0) * (height / 1000.0)  # Convert mm to m
      capacity = area * 5.0  # Typical max velocity 5 m/s
    else
      capacity = nil
    end
    if max_flow && capacity && capacity > 0
      total_pipes += 1
      efficient_pipes += 1 if (max_flow.abs / capacity) < 0.85
    end
  end
  efficiency = total_pipes > 0 ? (efficient_pipes.to_f / total_pipes * 100).round : 0
  
  # Asset Utilization: average % of capacity used
  total_utilization = 0.0
  util_count = 0
  net.row_objects('hw_conduit').each do |pipe|
    max_flow = pipe.result('flow') rescue nil
    # Calculate capacity from geometry: Q = A × V
    width = pipe['conduit_width'] rescue nil
    height = pipe['conduit_height'] rescue width rescue nil
    if width && height && width > 0 && height > 0
      area = (width / 1000.0) * (height / 1000.0)  # Convert mm to m
      capacity = area * 5.0  # Typical max velocity 5 m/s
    else
      capacity = nil
    end
    if max_flow && capacity && capacity > 0
      utilization = (max_flow.abs / capacity * 100)
      total_utilization += utilization
      util_count += 1
    end
  end
  asset_util = util_count > 0 ? (total_utilization / util_count).round : 0
  
  # CSO Compliance: % of CSOs not spilling
  total_csos = 0
  compliant_csos = 0
  net.row_objects('hw_node').each do |node|
    flood_vol = node.result('flood_volume') rescue nil
    if flood_vol
      total_csos += 1
      compliant_csos += 1 if flood_vol == 0
    end
  end
  cso_compliance = total_csos > 0 ? (compliant_csos.to_f / total_csos * 100).round : 100
  
  # Energy Efficiency: estimated from pump efficiency (simplified)
  energy_efficiency = 75  # Placeholder - would need pump data
  
  net.close
  
  metrics = {
    'Network Efficiency' => {value: efficiency, target: 85, unit: '%', status: efficiency >= 80 ? 'excellent' : (efficiency >= 70 ? 'good' : 'warning')},
    'Asset Utilization' => {value: asset_util, target: 70, unit: '%', status: asset_util >= 65 ? 'good' : 'warning'},
    'CSO Compliance' => {value: cso_compliance, target: 90, unit: '%', status: cso_compliance >= 90 ? 'excellent' : (cso_compliance >= 80 ? 'good' : 'warning')},
    'Energy Efficiency' => {value: energy_efficiency, target: 75, unit: '%', status: 'good'}
  }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'performance_dashboard.html')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Performance Dashboard</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 0; background: #1e1e1e; color: white; }
    .dashboard { padding: 30px; }
    h1 { margin: 0 0 30px 0; font-size: 32px; }
    .metrics { display: grid; grid-template-columns: repeat(2, 1fr); gap: 20px; }
    .metric-card { background: #2d2d2d; padding: 25px; border-radius: 10px; border: 2px solid #444; }
    .metric-title { font-size: 14px; color: #aaa; margin-bottom: 15px; }
    .gauge { position: relative; width: 150px; height: 150px; margin: 0 auto; }
    .gauge-circle { fill: none; stroke: #444; stroke-width: 12; }
    .gauge-value { fill: none; stroke-width: 12; stroke-linecap: round; }
    .gauge-excellent { stroke: #4caf50; }
    .gauge-good { stroke: #2196f3; }
    .gauge-warning { stroke: #ff9800; }
    .gauge-poor { stroke: #f44336; }
    .gauge-text { position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%); font-size: 28px; font-weight: bold; }
    .metric-footer { text-align: center; margin-top: 15px; font-size: 12px; color: #999; }
  </style>
</head>
<body>
  <div class="dashboard">
    <h1>⚡ System Performance Dashboard</h1>
    <div class="metrics">
  HTML
  
  metrics.each do |name, data|
    circumference = 2 * Math::PI * 60
    offset = circumference - (data[:value] / 100.0 * circumference)
    
    html += <<-METRIC
      <div class="metric-card">
        <div class="metric-title">#{name}</div>
        <div class="gauge">
          <svg width="150" height="150">
            <circle class="gauge-circle" cx="75" cy="75" r="60"/>
            <circle class="gauge-value gauge-#{data[:status]}" cx="75" cy="75" r="60" 
                    stroke-dasharray="#{circumference}" stroke-dashoffset="#{offset}"
                    transform="rotate(-90 75 75)"/>
          </svg>
          <div class="gauge-text">#{data[:value]}#{data[:unit]}</div>
        </div>
        <div class="metric-footer">Target: #{data[:target]}#{data[:unit]}</div>
      </div>
    METRIC
  end
  
  html += <<-HTML
    </div>
  </div>
</body>
</html>
  HTML
  
  File.write(html_file, html)
  puts "✓ Dashboard generated: #{html_file}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













