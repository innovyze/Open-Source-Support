# Script: 04_instability_hotspot_finder.rb
# Context: Exchange
# Purpose: Identify nodes with oscillating results (instability hotspots) with heatmap
# Outputs: HTML with heatmap table
# Usage: ruby script.rb [database_path] [simulation_name]
#        Detects oscillations by analyzing depth variations across timesteps

begin
  puts "Instability Hotspot Finder - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulation
  sim_name = ARGV[1]
  unless sim_name
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_name]"
    exit 1
  end
  
  sim_mo = db.model_object(sim_name)
  
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    exit 1
  end
  
  # Detect instability by analyzing oscillations
  net = sim_mo.open
  timesteps = sim_mo.list_timesteps rescue []
  
  nodes = []
  
  if timesteps && timesteps.length > 10
    # Sample timesteps for performance
    sample_timesteps = timesteps.select.with_index { |_, i| i % 5 == 0 }
    
    net.row_objects('hw_node').each do |node|
      node_id = node.id
      depth_history = []
      
      # Collect depth values over time
      sample_timesteps.each do |ts|
        net.current_timestep = ts
        depth = node.results('depth') rescue nil
        depth_history << depth if depth
      end
      
      if depth_history.length > 5
        # Detect oscillations (changes in direction)
        oscillation_count = 0
        max_variance = 0.0
        
        (1...(depth_history.length - 1)).each do |i|
          prev = depth_history[i-1]
          curr = depth_history[i]
          next_val = depth_history[i+1]
          
          if prev && curr && next_val
            # Check for direction change
            if (prev < curr && curr > next_val) || (prev > curr && curr < next_val)
              oscillation_count += 1
            end
            
            # Track variance
            variance = (curr - prev).abs
            max_variance = variance if variance > max_variance
          end
        end
        
        if oscillation_count > 0
          severity = if oscillation_count > 20
            'Critical'
          elsif oscillation_count > 10
            'High'
          elsif oscillation_count > 5
            'Medium'
          else
            'Low'
          end
          
          nodes << {
            id: node_id,
            osc_count: oscillation_count,
            max_var: max_variance.round(2),
            severity: severity
          }
        end
      end
    end
  end
  
  net.close
  
  if nodes.empty?
    puts "No instability hotspots detected"
    exit 0
  end
  
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











