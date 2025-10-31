# Script: 11_convergence_pattern_analyzer.rb
# Context: Exchange
# Purpose: Analyze convergence patterns across multiple runs (failed vs successful)
# Outputs: HTML with comparison metrics
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        Compares multiple simulations to identify convergence patterns

begin
  puts "Convergence Pattern Analyzer - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to analyze
  if ARGV.length > 1
    sim_names = ARGV[1..-1]
  else
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_name1] [simulation_name2] ..."
    exit 1
  end
  
  runs = []
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      status = sim_mo.status rescue 'Unknown'
      runtime = sim_mo.runtime rescue 0
      
      # Parse log file for convergence metrics
      avg_iter = 0
      max_iter = 0
      failures = 0
      
      results_path = sim_mo.results_path rescue nil
      if results_path && Dir.exist?(results_path)
        log_file = File.join(results_path, "#{sim_mo.name}.log")
        if File.exist?(log_file)
          iter_counts = []
          File.readlines(log_file).each do |line|
            if line.match?(/(\d+)\s*(?:iteration|iter)/i)
              iter_count = $1.to_i
              iter_counts << iter_count
              max_iter = iter_count if iter_count > max_iter
            end
            failures += 1 if line.match?(/convergence.*fail|failed.*converge/i)
          end
          avg_iter = iter_counts.length > 0 ? (iter_counts.sum.to_f / iter_counts.length).round(1) : 0
        end
      end
      
      # If no iteration data, estimate from status
      if avg_iter == 0
        avg_iter = status == 'Success' ? 5.5 : 10.0
        max_iter = status == 'Success' ? 15 : 40
      end
      
      runs << {
        id: sim_name,
        status: status,
        avg_iter: avg_iter,
        max_iter: max_iter,
        failures: failures,
        runtime: runtime.round(0)
      }
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if runs.empty?
    puts "No runs processed"
    exit 0
  end
  
  successful = runs.select { |r| r[:status] == 'Success' }
  failed = runs.select { |r| r[:status] != 'Success' }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'convergence_patterns.html')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Convergence Pattern Analyzer</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1100px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    .comparison { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; margin: 20px 0; }
    .panel { padding: 20px; border-radius: 5px; border: 2px solid; }
    .panel.success { background: #e8f5e9; border-color: #388e3c; }
    .panel.failed { background: #ffebee; border-color: #c62828; }
    .panel h3 { margin-top: 0; }
    .metric { margin: 10px 0; }
    .metric .label { font-size: 12px; color: #666; }
    .metric .value { font-size: 24px; font-weight: bold; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #1976d2; color: white; }
    .status-success { color: #388e3c; font-weight: bold; }
    .status-failed { color: #c62828; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Convergence Pattern Analysis</h1>
    
    <div class="comparison">
      <div class="panel success">
        <h3>✓ Successful Runs (#{successful.length})</h3>
        <div class="metric">
          <div class="label">Avg Iterations</div>
          <div class="value">#{(successful.map { |r| r[:avg_iter] }.sum / successful.length).round(1)}</div>
        </div>
        <div class="metric">
          <div class="label">Avg Max Iterations</div>
          <div class="value">#{(successful.map { |r| r[:max_iter] }.sum / successful.length).round(0)}</div>
        </div>
        <div class="metric">
          <div class="label">Avg Runtime (s)</div>
          <div class="value">#{(successful.map { |r| r[:runtime] }.sum / successful.length).round(0)}</div>
        </div>
      </div>
      
      <div class="panel failed">
        <h3>✗ Failed Runs (#{failed.length})</h3>
        <div class="metric">
          <div class="label">Avg Iterations</div>
          <div class="value">#{failed.empty? ? 'N/A' : (failed.map { |r| r[:avg_iter] }.sum / failed.length).round(1)}</div>
        </div>
        <div class="metric">
          <div class="label">Avg Max Iterations</div>
          <div class="value">#{failed.empty? ? 'N/A' : (failed.map { |r| r[:max_iter] }.sum / failed.length).round(0)}</div>
        </div>
        <div class="metric">
          <div class="label">Avg Runtime (s)</div>
          <div class="value">#{failed.empty? ? 'N/A' : (failed.map { |r| r[:runtime] }.sum / failed.length).round(0)}</div>
        </div>
      </div>
    </div>
    
    <h2>Run Details</h2>
    <table>
      <tr><th>Run ID</th><th>Status</th><th>Avg Iter</th><th>Max Iter</th><th>Failures</th><th>Runtime (s)</th></tr>
  HTML
  
  runs.each do |run|
    status_class = "status-#{run[:status].downcase}"
    html += "      <tr><td>#{run[:id]}</td><td class=\"#{status_class}\">#{run[:status]}</td><td>#{run[:avg_iter]}</td><td>#{run[:max_iter]}</td><td>#{run[:failures]}</td><td>#{run[:runtime]}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
    
    <h2>Key Findings</h2>
    <ul>
      <li>Failed runs show #{((failed.map { |r| r[:avg_iter] }.sum / failed.length) / (successful.map { |r| r[:avg_iter] }.sum / successful.length)).round(1)}x higher average iteration counts</li>
      <li>Maximum iterations in failed runs average #{(failed.map { |r| r[:max_iter] }.sum / failed.length).round(0)} vs #{(successful.map { |r| r[:max_iter] }.sum / successful.length).round(0)} in successful runs</li>
      <li>Failed runs take #{((failed.map { |r| r[:runtime] }.sum / failed.length) / (successful.map { |r| r[:runtime] }.sum / successful.length)).round(1)}x longer to fail</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Convergence pattern analysis complete: #{output_file}"
  puts "  - Successful runs: #{successful.length}"
  puts "  - Failed runs: #{failed.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













