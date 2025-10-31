# Script: 12_rainfall_runoff_correlation.rb
# Context: Exchange
# Purpose: Rainfall-runoff correlation analyzer with R² calculation
# Outputs: HTML scatterplot + CSV
# Usage: ruby script.rb [database_path] [simulation_name]
#        Correlates rainfall input with runoff output from simulation

begin
  puts "Rainfall-Runoff Correlation - Starting..."
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
  
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    exit 1
  end
  
  # Extract rainfall and runoff data
  net = sim_mo.open
  timesteps = sim_mo.list_timesteps rescue []
  
  data_points = []
  
  if timesteps && timesteps.length > 0
    # Sample timesteps for performance
    sample_timesteps = timesteps.select.with_index { |_, i| i % 20 == 0 }
    
    sample_timesteps.each do |ts|
      net.current_timestep = ts
      
      # Get rainfall (from subcatchments)
      rainfall_total = 0.0
      net.row_objects('hw_subcatchment').each do |sub|
        rainfall = sub.results('rainfall') rescue nil
        rainfall_total += rainfall if rainfall && rainfall > 0
      end
      
      # Get runoff (from subcatchments)
      runoff_total = 0.0
      net.row_objects('hw_subcatchment').each do |sub|
        runoff = sub.results('runoff') rescue nil
        runoff_total += runoff if runoff && runoff > 0
      end
      
      if rainfall_total > 0 && runoff_total > 0
        data_points << {
          rainfall: rainfall_total.round(1),
          runoff: runoff_total.round(1)
        }
      end
    end
  end
  
  net.close
  
  if data_points.empty?
    puts "No rainfall-runoff data found"
    exit 0
  end
  
  # Calculate R²
  mean_runoff = data_points.map { |d| d[:runoff] }.sum / data_points.length.to_f
  ss_tot = data_points.map { |d| (d[:runoff] - mean_runoff) ** 2 }.sum
  
  # Simple linear regression
  n = data_points.length
  sum_x = data_points.map { |d| d[:rainfall] }.sum
  sum_y = data_points.map { |d| d[:runoff] }.sum
  sum_xy = data_points.map { |d| d[:rainfall] * d[:runoff] }.sum
  sum_x2 = data_points.map { |d| d[:rainfall] ** 2 }.sum
  
  slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x ** 2).to_f
  intercept = (sum_y - slope * sum_x) / n.to_f
  
  ss_res = data_points.map { |d| (d[:runoff] - (slope * d[:rainfall] + intercept)) ** 2 }.sum
  r_squared = (1 - ss_res / ss_tot).round(3)
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'rainfall_runoff.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Rainfall_mm,Runoff_mm"
    data_points.each { |d| f.puts "#{d[:rainfall]},#{d[:runoff]}" }
  end
  
  html_file = File.join(output_dir, 'rainfall_runoff.html')
  chart_data = data_points.map { |d| "{x:#{d[:rainfall]},y:#{d[:runoff]}}" }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Rainfall-Runoff</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.r2{text-align:center;padding:20px;background:#e3f2fd;border-radius:5px;margin:20px 0;font-size:24px;font-weight:bold}.chart-container{height:500px}</style></head>"
  html += "<body><div class='container'><h1>Rainfall-Runoff Correlation</h1>"
  html += "<div class='r2'>R² = #{r_squared} | Equation: y = #{slope.round(2)}x + #{intercept.round(2)}</div>"
  html += "<div class='chart-container'><canvas id='chart'></canvas></div><p><strong>CSV:</strong> rainfall_runoff.csv</p></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'scatter',data:{datasets:[{label:'Data Points',data:[#{chart_data}],backgroundColor:'#1976d2'}]},options:{responsive:true,maintainAspectRatio:false,scales:{x:{title:{display:true,text:'Rainfall (mm)'}},y:{title:{display:true,text:'Runoff (mm)'}}}linear}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Correlation analysis: #{html_file}"
  puts "  - R² = #{r_squared}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



