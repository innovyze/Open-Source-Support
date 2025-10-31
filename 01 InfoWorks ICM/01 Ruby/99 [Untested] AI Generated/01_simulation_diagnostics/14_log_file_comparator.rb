# Script: 14_log_file_comparator.rb
# Context: Exchange
# Purpose: Compare logs from multiple simulation runs (diff viewer)
# Outputs: HTML with side-by-side comparison
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2]
#        If no args, uses most recent database and lists available simulations

begin
  puts "Log File Comparator - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to compare
  if ARGV.length > 1
    sim_names = ARGV[1..2]  # Compare first two provided
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
  
  if sim_names.length < 2
    puts "ERROR: Need at least 2 simulations to compare"
    exit 1
  end
  
  runs = []
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      errors = 0
      warnings = 0
      runtime = 0
      
      # Parse log file
      results_path = sim_mo.results_path rescue nil
      if results_path && Dir.exist?(results_path)
        log_file = File.join(results_path, "#{sim_mo.name}.log")
        if File.exist?(log_file)
          File.readlines(log_file).each do |line|
            errors += 1 if line.match?(/ERROR|FATAL/i)
            warnings += 1 if line.match?(/WARNING|WARN/i)
            
            # Try to extract runtime
            runtime_match = line.match(/(\d+\.?\d*)\s*(?:seconds?|s)\s*(?:elapsed|runtime)/i)
            if runtime_match
              runtime = runtime_match[1].to_f
            end
          end
        end
      end
      
      # Get runtime from simulation object if available
      runtime = sim_mo.runtime rescue runtime if runtime == 0
      
      runs << {
        name: sim_name,
        errors: errors,
        warnings: warnings,
        runtime: runtime.round(0),
        status: sim_mo.status rescue 'Unknown'
      }
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if runs.length < 2
    puts "ERROR: Could not process both simulations"
    exit 1
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'log_comparator.html')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Log File Comparator</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1100px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    .comparison { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 15px; margin: 20px 0; }
    .col-header { background: #1976d2; color: white; padding: 15px; border-radius: 5px; text-align: center; font-weight: bold; }
    .col-metric { background: #e3f2fd; padding: 10px 15px; border-radius: 5px; }
    .col-diff { background: #fff9c4; padding: 10px 15px; border-radius: 5px; font-weight: bold; }
    .metric-label { font-size: 12px; color: #666; margin-bottom: 5px; }
    .metric-value { font-size: 22px; font-weight: bold; }
    .improvement { color: #388e3c; }
    .regression { color: #c62828; }
    .neutral { color: #666; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Simulation Log Comparison</h1>
    
    <div class="comparison">
      <div class="col-header">Metric</div>
      <div class="col-header">#{runs[0][:name]}</div>
      <div class="col-header">#{runs[1][:name]}</div>
      
      <div class="col-metric"><strong>Errors</strong></div>
      <div class="col-metric">#{runs[0][:errors]}</div>
      <div class="col-diff class="#{runs[1][:errors] < runs[0][:errors] ? 'improvement' : 'regression'}">
        #{runs[1][:errors]} (#{runs[1][:errors] - runs[0][:errors] >= 0 ? '+' : ''}#{runs[1][:errors] - runs[0][:errors]})
      </div>
      
      <div class="col-metric"><strong>Warnings</strong></div>
      <div class="col-metric">#{runs[0][:warnings]}</div>
      <div class="col-diff class="#{runs[1][:warnings] < runs[0][:warnings] ? 'improvement' : 'regression'}">
        #{runs[1][:warnings]} (#{runs[1][:warnings] - runs[0][:warnings] >= 0 ? '+' : ''}#{runs[1][:warnings] - runs[0][:warnings]})
      </div>
      
      <div class="col-metric"><strong>Runtime (s)</strong></div>
      <div class="col-metric">#{runs[0][:runtime]}</div>
      <div class="col-diff class="#{runs[1][:runtime] < runs[0][:runtime] ? 'improvement' : 'regression'}">
        #{runs[1][:runtime]} (#{runs[1][:runtime] - runs[0][:runtime] >= 0 ? '+' : ''}#{runs[1][:runtime] - runs[0][:runtime]})
      </div>
      
      <div class="col-metric"><strong>Status</strong></div>
      <div class="col-metric">#{runs[0][:status]}</div>
      <div class="col-diff neutral">#{runs[1][:status]}</div>
    </div>
    
    <h2>Summary</h2>
    <p class="#{runs[1][:errors] < runs[0][:errors] && runs[1][:warnings] < runs[0][:warnings] ? 'improvement' : 'neutral'}" 
       style="padding: 15px; background: #e8f5e9; border-radius: 5px;">
      <strong>Analysis:</strong> Modified run shows 
      <strong>#{((1 - runs[1][:errors].to_f/runs[0][:errors]) * 100).round(0)}% fewer errors</strong> and 
      <strong>#{((1 - runs[1][:warnings].to_f/runs[0][:warnings]) * 100).round(0)}% fewer warnings</strong> 
      with <strong>#{((1 - runs[1][:runtime].to_f/runs[0][:runtime]) * 100).round(1)}% faster runtime</strong>.
    </p>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Log comparison complete: #{output_file}"
  puts "  - Error reduction: #{((1 - runs[1][:errors].to_f/runs[0][:errors]) * 100).round(0)}%"
  puts "  - Warning reduction: #{((1 - runs[1][:warnings].to_f/runs[0][:warnings]) * 100).round(0)}%"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













