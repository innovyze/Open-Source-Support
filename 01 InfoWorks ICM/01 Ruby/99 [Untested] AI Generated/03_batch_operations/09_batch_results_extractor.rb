# Script: 09_batch_results_extractor.rb
# Context: Exchange
# Purpose: Pull same metrics from multiple simulation results
# Outputs: CSV with aggregated metrics
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        If no args, uses most recent database and all successful simulations

begin
  puts "Batch Results Extractor - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to process
  if ARGV.length > 1
    sim_names = ARGV[1..-1]
  else
    # Get all successful simulations
    sim_names = db.model_object_collection('Sim')
      .select { |sim| sim.status == 'Success' rescue false }
      .map { |sim| sim.name }
  end
  
  puts "Processing #{sim_names.length} simulation(s)..."
  
  simulations = []
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      if sim_mo.status != 'Success'
        puts "  ⚠ Skipping #{sim_name}: status is #{sim_mo.status}"
        next
      end
      
      net = sim_mo.open
      
      # Extract metrics
      peak_flow = 0.0
      total_volume = 0.0
      max_depth = 0.0
      
      # Find peak flow
      net.row_objects('hw_conduit').each do |pipe|
        flow = pipe.result('flow') rescue nil
        if flow && flow.abs > peak_flow
          peak_flow = flow.abs
        end
      end
      
      # Find max depth and accumulate volume
      net.row_objects('hw_node').each do |node|
        depth = node.result('depth') rescue nil
        if depth && depth > max_depth
          max_depth = depth
        end
        
        # Estimate volume (simplified - would need actual volume field)
        volume = node.result('volume') rescue nil
        total_volume += volume if volume && volume > 0
      end
      
      # Get runtime (if available)
      runtime_min = sim_mo.runtime rescue nil
      runtime_min = runtime_min ? (runtime_min / 60.0).round(1) : 0.0
      
      net.close
      
      simulations << {
        sim_id: sim_name,
        peak_flow: peak_flow.round(2),
        total_volume: total_volume.round(0),
        max_depth: max_depth.round(2),
        runtime_min: runtime_min
      }
      
      puts "  ✓ #{sim_name}: Peak flow #{peak_flow.round(2)} m³/s, Max depth #{max_depth.round(2)} m"
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if simulations.empty?
    puts "No simulation results found"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'batch_results.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "SimulationID,PeakFlow(m3/s),TotalVolume(m3),MaxDepth(m),Runtime(min)"
    simulations.each { |s| f.puts "#{s[:sim_id]},#{s[:peak_flow]},#{s[:total_volume]},#{s[:max_depth]},#{s[:runtime_min]}" }
  end
  
  avg_flow = simulations.length > 0 ? (simulations.map { |s| s[:peak_flow] }.sum / simulations.length).round(2) : 0.0
  puts "✓ Results extracted: #{csv_file}"
  puts "  - Simulations: #{simulations.length}"
  puts "  - Avg peak flow: #{avg_flow} m³/s"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.join("\n")
  $stdout.flush
  exit 1
end

