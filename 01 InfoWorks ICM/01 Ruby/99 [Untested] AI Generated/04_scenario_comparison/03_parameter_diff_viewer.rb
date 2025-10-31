# Script: 03_parameter_diff_viewer.rb
# Context: Exchange
# Purpose: Side-by-side scenario parameter comparison table
# Outputs: HTML comparison table
# Test Data: Sample parameter differences
# Cleanup: N/A

begin
  puts "Parameter Diff Viewer - Starting..."
  $stdout.flush
  
  parameters = [
    {param: 'Pipe Roughness', base: 0.013, opt_a: 0.015, opt_b: 0.012},
    {param: 'Timestep (s)', base: 1.0, opt_a: 0.5, opt_b: 0.25},
    {param: 'Rainfall Multiplier', base: 1.0, opt_a: 1.2, opt_b: 1.5},
    {param: 'Pump Count', base: 8, opt_a: 10, opt_b: 12}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'parameter_diff.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Parameter Diff</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:12px;border-bottom:1px solid #ddd}th{background:#1976d2;color:white}.changed{background:#fff9c4;font-weight:bold}</style></head>"
  html += "<body><div class='container'><h1>Scenario Parameter Comparison</h1><table><tr><th>Parameter</th><th>Base</th><th>Option A</th><th>Option B</th></tr>"
  
  parameters.each do |p|
    html += "<tr><td>#{p[:param]}</td><td>#{p[:base]}</td>"
    html += "<td#{p[:opt_a] != p[:base] ? ' class="changed"' : ''}>#{p[:opt_a]}</td>"
    html += "<td#{p[:opt_b] != p[:base] ? ' class="changed"' : ''}>#{p[:opt_b]}</td></tr>"
  end
  
  html += "</table></div></body></html>"
  File.write(html_file, html)
  puts "✓ Parameter diff: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



