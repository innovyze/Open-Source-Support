# Script: 06_lid_performance_reporter.rb
# Context: Exchange
# Purpose: LID performance metrics (before/after comparison)
# Outputs: HTML comparison report
# Usage: ruby script.rb [database_path] [simulation_before] [simulation_after]
#        Compares two simulations to show LID impact

begin
  puts "LID Performance Reporter - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to compare
  if ARGV.length > 2
    sim_before = ARGV[1]
    sim_after = ARGV[2]
  else
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_before] [simulation_after]"
    exit 1
  end
  
  # Extract metrics from both simulations
  metrics = {}
  
  ['Runoff Volume (m³)', 'Peak Flow (m³/s)', 'Pollutant Load (kg)'].each do |metric_name|
    before_val = 0.0
    after_val = 0.0
    
    # Process before simulation
    begin
      sim_mo_before = db.model_object(sim_before)
      if sim_mo_before.status == 'Success'
        net_before = sim_mo_before.open
        
        case metric_name
        when 'Runoff Volume (m³)'
          # Sum runoff volume from subcatchments
          net_before.row_objects('hw_subcatchment').each do |sub|
            vol = sub.result('runoff_volume') rescue nil
            before_val += vol if vol && vol > 0
          end
        when 'Peak Flow (m³/s)'
          # Find peak flow
          net_before.row_objects('hw_conduit').each do |pipe|
            flow = pipe.result('flow') rescue nil
            if flow && flow.abs > before_val
              before_val = flow.abs
            end
          end
        when 'Pollutant Load (kg)'
          # Estimate pollutant load (simplified)
          net_before.row_objects('hw_subcatchment').each do |sub|
            vol = sub.result('runoff_volume') rescue nil
            # Simplified: assume 0.01 kg/m³ (would need actual pollutant data)
            before_val += (vol * 0.01) if vol && vol > 0
          end
        end
        
        net_before.close
      end
    rescue => e
      puts "  Warning: Could not process #{sim_before}: #{e.message}"
    end
    
    # Process after simulation
    begin
      sim_mo_after = db.model_object(sim_after)
      if sim_mo_after.status == 'Success'
        net_after = sim_mo_after.open
        
        case metric_name
        when 'Runoff Volume (m³)'
          net_after.row_objects('hw_subcatchment').each do |sub|
            vol = sub.result('runoff_volume') rescue nil
            after_val += vol if vol && vol > 0
          end
        when 'Peak Flow (m³/s)'
          net_after.row_objects('hw_conduit').each do |pipe|
            flow = pipe.result('flow') rescue nil
            if flow && flow.abs > after_val
              after_val = flow.abs
            end
          end
        when 'Pollutant Load (kg)'
          net_after.row_objects('hw_subcatchment').each do |sub|
            vol = sub.result('runoff_volume') rescue nil
            after_val += (vol * 0.01) if vol && vol > 0
          end
        end
        
        net_after.close
      end
    rescue => e
      puts "  Warning: Could not process #{sim_after}: #{e.message}"
    end
    
    # Calculate improvement
    improvement = before_val > 0 ? (((before_val - after_val) / before_val) * 100).round : 0
    
    metrics[metric_name] = {
      before: before_val.round(1),
      after: after_val.round(1),
      improvement: improvement
    }
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'lid_performance.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>LID Performance</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#388e3c}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:12px;border-bottom:1px solid #ddd}th{background:#388e3c;color:white}.improvement{color:#388e3c;font-weight:bold}</style></head>"
  html += "<body><div class='container'><h1>LID Performance Analysis</h1><table><tr><th>Metric</th><th>Before</th><th>After</th><th>Improvement</th></tr>"
  
  metrics.each { |name, data| html += "<tr><td>#{name}</td><td>#{data[:before]}</td><td>#{data[:after]}</td><td class='improvement'>#{data[:improvement]}%</td></tr>" }
  
  html += "</table></div></body></html>"
  File.write(html_file, html)
  puts "✓ LID report generated: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end




