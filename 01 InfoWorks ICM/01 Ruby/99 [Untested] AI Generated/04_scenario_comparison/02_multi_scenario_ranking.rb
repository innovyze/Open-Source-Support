# Script: 02_multi_scenario_ranking.rb
# Context: Exchange
# Purpose: Multi-scenario performance ranking with radar charts
# Outputs: HTML with ranking table + radar chart
# Test Data: Sample scenario metrics
# Cleanup: N/A

begin
  puts "Multi-Scenario Ranking - Starting..."
  $stdout.flush
  
  scenarios = [
    {name: 'Base', cost: 100, performance: 70, reliability: 65, sustainability: 60, overall: 73.75},
    {name: 'Option_A', cost: 75, performance: 82, reliability: 78, sustainability: 72, overall: 76.75},
    {name: 'Option_B', cost: 50, performance: 91, reliability: 85, sustainability: 88, overall: 78.5}
  ]
  
  scenarios.sort_by! { |s| -s[:overall] }
  scenarios.each_with_index { |s, i| s[:rank] = i + 1 }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'scenario_ranking.html')
  
  # Prepare radar chart data
  labels = "'Cost','Performance','Reliability','Sustainability'"
  datasets = scenarios.map do |s|
    "{label:'#{s[:name]}',data:[#{s[:cost]},#{s[:performance]},#{s[:reliability]},#{s[:sustainability]}],borderWidth:2}"
  end.join(',')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Scenario Ranking</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/chart.js'></script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1100px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#1976d2;color:white}.rank1{background:#ffd700}.chart-container{height:500px;margin:30px 0}</style></head>"
  html += "<body><div class='container'><h1>🏆 Scenario Performance Ranking</h1><table><tr><th>Rank</th><th>Scenario</th><th>Cost</th><th>Performance</th><th>Reliability</th><th>Sustainability</th><th>Overall</th></tr>"
  
  scenarios.each { |s| html += "<tr#{s[:rank] == 1 ? ' class="rank1"' : ''}><td><strong>#{s[:rank]}</strong></td><td>#{s[:name]}</td><td>#{s[:cost]}</td><td>#{s[:performance]}</td><td>#{s[:reliability]}</td><td>#{s[:sustainability]}</td><td><strong>#{s[:overall]}</strong></td></tr>" }
  
  html += "</table><h2>Radar Comparison</h2><div class='chart-container'><canvas id='chart'></canvas></div></div>"
  html += "<script>new Chart(document.getElementById('chart'),{type:'radar',data:{labels:[#{labels}],datasets:[#{datasets}]},options:{responsive:true,maintainAspectRatio:false,scales:{r:{beginAtZero:true,max:100}}}});</script>"
  html += "</body></html>"
  
  File.write(html_file, html)
  puts "✓ Scenario ranking: #{html_file}"
  puts "  - Winner: #{scenarios[0][:name]} (#{scenarios[0][:overall]})"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



