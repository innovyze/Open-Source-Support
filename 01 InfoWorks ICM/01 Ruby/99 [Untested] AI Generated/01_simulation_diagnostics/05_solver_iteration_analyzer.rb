# Script: 05_solver_iteration_analyzer.rb
# Context: Exchange
# Purpose: Analyze solver iteration counts and provide statistical summary
# Outputs: CSV + HTML with statistics
# Test Data: Sample iteration count data
# Cleanup: N/A

begin
  puts "Solver Iteration Analyzer - Starting..."
  $stdout.flush
  
  # Sample iteration data by timestep
  iterations = (1..200).map do |ts|
    # Simulate occasional spikes in iteration count
    base = rand(3..8)
    spike = (ts % 25 == 0) ? rand(15..30) : 0
    {timestep: ts, iterations: base + spike}
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  # Calculate statistics
  iter_counts = iterations.map { |i| i[:iterations] }
  mean = (iter_counts.sum.to_f / iter_counts.length).round(2)
  median = iter_counts.sort[iter_counts.length / 2]
  max_iter = iter_counts.max
  min_iter = iter_counts.min
  std_dev = Math.sqrt(iter_counts.map { |x| (x - mean) ** 2 }.sum / iter_counts.length).round(2)
  high_iter_steps = iterations.count { |i| i[:iterations] > 15 }
  
  # Write CSV
  csv_file = File.join(output_dir, 'solver_iterations.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Timestep,Iterations"
    iterations.each { |i| f.puts "#{i[:timestep]},#{i[:iterations]}" }
  end
  
  # Generate HTML
  html_file = File.join(output_dir, 'solver_iteration_analyzer.html')
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Solver Iteration Analysis</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 900px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    .stats-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin: 20px 0; }
    .stat-card { padding: 15px; background: #e3f2fd; border-radius: 5px; border: 2px solid #1976d2; text-align: center; }
    .stat-card .value { font-size: 26px; font-weight: bold; color: #1976d2; }
    .stat-card .label { font-size: 13px; color: #666; margin-top: 5px; }
    .alert { padding: 15px; background: #fff3e0; border-left: 4px solid #f57c00; margin: 20px 0; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #1976d2; color: white; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Solver Iteration Analysis</h1>
    
    <h2>Statistical Summary</h2>
    <div class="stats-grid">
      <div class="stat-card">
        <div class="value">#{mean}</div>
        <div class="label">Mean Iterations</div>
      </div>
      <div class="stat-card">
        <div class="value">#{median}</div>
        <div class="label">Median Iterations</div>
      </div>
      <div class="stat-card">
        <div class="value">#{std_dev}</div>
        <div class="label">Std Deviation</div>
      </div>
      <div class="stat-card">
        <div class="value">#{min_iter}</div>
        <div class="label">Minimum</div>
      </div>
      <div class="stat-card">
        <div class="value">#{max_iter}</div>
        <div class="label">Maximum</div>
      </div>
      <div class="stat-card">
        <div class="value">#{high_iter_steps}</div>
        <div class="label">High Iter Steps (>15)</div>
      </div>
    </div>
    
    #{high_iter_steps > 10 ? '<div class="alert"><strong>Warning:</strong> ' + high_iter_steps.to_s + ' timesteps required >15 iterations. Consider adjusting solver parameters or reviewing model stability.</div>' : ''}
    
    <h2>Interpretation</h2>
    <table>
      <tr><th>Metric</th><th>Value</th><th>Assessment</th></tr>
      <tr><td>Mean Iterations</td><td>#{mean}</td><td>#{mean < 10 ? 'Good' : 'Review needed'}</td></tr>
      <tr><td>Max Iterations</td><td>#{max_iter}</td><td>#{max_iter < 20 ? 'Acceptable' : 'High - investigate'}</td></tr>
      <tr><td>Std Deviation</td><td>#{std_dev}</td><td>#{std_dev < 5 ? 'Consistent' : 'Variable'}</td></tr>
    </table>
    
    <p><strong>Data exported to:</strong> solver_iterations.csv</p>
    
    <h2>Recommendations</h2>
    <ul>
      <li>Target mean iterations: <strong>3-8</strong> for stable models</li>
      <li>High iteration counts may indicate convergence issues or tight tolerances</li>
      <li>Consider relaxing convergence criteria if accuracy requirements permit</li>
      <li>Check for model setup issues if max iterations >30 regularly</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(html_file, html)
  puts "✓ Solver iteration analysis complete:"
  puts "  - CSV: #{csv_file}"
  puts "  - HTML: #{html_file}"
  puts "  - Mean iterations: #{mean}"
  puts "  - Max iterations: #{max_iter}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end











