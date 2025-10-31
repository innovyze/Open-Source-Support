# Script: 10_simulation_profiler.rb
# Context: Exchange
# Purpose: Profile simulation performance (runtime vs network size)
# Outputs: HTML with scatterplot
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        If no args, analyzes all simulations in database

begin
  puts "Simulation Performance Profiler - Starting..."
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
    sim_names = sims.map(&:name)
    puts "Analyzing all #{sim_names.length} simulations in database..."
  end
  
  perf_data = []
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      # Get network size
      net = sim_mo.open
      node_count = 0
      link_count = 0
      
      net.row_objects('hw_node').each { |_| node_count += 1 }
      net.row_objects('hw_conduit').each { |_| link_count += 1 }
      
      net.close
      
      # Get runtime (in minutes)
      runtime = sim_mo.runtime rescue nil
      runtime_min = runtime ? (runtime / 60.0).round(1) : 0.0
      
      perf_data << {
        name: sim_name,
        nodes: node_count,
        links: link_count,
        runtime: runtime_min
      }
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if perf_data.empty?
    puts "No performance data collected"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'simulation_profiler.html')
  
  # Prepare chart data
  chart_data = perf_data.map { |d| "{x: #{d[:nodes]}, y: #{d[:runtime]}, label: '#{d[:name]}'}" }.join(',')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Simulation Performance Profiler</title>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1100px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    .chart-container { position: relative; height: 500px; margin: 30px 0; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #1976d2; color: white; }
    .note { padding: 15px; background: #e3f2fd; border-radius: 5px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Simulation Performance Analysis</h1>
    
    <div class="note">
      <strong>Performance Metrics:</strong> Runtime scaling with network size
    </div>
    
    <h2>Runtime vs Network Size</h2>
    <div class="chart-container">
      <canvas id="perfChart"></canvas>
    </div>
    
    <h2>Performance Data</h2>
    <table>
      <tr><th>Network</th><th>Nodes</th><th>Links</th><th>Runtime (min)</th><th>Nodes/min</th></tr>
  HTML
  
  perf_data.each do |d|
    rate = (d[:nodes] / d[:runtime]).round(1)
    html += "      <tr><td>#{d[:name]}</td><td>#{d[:nodes]}</td><td>#{d[:links]}</td><td>#{d[:runtime]}</td><td>#{rate}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
  </div>
  
  <script>
    const ctx = document.getElementById('perfChart').getContext('2d');
    new Chart(ctx, {
      type: 'scatter',
      data: {
        datasets: [{
          label: 'Simulation Runtime',
          data: [#{chart_data}],
          backgroundColor: '#1976d2',
          borderColor: '#0d47a1',
          pointRadius: 8,
          pointHoverRadius: 10
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { title: { display: true, text: 'Network Size (nodes)' }, beginAtZero: true },
          y: { title: { display: true, text: 'Runtime (minutes)' }, beginAtZero: true }
        },
        plugins: {
          tooltip: {
            callbacks: {
              label: function(context) {
                return context.raw.label + ': ' + context.parsed.y + ' min (' + context.parsed.x + ' nodes)';
              }
            }
          }
        }
      }
    });
  </script>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Performance profiler complete: #{output_file}"
  puts "  - Networks analyzed: #{perf_data.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













