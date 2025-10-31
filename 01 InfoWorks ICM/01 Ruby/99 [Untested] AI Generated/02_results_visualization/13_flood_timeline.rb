# Script: 13_flood_timeline.rb
# Context: Exchange
# Purpose: Time series animation (mermaid timeline of flood progression)
# Outputs: HTML with mermaid timeline
# Test Data: Sample flood events
# Cleanup: N/A

begin
  puts "Flood Timeline Animator - Starting..."
  $stdout.flush
  
  events = [
    {time: '12:00', node: 'N001', event: 'Initial ponding'},
    {time: '12:15', node: 'N005', event: 'Flooding begins'},
    {time: '12:30', node: 'N008', event: 'Critical depth reached'},
    {time: '12:45', node: 'N012', event: 'Peak flood level'},
    {time: '13:00', node: 'N008', event: 'Water receding'},
    {time: '13:30', node: 'N005', event: 'Flooding cleared'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'flood_timeline.html')
  
  mermaid = "timeline\n    title Flood Progression Event Timeline\n"
  events.each { |e| mermaid += "    #{e[:time]} : #{e[:node]} - #{e[:event]}\n" }
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Flood Timeline</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js'></script>"
  html += "<script>mermaid.initialize({startOnLoad:true});</script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#2196f3}.mermaid{background:#fafafa;padding:20px;border-radius:5px;margin:20px 0}</style></head>"
  html += "<body><div class='container'><h1>Flood Progression Timeline</h1><div class='mermaid'>\n#{mermaid}</div></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Flood timeline: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



