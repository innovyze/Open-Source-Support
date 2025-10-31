# Script: 01_exceedance_frequency_plotter.rb
# Context: Exchange
# Purpose: Plot exceedance frequency curves with regression lines
# Outputs: HTML with scatterplot and regression
# Usage: ruby script.rb [database_path] [simulation_name] [object_type] [field_name]
#        object_type defaults to 'hw_node', field_name defaults to 'flow'

begin
  puts "Exceedance Frequency Plotter - Starting..."
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
    puts "\nUsage: script.rb [database_path] [simulation_name] [object_type] [field_name]"
    exit 1
  end
  
  sim_mo = db.model_object(sim_name)
  
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    exit 1
  end
  
  object_type = ARGV[2] || 'hw_node'
  field_name = ARGV[3] || 'flow'
  
  puts "Extracting #{field_name} values from #{object_type}..."
  
  # Extract maximum values from all objects
  net = sim_mo.open
  flows = []
  
  net.row_objects(object_type).each do |obj|
    max_val = obj.result(field_name) rescue nil
    if max_val && max_val > 0
      flows << max_val
    end
  end
  
  net.close
  
  if flows.empty?
    puts "No #{field_name} data found for #{object_type}"
    exit 0
  end
  
  # Sort flows descending and calculate exceedance percentages
  flows.sort!.reverse!
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
  puts "  - Max #{field_name}: #{flows.max.round(3)}"
  puts "  - Min #{field_name}: #{flows.min.round(3)}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













