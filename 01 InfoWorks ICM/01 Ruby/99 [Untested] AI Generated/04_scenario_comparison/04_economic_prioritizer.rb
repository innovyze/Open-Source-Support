# Script: 04_economic_prioritizer.rb
# Context: Exchange
# Purpose: Economic scenario prioritizer (NPV/IRR/Payback ranking)
# Outputs: HTML + CSV economic analysis
# Test Data: Sample economic metrics
# Cleanup: N/A

begin
  puts "Economic Prioritizer - Starting..."
  $stdout.flush
  
  scenarios = [
    {name: 'Option_A', capex: 250000, opex_annual: 15000, benefit_annual: 45000, npv: 125000, irr: 12.5, payback: 6.8},
    {name: 'Option_B', capex: 580000, opex_annual: 28000, benefit_annual: 95000, npv: 285000, irr: 15.2, payback: 8.2},
    {name: 'Option_C', capex: 120000, opex_annual: 8000, benefit_annual: 28000, npv: 95000, irr: 18.5, payback: 5.2}
  ]
  
  scenarios.sort_by! { |s| -s[:npv] }
  scenarios.each_with_index { |s, i| s[:rank] = i + 1 }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'economic_analysis.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Rank,Scenario,CAPEX,OPEX_Annual,Benefit_Annual,NPV,IRR(%),Payback(yr)"
    scenarios.each { |s| f.puts "#{s[:rank]},#{s[:name]},#{s[:capex]},#{s[:opex_annual]},#{s[:benefit_annual]},#{s[:npv]},#{s[:irr]},#{s[:payback]}" }
  end
  
  html_file = File.join(output_dir, 'economic_prioritizer.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Economic Analysis</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#388e3c}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:right}th{background:#388e3c;color:white}td:first-child,th:first-child{text-align:center}td:nth-child(2),th:nth-child(2){text-align:left}.rank1{background:#c8e6c9}</style></head>"
  html += "<body><div class='container'><h1>💰 Economic Scenario Prioritization</h1><table><tr><th>Rank</th><th>Scenario</th><th>CAPEX ($)</th><th>OPEX/yr ($)</th><th>Benefit/yr ($)</th><th>NPV ($)</th><th>IRR (%)</th><th>Payback (yr)</th></tr>"
  
  scenarios.each { |s| html += "<tr#{s[:rank] == 1 ? ' class="rank1"' : ''}><td><strong>#{s[:rank]}</strong></td><td>#{s[:name]}</td><td>#{s[:capex]}</td><td>#{s[:opex_annual]}</td><td>#{s[:benefit_annual]}</td><td><strong>#{s[:npv]}</strong></td><td>#{s[:irr]}</td><td>#{s[:payback]}</td></tr>" }
  
  html += "</table><p><strong>Recommended:</strong> #{scenarios[0][:name]} (NPV: $#{scenarios[0][:npv]}, IRR: #{scenarios[0][:irr]}%)</p>"
  html += "<p><strong>CSV:</strong> economic_analysis.csv</p></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Economic analysis: #{html_file}"
  puts "  - Best NPV: #{scenarios[0][:name]} ($#{scenarios[0][:npv]})"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



