# Script: 09_hgl_discontinuity_finder.rb
# Context: Exchange
# Purpose: Find hydraulic grade line discontinuities at nodes
# Outputs: CSV + HTML report
# Test Data: Sample HGL data
# Cleanup: N/A

begin
  puts "HGL Discontinuity Finder - Starting..."
  $stdout.flush
  
  # Sample HGL discontinuity data
  discontinuities = [
    {node: 'N205', upstream_hgl: 125.5, downstream_hgl: 123.2, diff: 2.3, type: 'Drop'},
    {node: 'N308', upstream_hgl: 110.2, downstream_hgl: 112.5, diff: 2.3, type: 'Jump'},
    {node: 'N412', upstream_hgl: 98.5, downstream_hgl: 97.8, diff: 0.7, type: 'Drop'},
    {node: 'N501', upstream_hgl: 88.2, downstream_hgl: 90.5, diff: 2.3, type: 'Jump'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  # Write CSV
  csv_file = File.join(output_dir, 'hgl_discontinuities.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Node,Upstream_HGL,Downstream_HGL,Difference,Type"
    discontinuities.each { |d| f.puts "#{d[:node]},#{d[:upstream_hgl]},#{d[:downstream_hgl]},#{d[:diff]},#{d[:type]}" }
  end
  
  html_file = File.join(output_dir, 'hgl_discontinuities.html')
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>HGL Discontinuity Finder</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 900px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #1976d2; color: white; }
    .type-drop { color: #c62828; font-weight: bold; }
    .type-jump { color: #2e7d32; font-weight: bold; }
    .summary { padding: 15px; background: #e3f2fd; border-radius: 5px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>HGL Discontinuity Analysis</h1>
    <div class="summary">
      <strong>Total Discontinuities:</strong> #{discontinuities.length} | 
      <strong>Drops:</strong> #{discontinuities.count { |d| d[:type] == 'Drop' }} | 
      <strong>Jumps:</strong> #{discontinuities.count { |d| d[:type] == 'Jump' }}
    </div>
    <table>
      <tr><th>Node</th><th>Upstream HGL (m)</th><th>Downstream HGL (m)</th><th>Difference (m)</th><th>Type</th></tr>
  HTML
  
  discontinuities.each do |d|
    type_class = "type-#{d[:type].downcase}"
    html += "      <tr><td>#{d[:node]}</td><td>#{d[:upstream_hgl]}</td><td>#{d[:downstream_hgl]}</td><td>#{d[:diff]}</td><td class=\"#{type_class}\">#{d[:type]}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
    <p><strong>CSV Export:</strong> hgl_discontinuities.csv</p>
    <h2>Interpretation</h2>
    <ul>
      <li><strong>Drops:</strong> May indicate energy losses at structures or numerical issues</li>
      <li><strong>Jumps:</strong> Can represent hydraulic jumps or model convergence problems</li>
      <li>Large discontinuities (>1m) warrant investigation</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(html_file, html)
  puts "✓ HGL discontinuity analysis complete:"
  puts "  - CSV: #{csv_file}"
  puts "  - HTML: #{html_file}"
  puts "  - Discontinuities found: #{discontinuities.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













