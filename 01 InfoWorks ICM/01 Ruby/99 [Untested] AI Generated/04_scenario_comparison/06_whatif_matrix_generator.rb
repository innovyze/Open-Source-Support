# Script: 06_whatif_matrix_generator.rb
# Context: Exchange
# Purpose: What-if scenario matrix (parameter combinations with outcomes)
# Outputs: HTML matrix table + CSV
# Test Data: Sample what-if combinations
# Cleanup: N/A

begin
  puts "What-If Matrix Generator - Starting..."
  $stdout.flush
  
  # Parameter combinations
  rainfall_levels = [0.8, 1.0, 1.2]
  storage_sizes = [1000, 1500, 2000]
  
  matrix = []
  rainfall_levels.each do |rain|
    storage_sizes.each do |storage|
      perf = (70 + (storage / 100) + (rain * 5) + rand(-5..5)).round(1)
      cost = (storage * 150 + rain * 50000).round(0)
      matrix << {rainfall: rain, storage: storage, performance: perf, cost: cost}
    end
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'whatif_matrix.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Rainfall_Factor,Storage_m3,Performance(%),Cost($)"
    matrix.each { |m| f.puts "#{m[:rainfall]},#{m[:storage]},#{m[:performance]},#{m[:cost]}" }
  end
  
  html_file = File.join(output_dir, 'whatif_matrix.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>What-If Matrix</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1100px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#9c27b0}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border:1px solid #ddd;text-align:center}th{background:#9c27b0;color:white}.high-perf{background:#c8e6c9}.medium-perf{background:#fff9c4}.low-perf{background:#ffcdd2}</style></head>"
  html += "<body><div class='container'><h1>🔮 What-If Scenario Matrix</h1><table><tr><th>Rainfall Factor</th><th>Storage (m³)</th><th>Performance (%)</th><th>Cost ($)</th></tr>"
  
  matrix.each do |m|
    perf_class = m[:performance] >= 80 ? 'high-perf' : (m[:performance] >= 75 ? 'medium-perf' : 'low-perf')
    html += "<tr><td>#{m[:rainfall]}</td><td>#{m[:storage]}</td><td class='#{perf_class}'><strong>#{m[:performance]}</strong></td><td>#{m[:cost]}</td></tr>"
  end
  
  html += "</table><p><strong>Total combinations:</strong> #{matrix.length}</p>"
  html += "<p><strong>CSV:</strong> whatif_matrix.csv</p></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ What-if matrix: #{html_file}"
  puts "  - Combinations: #{matrix.length}"
  puts "  - CSV: #{csv_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



