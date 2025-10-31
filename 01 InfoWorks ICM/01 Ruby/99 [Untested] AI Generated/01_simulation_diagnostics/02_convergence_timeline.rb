# Script: 02_convergence_timeline.rb
# Context: Exchange
# Purpose: Visualize convergence failures on a timeline using mermaid Gantt chart
# Outputs: HTML with embedded mermaid Gantt chart
# Test Data: Sample convergence failure events
# Cleanup: N/A

begin
  puts "Convergence Timeline Visualizer - Starting..."
  $stdout.flush
  
  # Sample convergence failure events
  failures = [
    {node: 'N101', start_time: 0.5, duration: 0.1, severity: 'High'},
    {node: 'N205', start_time: 1.2, duration: 0.15, severity: 'Medium'},
    {node: 'N101', start_time: 2.3, duration: 0.2, severity: 'Critical'},
    {node: 'N308', start_time: 3.0, duration: 0.05, severity: 'Low'},
    {node: 'N205', start_time: 4.5, duration: 0.3, severity: 'High'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'convergence_timeline.html')
  
  # Build mermaid gantt chart
  mermaid_code = "gantt\n"
  mermaid_code += "    title Convergence Failure Timeline\n"
  mermaid_code += "    dateFormat X\n"
  mermaid_code += "    axisFormat %H:%M:%S\n\n"
  
  # Group by node
  nodes = failures.map { |f| f[:node] }.uniq.sort
  nodes.each do |node|
    mermaid_code += "    section #{node}\n"
    node_failures = failures.select { |f| f[:node] == node }
    node_failures.each_with_index do |f, idx|
      start_ms = (f[:start_time] * 1000).to_i
      end_ms = ((f[:start_time] + f[:duration]) * 1000).to_i
      criticality = f[:severity] == 'Critical' ? 'crit, ' : ''
      mermaid_code += "    #{f[:severity]} failure #{idx + 1} :#{criticality}#{start_ms}, #{end_ms}\n"
    end
  end
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Convergence Timeline</title>
  <script src="https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js"></script>
  <script>mermaid.initialize({startOnLoad:true});</script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1400px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #c62828; padding-bottom: 10px; }
    .summary { margin: 20px 0; padding: 15px; background: #fff3e0; border-left: 4px solid #f57c00; }
    .mermaid { background: white; padding: 20px; border: 1px solid #ddd; border-radius: 5px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #c62828; color: white; }
    .severity-critical { color: #c62828; font-weight: bold; }
    .severity-high { color: #f57c00; font-weight: bold; }
    .severity-medium { color: #ffa726; }
    .severity-low { color: #66bb6a; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Convergence Failure Timeline</h1>
    <div class="summary">
      <strong>Total Failures:</strong> #{failures.length} | 
      <strong>Affected Nodes:</strong> #{nodes.length} | 
      <strong>Time Range:</strong> 0.0s - #{failures.map { |f| f[:start_time] + f[:duration] }.max.round(2)}s
    </div>
    
    <h2>Timeline Visualization</h2>
    <div class="mermaid">
#{mermaid_code}
    </div>
    
    <h2>Failure Details</h2>
    <table>
      <tr>
        <th>Node ID</th>
        <th>Start Time (s)</th>
        <th>Duration (s)</th>
        <th>Severity</th>
      </tr>
  HTML
  
  failures.each do |f|
    severity_class = "severity-#{f[:severity].downcase}"
    html += "      <tr><td>#{f[:node]}</td><td>#{f[:start_time]}</td><td>#{f[:duration]}</td><td class=\"#{severity_class}\">#{f[:severity]}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Timeline visualization generated: #{output_file}"
  puts "  - Total failures: #{failures.length}"
  puts "  - Affected nodes: #{nodes.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.join("\n")
  $stdout.flush
  exit 1
end











