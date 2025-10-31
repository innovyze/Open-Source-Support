# Script: 18_pump_efficiency_plotter.rb
# Context: Exchange
# Purpose: Pump efficiency curve vs operating point plotter
# Outputs: HTML chart
# Test Data: Sample pump data
# Cleanup: N/A

begin
  puts "Pump Efficiency Plotter - Starting..."
  $stdout.flush
  
  # Efficiency curve (flow, efficiency)
  curve = (0..10).map do |i|
    flow = i * 10
    eff = -0.05 * (flow - 50) ** 2 + 85  # Parabola peaked at 50 L/s
    {flow: flow, efficiency: eff.round(1)}
  end
  
  operating_point = {flow: 62, efficiency: 78.2}
  
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



