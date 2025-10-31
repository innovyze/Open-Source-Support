# Script: 04_surcharge_duration_heatmap.rb
# Context: Exchange
# Purpose: Generate surcharge duration heatmap by catchment
# Outputs: HTML heatmap
# Test Data: Sample surcharge data
# Cleanup: N/A

begin
  puts "Surcharge Duration Heatmap - Starting..."
  $stdout.flush
  
  catchments = [
    {id: 'C01', surcharge_min: 45, severity: 'High'},
    {id: 'C02', surcharge_min: 12, severity: 'Low'},
    {id: 'C03', surcharge_min: 78, severity: 'Critical'},
    {id: 'C04', surcharge_min: 28, severity: 'Medium'},
    {id: 'C05', surcharge_min: 5, severity: 'Low'},
    {id: 'C06', surcharge_min: 62, severity: 'High'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'surcharge_heatmap.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Surcharge Heatmap</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:800px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid #f57c00}.heatmap{display:grid;grid-template-columns:repeat(3,1fr);gap:15px;margin:20px 0}.cell{padding:30px;border-radius:8px;text-align:center;font-size:18px;font-weight:bold}.critical{background:#ef5350;color:white}.high{background:#ff9800;color:white}.medium{background:#ffa726;color:white}.low{background:#66bb6a;color:white}</style></head>"
  html += "<body><div class='container'><h1>Surcharge Duration Heatmap</h1><div class='heatmap'>"
  
  catchments.each { |c| html += "<div class='cell #{c[:severity].downcase}'>#{c[:id]}<br>#{c[:surcharge_min]} min</div>" }
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Heatmap generated: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













