# Script: 14_log_file_comparator.rb
# Context: Exchange
# Purpose: Compare logs from multiple simulation runs (diff viewer)
# Outputs: HTML with side-by-side comparison
# Test Data: Sample log statistics
# Cleanup: N/A

begin
  puts "Log File Comparator - Starting..."
  $stdout.flush
  
  # Sample log comparison data
  runs = [
    {name: 'Baseline', errors: 5, warnings: 23, runtime: 245, status: 'Success'},
    {name: 'Modified', errors: 2, warnings: 15, runtime: 238, status: 'Success'}
  ]
  
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













