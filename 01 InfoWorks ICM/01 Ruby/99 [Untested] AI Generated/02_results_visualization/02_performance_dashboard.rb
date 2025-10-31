# Script: 02_performance_dashboard.rb
# Context: Exchange
# Purpose: Generate HTML multi-metric performance dashboard with gauges
# Outputs: HTML dashboard
# Test Data: Sample performance metrics
# Cleanup: N/A

begin
  puts "Performance Dashboard Generator - Starting..."
  $stdout.flush
  
  metrics = {
    'Network Efficiency' => {value: 78, target: 85, unit: '%', status: 'warning'},
    'Asset Utilization' => {value: 65, target: 70, unit: '%', status: 'good'},
    'CSO Compliance' => {value: 92, target: 90, unit: '%', status: 'excellent'},
    'Energy Efficiency' => {value: 71, target: 75, unit: '%', status: 'good'}
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













