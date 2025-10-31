# Script: 02_batch_property_exporter.rb
# Context: Exchange
# Purpose: Export network properties to CSV (metadata, statistics)
# Outputs: CSV with network metadata
# Test Data: Sample network data
# Cleanup: N/A

begin
  puts "Batch Network Property Exporter - Starting..."
  $stdout.flush
  
  networks = [
    {name: 'Network_A', nodes: 150, links: 220, area_ha: 45.2, created: '2023-01-15'},
    {name: 'Network_B', nodes: 280, links: 410, area_ha: 78.5, created: '2023-03-22'},
    {name: 'Network_C', nodes: 95, links: 135, area_ha: 28.1, created: '2023-05-10'}
  ]
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'network_properties.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Nodes,Links,Area(ha),Created"
    networks.each { |n| f.puts "#{n[:name]},#{n[:nodes]},#{n[:links]},#{n[:area_ha]},#{n[:created]}" }
  end
  
  puts "✓ Properties exported: #{csv_file}"
  puts "  - Networks processed: #{networks.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



