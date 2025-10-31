# Script: 08_asset_inventory_aggregator.rb
# Context: Exchange
# Purpose: Aggregate asset inventory across networks (global asset register)
# Outputs: CSV asset register
# Test Data: Sample asset data
# Cleanup: N/A

begin
  puts "Asset Inventory Aggregator - Starting..."
  $stdout.flush
  
  networks = {
    'Network_A' => {pipes: 220, manholes: 150, pumps: 8, tanks: 2},
    'Network_B' => {pipes: 410, manholes: 280, pumps: 12, tanks: 5},
    'Network_C' => {pipes: 135, manholes: 95, pumps: 5, tanks: 1}
  }
  
  totals = {pipes: 0, manholes: 0, pumps: 0, tanks: 0}
  networks.each { |net, assets| assets.each { |type, count| totals[type] += count } }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'asset_inventory.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Pipes,Manholes,Pumps,Tanks,Total"
    networks.each do |net, assets|
      total = assets.values.sum
      f.puts "#{net},#{assets[:pipes]},#{assets[:manholes]},#{assets[:pumps]},#{assets[:tanks]},#{total}"
    end
    f.puts "TOTAL,#{totals[:pipes]},#{totals[:manholes]},#{totals[:pumps]},#{totals[:tanks]},#{totals.values.sum}"
  end
  
  puts "✓ Asset inventory: #{csv_file}"
  puts "  - Total assets: #{totals.values.sum}"
  puts "  - Networks: #{networks.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



