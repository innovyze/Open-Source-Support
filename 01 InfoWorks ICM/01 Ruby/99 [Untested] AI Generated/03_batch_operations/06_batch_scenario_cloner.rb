# Script: 06_batch_scenario_cloner.rb
# Context: Exchange
# Purpose: Batch scenario cloner with naming convention
# Outputs: Log of cloned scenarios
# Test Data: Simulates scenario cloning
# Cleanup: N/A

begin
  puts "Batch Scenario Cloner - Starting..."
  $stdout.flush
  
  base_scenarios = ['Base_Case', 'Design_Storm', 'Climate_Change']
  variants = ['Low', 'Medium', 'High']
  
  cloned = []
  base_scenarios.each do |base|
    variants.each do |variant|
      new_name = "#{base}_#{variant}_#{Time.now.strftime('%Y%m%d')}"
      cloned << {original: base, new_name: new_name, variant: variant, timestamp: Time.now}
    end
  end
  
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



