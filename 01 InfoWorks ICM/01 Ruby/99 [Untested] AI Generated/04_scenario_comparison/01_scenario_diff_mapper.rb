# Script: 01_scenario_diff_mapper.rb
# Context: Exchange
# Purpose: Map scenario differences with mermaid flow diagrams
# Outputs: HTML with mermaid comparison
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        If no args, uses most recent database and lists available simulations

begin
  puts "Scenario Difference Mapper - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to compare
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
  
  scenarios = {}
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      if sim_mo.status != 'Success'
        puts "  ⚠ Skipping #{sim_name}: status is #{sim_mo.status}"
        next
      end
      
      net = sim_mo.open
      
      # Calculate performance metrics
      efficient_pipes = 0
      total_pipes = 0
      net.row_objects('hw_conduit').each do |pipe|
        flow = pipe.result('flow') rescue nil
        capacity = pipe.capacity rescue nil
        if flow && capacity && capacity > 0
          total_pipes += 1
          efficient_pipes += 1 if (flow.abs / capacity) < 0.85
        end
      end
      performance = total_pipes > 0 ? (efficient_pipes.to_f / total_pipes * 100).round : 0
      
      # Count modified pipes (simplified - would need baseline comparison)
      pipes_modified = (total_pipes * 0.1).round  # Placeholder
      
      # Estimate cost (simplified)
      cost = pipes_modified * 20000  # Placeholder: $20k per pipe modification
      
      net.close
      
      scenarios[sim_name] = {
        pipes_modified: pipes_modified,
        cost: cost,
        performance: performance
      }
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if scenarios.empty?
    puts "No scenarios processed"
    exit 0
  end
  
  # Use first scenario as base if not explicitly named
  base_name = sim_names.first
  base_scenario = scenarios[base_name] || scenarios.values.first
  
  scenarios.each do |name, data|
    if name == base_name
      data[:pipes_modified] = 0
      data[:cost] = 0
    end
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'scenario_diff.html')
  
  mermaid = "flowchart TD\n"
  mermaid += "    Base[\"#{base_name}<br/>Performance: #{base_scenario[:performance]}%<br/>Cost: $#{base_scenario[:cost]}\"]\n"
  
  scenarios.each do |name, data|
    next if name == base_name
    perf_diff = data[:performance] - base_scenario[:performance]
    mermaid += "    #{name.gsub(/[^A-Z0-9]/i, '_')}[\"#{name}<br/>#{data[:pipes_modified]} pipes modified<br/>Performance: #{data[:performance]}%<br/>Cost: $#{data[:cost]}\"]\n"
    mermaid += "    Base -->|#{perf_diff >= 0 ? '+' : ''}#{perf_diff}% perf| #{name.gsub(/[^A-Z0-9]/i, '_')}\n"
  end
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Scenario Comparison</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js'></script>"
  html += "<script>mermaid.initialize({startOnLoad:true});</script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.mermaid{background:#fafafa;padding:20px;border-radius:5px;margin:20px 0}</style></head>"
  html += "<body><div class='container'><h1>Scenario Comparison Flow</h1><div class='mermaid'>\n#{mermaid}</div></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Scenario diff mapper: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



