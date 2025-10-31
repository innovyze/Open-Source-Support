# Script: 02_convergence_timeline.rb
# Context: Exchange
# Purpose: Visualize convergence failures on a timeline using mermaid Gantt chart
# Outputs: HTML with embedded mermaid Gantt chart
# Usage: ruby script.rb [database_path] [simulation_name]
#        Extracts convergence failures from log file

begin
  puts "Convergence Timeline Visualizer - Starting..."
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
  
  # Parse log file for convergence failures
  failures = []
  results_path = sim_mo.results_path rescue nil
  
  if results_path && Dir.exist?(results_path)
    log_file = File.join(results_path, "#{sim_mo.name}.log")
    if File.exist?(log_file)
      puts "Parsing log file for convergence failures..."
      
      File.readlines(log_file).each_with_index do |line, idx|
        # Look for convergence failure patterns
        if line.match?(/convergence.*fail|failed.*converge|converge.*fail/i)
          # Try to extract node ID and time
          node_match = line.match(/(?:node|at)\s+([A-Z0-9_]+)/i)
          time_match = line.match(/(\d+\.?\d*)\s*(?:s|seconds?|minutes?)/i)
          
          node_id = node_match ? node_match[1] : "Unknown_#{idx}"
          start_time = time_match ? time_match[1].to_f : (idx * 0.1)
          
          # Determine severity based on context
          severity = if line.match?(/critical|fatal|severe/i)
            'Critical'
          elsif line.match?(/high|major/i)
            'High'
          elsif line.match?(/minor|low/i)
            'Low'
          else
            'Medium'
          end
          
          failures << {
            node: node_id,
            start_time: start_time.round(2),
            duration: 0.1,  # Default duration
            severity: severity
          }
        end
      end
    end
  end
  
  if failures.empty?
    puts "No convergence failures found in log file"
    puts "Note: Convergence failures may not be explicitly logged"
    exit 0
  end
  
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











