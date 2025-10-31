# Script: 07_asset_utilization_heatmap.rb
# Context: Exchange
# Purpose: Asset utilization heatmap (pipes, pumps, tanks as % capacity)
# Outputs: HTML heatmap
# Test Data: Sample asset data
# Cleanup: N/A

begin
  puts "Asset Utilization Heatmap - Starting..."
  $stdout.flush
  
  assets = [
    {id: 'Pipe_001', type: 'Pipe', util: 92, status: 'High'},
    {id: 'Pipe_002', type: 'Pipe', util: 45, status: 'Low'},
    {id: 'Pump_A', type: 'Pump', util: 78, status: 'Medium'},
    {id: 'Tank_1', type: 'Tank', util: 68, status: 'Medium'},
    {id: 'Pipe_003', type: 'Pipe', util: 105, status: 'Critical'},
    {id: 'Pump_B', type: 'Pump', util: 55, status: 'Low'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'asset_utilization.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Asset Utilization</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:15px;margin:20px 0}.asset{padding:20px;border-radius:8px;text-align:center;font-weight:bold;color:white}.critical{background:#ef5350}.high{background:#ff9800}.medium{background:#42a5f5}.low{background:#66bb6a}</style></head>"
  html += "<body><div class='container'><h1>Asset Utilization Heatmap</h1><div class='grid'>"
  
  assets.each { |a| html += "<div class='asset #{a[:status].downcase}'>#{a[:id]}<br>#{a[:type]}<br>#{a[:util]}%</div>" }
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Asset utilization heatmap: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end




