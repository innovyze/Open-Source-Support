# Script: 03_flow_capacity_comparison.rb
# Context: Exchange
# Purpose: Compare peak flows vs pipe capacity with color-coded severity
# Outputs: HTML + CSV
# Test Data: Sample pipe flow data
# Cleanup: N/A

begin
  puts "Flow vs Capacity Comparison - Starting..."
  $stdout.flush
  
  pipes = [
    {id: 'P101', peak_flow: 0.45, capacity: 0.5, util_pct: 90, severity: 'High'},
    {id: 'P102', peak_flow: 0.28, capacity: 0.6, util_pct: 47, severity: 'Low'},
    {id: 'P103', peak_flow: 1.2, capacity: 1.0, util_pct: 120, severity: 'Critical'},
    {id: 'P104', peak_flow: 0.65, capacity: 0.8, util_pct: 81, severity: 'Medium'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'flow_capacity.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "PipeID,PeakFlow,Capacity,Utilization,Severity"
    pipes.each { |p| f.puts "#{p[:id]},#{p[:peak_flow]},#{p[:capacity]},#{p[:util_pct]},#{p[:severity]}" }
  end
  
  html_file = File.join(output_dir, 'flow_capacity.html')
  html = <<-HTML
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Flow Capacity</title>
<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid #1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd}th{background:#1976d2;color:white}.critical{background:#ffcdd2}.high{background:#ffe0b2}.medium{background:#fff9c4}.low{background:#c8e6c9}</style></head>
<body><div class="container"><h1>Flow vs Capacity Analysis</h1><table><tr><th>Pipe ID</th><th>Peak Flow</th><th>Capacity</th><th>Utilization</th><th>Severity</th></tr>
  HTML
  
  pipes.each { |p| html += "<tr class='#{p[:severity].downcase}'><td>#{p[:id]}</td><td>#{p[:peak_flow]}</td><td>#{p[:capacity]}</td><td>#{p[:util_pct]}%</td><td>#{p[:severity]}</td></tr>" }
  html += "</table><p><strong>CSV:</strong> flow_capacity.csv</p></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Analysis complete: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













