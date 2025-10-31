# Script: 10_ensemble_statistics.rb
# Context: Exchange
# Purpose: Multi-run ensemble statistics (min/max/mean/percentiles box plots)
# Outputs: HTML + CSV
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        Compares multiple simulations for ensemble statistics

begin
  puts "Ensemble Statistics - Starting..."
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
  
  # Sample nodes from first simulation
  sample_nodes = []
  begin
    sim_mo = db.model_object(sim_names.first)
    if sim_mo.status == 'Success'
      net = sim_mo.open
      count = 0
      net.row_objects('hw_node').each do |node|
        break if count >= 5
        sample_nodes << node.id
        count += 1
      end
      net.close
    end
  rescue => e
    puts "  Warning: Could not sample nodes: #{e.message}"
  end
  
  if sample_nodes.empty?
    sample_nodes = ['N1', 'N2', 'N3', 'N4', 'N5']  # Fallback
  end
  
  # Collect data for each location across simulations
  ensemble_data = []
  
  sample_nodes.each do |loc|
    values = []
    
    sim_names.each do |sim_name|
      begin
        sim_mo = db.model_object(sim_name)
        if sim_mo.status == 'Success'
          net = sim_mo.open
          node = net.row_object('hw_node', loc) rescue nil
          if node
            depth = node.result('depth') rescue nil
            values << depth if depth && depth > 0
          end
          net.close
        end
      rescue => e
        puts "  Warning: Could not process #{sim_name} for #{loc}: #{e.message}"
      end
    end
    
    if values.length > 0
      sorted = values.sort
      ensemble_data << {
        location: loc,
        min: sorted.first.round(2),
        max: sorted.last.round(2),
        mean: (values.sum / values.length.to_f).round(2),
        p25: sorted[sorted.length / 4].round(2),
        p75: sorted[(sorted.length * 3) / 4].round(2)
      }
    end
  end
  
  if ensemble_data.empty?
    puts "No ensemble data collected"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'ensemble_stats.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Location,Min,P25,Mean,P75,Max"
    ensemble_data.each { |d| f.puts "#{d[:location]},#{d[:min]},#{d[:p25]},#{d[:mean]},#{d[:p75]},#{d[:max]}" }
  end
  
  html_file = File.join(output_dir, 'ensemble_stats.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Ensemble Statistics</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#1976d2;color:white}</style></head>"
  html += "<body><div class='container'><h1>Ensemble Statistics (5 Runs)</h1><table><tr><th>Location</th><th>Min</th><th>P25</th><th>Mean</th><th>P75</th><th>Max</th></tr>"
  
  ensemble_data.each { |d| html += "<tr><td>#{d[:location]}</td><td>#{d[:min]}</td><td>#{d[:p25]}</td><td>#{d[:mean]}</td><td>#{d[:p75]}</td><td>#{d[:max]}</td></tr>" }
  
  html += "</table><p><strong>CSV:</strong> ensemble_stats.csv</p></div></body></html>"
  File.write(html_file, html)
  puts "✓ Ensemble stats: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



