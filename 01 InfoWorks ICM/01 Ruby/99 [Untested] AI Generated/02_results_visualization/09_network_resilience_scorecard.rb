# Script: 09_network_resilience_scorecard.rb
# Context: Exchange
# Purpose: Network resilience composite metrics dashboard
# Outputs: HTML scorecard
# Test Data: Sample resilience metrics
# Cleanup: N/A

begin
  puts "Network Resilience Scorecard - Starting..."
  $stdout.flush
  
  scores = {
    'Redundancy' => 75,
    'Robustness' => 82,
    'Adaptability' => 68,
    'Recovery Speed' => 71
  }
  
  overall = scores.values.sum / scores.length
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'resilience_scorecard.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Resilience Scorecard</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#1e1e1e;color:white}.container{max-width:900px;margin:0 auto;padding:20px}h1{font-size:32px;margin-bottom:30px}.overall{text-align:center;padding:40px;background:#2d2d2d;border-radius:10px;margin:20px 0}.overall .score{font-size:72px;font-weight:bold;color:#2196f3}.metrics{display:grid;grid-template-columns:repeat(2,1fr);gap:20px;margin:30px 0}.metric{background:#2d2d2d;padding:25px;border-radius:10px}.metric-name{font-size:14px;color:#aaa;margin-bottom:10px}.metric-score{font-size:36px;font-weight:bold;color:#2196f3}.bar{height:10px;background:#444;border-radius:5px;margin-top:10px;overflow:hidden}.bar-fill{height:100%;background:#2196f3;border-radius:5px}</style></head>"
  html += "<body><div class='container'><h1>🛡️ Network Resilience Scorecard</h1>"
  html += "<div class='overall'><div>Overall Resilience Score</div><div class='score'>#{overall}</div><div style='font-size:20px;color:#aaa'>out of 100</div></div>"
  html += "<div class='metrics'>"
  
  scores.each do |name, score|
    html += "<div class='metric'><div class='metric-name'>#{name}</div><div class='metric-score'>#{score}</div>"
    html += "<div class='bar'><div class='bar-fill' style='width:#{score}%'></div></div></div>"
  end
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Resilience scorecard: #{html_file}"
  puts "  - Overall score: #{overall}/100"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



