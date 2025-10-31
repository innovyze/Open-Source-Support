# Script: 05_sensitivity_tornado.rb
# Context: Exchange
# Purpose: Sensitivity tornado chart (variable impact ranking)
# Outputs: HTML tornado chart
# Test Data: Sample sensitivity data
# Cleanup: N/A

begin
  puts "Sensitivity Tornado Chart - Starting..."
  $stdout.flush
  
  variables = [
    {name: 'Rainfall Intensity', low: -15.5, high: 22.3},
    {name: 'Pipe Roughness', low: -8.2, high: 12.1},
    {name: 'Infiltration Rate', low: -12.8, high: 18.5},
    {name: 'Pump Capacity', low: -6.5, high: 9.2},
    {name: 'Storage Volume', low: -10.1, high: 14.8}
  ]
  
  # Sort by total range (impact)
  variables.each { |v| v[:range] = (v[:high] - v[:low]).abs }
  variables.sort_by! { |v| -v[:range] }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'sensitivity_tornado.html')
  
  labels = variables.map { |v| "'#{v[:name]}'" }.join(',')
  low_data = variables.map { |v| v[:low] }.join(',')
  high_data = variables.map { |v| v[:high] }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Sensitivity Tornado</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1100px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#f57c00}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Sensitivity Tornado Chart</h1><p><strong>Variables ranked by impact on system performance</strong></p>"
  html += "<div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'bar',data:{labels:[#{labels}],datasets:[{label:'Low (-)',data:[#{low_data}],backgroundColor:'#2196f3'},{label:'High (+)',data:[#{high_data}],backgroundColor:'#f44336'}]},options:{indexAxis:'y',responsive:true,maintainAspectRatio:false,scales:{x:{title:{display:true,text:'Impact on Performance (%)'}}}}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Tornado chart: #{html_file}"
  puts "  - Most sensitive: #{variables[0][:name]} (±#{variables[0][:range].round(1)}%)"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



