# Script: 07_warning_frequency_counter.rb
# Context: Exchange
# Purpose: Count and categorize warning messages with bar chart visualization
# Outputs: HTML with bar chart
# Usage: ruby script.rb [database_path] [simulation_name]
#        Parses log file for warning messages

begin
  puts "Warning Frequency Counter - Starting..."
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
  
  # Parse log file for warnings
  warnings = Hash.new(0)
  results_path = sim_mo.results_path rescue nil
  
  if results_path && Dir.exist?(results_path)
    log_file = File.join(results_path, "#{sim_mo.name}.log")
    if File.exist?(log_file)
      puts "Parsing log file for warnings..."
      
      File.readlines(log_file).each do |line|
        if line.match?(/WARNING|WARN/i)
          # Categorize warning by content
          warning_type = 'General Warning'
          
          warning_type = 'Flow reversal detected' if line.match?(/flow.*reversal|reversal.*flow/i)
          warning_type = 'Supercritical flow' if line.match?(/supercritical/i)
          warning_type = 'Pump operating beyond curve' if line.match?(/pump.*curve|beyond.*curve/i)
          warning_type = 'Weir overtopped' if line.match?(/weir.*over|overtopped/i)
          warning_type = 'Negative depth encountered' if line.match?(/negative.*depth/i)
          warning_type = 'Timestep reduced' if line.match?(/timestep.*reduc|reduc.*timestep/i)
          warning_type = 'Convergence slow' if line.match?(/convergence.*slow|slow.*convergence/i)
          
          warnings[warning_type] += 1
        end
      end
    end
  end
  
  if warnings.empty?
    puts "No warnings found in log file"
    exit 0
  end
  
  total = warnings.values.sum
  sorted_warnings = warnings.sort_by { |k, v| -v }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'warning_frequency.html')
  
  # Prepare chart data
  labels = sorted_warnings.map { |k, v| "'#{k}'" }.join(',')
  data = sorted_warnings.map { |k, v| v }.join(',')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Warning Frequency Counter</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1000px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #f57c00; padding-bottom: 10px; }
    .total { text-align: center; padding: 20px; background: #fff3e0; border-radius: 5px; margin: 20px 0; }
    .total .number { font-size: 48px; font-weight: bold; color: #f57c00; }
    .total .label { font-size: 16px; color: #666; }
    .chart-container { position: relative; height: 400px; margin: 30px 0; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #f57c00; color: white; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Warning Frequency Analysis</h1>
    
    <div class="total">
      <div class="number">#{total}</div>
      <div class="label">Total Warnings</div>
    </div>
    
    <h2>Warning Distribution</h2>
    <div class="chart-container">
      <canvas id="warningChart"></canvas>
    </div>
    
    <h2>Warning Summary Table</h2>
    <table>
      <tr><th>Warning Type</th><th>Count</th><th>Percentage</th></tr>
  HTML
  
  sorted_warnings.each do |warning, count|
    pct = (count.to_f / total * 100).round(1)
    html += "      <tr><td>#{warning}</td><td>#{count}</td><td>#{pct}%</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
  </div>
  
  <script>
    const ctx = document.getElementById('warningChart').getContext('2d');
    new Chart(ctx, {
      type: 'bar',
      data: {
        labels: [#{labels}],
        datasets: [{
          label: 'Warning Count',
          data: [#{data}],
          backgroundColor: '#f57c00',
          borderColor: '#e65100',
          borderWidth: 1
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { beginAtZero: true, title: { display: true, text: 'Count' } },
          x: { ticks: { maxRotation: 45, minRotation: 45 } }
        },
        plugins: {
          legend: { display: false }
        }
      }
    });
  </script>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Warning frequency analysis complete: #{output_file}"
  puts "  - Total warnings: #{total}"
  puts "  - Unique types: #{warnings.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end











