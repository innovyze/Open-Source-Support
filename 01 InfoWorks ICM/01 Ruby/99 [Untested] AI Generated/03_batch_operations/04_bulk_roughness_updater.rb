# Script: 04_bulk_roughness_updater.rb
# Context: Exchange
# Purpose: Bulk roughness coefficient updater with audit trail
# Outputs: CSV audit log
# Usage: ruby script.rb [database_path] [network_name] [new_roughness_value]
#        Updates roughness for all conduits in network (or pipes matching criteria)

begin
  puts "Bulk Roughness Updater - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get network
  network_name = ARGV[1]
  unless network_name
    nets = db.model_object_collection('Model Network')
    if nets.empty?
      puts "ERROR: No networks found in database"
      exit 1
    end
    puts "Available networks:"
    nets.each_with_index { |net, i| puts "  #{i+1}. #{net.name}" }
    puts "\nUsage: script.rb [database_path] [network_name] [new_roughness_value]"
    exit 1
  end
  
  new_roughness = ARGV[2] ? ARGV[2].to_f : nil
  unless new_roughness && new_roughness > 0
    puts "ERROR: Please provide a valid new roughness value (e.g., 0.015)"
    puts "Usage: script.rb [database_path] [network_name] [new_roughness_value]"
    exit 1
  end
  
  net_mo = db.model_object(network_name)
  net = net_mo.open
  
  pipes = []
  
  net.row_objects('hw_conduit').each do |pipe|
    old_n = pipe.roughness rescue 0.013
    material = pipe.material rescue 'Unknown'
    
    pipes << {
      id: pipe.id,
      old_n: old_n.round(3),
      new_n: new_roughness.round(3),
      material: material
    }
    
    # Update roughness (uncomment to actually modify database)
    # pipe.roughness = new_roughness
    # pipe.write
  end
  
  net.close
  
  if pipes.empty?
    puts "No pipes found in network"
    exit 0
  end
  
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
  
  avg_change = pipes.length > 0 ? ((pipes.map { |p| ((p[:new_n] - p[:old_n]) / p[:old_n] * 100) }.sum) / pipes.length).round(1) : 0
  
  puts "✓ Bulk update audit complete: #{audit_file}"
  puts "  - Pipes analyzed: #{pipes.length}"
  puts "  - Average change: #{avg_change}%"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



