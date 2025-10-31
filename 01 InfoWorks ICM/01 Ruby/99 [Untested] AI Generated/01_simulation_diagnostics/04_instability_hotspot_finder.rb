# Script: 04_instability_hotspot_finder.rb
# Context: Exchange
# Purpose: Identify nodes with oscillating results (instability hotspots) with heatmap
# Outputs: HTML with heatmap table
# Test Data: Sample node oscillation data
# Cleanup: N/A

begin
  puts "Instability Hotspot Finder - Starting..."
  $stdout.flush
  
  # Sample node instability data (node_id, oscillation_count, max_variance, severity)
  nodes = [
    {id: 'N101', osc_count: 25, max_var: 2.5, severity: 'Critical'},
    {id: 'N102', osc_count: 5, max_var: 0.3, severity: 'Low'},
    {id: 'N103', osc_count: 15, max_var: 1.2, severity: 'High'},
    {id: 'N104', osc_count: 2, max_var: 0.1, severity: 'Low'},
    {id: 'N105', osc_count: 18, max_var: 1.8, severity: 'High'},
    {id: 'N106', osc_count: 30, max_var: 3.1, severity: 'Critical'},
    {id: 'N107', osc_count: 8, max_var: 0.6, severity: 'Medium'},
    {id: 'N108', osc_count: 12, max_var: 0.9, severity: 'Medium'},
    {id: 'N109', osc_count: 20, max_var: 2.0, severity: 'High'},
    {id: 'N110', osc_count: 3, max_var: 0.2, severity: 'Low'}
  ]
  
  # Sort by severity
  severity_order = {'Critical' => 0, 'High' => 1, 'Medium' => 2, 'Low' => 3}
  nodes.sort_by! { |n| [severity_order[n[:severity]], -n[:osc_count]] }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'instability_hotspots.html')
  
  # Calculate statistics
  critical_count = nodes.count { |n| n[:severity] == 'Critical' }
  high_count = nodes.count { |n| n[:severity] == 'High' }
  total_oscillations = nodes.map { |n| n[:osc_count] }.sum
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Instability Hotspot Finder</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #c62828; padding-bottom: 10px; }
    .summary { display: flex; gap: 20px; margin: 20px 0; }
    .stat-box { flex: 1; padding: 15px; border-radius: 5px; text-align: center; }
    .stat-box.critical { background: #ffebee; border: 2px solid #c62828; }
    .stat-box.high { background: #fff3e0; border: 2px solid #f57c00; }
    .stat-box .count { font-size: 28px; font-weight: bold; }
    .stat-box .label { font-size: 13px; color: #666; margin-top: 5px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #c62828; color: white; }
    tr:hover { background: #f5f5f5; }
    .heatmap-critical { background: #ffcdd2; font-weight: bold; }
    .heatmap-high { background: #ffe0b2; }
    .heatmap-medium { background: #fff9c4; }
    .heatmap-low { background: #c8e6c9; }
    .severity-badge { padding: 4px 8px; border-radius: 3px; font-size: 11px; font-weight: bold; }
    .badge-critical { background: #c62828; color: white; }
    .badge-high { background: #f57c00; color: white; }
    .badge-medium { background: #ffa726; color: white; }
    .badge-low { background: #66bb6a; color: white; }
    .legend { margin: 20px 0; padding: 15px; background: #f5f5f5; border-radius: 5px; }
    .legend-item { display: inline-block; margin-right: 20px; }
    .legend-color { display: inline-block; width: 20px; height: 20px; margin-right: 5px; vertical-align: middle; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Instability Hotspot Analysis</h1>
    
    <div class="summary">
      <div class="stat-box critical">
        <div class="count">#{critical_count}</div>
        <div class="label">CRITICAL NODES</div>
      </div>
      <div class="stat-box high">
        <div class="count">#{high_count}</div>
        <div class="label">HIGH RISK NODES</div>
      </div>
      <div class="stat-box">
        <div class="count">#{total_oscillations}</div>
        <div class="label">TOTAL OSCILLATIONS</div>
      </div>
    </div>
    
    <div class="legend">
      <strong>Severity Levels:</strong><br>
      <div class="legend-item"><span class="legend-color heatmap-critical"></span>Critical (>20 oscillations)</div>
      <div class="legend-item"><span class="legend-color heatmap-high"></span>High (10-20 oscillations)</div>
      <div class="legend-item"><span class="legend-color heatmap-medium"></span>Medium (5-10 oscillations)</div>
      <div class="legend-item"><span class="legend-color heatmap-low"></span>Low (<5 oscillations)</div>
    </div>
    
    <h2>Hotspot Heatmap</h2>
    <table>
      <tr>
        <th>Node ID</th>
        <th>Oscillation Count</th>
        <th>Max Variance (m)</th>
        <th>Severity</th>
      </tr>
  HTML
  
  nodes.each do |node|
    row_class = "heatmap-#{node[:severity].downcase}"
    badge_class = "severity-badge badge-#{node[:severity].downcase}"
    html += "      <tr class=\"#{row_class}\">\n"
    html += "        <td><strong>#{node[:id]}</strong></td>\n"
    html += "        <td>#{node[:osc_count]}</td>\n"
    html += "        <td>#{node[:max_var]}</td>\n"
    html += "        <td><span class=\"#{badge_class}\">#{node[:severity]}</span></td>\n"
    html += "      </tr>\n"
  end
  
  html += <<-HTML
    </table>
    
    <h2>Recommendations</h2>
    <ul>
      <li>Investigate critical nodes (#{critical_count} found) for model setup issues</li>
      <li>Check boundary conditions and initial conditions at hotspot locations</li>
      <li>Consider reducing timestep or adjusting solver parameters</li>
      <li>Review network connectivity near unstable nodes</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Instability hotspot report generated: #{output_file}"
  puts "  - Critical nodes: #{critical_count}"
  puts "  - High risk nodes: #{high_count}"
  puts "  - Total oscillations: #{total_oscillations}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.join("\n")
  $stdout.flush
  exit 1
end











