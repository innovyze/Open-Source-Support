# Script: 15_flow_profile_plotter.rb
# Context: Exchange
# Purpose: Flow profile longitudinal section plotter
# Outputs: HTML profile chart
# Test Data: Sample profile data
# Cleanup: N/A

begin
  puts "Flow Profile Plotter - Starting..."
  $stdout.flush
  
  profile = (0..10).map do |i|
    {chainage: i * 100, invert: 95 - i * 0.5, wse: 96 - i * 0.4, ground: 98 - i * 0.3}
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'flow_profile.html')
  
  labels = profile.map { |p| p[:chainage] }.join(',')
  invert_data = profile.map { |p| p[:invert] }.join(',')
  wse_data = profile.map { |p| p[:wse] }.join(',')
  ground_data = profile.map { |p| p[:ground] }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Flow Profile</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Longitudinal Profile</h1><div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'line',data:{labels:[#{labels}],datasets:[{label:'Ground Level',data:[#{ground_data}],borderColor:'#8d6e63',fill:false},{label:'Water Surface',data:[#{wse_data}],borderColor:'#2196f3',fill:true,backgroundColor:'rgba(33,150,243,0.2)'},{label:'Invert',data:[#{invert_data}],borderColor:'#424242',fill:false}]},options:{responsive:true,maintainAspectRatio:false,scales:{x:{title:{display:true,text:'Chainage (m)'}},y:{title:{display:true,text:'Elevation (m)'}}}linear}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Flow profile: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



