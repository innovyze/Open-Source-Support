# Script: 03_parameter_diff_viewer.rb
# Context: Exchange
# Purpose: Side-by-side scenario parameter comparison table
# Outputs: HTML comparison table
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2]
#        Compares parameters between two simulations

begin
  puts "Parameter Diff Viewer - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to compare
  if ARGV.length > 2
    sim1_name = ARGV[1]
    sim2_name = ARGV[2]
  else
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_name1] [simulation_name2]"
    exit 1
  end
  
  # Extract parameters from both simulations
  base_params = {}
  opt_a_params = {}
  
  begin
    sim1_mo = db.model_object(sim1_name)
    if sim1_mo.status == 'Success'
      net1 = sim1_mo.open
      
      # Average roughness
      roughness_values = []
      net1.row_objects('hw_conduit').each do |pipe|
        n = pipe.roughness rescue nil
        roughness_values << n if n && n > 0
      end
      base_params['Pipe Roughness'] = roughness_values.length > 0 ? (roughness_values.sum / roughness_values.length.to_f).round(3) : 0.013
      
      # Timestep
      base_params['Timestep (s)'] = sim1_mo.timestep rescue 1.0
      
      # Rainfall multiplier (simplified - would need actual rainfall data)
      base_params['Rainfall Multiplier'] = 1.0
      
      # Pump count
      pump_count = 0
      net1.row_objects('hw_pump').each { |_| pump_count += 1 }
      base_params['Pump Count'] = pump_count
      
      net1.close
    end
  rescue => e
    puts "  Warning: Could not process #{sim1_name}: #{e.message}"
  end
  
  begin
    sim2_mo = db.model_object(sim2_name)
    if sim2_mo.status == 'Success'
      net2 = sim2_mo.open
      
      # Average roughness
      roughness_values = []
      net2.row_objects('hw_conduit').each do |pipe|
        n = pipe.roughness rescue nil
        roughness_values << n if n && n > 0
      end
      opt_a_params['Pipe Roughness'] = roughness_values.length > 0 ? (roughness_values.sum / roughness_values.length.to_f).round(3) : 0.013
      
      # Timestep
      opt_a_params['Timestep (s)'] = sim2_mo.timestep rescue 1.0
      
      # Rainfall multiplier
      opt_a_params['Rainfall Multiplier'] = 1.0
      
      # Pump count
      pump_count = 0
      net2.row_objects('hw_pump').each { |_| pump_count += 1 }
      opt_a_params['Pump Count'] = pump_count
      
      net2.close
    end
  rescue => e
    puts "  Warning: Could not process #{sim2_name}: #{e.message}"
  end
  
  # Build comparison table
  all_params = (base_params.keys + opt_a_params.keys).uniq
  parameters = all_params.map do |param|
    {
      param: param,
      base: base_params[param] || 0,
      opt_a: opt_a_params[param] || 0
    }
  end
  
  if parameters.empty?
    puts "No parameters to compare"
    exit 0
  end
  
  # Use first sim as base, second as option A
  base_name = sim1_name
  opt_a_name = sim2_name
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'parameter_diff.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Parameter Diff</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:12px;border-bottom:1px solid #ddd}th{background:#1976d2;color:white}.changed{background:#fff9c4;font-weight:bold}</style></head>"
  html += "<body><div class='container'><h1>Scenario Parameter Comparison</h1><table><tr><th>Parameter</th><th>#{base_name}</th><th>#{opt_a_name}</th></tr>"
  
  parameters.each do |p|
    html += "<tr><td>#{p[:param]}</td><td>#{p[:base]}</td>"
    html += "<td#{p[:opt_a] != p[:base] ? ' class="changed"' : ''}>#{p[:opt_a]}</td></tr>"
  end
  
  html += "</table></div></body></html>"
  File.write(html_file, html)
  puts "✓ Parameter diff: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



