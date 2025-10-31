# Script: 08_flow_reversal_detector.rb
# Context: Exchange
# Purpose: Detect and map flow reversals (link instability indicator)
# Outputs: HTML with network map showing reversals
# Usage: ruby script.rb [database_path] [simulation_name]
#        Detects flow reversals by analyzing flow direction changes

begin
  puts "Flow Reversal Detector - Starting..."
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
  
  # Detect flow reversals
  net = sim_mo.open
  timesteps = sim_mo.list_timesteps rescue []
  
  reversals = []
  
  if timesteps && timesteps.length > 10
    # Sample timesteps for performance
    sample_timesteps = timesteps.select.with_index { |_, i| i % 5 == 0 }
    
    net.row_objects('hw_conduit').each do |link|
      link_id = link.id
      flow_history = []
      
      # Collect flow values over time
      sample_timesteps.each do |ts|
        net.current_timestep = ts
        flow = link.results('flow') rescue nil
        flow_history << flow if flow
      end
      
      if flow_history.length > 5
        # Count reversals (sign changes)
        reversal_count = 0
        peak_velocity = 0.0
        
        (1...flow_history.length).each do |i|
          prev = flow_history[i-1]
          curr = flow_history[i]
          
          if prev && curr
            # Check for sign change (reversal)
            if (prev > 0 && curr < 0) || (prev < 0 && curr > 0)
              reversal_count += 1
            end
            
            # Track peak velocity
            velocity = link.results('velocity') rescue nil
            if velocity && velocity.abs > peak_velocity
              peak_velocity = velocity.abs
            end
          end
        end
        
        if reversal_count > 0
          severity = if reversal_count > 20
            'Critical'
          elsif reversal_count > 10
            'High'
          elsif reversal_count > 5
            'Medium'
          else
            'Low'
          end
          
          reversals << {
            link: link_id,
            count: reversal_count,
            peak_vel: peak_velocity.round(2),
            severity: severity
          }
        end
      end
    end
  end
  
  net.close
  
  if reversals.empty?
    puts "No flow reversals detected"
    exit 0
  end
  
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











