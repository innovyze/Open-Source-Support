# Script: 11_ddf_curves.rb
# Context: Exchange
# Purpose: Depth-duration-frequency curves (multiple return periods)
# Outputs: HTML with curves
# Test Data: Sample DDF data
# Cleanup: N/A

begin
  puts "Depth-Duration-Frequency Curves - Starting..."
  $stdout.flush
  
  durations = [5, 10, 15, 30, 60, 120, 180]  # minutes
  return_periods = {'2yr' => [15, 22, 28, 38, 52, 68, 78],
                    '5yr' => [22, 32, 41, 55, 75, 98, 112],
                    '10yr' => [28, 42, 53, 71, 98, 128, 146]}
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'ddf_curves.html')
  
  labels = durations.map { |d| "'#{d}min'" }.join(',')
  datasets = return_periods.map do |rp, values|
    "{label:'#{rp}',data:[#{values.join(',')}],borderColor:'##{rand(0..255).to_s(16).rjust(2,'0')}#{rand(0..255).to_s(16).rjust(2,'0')}#{rand(0..255).to_s(16).rjust(2,'0')}',fill:false,tension:0.3}"
  end.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>DDF Curves</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1100px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Depth-Duration-Frequency Curves</h1><div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'line',data:{labels:[#{labels}],datasets:[#{datasets}]},options:{responsive:true,maintainAspectRatio:false,scales:{x:{title:{display:true,text:'Duration'}},y:{title:{display:true,text:'Rainfall Depth (mm)'}}}linear}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ DDF curves generated: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



