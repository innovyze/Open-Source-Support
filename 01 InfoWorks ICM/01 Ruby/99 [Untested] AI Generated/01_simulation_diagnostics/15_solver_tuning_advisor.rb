# Script: 15_solver_tuning_advisor.rb
# Context: Exchange
# Purpose: Suggest solver parameter adjustments based on log patterns
# Outputs: HTML with tuning recommendations
# Usage: ruby script.rb [database_path] [simulation_name]
#        Analyzes log file to suggest solver parameter improvements

begin
  puts "Solver Parameter Tuning Advisor - Starting..."
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
  
  # Analyze log file
  log_analysis = {
    avg_iterations: 0,
    max_iterations: 0,
    convergence_failures: 0,
    timestep_reductions: 0,
    mass_balance_errors: 0,
    runtime_minutes: 0
  }
  
  results_path = sim_mo.results_path rescue nil
  
  if results_path && Dir.exist?(results_path)
    log_file = File.join(results_path, "#{sim_mo.name}.log")
    if File.exist?(log_file)
      puts "Analyzing log file..."
      
      iter_counts = []
      timestep_count = 0
      
      File.readlines(log_file).each do |line|
        # Extract iteration counts
        iter_match = line.match(/(\d+)\s*(?:iteration|iter)/i)
        if iter_match
          iter_counts << iter_match[1].to_i
        end
        
        # Count convergence failures
        log_analysis[:convergence_failures] += 1 if line.match?(/convergence.*fail|failed.*converge/i)
        
        # Count timestep reductions
        timestep_count += 1 if line.match?(/timestep.*reduc|reduc.*timestep/i)
        
        # Count mass balance errors
        log_analysis[:mass_balance_errors] += 1 if line.match?(/mass.*balance.*error/i)
      end
      
      log_analysis[:avg_iterations] = iter_counts.length > 0 ? (iter_counts.sum.to_f / iter_counts.length).round(1) : 0
      log_analysis[:max_iterations] = iter_counts.max || 0
      log_analysis[:timestep_reductions] = timestep_count
      log_analysis[:runtime_minutes] = sim_mo.runtime ? (sim_mo.runtime / 60.0).round(1) : 0
    end
  end
  
  # Generate recommendations based on patterns
  recommendations = []
  
  if log_analysis[:avg_iterations] > 10
    recommendations << {
      issue: 'High average iteration count',
      current: "#{log_analysis[:avg_iterations]} iterations/step",
      suggestion: 'Relax convergence tolerance',
      parameter: 'Tolerance: 0.001 → 0.005',
      impact: 'Reduce iterations by 30-40%'
    }
  end
  
  if log_analysis[:max_iterations] > 30
    recommendations << {
      issue: 'Excessive maximum iterations',
      current: "#{log_analysis[:max_iterations]} iterations",
      suggestion: 'Increase timestep flexibility',
      parameter: 'Min timestep: 0.1s → 0.05s',
      impact: 'Allow finer resolution during instability'
    }
  end
  
  if log_analysis[:timestep_reductions] > 15
    recommendations << {
      issue: 'Frequent timestep reductions',
      current: "#{log_analysis[:timestep_reductions]} reductions",
      suggestion: 'Start with smaller timestep',
      parameter: 'Initial timestep: 1.0s → 0.5s',
      impact: 'Reduce reductions by ~50%'
    }
  end
  
  if log_analysis[:convergence_failures] > 10
    recommendations << {
      issue: 'Numerous convergence failures',
      current: "#{log_analysis[:convergence_failures]} failures",
      suggestion: 'Enable adaptive solver',
      parameter: 'Solver mode: Fixed → Adaptive',
      impact: 'Better handling of transient conditions'
    }
  end
  
  if recommendations.empty?
    puts "No tuning recommendations needed - simulation appears healthy"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'solver_tuning_advisor.html')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Solver Tuning Advisor</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1100px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    .analysis { background: #e3f2fd; padding: 20px; border-radius: 5px; margin: 20px 0; }
    .analysis h3 { margin-top: 0; color: #1976d2; }
    .metrics { display: grid; grid-template-columns: repeat(3, 1fr); gap: 15px; margin: 15px 0; }
    .metric { text-align: center; }
    .metric-value { font-size: 24px; font-weight: bold; color: #1976d2; }
    .metric-label { font-size: 12px; color: #666; }
    .recommendation { background: #fff; border: 2px solid #1976d2; border-radius: 5px; padding: 15px; margin: 15px 0; }
    .recommendation h4 { margin: 0 0 10px 0; color: #c62828; }
    .rec-detail { margin: 8px 0; }
    .rec-label { font-weight: bold; color: #666; }
    .rec-value { color: #333; }
    .impact { background: #e8f5e9; padding: 10px; border-radius: 3px; margin-top: 10px; color: #2e7d32; font-weight: bold; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Solver Parameter Tuning Recommendations</h1>
    
    <div class="analysis">
      <h3>Current Performance Analysis</h3>
      <div class="metrics">
        <div class="metric">
          <div class="metric-value">#{log_analysis[:avg_iterations]}</div>
          <div class="metric-label">Avg Iterations</div>
        </div>
        <div class="metric">
          <div class="metric-value">#{log_analysis[:convergence_failures]}</div>
          <div class="metric-label">Conv. Failures</div>
        </div>
        <div class="metric">
          <div class="metric-value">#{log_analysis[:timestep_reductions]}</div>
          <div class="metric-label">Timestep Reductions</div>
        </div>
      </div>
      <p><strong>Runtime:</strong> #{log_analysis[:runtime_minutes]} minutes | 
         <strong>Mass Balance Errors:</strong> #{log_analysis[:mass_balance_errors]}</p>
    </div>
    
    <h2>Tuning Recommendations (#{recommendations.length})</h2>
  HTML
  
  recommendations.each_with_index do |rec, i|
    html += <<-REC
    <div class="recommendation">
      <h4>#{i + 1}. #{rec[:issue]}</h4>
      <div class="rec-detail">
        <span class="rec-label">Current:</span> 
        <span class="rec-value">#{rec[:current]}</span>
      </div>
      <div class="rec-detail">
        <span class="rec-label">Suggestion:</span> 
        <span class="rec-value">#{rec[:suggestion]}</span>
      </div>
      <div class="rec-detail">
        <span class="rec-label">Parameter Change:</span> 
        <span class="rec-value">#{rec[:parameter]}</span>
      </div>
      <div class="impact">Expected Impact: #{rec[:impact]}</div>
    </div>
    REC
  end
  
  html += <<-HTML
    
    <h2>Implementation Priority</h2>
    <ol>
      <li><strong>High:</strong> Apply timestep and tolerance adjustments first</li>
      <li><strong>Medium:</strong> Test solver mode changes</li>
      <li><strong>Low:</strong> Fine-tune based on results</li>
    </ol>
    
    <p style="padding: 15px; background: #fff3e0; border-left: 4px solid #f57c00; margin-top: 20px;">
      <strong>Note:</strong> Apply one change at a time and re-test to isolate impact. 
      Document baseline metrics before making adjustments.
    </p>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ Solver tuning recommendations generated: #{output_file}"
  puts "  - Recommendations: #{recommendations.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













