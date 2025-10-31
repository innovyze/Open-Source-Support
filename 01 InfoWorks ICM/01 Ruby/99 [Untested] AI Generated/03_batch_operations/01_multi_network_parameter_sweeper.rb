# Script: 01_multi_network_parameter_sweeper.rb
# Context: Exchange
# Purpose: Batch sensitivity analysis across multiple networks
# Outputs: CSV with parameter sweep results
# Test Data: Simulates parameter sweep
# Cleanup: N/A

begin
  puts "Multi-Network Parameter Sweeper - Starting..."
  $stdout.flush
  
  networks = ['Network_A', 'Network_B', 'Network_C']
  parameters = ['Roughness', 'Infiltration', 'Timestep']
  
  results = []
  networks.each do |net|
    parameters.each do |param|
      value = rand(0.5..1.5).round(3)
      impact = rand(-15..25).round(1)
      results << {network: net, parameter: param, value: value, impact_pct: impact}
    end
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'parameter_sweep.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Parameter,Value,Impact(%)"
    results.each { |r| f.puts "#{r[:network]},#{r[:parameter]},#{r[:value]},#{r[:impact_pct]}" }
  end
  
  puts "✓ Parameter sweep complete: #{csv_file}"
  puts "  - Networks: #{networks.length}"
  puts "  - Parameters tested: #{parameters.length}"
  puts "  - Total combinations: #{results.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



