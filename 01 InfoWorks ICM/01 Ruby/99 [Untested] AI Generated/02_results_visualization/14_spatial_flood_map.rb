# Script: 14_spatial_flood_map.rb
# Context: Exchange
# Purpose: Spatial flood map (node depths with color gradients)
# Outputs: HTML map
# Test Data: Sample node depths
# Cleanup: N/A

begin
  puts "Spatial Flood Map - Starting..."
  $stdout.flush
  
  nodes = [
    {id: 'N001', depth: 0.2, status: 'Minor'},
    {id: 'N002', depth: 0.8, status: 'Moderate'},
    {id: 'N003', depth: 1.5, status: 'Major'},
    {id: 'N004', depth: 0.1, status: 'Minor'},
    {id: 'N005', depth: 2.2, status: 'Severe'},
    {id: 'N006', depth: 0.5, status: 'Minor'},
    {id: 'N007', depth: 1.2, status: 'Moderate'},
    {id: 'N008', depth: 1.8, status: 'Major'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'flood_map.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Flood Map</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#2196f3}.map{display:grid;grid-template-columns:repeat(4,1fr);gap:15px;margin:20px 0}.node{padding:25px;border-radius:8px;text-align:center;font-weight:bold;color:white}.minor{background:#4caf50}.moderate{background:#ff9800}.major{background:#f44336}.severe{background:#b71c1c}.legend{display:flex;gap:20px;margin:20px 0;justify-content:center}.legend-item{display:flex;align-items:center;gap:8px}.legend-box{width:30px;height:30px;border-radius:5px}</style></head>"
  html += "<body><div class='container'><h1>🌊 Spatial Flood Map</h1>"
  html += "<div class='legend'>"
  html += "<div class='legend-item'><div class='legend-box minor'></div><div>Minor (<0.5m)</div></div>"
  html += "<div class='legend-item'><div class='legend-box moderate'></div><div>Moderate (0.5-1.0m)</div></div>"
  html += "<div class='legend-item'><div class='legend-box major'></div><div>Major (1.0-2.0m)</div></div>"
  html += "<div class='legend-item'><div class='legend-box severe'></div><div>Severe (>2.0m)</div></div>"
  html += "</div><div class='map'>"
  
  nodes.each { |n| html += "<div class='node #{n[:status].downcase}'>#{n[:id]}<br>#{n[:depth]}m</div>" }
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Flood map: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



