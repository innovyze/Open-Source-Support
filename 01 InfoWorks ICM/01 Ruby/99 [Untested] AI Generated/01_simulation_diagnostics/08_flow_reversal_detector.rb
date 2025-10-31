# Script: 08_flow_reversal_detector.rb
# Context: Exchange
# Purpose: Detect and map flow reversals (link instability indicator)
# Outputs: HTML with network map showing reversals
# Test Data: Sample flow reversal data
# Cleanup: N/A

begin
  puts "Flow Reversal Detector - Starting..."
  $stdout.flush
  
  # Sample flow reversal data (link_id, reversal_count, peak_velocity)
  reversals = [
    {link: 'L101', count: 15, peak_vel: 2.5, severity: 'High'},
    {link: 'L102', count: 3, peak_vel: 0.8, severity: 'Low'},
    {link: 'L103', count: 8, peak_vel: 1.5, severity: 'Medium'},
    {link: 'L104', count: 22, peak_vel: 3.2, severity: 'Critical'},
    {link: 'L105', count: 5, peak_vel: 1.0, severity: 'Low'},
    {link: 'L106', count: 18, peak_vel: 2.8, severity: 'High'}
  ]
  
  critical = reversals.count { |r| r[:severity] == 'Critical' }
  high = reversals.count { |r| r[:severity] == 'High' }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'flow_reversals.html')
  
  # Build mermaid network diagram
  mermaid = "graph LR\n"
  reversals.each_with_index do |r, i|
    style_class = case r[:severity]
    when 'Critical' then 'criticalLink'
    when 'High' then 'highLink'
    when 'Medium' then 'mediumLink'
    else 'lowLink'
    end
    mermaid += "    #{r[:link]}[\"#{r[:link]}<br/>Reversals: #{r[:count]}<br/>Peak: #{r[:peak_vel]} m/s\"]:::#{style_class}\n"
  end
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Flow Reversal Detector</title>
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({startOnLoad:true, theme:'default'});</script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #c62828; padding-bottom: 10px; }
    .alert { padding: 15px; background: #ffebee; border-left: 4px solid #c62828; margin: 20px 0; }
    .summary { display: flex; gap: 20px; margin: 20px 0; }
    .stat-box { flex: 1; padding: 15px; border-radius: 5px; text-align: center; border: 2px solid; }
    .stat-box.critical { background: #ffcdd2; border-color: #b71c1c; }
    .stat-box.high { background: #ffe0b2; border-color: #e65100; }
    .stat-box .count { font-size: 28px; font-weight: bold; }
    .mermaid { background: #fafafa; padding: 20px; border-radius: 5px; margin: 20px 0; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #c62828; color: white; }
  </style>
  <style>
    .criticalLink { fill: #ef5350 !important; stroke: #c62828 !important; stroke-width: 3px; }
    .highLink { fill: #ff9800 !important; stroke: #e65100 !important; stroke-width: 3px; }
    .mediumLink { fill: #ffa726 !important; stroke: #f57c00 !important; stroke-width: 2px; }
    .lowLink { fill: #66bb6a !important; stroke: #388e3c !important; stroke-width: 2px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Flow Reversal Analysis</h1>
    
    #{critical > 0 ? "<div class=\"alert\"><strong>Alert:</strong> #{critical} link(s) with critical flow instability detected!</div>" : ""}
    
    <div class="summary">
      <div class="stat-box critical">
        <div class="count">#{critical}</div>
        <div class="label">Critical</div>
      </div>
      <div class="stat-box high">
        <div class="count">#{high}</div>
        <div class="label">High Risk</div>
      </div>
      <div class="stat-box">
        <div class="count">#{reversals.length}</div>
        <div class="label">Total Links</div>
      </div>
    </div>
    
    <h2>Network Map</h2>
    <div class="mermaid">
#{mermaid}
    </div>
    
    <h2>Reversal Details</h2>
    <table>
      <tr><th>Link ID</th><th>Reversal Count</th><th>Peak Velocity (m/s)</th><th>Severity</th></tr>
  HTML
  
  reversals.sort_by { |r| -r[:count] }.each do |r|
    html += "      <tr><td>#{r[:link]}</td><td>#{r[:count]}</td><td>#{r[:peak_vel]}</td><td>#{r[:severity]}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
    
    <h2>Recommendations</h2>
    <ul>
      <li>Flow reversals indicate hydraulic instability or surge conditions</li>
      <li>Check boundary conditions and control structures near affected links</li>
      <li>Consider installing surge protection or pressure relief valves</li>
      <li>Review pump start/stop sequences and valve operations</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Flow reversal analysis complete: #{output_file}"
  puts "  - Critical links: #{critical}"
  puts "  - High risk links: #{high}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end











