# Script: 07_multi_network_validator.rb
# Context: Exchange
# Purpose: Run batch QA checks across multiple networks
# Outputs: CSV with validation results
# Usage: ruby script.rb [database_path] [network_name1] [network_name2] ...
#        If no args, validates all networks in database

begin
  puts "Multi-Network Validator - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get networks to validate
  if ARGV.length > 1
    network_names = ARGV[1..-1]
  else
    nets = db.model_object_collection('Model Network')
    if nets.empty?
      puts "ERROR: No networks found in database"
      exit 1
    end
    network_names = nets.map(&:name)
    puts "Validating all #{network_names.length} networks in database..."
  end
  
  checks = ['Connectivity', 'Data Completeness', 'Topology', 'Ranges']
  results = []
  
  network_names.each do |net_name|
    begin
      net_mo = db.model_object(net_name)
      net = net_mo.open
      
      checks.each do |check|
        status = 'PASS'
        issues = 0
        
        case check
        when 'Connectivity'
          # Check for orphaned nodes
          net.row_objects('hw_node').each do |node|
            connected = false
            net.row_objects('hw_conduit').each do |pipe|
              if pipe.us_node_id == node.id || pipe.ds_node_id == node.id
                connected = true
                break
              end
            end
            issues += 1 unless connected
          end
          
        when 'Data Completeness'
          # Check for missing required fields
          net.row_objects('hw_conduit').each do |pipe|
            issues += 1 unless pipe.roughness rescue true
            issues += 1 unless pipe.length rescue true
          end
          
        when 'Topology'
          # Check for circular references (simplified)
          net.row_objects('hw_conduit').each do |pipe|
            issues += 1 if pipe.us_node_id == pipe.ds_node_id rescue false
          end
          
        when 'Ranges'
          # Check for unrealistic values
          net.row_objects('hw_conduit').each do |pipe|
            roughness = pipe.roughness rescue nil
            issues += 1 if roughness && (roughness < 0.001 || roughness > 1.0)
          end
        end
        
        status = issues > 0 ? 'FAIL' : 'PASS'
        
        results << {network: net_name, check: check, status: status, issues: issues}
      end
      
      net.close
      
    rescue => e
      puts "  ✗ Error validating #{net_name}: #{e.message}"
    end
  end
  
  if results.empty?
    puts "No validation results collected"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  csv_file = File.join(output_dir, 'validation_results.csv')
  
  File.open(csv_file, 'w') do |f|
    f.puts "Network,Check,Status,Issues"
    results.each { |r| f.puts "#{r[:network]},#{r[:check]},#{r[:status]},#{r[:issues]}" }
  end
  
  failed = results.count { |r| r[:status] == 'FAIL' }
  puts "✓ Validation complete: #{csv_file}"
  puts "  - Networks checked: #{networks.length}"
  puts "  - Failed checks: #{failed}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



