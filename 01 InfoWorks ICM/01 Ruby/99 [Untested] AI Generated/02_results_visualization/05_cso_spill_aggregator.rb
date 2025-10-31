# Script: 05_cso_spill_aggregator.rb
# Context: Exchange
# Purpose: Aggregate CSO spill volumes with stacked bar charts
# Outputs: HTML + CSV
# Test Data: Sample CSO data
# Cleanup: N/A

begin
  puts "CSO Spill Aggregator - Starting..."
  $stdout.flush
  
  csos = [
    {id: 'CSO_01', volume_m3: 1250, events: 8},
    {id: 'CSO_02', volume_m3: 780, events: 5},
    {id: 'CSO_03', volume_m3: 2100, events: 12},
    {id: 'CSO_04', volume_m3: 450, events: 3}
  ]
  
  total_vol = csos.map { |c| c[:volume_m3] }.sum
  total_events = csos.map { |c| c[:events] }.sum
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'cso_spills.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "CSO_ID,Volume_m3,Events"
    csos.each { |c| f.puts "#{c[:id]},#{c[:volume_m3]},#{c[:events]}" }
  end
  
  html_file = File.join(output_dir, 'cso_spills.html')
  labels = csos.map { |c| "'#{c[:id]}'" }.join(',')
  data = csos.map { |c| c[:volume_m3] }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>CSO Spills</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid #f44336}.summary{display:flex;gap:20px;margin:20px 0}.stat{flex:1;padding:15px;background:#ffebee;border-radius:5px;text-align:center}.stat .value{font-size:28px;font-weight:bold;color:#c62828}.chart-container{height:400px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>CSO Spill Analysis</h1>"
  html += "<div class='summary'><div class='stat'><div class='value'>#{total_vol}</div><div>Total Volume (m³)</div></div>"
  html += "<div class='stat'><div class='value'>#{total_events}</div><div>Total Events</div></div></div>"
  html += "<div class='chart-container'><canvas id='chart'></canvas></div>"
  html += "<p><strong>CSV:</strong> cso_spills.csv</p></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'bar',data:{labels:[#{labels}],datasets:[{label:'Spill Volume (m³)',data:[#{data}],backgroundColor:'#f44336'}]},options:{responsive:true,maintainAspectRatio:false}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ CSO analysis complete: #{html_file}"
  puts "  - Total volume: #{total_vol} m³"
  puts "  - Total events: #{total_events}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end




