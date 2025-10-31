# Script: 06_lid_performance_reporter.rb
# Context: Exchange
# Purpose: LID performance metrics (before/after comparison)
# Outputs: HTML comparison report
# Test Data: Sample LID data
# Cleanup: N/A

begin
  puts "LID Performance Reporter - Starting..."
  $stdout.flush
  
  metrics = {
    'Runoff Volume (m³)' => {before: 12500, after: 8750, improvement: 30},
    'Peak Flow (m³/s)' => {before: 2.8, after: 1.9, improvement: 32},
    'Pollutant Load (kg)' => {before: 145, after: 92, improvement: 37}
  }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'lid_performance.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>LID Performance</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#388e3c}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:12px;border-bottom:1px solid #ddd}th{background:#388e3c;color:white}.improvement{color:#388e3c;font-weight:bold}</style></head>"
  html += "<body><div class='container'><h1>LID Performance Analysis</h1><table><tr><th>Metric</th><th>Before</th><th>After</th><th>Improvement</th></tr>"
  
  metrics.each { |name, data| html += "<tr><td>#{name}</td><td>#{data[:before]}</td><td>#{data[:after]}</td><td class='improvement'>#{data[:improvement]}%</td></tr>" }
  
  html += "</table></div></body></html>"
  File.write(html_file, html)
  puts "✓ LID report generated: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end




