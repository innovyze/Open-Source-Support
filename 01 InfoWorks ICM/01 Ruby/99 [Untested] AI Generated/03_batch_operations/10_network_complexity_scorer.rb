# Script: 10_network_complexity_scorer.rb
# Context: Exchange
# Purpose: Calculate complexity metrics across network portfolio
# Outputs: HTML scorecard + CSV
# Test Data: Sample complexity metrics
# Cleanup: N/A

begin
  puts "Network Complexity Scorer - Starting..."
  $stdout.flush
  
  networks = [
    {name: 'Network_A', nodes: 150, loops: 8, structures: 12, score: 45},
    {name: 'Network_B', nodes: 280, loops: 18, structures: 25, score: 78},
    {name: 'Network_C', nodes: 95, loops: 4, structures: 6, score: 28}
  ]
  
  # Calculate composite score
  networks.each do |net|
    net[:complexity] = (net[:nodes] * 0.1 + net[:loops] * 2 + net[:structures] * 1.5).round(0)
    net[:rating] = net[:complexity] < 40 ? 'Simple' : (net[:complexity] < 70 ? 'Moderate' : 'Complex')
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'complexity_scores.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Nodes,Loops,Structures,ComplexityScore,Rating"
    networks.each { |n| f.puts "#{n[:name]},#{n[:nodes]},#{n[:loops]},#{n[:structures]},#{n[:complexity]},#{n[:rating]}" }
  end
  
  html_file = File.join(output_dir, 'complexity_scorecard.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Complexity Scorecard</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#1976d2;color:white}.simple{background:#c8e6c9}.moderate{background:#fff9c4}.complex{background:#ffccbc}</style></head>"
  html += "<body><div class='container'><h1>Network Complexity Scorecard</h1><table><tr><th>Network</th><th>Nodes</th><th>Loops</th><th>Structures</th><th>Score</th><th>Rating</th></tr>"
  
  networks.each { |n| html += "<tr class='#{n[:rating].downcase}'><td>#{n[:name]}</td><td>#{n[:nodes]}</td><td>#{n[:loops]}</td><td>#{n[:structures]}</td><td><strong>#{n[:complexity]}</strong></td><td>#{n[:rating]}</td></tr>" }
  
  html += "</table><p><strong>CSV:</strong> complexity_scores.csv</p></div></body></html>"
  File.write(html_file, html)
  
  puts "✓ Complexity scoring complete:"
  puts "  - HTML: #{html_file}"
  puts "  - CSV: #{csv_file}"
  puts "  - Networks scored: #{networks.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



