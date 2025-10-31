# Script: 04_bulk_roughness_updater.rb
# Context: Exchange
# Purpose: Bulk roughness coefficient updater with audit trail
# Outputs: CSV audit log
# Test Data: Simulates bulk update
# Cleanup: N/A

begin
  puts "Bulk Roughness Updater - Starting..."
  $stdout.flush
  
  pipes = 20.times.map { |i| {id: "P#{100+i}", old_n: 0.013, new_n: 0.015, material: 'Concrete'} }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  audit_file = File.join(output_dir, 'roughness_audit.csv')
  
  File.open(audit_file, 'w') do |f|
    f.puts "PipeID,Material,OldRoughness,NewRoughness,Change,Timestamp"
    pipes.each do |p|
      change = ((p[:new_n] - p[:old_n]) / p[:old_n] * 100).round(1)
      f.puts "#{p[:id]},#{p[:material]},#{p[:old_n]},#{p[:new_n]},#{change}%,#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    end
  end
  
  puts "✓ Bulk update complete: #{audit_file}"
  puts "  - Pipes updated: #{pipes.length}"
  puts "  - Average change: #{((0.015 - 0.013) / 0.013 * 100).round(1)}%"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



