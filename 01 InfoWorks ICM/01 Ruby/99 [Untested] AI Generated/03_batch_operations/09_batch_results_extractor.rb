# Script: 09_batch_results_extractor.rb
# Context: Exchange
# Purpose: Pull same metrics from multiple simulation results
# Outputs: CSV with aggregated metrics
# Test Data: Sample simulation metrics
# Cleanup: N/A

begin
  puts "Batch Results Extractor - Starting..."
  $stdout.flush
  
  simulations = 10.times.map do |i|
    {sim_id: "Run_#{i+1}", peak_flow: rand(1.5..4.5).round(2), 
     total_volume: rand(5000..15000).round(0), max_depth: rand(0.5..2.5).round(2),
     runtime_min: rand(5..25).round(1)}
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'batch_results.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "SimulationID,PeakFlow(m3/s),TotalVolume(m3),MaxDepth(m),Runtime(min)"
    simulations.each { |s| f.puts "#{s[:sim_id]},#{s[:peak_flow]},#{s[:total_volume]},#{s[:max_depth]},#{s[:runtime_min]}" }
  end
  
  avg_flow = (simulations.map { |s| s[:peak_flow] }.sum / simulations.length).round(2)
  puts "✓ Results extracted: #{csv_file}"
  puts "  - Simulations: #{simulations.length}"
  puts "  - Avg peak flow: #{avg_flow} m³/s"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



