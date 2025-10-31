# Script: 10_ensemble_statistics.rb
# Context: Exchange
# Purpose: Multi-run ensemble statistics (min/max/mean/percentiles box plots)
# Outputs: HTML + CSV
# Test Data: Sample ensemble data
# Cleanup: N/A

begin
  puts "Ensemble Statistics - Starting..."
  $stdout.flush
  
  # 5 simulation runs, 10 locations
  locations = ['N1', 'N2', 'N3', 'N4', 'N5']
  ensemble_data = locations.map do |loc|
    runs = 5.times.map { rand(1.0..5.0).round(2) }
    {location: loc, min: runs.min, max: runs.max, mean: (runs.sum / runs.length).round(2), 
     p25: runs.sort[1], p75: runs.sort[3]}
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'ensemble_stats.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Location,Min,P25,Mean,P75,Max"
    ensemble_data.each { |d| f.puts "#{d[:location]},#{d[:min]},#{d[:p25]},#{d[:mean]},#{d[:p75]},#{d[:max]}" }
  end
  
  html_file = File.join(output_dir, 'ensemble_stats.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Ensemble Statistics</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#1976d2;color:white}</style></head>"
  html += "<body><div class='container'><h1>Ensemble Statistics (5 Runs)</h1><table><tr><th>Location</th><th>Min</th><th>P25</th><th>Mean</th><th>P75</th><th>Max</th></tr>"
  
  ensemble_data.each { |d| html += "<tr><td>#{d[:location]}</td><td>#{d[:min]}</td><td>#{d[:p25]}</td><td>#{d[:mean]}</td><td>#{d[:p75]}</td><td>#{d[:max]}</td></tr>" }
  
  html += "</table><p><strong>CSV:</strong> ensemble_stats.csv</p></div></body></html>"
  File.write(html_file, html)
  puts "✓ Ensemble stats: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



