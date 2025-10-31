# Script: 05_sensitivity_tornado.rb
# Context: Exchange
# Purpose: Sensitivity tornado chart (variable impact ranking)
# Outputs: HTML tornado chart
# Usage: ruby script.rb [database_path] [base_simulation] [simulation1] [simulation2] ...
#        Compares base simulation with variations to show sensitivity

begin
  puts "Sensitivity Tornado Chart - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations
  if ARGV.length > 2
    base_sim = ARGV[1]
    variant_sims = ARGV[2..-1]
  else
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [base_simulation] [simulation1] [simulation2] ..."
    exit 1
  end
  
  # Get base performance
  base_performance = 0.0
  begin
    base_mo = db.model_object(base_sim)
    if base_mo.status == 'Success'
      net = base_mo.open
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
      base_performance = total_pipes > 0 ? (efficient_pipes.to_f / total_pipes * 100) : 0.0
      net.close
    end
  rescue => e
    puts "  Warning: Could not process base simulation: #{e.message}"
  end
  
  # Compare variants
  variables = []
  
  variant_sims.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      if sim_mo.status != 'Success'
        puts "  ⚠ Skipping #{sim_name}: status is #{sim_mo.status}"
        next
      end
      
      net = sim_mo.open
      
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
      performance = total_pipes > 0 ? (efficient_pipes.to_f / total_pipes * 100) : 0.0
      
      net.close
      
      # Determine variable name from simulation name (simplified)
      var_name = sim_name.gsub(/^.*_/, '').gsub(/[0-9]/, '') || sim_name
      
      # Calculate impact
      impact = performance - base_performance
      
      # Determine if this is high or low variation (simplified)
      # Would need to know parameter values - for now assume +/- variation
      if impact > 0
        variables << {name: var_name, low: 0, high: impact.round(1)}
      else
        variables << {name: var_name, low: impact.round(1), high: 0}
      end
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if variables.empty?
    puts "No variable comparisons processed"
    exit 0
  end
  
  # Sort by total range (impact)
  variables.each { |v| v[:range] = (v[:high] - v[:low]).abs }
  variables.sort_by! { |v| -v[:range] }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'sensitivity_tornado.html')
  
  labels = variables.map { |v| "'#{v[:name]}'" }.join(',')
  low_data = variables.map { |v| v[:low] }.join(',')
  high_data = variables.map { |v| v[:high] }.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Sensitivity Tornado</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1100px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#f57c00}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>Sensitivity Tornado Chart</h1><p><strong>Variables ranked by impact on system performance</strong></p>"
  html += "<div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'bar',data:{labels:[#{labels}],datasets:[{label:'Low (-)',data:[#{low_data}],backgroundColor:'#2196f3'},{label:'High (+)',data:[#{high_data}],backgroundColor:'#f44336'}]},options:{indexAxis:'y',responsive:true,maintainAspectRatio:false,scales:{x:{title:{display:true,text:'Impact on Performance (%)'}}}}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Tornado chart: #{html_file}"
  puts "  - Most sensitive: #{variables[0][:name]} (±#{variables[0][:range].round(1)}%)"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



