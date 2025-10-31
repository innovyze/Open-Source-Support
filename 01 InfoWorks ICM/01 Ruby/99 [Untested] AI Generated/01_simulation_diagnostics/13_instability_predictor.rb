# Script: 13_instability_predictor.rb
# Context: Exchange
# Purpose: Pre-run risk assessment for numerical instability
# Outputs: HTML risk scorecard
# Usage: ruby script.rb [database_path] [network_name]
#        Analyzes network characteristics to predict instability risk

begin
  puts "Numerical Instability Predictor - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get network
  network_name = ARGV[1]
  unless network_name
    nets = db.model_object_collection('Model Network')
    if nets.empty?
      puts "ERROR: No networks found in database"
      exit 1
    end
    puts "Available networks:"
    nets.each_with_index { |net, i| puts "  #{i+1}. #{net.name}" }
    puts "\nUsage: script.rb [database_path] [network_name]"
    exit 1
  end
  
  net_mo = db.model_object(network_name)
  net = net_mo.open
  
  # Analyze network characteristics
  risk_factors = []
  
  # Network complexity
  node_count = 0
  link_count = 0
  net.row_objects('hw_node').each { |_| node_count += 1 }
  net.row_objects('hw_conduit').each { |_| link_count += 1 }
  complexity_score = (node_count > 500 ? 8 : (node_count > 200 ? 6 : 4))
  risk_factors << {factor: 'Network complexity', score: complexity_score, max: 10, status: complexity_score > 7 ? 'High' : (complexity_score > 5 ? 'Medium' : 'Low')}
  
  # Steep slopes
  steep_slopes = 0
  net.row_objects('hw_conduit').each do |pipe|
    slope = pipe.slope rescue nil
    steep_slopes += 1 if slope && slope.abs > 0.05
  end
  slope_score = (steep_slopes > 10 ? 8 : (steep_slopes > 5 ? 6 : 3))
  risk_factors << {factor: 'Steep slopes present', score: slope_score, max: 10, status: slope_score > 7 ? 'High' : (slope_score > 5 ? 'Medium' : 'Low')}
  
  # Pumps
  pump_count = 0
  net.row_objects('hw_pump').each { |_| pump_count += 1 }
  pump_score = (pump_count > 5 ? 9 : (pump_count > 2 ? 6 : 3))
  risk_factors << {factor: 'Pumps with fast cycling', score: pump_score, max: 10, status: pump_score > 7 ? 'High' : (pump_score > 5 ? 'Medium' : 'Low')}
  
  # Small pipe diameters
  small_pipes = 0
  net.row_objects('hw_conduit').each do |pipe|
    diameter = pipe.diameter rescue nil
    small_pipes += 1 if diameter && diameter < 0.3
  end
  diameter_score = (small_pipes > 20 ? 7 : (small_pipes > 10 ? 5 : 3))
  risk_factors << {factor: 'Small pipe diameters', score: diameter_score, max: 10, status: diameter_score > 6 ? 'High' : (diameter_score > 4 ? 'Medium' : 'Low')}
  
  # Rapid inflow changes (estimated from subcatchments)
  subcatch_count = 0
  net.row_objects('hw_subcatchment').each { |_| subcatch_count += 1 }
  inflow_score = (subcatch_count > 50 ? 6 : (subcatch_count > 20 ? 4 : 2))
  risk_factors << {factor: 'Rapid inflow changes', score: inflow_score, max: 10, status: inflow_score > 5 ? 'Medium' : 'Low'}
  
  # Looped network topology
  loop_score = 4  # Simplified - would need graph analysis
  risk_factors << {factor: 'Looped network topology', score: loop_score, max: 10, status: loop_score > 6 ? 'Medium' : 'Low'}
  
  # Supercritical flow potential
  supercritical_score = (steep_slopes > 10 ? 7 : 4)
  risk_factors << {factor: 'Supercritical flow potential', score: supercritical_score, max: 10, status: supercritical_score > 6 ? 'Medium' : 'Low'}
  
  net.close
  
  total_score = risk_factors.map { |r| r[:score] }.sum
  max_score = risk_factors.map { |r| r[:max] }.sum
  risk_pct = (total_score.to_f / max_score * 100).round(1)
  
  risk_level = if risk_pct > 70 then 'High Risk'
              elsif risk_pct > 50 then 'Medium Risk'
              else 'Low Risk'
              end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'instability_predictor.html')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Instability Risk Predictor</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 900px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #f57c00; padding-bottom: 10px; }
    .risk-score { text-align: center; padding: 30px; margin: 20px 0; border-radius: 10px; }
    .risk-high { background: #ffcdd2; border: 3px solid #c62828; }
    .risk-medium { background: #fff9c4; border: 3px solid #f57c00; }
    .risk-low { background: #c8e6c9; border: 3px solid #388e3c; }
    .risk-score .value { font-size: 56px; font-weight: bold; }
    .risk-score .label { font-size: 20px; margin-top: 10px; }
    .factor { display: flex; align-items: center; margin: 15px 0; }
    .factor-name { flex: 1; font-weight: 500; }
    .factor-bar { flex: 2; height: 30px; background: #e0e0e0; border-radius: 15px; position: relative; overflow: hidden; }
    .factor-fill { height: 100%; border-radius: 15px; transition: width 0.3s; }
    .fill-high { background: #ef5350; }
    .fill-medium { background: #ffa726; }
    .fill-low { background: #66bb6a; }
    .factor-score { margin-left: 10px; font-weight: bold; width: 50px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Numerical Instability Risk Assessment</h1>
    
    <div class="risk-score risk-#{risk_level.split.last.downcase}">
      <div class="value">#{risk_pct}%</div>
      <div class="label">#{risk_level}</div>
      <div style="font-size: 14px; margin-top: 10px;">Overall Risk Score: #{total_score}/#{max_score}</div>
    </div>
    
    <h2>Risk Factor Breakdown</h2>
  HTML
  
  risk_factors.each do |factor|
    fill_pct = (factor[:score].to_f / factor[:max] * 100).round(0)
    fill_class = case factor[:status]
                when 'High' then 'fill-high'
                when 'Medium' then 'fill-medium'
                else 'fill-low'
                end
    
    html += <<-FACTOR
    <div class="factor">
      <div class="factor-name">#{factor[:factor]}</div>
      <div class="factor-bar">
        <div class="factor-fill #{fill_class}" style="width: #{fill_pct}%"></div>
      </div>
      <div class="factor-score">#{factor[:score]}/#{factor[:max]}</div>
    </div>
    FACTOR
  end
  
  html += <<-HTML
    
    <h2>Recommendations</h2>
    #{risk_level == 'High Risk' ? '<p style="padding: 15px; background: #ffebee; border-left: 4px solid #c62828;"><strong>High Risk:</strong> Consider pre-simulation adjustments before running.</p>' : ''}
    <ul>
      <li><strong>Solver settings:</strong> #{risk_pct > 60 ? 'Use conservative timestep and tight tolerances' : 'Default settings should be adequate'}</li>
      <li><strong>Initial conditions:</strong> #{risk_pct > 60 ? 'Critical - ensure proper initialization' : 'Standard initialization acceptable'}</li>
      <li><strong>Monitoring:</strong> #{risk_pct > 60 ? 'Enable detailed logging and frequent checkpoints' : 'Standard monitoring sufficient'}</li>
      <li><strong>Network review:</strong> #{risk_pct > 60 ? 'Highly recommended before running' : 'Optional pre-check'}</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Instability risk assessment complete: #{output_file}"
  puts "  - Risk level: #{risk_level} (#{risk_pct}%)"
  puts "  - Score: #{total_score}/#{max_score}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













