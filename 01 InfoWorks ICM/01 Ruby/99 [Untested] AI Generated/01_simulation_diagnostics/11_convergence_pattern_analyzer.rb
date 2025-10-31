# Script: 11_convergence_pattern_analyzer.rb
# Context: Exchange
# Purpose: Analyze convergence patterns across multiple runs (failed vs successful)
# Outputs: HTML with comparison metrics
# Test Data: Sample run data
# Cleanup: N/A

begin
  puts "Convergence Pattern Analyzer - Starting..."
  $stdout.flush
  
  # Sample run data
  runs = [
    {id: 'Run_001', status: 'Success', avg_iter: 5.2, max_iter: 12, failures: 0, runtime: 245},
    {id: 'Run_002', status: 'Failed', avg_iter: 8.5, max_iter: 45, failures: 23, runtime: 580},
    {id: 'Run_003', status: 'Success', avg_iter: 4.8, max_iter: 10, failures: 0, runtime: 238},
    {id: 'Run_004', status: 'Failed', avg_iter: 12.3, max_iter: 52, failures: 35, runtime: 720},
    {id: 'Run_005', status: 'Success', avg_iter: 5.5, max_iter: 14, failures: 0, runtime: 255},
    {id: 'Run_006', status: 'Success', avg_iter: 5.1, max_iter: 11, failures: 0, runtime: 242}
  ]
  
  successful = runs.select { |r| r[:status] == 'Success' }
  failed = runs.select { |r| r[:status] == 'Failed' }
  
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













