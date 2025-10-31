# Script: 03_mass_balance_tracker.rb
# Context: Exchange
# Purpose: Track mass balance errors by timestep and visualize with line chart
# Outputs: CSV + HTML with line chart
# Test Data: Sample mass balance error data
# Cleanup: N/A

begin
  puts "Mass Balance Error Tracker - Starting..."
  $stdout.flush
  
  # Sample mass balance data (timestep, error_percentage)
  mb_data = (0..100).map do |i|
    time = i * 0.1
    # Simulate increasing error with random spikes
    base_error = time * 0.01
    spike = (i % 15 == 0) ? rand(0.5..1.5) : 0
    error = base_error + spike + rand(-0.1..0.1)
    {timestep: i, time: time.round(2), error_pct: error.round(4)}
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  # Write CSV
  csv_file = File.join(output_dir, 'mass_balance_errors.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Timestep,Time(s),Error(%)"
    mb_data.each { |d| f.puts "#{d[:timestep]},#{d[:time]},#{d[:error_pct]}" }
  end
  
  # Find statistics
  max_error = mb_data.map { |d| d[:error_pct] }.max
  avg_error = (mb_data.map { |d| d[:error_pct] }.sum / mb_data.length).round(4)
  threshold_violations = mb_data.count { |d| d[:error_pct].abs > 1.0 }
  
  # Generate HTML with chart
  html_file = File.join(output_dir, 'mass_balance_tracker.html')
  
  # Prepare data for chart
  chart_data = mb_data.map { |d| "{x: #{d[:time]}, y: #{d[:error_pct]}}" }.join(',')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Mass Balance Error Tracker</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    .stats { display: flex; gap: 20px; margin: 20px 0; }
    .stat-box { flex: 1; padding: 15px; background: #e3f2fd; border-radius: 5px; border: 2px solid #1976d2; }
    .stat-box .value { font-size: 24px; font-weight: bold; color: #1976d2; }
    .stat-box .label { font-size: 14px; color: #666; margin-top: 5px; }
    .chart-container { position: relative; height: 400px; margin: 30px 0; }
    .threshold-note { padding: 10px; background: #fff3e0; border-left: 4px solid #f57c00; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Mass Balance Error Tracker</h1>
    
    <div class="stats">
      <div class="stat-box">
        <div class="value">#{max_error.round(3)}%</div>
        <div class="label">Maximum Error</div>
      </div>
      <div class="stat-box">
        <div class="value">#{avg_error}%</div>
        <div class="label">Average Error</div>
      </div>
      <div class="stat-box">
        <div class="value">#{threshold_violations}</div>
        <div class="label">Threshold Violations (>1%)</div>
      </div>
    </div>
    
    <div class="threshold-note">
      <strong>Note:</strong> Mass balance errors exceeding ±1% may indicate numerical instability or model setup issues.
    </div>
    
    <h2>Error Timeline</h2>
    <div class="chart-container">
      <canvas id="errorChart"></canvas>
    </div>
    
    <p><strong>CSV Export:</strong> mass_balance_errors.csv</p>
  </div>
  
  <script>
    const ctx = document.getElementById('errorChart').getContext('2d');
    new Chart(ctx, {
      type: 'line',
      data: {
        datasets: [{
          label: 'Mass Balance Error (%)',
          data: [#{chart_data}],
          borderColor: '#1976d2',
          backgroundColor: 'rgba(25, 118, 210, 0.1)',
          tension: 0.1,
          pointRadius: 1
        }, {
          label: 'Threshold (+1%)',
          data: [{x: 0, y: 1}, {x: #{mb_data.last[:time]}, y: 1}],
          borderColor: '#f57c00',
          borderDash: [5, 5],
          pointRadius: 0
        }, {
          label: 'Threshold (-1%)',
          data: [{x: 0, y: -1}, {x: #{mb_data.last[:time]}, y: -1}],
          borderColor: '#f57c00',
          borderDash: [5, 5],
          pointRadius: 0
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            type: 'linear',
            title: { display: true, text: 'Time (seconds)' }
          },
          y: {
            title: { display: true, text: 'Error (%)' }
          }
        },
        plugins: {
          legend: { display: true, position: 'top' }
        }
      }
    });
  </script>
</body>
</html>
  HTML
  
  File.write(html_file, html)
  puts "✓ Mass balance tracker generated:"
  puts "  - CSV: #{csv_file}"
  puts "  - HTML: #{html_file}"
  puts "  - Max error: #{max_error.round(3)}%"
  puts "  - Threshold violations: #{threshold_violations}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.join("\n")
  $stdout.flush
  exit 1
end










