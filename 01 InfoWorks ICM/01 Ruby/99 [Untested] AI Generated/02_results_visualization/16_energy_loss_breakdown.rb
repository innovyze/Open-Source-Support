# Script: 16_energy_loss_breakdown.rb
# Context: Exchange
# Purpose: Energy loss breakdown pie chart (friction, minor, form losses)
# Outputs: HTML pie chart
# Test Data: Sample energy data
# Cleanup: N/A

begin
  puts "Energy Loss Breakdown - Starting..."
  $stdout.flush
  
  losses = {
    'Friction Loss' => 45.2,
    'Minor Losses' => 28.5,
    'Form Losses' => 18.3,
    'Other' => 8.0
  }
  
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



