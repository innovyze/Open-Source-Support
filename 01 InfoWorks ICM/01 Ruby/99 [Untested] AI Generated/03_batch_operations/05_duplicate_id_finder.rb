# Script: 05_duplicate_id_finder.rb
# Context: Exchange
# Purpose: Cross-database duplicate ID finder and reporter
# Outputs: HTML report with duplicates
# Usage: ruby script.rb [database_path1] [database_path2] [database_path3] ...
#        If no args, searches current database for duplicates

begin
  puts "Duplicate ID Finder - Starting..."
  $stdout.flush
  
  # Get databases to check
  if ARGV.length > 0
    db_paths = ARGV
  else
    # Use current database
    db = WSApplication.open()
    db_paths = [nil]
  end
  
  databases = {}
  
  db_paths.each do |db_path|
    begin
      db = db_path ? WSApplication.open(db_path) : WSApplication.open()
      db_name = db_path || 'Current Database'
      
      ids = []
      
      # Collect IDs from networks
      nets = db.model_object_collection('Model Network')
      nets.each do |net_mo|
        net = net_mo.open
        
        net.row_objects('hw_node').each { |node| ids << node.id }
        net.row_objects('hw_conduit').each { |pipe| ids << pipe.id }
        net.row_objects('hw_pump').each { |pump| ids << pump.id }
        net.row_objects('hw_storage').each { |storage| ids << storage.id }
        
        net.close
      end
      
      databases[db_name] = ids
      
    rescue => e
      puts "  ✗ Error processing #{db_path}: #{e.message}"
    end
  end
  
  if databases.empty?
    puts "No databases processed"
    exit 0
  end
  
  # Find duplicates
  all_ids = databases.values.flatten
  duplicates = all_ids.select { |id| all_ids.count(id) > 1 }.uniq
  
  duplicate_details = duplicates.map do |id|
    dbs = databases.select { |db, ids| ids.include?(id) }.keys
    {id: id, count: all_ids.count(id), databases: dbs.join(', ')}
  end
  
  if duplicates.empty?
    puts "No duplicate IDs found"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'duplicate_ids.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Duplicate IDs</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#f44336}.alert{padding:15px;background:#ffebee;border-left:4px solid #c62828;margin:20px 0}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd}th{background:#f44336;color:white}</style></head>"
  html += "<body><div class='container'><h1>⚠️ Duplicate ID Analysis</h1>"
  html += "<div class='alert'><strong>#{duplicates.length} duplicate IDs</strong> found across #{databases.length} databases</div>"
  html += "<table><tr><th>ID</th><th>Occurrences</th><th>Found In Databases</th></tr>"
  
  duplicate_details.each { |d| html += "<tr><td>#{d[:id]}</td><td>#{d[:count]}</td><td>#{d[:databases]}</td></tr>" }
  
  html += "</table></div></body></html>"
  File.write(html_file, html)
  puts "✓ Duplicate analysis: #{html_file}"
  puts "  - Duplicates found: #{duplicates.length}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



