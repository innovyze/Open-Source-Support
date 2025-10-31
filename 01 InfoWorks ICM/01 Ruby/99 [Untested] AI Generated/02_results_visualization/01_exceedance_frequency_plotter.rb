# Script: 01_exceedance_frequency_plotter.rb
# Context: Exchange
# Purpose: Plot exceedance frequency curves with regression lines
# Outputs: HTML with scatterplot and regression
# Test Data: Sample flow exceedance data
# Cleanup: N/A

begin
  puts "Exceedance Frequency Plotter - Starting..."
  $stdout.flush
  
  # Sample exceedance data (sorted flows)
  flows = [1.5, 2.1, 2.8, 3.2, 4.1, 4.8, 5.5, 6.2, 7.1, 8.5, 9.8, 11.2, 13.5, 16.2, 20.5]
  exceedance_pct = flows.each_with_index.map { |f, i| {flow: f, exceedance: (i + 1).to_f / flows.length * 100} }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  # CSV export
  csv_file = File.join(output_dir, 'exceedance_frequency.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Flow(m3/s),Exceedance(%)"
    exceedance_pct.each { |d| f.puts "#{d[:flow]},#{d[:exceedance].round(2)}" }
  end
  
  # HTML chart
  html_file = File.join(output_dir, 'exceedance_frequency.html')
  chart_data = exceedance_pct.map { |d| "{x: #{d[:exceedance].round(2)}, y: #{d[:flow]}}" }.join(',')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Exceedance Frequency</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1100px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; }
    .chart-container { height: 500px; margin: 30px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Flow Exceedance Frequency Curve</h1>
    <div class="chart-container">
      <canvas id="chart"></canvas>
    </div>
    <p><strong>CSV:</strong> exceedance_frequency.csv</p>
  </div>
  <script>
    new Chart(document.getElementById('chart'), {
      type: 'scatter',
      data: {
        datasets: [{
          label: 'Flow Exceedance',
          data: [#{chart_data}],
          backgroundColor: '#1976d2',
          showLine: true,
          tension: 0.3
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { title: { display: true, text: 'Exceedance (%)' } },
          y: { title: { display: true, text: 'Flow (m³/s)' } }
        }
      }
    });
  </script>
</body>
</html>
  HTML
  
  File.write(html_file, html)
  puts "✓ Exceedance plot generated: #{html_file}"
  puts "  - Data points: #{flows.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













