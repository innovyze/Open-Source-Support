# =============================================================================
# InfoWorks ICM - Batch Copy Databases to Cloud
# =============================================================================
# Copies multiple source databases to a single cloud destination.
# Each database is copied in a separate ICM process to prevent crashes.
#
# Configuration:
#   1. Set destination_db below to your cloud database path
#   2. Edit batch.csv with source database paths (one per line)
#   3. Run via Batch_Exchange.bat
#
# Features:
#   - Process isolation prevents transportable database crashes
#   - Robust CSV encoding handling (UTF-8, Windows-1252, BOM)
#   - Success/failure summary with detailed reporting
# =============================================================================

require 'csv'

# Destination database - set this to your target cloud database
destination_db = 'cloud://UserName@1234567890abcdef/region' #'cloud://NAME@IDSTRING/REGION'

# Path to ICMExchange and the single copy script
icm_exchange = 'C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2026\ICMExchange'
copy_script = File.expand_path('Copy_all_to_cloud.rb', __dir__)

# Read your CSV file into an array of arrays with robust encoding handling
begin
  csv_data = CSV.read('batch.csv', encoding: 'UTF-8')
rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
  # Fallback to Windows-1252 (Windows ANSI) if UTF-8 fails
  begin
    csv_data = CSV.read('batch.csv', encoding: 'Windows-1252:UTF-8')
  rescue
    # Final fallback: try with BOM|UTF-8
    csv_data = CSV.read('batch.csv', encoding: 'BOM|UTF-8:UTF-8')
  end
end

successful_copies = []
failed_copies = []

# Iterate over each row in your CSV file
csv_data.each do |row|
  # Skip empty rows
  next if row.nil? || row[0].nil? || row[0].strip.empty?
  
  source_db = row[0]
  
  puts "Processing #{source_db}..."
  
  # Spawn a new ICMExchange process for complete transaction isolation
  command = "\"#{icm_exchange}\" \"#{copy_script}\" \"#{source_db}\" \"#{destination_db}\" /ICM"
  output = `#{command} 2>&1`
  puts output
  
  # Check if the copy actually succeeded by looking for the success message
  if output =~ /All root data copied/
    successful_copies << source_db
  else
    failed_copies << source_db
  end
  
  sleep(2)
end

puts "\n=== Copy Summary ==="
puts "#{successful_copies.length} of #{successful_copies.length + failed_copies.length} databases successfully copied."
if failed_copies.any?
  puts "These databases failed:"
  failed_copies.each { |db| puts "  - #{db}" }
end