# Script: 01_simulation_log_parser.rb
# Context: Exchange
# Purpose: Parse simulation log files and categorize errors/warnings into an HTML report
# Outputs: HTML with categorized error summary
# Test Data: Simulates log parsing with sample data
# Cleanup: N/A (no database objects created)

begin
  puts "Simulation Log Parser - Starting..."
  $stdout.flush
  
  # Sample log data structure (in real use, would parse from file)
  log_entries = [
    {type: 'ERROR', time: '00:15:30', message: 'Convergence failure at node N123', category: 'Convergence'},
    {type: 'WARNING', time: '00:15:35', message: 'Flow reversal detected in link L456', category: 'Flow'},
    {type: 'ERROR', time: '00:20:10', message: 'Mass balance error exceeds threshold', category: 'Mass Balance'},
    {type: 'WARNING', time: '00:25:00', message: 'Timestep reduced to 0.1s', category: 'Timestep'},
    {type: 'ERROR', time: '00:30:15', message: 'HGL discontinuity at node N789', category: 'Hydraulics'},
    {type: 'INFO', time: '00:35:00', message: 'Simulation completed with warnings', category: 'Status'}
  ]
  
  # Categorize entries
  errors = log_entries.select { |e| e[:type] == 'ERROR' }
  warnings = log_entries.select { |e| e[:type] == 'WARNING' }
  info = log_entries.select { |e| e[:type] == 'INFO' }
  
  # Count by category
  category_counts = Hash.new(0)
  log_entries.each { |e| category_counts[e[:category]] += 1 }
  
  # Generate HTML report
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  output_file = File.join(output_dir, 'simulation_log_parser.html')
  
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Simulation Log Analysis</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #0066cc; padding-bottom: 10px; }
    h2 { color: #555; margin-top: 30px; }
    .summary { display: flex; gap: 20px; margin: 20px 0; }
    .stat-box { flex: 1; padding: 15px; border-radius: 5px; text-align: center; }
    .stat-box.error { background: #ffebee; border: 2px solid #c62828; }
    .stat-box.warning { background: #fff3e0; border: 2px solid #f57c00; }
    .stat-box.info { background: #e3f2fd; border: 2px solid #1976d2; }
    .stat-box .count { font-size: 36px; font-weight: bold; margin: 10px 0; }
    .stat-box .label { font-size: 14px; text-transform: uppercase; color: #666; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #0066cc; color: white; }
    tr:hover { background: #f5f5f5; }
    .error-row { border-left: 4px solid #c62828; }
    .warning-row { border-left: 4px solid #f57c00; }
    .info-row { border-left: 4px solid #1976d2; }
    .category-chart { margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Simulation Log Analysis Report</h1>
    <p><strong>Analysis Date:</strong> #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}</p>
    
    <div class="summary">
      <div class="stat-box error">
        <div class="label">Errors</div>
        <div class="count">#{errors.length}</div>
      </div>
      <div class="stat-box warning">
        <div class="label">Warnings</div>
        <div class="count">#{warnings.length}</div>
      </div>
      <div class="stat-box info">
        <div class="label">Info Messages</div>
        <div class="count">#{info.length}</div>
      </div>
    </div>
    
    <h2>Error Distribution by Category</h2>
    <table>
      <tr>
        <th>Category</th>
        <th>Count</th>
        <th>Percentage</th>
      </tr>
  HTML
  
  category_counts.each do |category, count|
    percentage = (count.to_f / log_entries.length * 100).round(1)
    html += "      <tr><td>#{category}</td><td>#{count}</td><td>#{percentage}%</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
    
    <h2>Detailed Log Entries</h2>
    <table>
      <tr>
        <th>Time</th>
        <th>Type</th>
        <th>Category</th>
        <th>Message</th>
      </tr>
  HTML
  
  log_entries.each do |entry|
    row_class = "#{entry[:type].downcase}-row"
    html += "      <tr class=\"#{row_class}\"><td>#{entry[:time]}</td><td>#{entry[:type]}</td><td>#{entry[:category]}</td><td>#{entry[:message]}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
  </div>
</body>
</html>
  HTML
  
  File.write(output_file, html)
  puts "✓ HTML report generated: #{output_file}"
  puts "  - Errors: #{errors.length}"
  puts "  - Warnings: #{warnings.length}"
  puts "  - Info: #{info.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.join("\n")
  $stdout.flush
  exit 1
end











