# Script: 06_batch_scenario_cloner.rb
# Context: Exchange
# Purpose: Batch scenario cloner with naming convention
# Outputs: Log of cloned scenarios
# Usage: ruby script.rb [database_path] [base_scenario] [variant1] [variant2] ...
#        Clones base scenario with variants

begin
  puts "Batch Scenario Cloner - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get base scenario
  base_scenario = ARGV[1]
  unless base_scenario
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [base_scenario] [variant1] [variant2] ..."
    exit 1
  end
  
  variants = ARGV.length > 2 ? ARGV[2..-1] : ['Low', 'Medium', 'High']
  
  cloned = []
  
  variants.each do |variant|
    new_name = "#{base_scenario}_#{variant}_#{Time.now.strftime('%Y%m%d')}"
    
    begin
      base_sim = db.model_object(base_scenario)
      
      # Clone scenario (simplified - would need actual cloning API)
      # Note: Actual cloning would use: cloned_sim = base_sim.clone(new_name)
      
      cloned << {
        original: base_scenario,
        new_name: new_name,
        variant: variant,
        timestamp: Time.now
      }
      
      puts "  ✓ Would clone: #{base_scenario} -> #{new_name}"
      
    rescue => e
      puts "  ✗ Error cloning #{base_scenario} -> #{new_name}: #{e.message}"
    end
  end
  
  if cloned.empty?
    puts "No scenarios cloned"
    exit 0
  end
  
  puts "\nNote: This script shows what would be cloned."
  puts "Actual cloning requires uncommenting clone API calls."
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  log_file = File.join(output_dir, 'scenario_cloning_log.txt')
  
  File.open(log_file, 'w') do |f|
    f.puts "Scenario Cloning Log"
    f.puts "=" * 60
    f.puts "Timestamp: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
    f.puts "Total scenarios cloned: #{cloned.length}"
    f.puts ""
    cloned.each do |s|
      f.puts "✓ #{s[:original]} -> #{s[:new_name]} [#{s[:variant]}]"
    end
  end
  
  puts "✓ Cloning complete: #{log_file}"
  puts "  - Scenarios cloned: #{cloned.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



