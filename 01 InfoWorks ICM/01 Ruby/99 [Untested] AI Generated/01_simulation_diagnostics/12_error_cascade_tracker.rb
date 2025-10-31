# Script: 12_error_cascade_tracker.rb
# Context: Exchange
# Purpose: Trace error propagation through network (error cascade analysis)
# Outputs: HTML with mermaid flow diagram
# Test Data: Sample error propagation
# Cleanup: N/A

begin
  puts "Error Cascade Tracker - Starting..."
  $stdout.flush
  
  # Sample error cascade (node, time, error_type, triggered_by)
  cascade = [
    {node: 'N100', time: 10.5, error: 'Convergence failure', triggered_by: nil},
    {node: 'N101', time: 10.6, error: 'HGL discontinuity', triggered_by: 'N100'},
    {node: 'N102', time: 10.8, error: 'Flow reversal', triggered_by: 'N101'},
    {node: 'N105', time: 11.2, error: 'Mass balance error', triggered_by: 'N102'},
    {node: 'N106', time: 11.5, error: 'Convergence failure', triggered_by: 'N105'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'error_cascade.html')
  
  # Build mermaid flowchart
  mermaid = "flowchart TD\n"
  cascade.each_with_index do |err, i|
    node_id = "E#{i}"
    mermaid += "    #{node_id}[\"#{err[:node]}<br/>#{err[:error]}<br/>t=#{err[:time]}s\"]\n"
    if err[:triggered_by]
      parent_idx = cascade.find_index { |e| e[:node] == err[:triggered_by] }
      mermaid += "    E#{parent_idx} -->|propagates| #{node_id}\n" if parent_idx
    end
  end
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Error Cascade Tracker</title>
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({startOnLoad:true});</script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #c62828; padding-bottom: 10px; }
    .alert { padding: 15px; background: #ffebee; border-left: 4px solid #c62828; margin: 20px 0; }
    .mermaid { background: #fafafa; padding: 20px; border-radius: 5px; margin: 20px 0; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #c62828; color: white; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Error Cascade Analysis</h1>
    
    <div class="alert">
      <strong>Cascade Detected:</strong> #{cascade.length} errors propagated through network over #{(cascade.last[:time] - cascade.first[:time]).round(1)}s
    </div>
    
    <h2>Error Propagation Flow</h2>
    <div class="mermaid">
#{mermaid}
    </div>
    
    <h2>Cascade Timeline</h2>
    <table>
      <tr><th>Time (s)</th><th>Node</th><th>Error Type</th><th>Triggered By</th></tr>
  HTML
  
  cascade.each do |err|
    html += "      <tr><td>#{err[:time]}</td><td>#{err[:node]}</td><td>#{err[:error]}</td><td>#{err[:triggered_by] || 'Initial'}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
    
    <h2>Root Cause Analysis</h2>
    <p><strong>Initial error:</strong> #{cascade.first[:error]} at node #{cascade.first[:node]} (t=#{cascade.first[:time]}s)</p>
    <p><strong>Propagation rate:</strong> #{(cascade.length / (cascade.last[:time] - cascade.first[:time])).round(2)} errors/second</p>
    
    <h2>Recommendations</h2>
    <ul>
      <li>Focus troubleshooting on initial error at #{cascade.first[:node]}</li>
      <li>Check boundary conditions and initial conditions at cascade origin</li>
      <li>Review network connectivity to prevent error propagation</li>
      <li>Consider adding control structures to isolate problem areas</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Error cascade analysis complete: #{output_file}"
  puts "  - Cascade length: #{cascade.length} errors"
  puts "  - Duration: #{(cascade.last[:time] - cascade.first[:time]).round(1)}s"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













