# Script: 03_network_metadata_comparator.rb
# Context: Exchange
# Purpose: Compare network metadata (versions/dates/sizes) across databases
# Outputs: HTML comparison table
# Test Data: Sample metadata
# Cleanup: N/A

begin
  puts "Network Metadata Comparator - Starting..."
  $stdout.flush
  
  networks = [
    {name: 'Network_A', version: 'v2.3', modified: '2024-10-15', size_mb: 12.5, scenarios: 8},
    {name: 'Network_B', version: 'v1.8', modified: '2024-09-22', size_mb: 28.3, scenarios: 5},
    {name: 'Network_C', version: 'v3.1', modified: '2024-10-20', size_mb: 8.7, scenarios: 12}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'network_comparison.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Network Comparison</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:12px;border-bottom:1px solid #ddd}th{background:#1976d2;color:white}tr:hover{background:#f5f5f5}</style></head>"
  html += "<body><div class='container'><h1>Network Metadata Comparison</h1><table><tr><th>Network</th><th>Version</th><th>Last Modified</th><th>Size (MB)</th><th>Scenarios</th></tr>"
  
  networks.each { |n| html += "<tr><td>#{n[:name]}</td><td>#{n[:version]}</td><td>#{n[:modified]}</td><td>#{n[:size_mb]}</td><td>#{n[:scenarios]}</td></tr>" }
  
  html += "</table></div></body></html>"
  File.write(html_file, html)
  puts "✓ Comparison generated: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



