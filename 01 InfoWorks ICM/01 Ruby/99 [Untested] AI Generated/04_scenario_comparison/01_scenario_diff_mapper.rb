# Script: 01_scenario_diff_mapper.rb
# Context: Exchange
# Purpose: Map scenario differences with mermaid flow diagrams
# Outputs: HTML with mermaid comparison
# Test Data: Sample scenario differences
# Cleanup: N/A

begin
  puts "Scenario Difference Mapper - Starting..."
  $stdout.flush
  
  scenarios = {
    'Base' => {pipes_modified: 0, cost: 0, performance: 70},
    'Option_A' => {pipes_modified: 12, cost: 250000, performance: 82},
    'Option_B' => {pipes_modified: 25, cost: 580000, performance: 91}
  }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'scenario_diff.html')
  
  mermaid = "flowchart TD\n"
  mermaid += "    Base[\"Base Scenario<br/>Performance: #{scenarios['Base'][:performance]}%<br/>Cost: $0\"]\n"
  mermaid += "    OptA[\"Option A<br/>#{scenarios['Option_A'][:pipes_modified]} pipes modified<br/>Performance: #{scenarios['Option_A'][:performance]}%<br/>Cost: $#{scenarios['Option_A'][:cost]}\"]\n"
  mermaid += "    OptB[\"Option B<br/>#{scenarios['Option_B'][:pipes_modified]} pipes modified<br/>Performance: #{scenarios['Option_B'][:performance]}%<br/>Cost: $#{scenarios['Option_B'][:cost]}\"]\n"
  mermaid += "    Base -->|+12% perf| OptA\n    Base -->|+21% perf| OptB\n"
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Scenario Comparison</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js'></script>"
  html += "<script>mermaid.initialize({startOnLoad:true});</script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.mermaid{background:#fafafa;padding:20px;border-radius:5px;margin:20px 0}</style></head>"
  html += "<body><div class='container'><h1>Scenario Comparison Flow</h1><div class='mermaid'>\n#{mermaid}</div></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Scenario diff mapper: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



