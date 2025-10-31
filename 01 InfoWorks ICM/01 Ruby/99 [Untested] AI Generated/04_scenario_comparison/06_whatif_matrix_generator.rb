# Script: 06_whatif_matrix_generator.rb
# Context: Exchange
# Purpose: What-if scenario matrix (parameter combinations with outcomes)
# Outputs: HTML matrix table + CSV
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        Generates what-if matrix from multiple simulations

begin
  puts "What-If Matrix Generator - Starting..."
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
  
  matrix = []
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      if sim_mo.status != 'Success'
        puts "  ⚠ Skipping #{sim_name}: status is #{sim_mo.status}"
        next
      end
      
      net = sim_mo.open
      
      # Extract parameters from simulation name or properties
      # Estimate rainfall factor from simulation name or properties
      rainfall = 1.0
      rainfall = 1.2 if sim_name.match?(/high|increase|1\.2/i)
      rainfall = 0.8 if sim_name.match?(/low|decrease|0\.8/i)
      
      # Estimate storage size (simplified)
      storage_volume = 0.0
      net.row_objects('hw_storage').each do |tank|
        # Use storage volume field as capacity
        vol = tank['storage_volume'] rescue tank['max_volume'] rescue tank['volume'] rescue nil
        storage_volume += vol if vol && vol > 0
      end
      storage_volume = storage_volume.round(0)
      
      # Calculate performance
      efficient_pipes = 0
      total_pipes = 0
      net.row_objects('hw_conduit').each do |pipe|
        flow = pipe.result('flow') rescue nil
        # Calculate capacity from geometry: Q = A × V
        width = pipe['conduit_width'] rescue nil
        height = pipe['conduit_height'] rescue width rescue nil
        if width && height && width > 0 && height > 0
          area = (width / 1000.0) * (height / 1000.0)  # Convert mm to m
          capacity = area * 5.0  # Typical max velocity 5 m/s
        else
          capacity = nil
        end
        if flow && capacity && capacity > 0
          total_pipes += 1
          efficient_pipes += 1 if (flow.abs / capacity) < 0.85
        end
      end
      performance = total_pipes > 0 ? (efficient_pipes.to_f / total_pipes * 100).round(1) : 0.0
      
      # Estimate cost (simplified)
      cost = (storage_volume * 150 + (rainfall - 1.0) * 50000).round(0)
      
      net.close
      
      matrix << {
        rainfall: rainfall,
        storage: storage_volume,
        performance: performance,
        cost: cost
      }
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if matrix.empty?
    puts "No matrix data collected"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'whatif_matrix.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Rainfall_Factor,Storage_m3,Performance(%),Cost($)"
    matrix.each { |m| f.puts "#{m[:rainfall]},#{m[:storage]},#{m[:performance]},#{m[:cost]}" }
  end
  
  html_file = File.join(output_dir, 'whatif_matrix.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>What-If Matrix</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1100px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#9c27b0}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border:1px solid #ddd;text-align:center}th{background:#9c27b0;color:white}.high-perf{background:#c8e6c9}.medium-perf{background:#fff9c4}.low-perf{background:#ffcdd2}</style></head>"
  html += "<body><div class='container'><h1>🔮 What-If Scenario Matrix</h1><table><tr><th>Rainfall Factor</th><th>Storage (m³)</th><th>Performance (%)</th><th>Cost ($)</th></tr>"
  
  matrix.each do |m|
    perf_class = m[:performance] >= 80 ? 'high-perf' : (m[:performance] >= 75 ? 'medium-perf' : 'low-perf')
    html += "<tr><td>#{m[:rainfall]}</td><td>#{m[:storage]}</td><td class='#{perf_class}'><strong>#{m[:performance]}</strong></td><td>#{m[:cost]}</td></tr>"
  end
  
  html += "</table><p><strong>Total combinations:</strong> #{matrix.length}</p>"
  html += "<p><strong>CSV:</strong> whatif_matrix.csv</p></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ What-if matrix: #{html_file}"
  puts "  - Combinations: #{matrix.length}"
  puts "  - CSV: #{csv_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



