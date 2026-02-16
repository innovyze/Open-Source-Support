# EXCHANGE SCRIPT
# Export Subcatchments from Multiple InfoWorks Networks via ODEC
# Reads network IDs from CSV file and exports subcatchments for networks marked for export

require 'csv'

# ============================================================================
# CONFIGURATION - Update these variables as needed
# ============================================================================

# Database connection string (Cloud://, //localhost:40000/DbName, or local path)
DATABASE_PATH = 'Cloud://'

# ============================================================================
# SCRIPT START
# ============================================================================

# Get script directory for relative paths
script_dir = File.dirname(WSApplication.script_file)

# Define file paths
csv_file = File.join(script_dir, 'Network_list.csv')
config_file = File.join(script_dir, 'config.cfg')

# Validate required files exist
unless File.exist?(csv_file)
  puts "ERROR: CSV file not found: #{csv_file}"
  return
end

unless File.exist?(config_file)
  puts "ERROR: Config file not found: #{config_file}"
  return
end

puts "============================================="
puts "ODEC Subcatchment Export from CSV"
puts "============================================="
puts "Database: #{DATABASE_PATH}"
puts "CSV File: #{csv_file}"
puts "Config File: #{config_file}"
puts "============================================="

# Open database connection
begin
  db = WSApplication.open(DATABASE_PATH, false)
  puts "Database connection opened successfully"
rescue => e
  puts "ERROR: Failed to open database: #{e.message}"
  return
end

# Read CSV and collect networks to export
networks_to_export = []

begin
  CSV.foreach(csv_file, headers: true) do |row|
    network_id = row[2]      # Column 3: Network ID
    export_flag = row[3]     # Column 4: Export flag (1 or 0)
    network_name = row[1]    # Column 2: Network name (for logging)
    
    # Skip if columns are nil or empty
    next if network_id.nil? || network_id.strip.empty?
    next if export_flag.nil? || export_flag.strip.empty?
    
    # Add to export list if flag is 1
    if export_flag.to_i == 1
      networks_to_export << {
        id: network_id.to_i,
        name: network_name || "Network #{network_id}"
      }
    end
  end
rescue => e
  puts "ERROR: Failed to read CSV file: #{e.message}"
  return
end

puts "\nFound #{networks_to_export.length} network(s) marked for export"
puts "---------------------------------------------"

# Exit if no networks to export
if networks_to_export.empty?
  puts "No networks marked for export (column 4 = 1)"
  return
end

# Counters for summary
successful_exports = 0
failed_exports = 0

# Process each network
networks_to_export.each do |network_info|
  network_id = network_info[:id]
  network_name = network_info[:name]
  
  puts "\nProcessing Network ID: #{network_id} (#{network_name})"
  
  begin
    # Get network model object
    mo = db.model_object_from_type_and_id('Model Network', network_id)
    
    if mo.nil?
      puts "  WARNING: Network ID #{network_id} not found in database"
      failed_exports += 1
      next
    end
    
    # Open the network
    net = mo.open
    puts "  Network opened: #{mo.name}"
    
    # Configure ODEC export options
    options = Hash.new
    options['Error File'] = File.join(script_dir, "export_errors_#{network_id}.txt")
    options['Units Behaviour'] = 'User'          # Export in user units
    options['Export Selection'] = false          # Export all subcatchments
    
    # Define export file path
    export_file = File.join(script_dir, "subcatchments_#{network_id}.shp")
    
    # Execute ODEC export
    net.odec_export_ex(
      'SHP',                    # Export format
      config_file,              # Config file path
      options,                  # Export options
      'hw_subcatchment',        # Table to export
      export_file               # Output file path
    )
    
    puts "  SUCCESS: Exported to #{File.basename(export_file)}"
    successful_exports += 1
    
  rescue => e
    puts "  ERROR: Export failed - #{e.message}"
    failed_exports += 1
  end
end

# Print summary
puts "\n============================================="
puts "EXPORT SUMMARY"
puts "============================================="
puts "Total networks processed: #{networks_to_export.length}"
puts "Successful exports: #{successful_exports}"
puts "Failed exports: #{failed_exports}"
puts "============================================="

puts "\nExport process complete"
return
