# Script: 03_network_metadata_comparator.rb
# Context: Exchange
# Purpose: Compare network metadata across databases
# Outputs: HTML comparison table
# Usage: ruby script.rb [database_path1] [database_path2] ...
#        If no args, uses current database and all networks

begin
  puts "Network Metadata Comparator - Starting..."
  $stdout.flush
  
  # Get databases to compare
  db_paths = ARGV.length > 0 ? ARGV : [nil]  # nil = most recent
  
  networks = []
  
  db_paths.each do |db_path|
    begin
      db = db_path ? WSApplication.open(db_path) : WSApplication.open()
      db_name = db_path || "Current Database"
      
      # Get all networks in this database
      db.model_object_collection('Model Network').each do |net_mo|
        begin
          # Get network metadata
          modified_date = net_mo.modified_date rescue nil
          modified_str = modified_date ? modified_date.strftime('%Y-%m-%d') : 'Unknown'
          
          # Count scenarios (sims associated with this network)
          scenario_count = 0
          begin
            db.model_object_collection('Sim').each do |sim|
              # Check if sim belongs to this network's parent group
              if sim.parent_id == net_mo.parent_id rescue false
                scenario_count += 1
              end
            end
          rescue
            # If counting fails, just use 0
          end
          
          # Get file size (if available)
          file_size_mb = net_mo.file_size rescue nil
          size_str = file_size_mb ? "#{(file_size_mb / 1024.0 / 1024.0).round(1)}" : 'N/A'
          
          # Get version (if available)
          version = net_mo.version rescue 'Unknown'
          
          networks << {
            name: net_mo.name,
            database: db_name,
            version: version.to_s,
            modified: modified_str,
            size_mb: size_str,
            scenarios: scenario_count
          }
        rescue => e
          puts "  Warning: Could not read metadata for #{net_mo.name}: #{e.message}"
        end
      end
    rescue => e
      puts "  Warning: Could not open database #{db_path || 'current'}: #{e.message}"
    end
  end
  
  if networks.empty?
    puts "No networks found to compare"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'network_comparison.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Network Comparison</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:12px;border-bottom:1px solid #ddd}th{background:#1976d2;color:white}tr:hover{background:#f5f5f5}</style></head>"
  html += "<body><div class='container'><h1>Network Metadata Comparison</h1>"
  html += "<p><strong>Databases compared:</strong> #{db_paths.length}</p>"
  html += "<table><tr><th>Network</th><th>Database</th><th>Version</th><th>Last Modified</th><th>Size (MB)</th><th>Scenarios</th></tr>"
  
  networks.each { |n| html += "<tr><td>#{n[:name]}</td><td>#{n[:database]}</td><td>#{n[:version]}</td><td>#{n[:modified]}</td><td>#{n[:size_mb]}</td><td>#{n[:scenarios]}</td></tr>" }
  
  html += "</table></div></body></html>"
  File.write(html_file, html)
  
  puts "✓ Comparison generated: #{html_file}"
  puts "  - Networks compared: #{networks.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  puts e.backtrace.join("\n")
  $stdout.flush
  exit 1
end



