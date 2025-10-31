# Script: 06_timestep_reduction_logger.rb
# Context: Exchange  
# Purpose: Log timestep reduction events and visualize on timeline
# Outputs: HTML with timeline visualization
# Test Data: Sample timestep reduction events
# Cleanup: N/A

begin
  puts "Timestep Reduction Logger - Starting..."
  $stdout.flush
  
  # Sample timestep reduction events
  events = [
    {time: 125.5, from_dt: 1.0, to_dt: 0.5, reason: 'Convergence'},
    {time: 234.2, from_dt: 0.5, to_dt: 0.25, reason: 'Mass balance'},
    {time: 450.8, from_dt: 0.25, to_dt: 0.1, reason: 'Instability'},
    {time: 678.3, from_dt: 0.1, to_dt: 0.5, reason: 'Recovery'},
    {time: 892.1, from_dt: 0.5, to_dt: 0.25, reason: 'Convergence'},
    {time: 1205.4, from_dt: 0.25, to_dt: 1.0, reason: 'Recovery'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'timestep_reductions.html')
  
  # Count reductions vs recoveries
  reductions = events.count { |e| e[:to_dt] < e[:from_dt] }
  recoveries = events.count { |e| e[:to_dt] > e[:from_dt] }
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Timestep Reduction Logger</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1100px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #f57c00; padding-bottom: 10px; }
    .summary { display: flex; gap: 20px; margin: 20px 0; }
    .stat-box { flex: 1; padding: 15px; border-radius: 5px; text-align: center; }
    .stat-box.reduction { background: #ffebee; border: 2px solid #c62828; }
    .stat-box.recovery { background: #e8f5e9; border: 2px solid #388e3c; }
    .stat-box .count { font-size: 28px; font-weight: bold; }
    .stat-box .label { font-size: 13px; color: #666; margin-top: 5px; }
    .timeline { position: relative; margin: 30px 0; padding: 20px; background: #fafafa; border-radius: 5px; }
    .event { margin: 15px 0; padding: 12px; background: white; border-left: 4px solid #f57c00; border-radius: 3px; }
    .event.recovery { border-left-color: #388e3c; }
    .event-time { font-weight: bold; color: #1976d2; }
    .event-detail { margin-top: 5px; font-size: 14px; color: #666; }
    .reason-badge { display: inline-block; padding: 3px 8px; border-radius: 3px; font-size: 11px; margin-left: 10px; }
    .reason-convergence { background: #ffcdd2; }
    .reason-mass { background: #fff9c4; }
    .reason-instability { background: #ffccbc; }
    .reason-recovery { background: #c8e6c9; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Timestep Reduction Event Log</h1>
    
    <div class="summary">
      <div class="stat-box reduction">
        <div class="count">#{reductions}</div>
        <div class="label">TIMESTEP REDUCTIONS</div>
      </div>
      <div class="stat-box recovery">
        <div class="count">#{recoveries}</div>
        <div class="label">TIMESTEP RECOVERIES</div>
      </div>
      <div class="stat-box">
        <div class="count">#{events.length}</div>
        <div class="label">TOTAL EVENTS</div>
      </div>
    </div>
    
    <h2>Event Timeline</h2>
    <div class="timeline">
  HTML
  
  events.each do |event|
    event_class = event[:to_dt] > event[:from_dt] ? 'event recovery' : 'event'
    reason_class = "reason-badge reason-#{event[:reason].downcase}"
    direction = event[:to_dt] > event[:from_dt] ? '↑' : '↓'
    
    html += <<-EVENT
      <div class="#{event_class}">
        <span class="event-time">#{event[:time].round(1)}s</span>
        <span class="#{reason_class}">#{event[:reason]}</span>
        <div class="event-detail">
          Timestep: #{event[:from_dt]}s #{direction} #{event[:to_dt]}s 
          (#{((event[:to_dt] / event[:from_dt] - 1) * 100).round(0)}% change)
        </div>
      </div>
    EVENT
  end
  
  html += <<-HTML
    </div>
    
    <h2>Analysis</h2>
    <p>Timestep reductions indicate the solver is adapting to challenging hydraulic conditions. 
    Frequent reductions may suggest:</p>
    <ul>
      <li>Model instability or numerical issues</li>
      <li>Rapid changes in boundary conditions</li>
      <li>Convergence tolerance too tight</li>
      <li>Complex hydraulics requiring finer resolution</li>
    </ul>
    
    <p><strong>Recommendation:</strong> #{reductions > recoveries ? 'Model shows persistent stability issues - review setup and parameters.' : 'Timestep management appears healthy with good recovery.'}</p>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Timestep reduction log generated: #{output_file}"
  puts "  - Reductions: #{reductions}"
  puts "  - Recoveries: #{recoveries}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end











