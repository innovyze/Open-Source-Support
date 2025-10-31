# Script: 17_capacity_bottleneck_ranker.rb
# Context: Exchange
# Purpose: Network capacity bottleneck ranker (top 20 critical assets)
# Outputs: HTML ranked list + CSV
# Test Data: Sample bottleneck data
# Cleanup: N/A

begin
  puts "Capacity Bottleneck Ranker - Starting..."
  $stdout.flush
  
  bottlenecks = 20.times.map do |i|
    {rank: i + 1, asset: "P#{100 + i}", util_pct: (95 + rand(0..25)).clamp(0, 150), 
     capacity: rand(0.5..2.0).round(2), peak_flow: rand(0.6..2.5).round(2)}
  end.sort_by { |b| -b[:util_pct] }
  
  bottlenecks.each_with_index { |b, i| b[:rank] = i + 1 }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'bottlenecks.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Rank,Asset,Utilization(%),Capacity,PeakFlow"
    bottlenecks.each { |b| f.puts "#{b[:rank]},#{b[:asset]},#{b[:util_pct]},#{b[:capacity]},#{b[:peak_flow]}" }
  end
  
  html_file = File.join(output_dir, 'bottlenecks.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Bottlenecks</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#c62828}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#c62828;color:white}.critical{background:#ffcdd2}.high{background:#ffe0b2}.rank{font-weight:bold;font-size:18px;color:#c62828}</style></head>"
  html += "<body><div class='container'><h1>⚠️ Capacity Bottlenecks (Top 20)</h1><table><tr><th>Rank</th><th>Asset</th><th>Utilization (%)</th><th>Capacity</th><th>Peak Flow</th></tr>"
  
  bottlenecks[0..19].each do |b|
    row_class = b[:util_pct] > 110 ? 'critical' : (b[:util_pct] > 95 ? 'high' : '')
    html += "<tr class='#{row_class}'><td class='rank'>#{b[:rank]}</td><td>#{b[:asset]}</td><td>#{b[:util_pct]}</td><td>#{b[:capacity]}</td><td>#{b[:peak_flow]}</td></tr>"
  end
  
  html += "</table><p><strong>CSV:</strong> bottlenecks.csv</p></div></body></html>"
  File.write(html_file, html)
  puts "✓ Bottleneck ranking: #{html_file}"
  puts "  - Top bottleneck: #{bottlenecks[0][:asset]} (#{bottlenecks[0][:util_pct]}%)"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



