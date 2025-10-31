# Script: 11_ddf_curves.rb
# Context: Exchange
# Purpose: Depth-duration-frequency curves (multiple return periods)
# Outputs: HTML with curves
# Usage: ruby script.rb [database_path]
#        Note: DDF curves typically come from rainfall data, not simulation results
#        This script provides a placeholder structure

begin
  puts "Depth-Duration-Frequency Curves - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # DDF curves are typically from rainfall data, not simulation results
  # This is a placeholder that would need actual rainfall data
  durations = [5, 10, 15, 30, 60, 120, 180]  # minutes
  
  # Placeholder data - would need actual rainfall analysis
  return_periods = {
    '2yr' => durations.map { |d| (d * 0.3 + rand(5..15)).round },
    '5yr' => durations.map { |d| (d * 0.4 + rand(10..25)).round },
    '10yr' => durations.map { |d| (d * 0.5 + rand(15..35)).round }
  }
  
  puts "Note: This script uses placeholder DDF data."
  puts "For real DDF curves, integrate with rainfall data analysis."
  
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



