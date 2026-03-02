# InfoWorks ICM - Run Mesh Job
# EXCHANGE Script
#
# Usage: ICMExchange.exe EX_Script.rb <database_path> <network_id> <scenario_name> <ground_model_id>
#
# Arguments (ICMExchange auto-injects ARGV[0]="ADSK" only):
#   ARGV[1] - Database path (cloud://... or local path)
#   ARGV[2] - Network ID
#   ARGV[3] - Scenario name
#   ARGV[4] - Ground Model ID (positive for grid, negative for TIN)

if ARGV.length < 5
  puts "❌ ERROR: Missing required arguments"
  puts "Usage: ICMExchange.exe script.rb <database_path> <network_id> <scenario_name> <ground_model_id>"
  exit(1)
end

DATABASE_PATH = ARGV[1]
NETWORK_ID = ARGV[2].to_i
SCENARIO_NAME = ARGV[3]
GROUND_MODEL_ID = ARGV[4].to_i

puts "=" * 80
puts "RUNNING MESH JOB"
puts "=" * 80
puts ""
puts "Database: #{DATABASE_PATH}"
puts "Network ID: #{NETWORK_ID}"
puts "Scenario: #{SCENARIO_NAME}"
puts "Ground Model ID: #{GROUND_MODEL_ID}"
puts ""

begin
  # Open database
  db = WSApplication.open(DATABASE_PATH)
  puts "✓ Database opened"
  
  # Get the network
  network = db.model_object_from_type_and_id('Model Network', NETWORK_ID)
  
  if network.nil?
    puts "❌ ERROR: Network with ID #{NETWORK_ID} not found"
    exit(1)
  end
  
  puts "✓ Found network"
  
  # Open the network
  net = network.open
  puts "✓ Network opened"
  
  # Set scenario
  puts ""
  puts "Setting scenario to '#{SCENARIO_NAME}'..."
  net.current_scenario = SCENARIO_NAME
  puts "✓ Scenario set"
  
  # Configure mesh options
  puts ""
  puts "Configuring mesh options..."
  
  mesh_options = {
    'GroundModel' => GROUND_MODEL_ID,
    '2DZones' => nil,  # nil means all 2D zones
    'LowerElementGroundLevels' => false,
    # 'VoidsCategory' => 'buildings',  # Use polygons with category 'buildings' as voids
    'RunOn' => '.'  # Run on this computer
  }
  
  puts "✓ Options configured"
  puts "  - Ground Model ID: #{GROUND_MODEL_ID}"
  puts "  - 2D Zones: All"
  puts "  - Lower Element Ground Levels: false"
  puts "  - Voids Category: buildings"
  
  # Run mesh job
  puts ""
  puts "🔧 Starting mesh job..."
  puts "⏳ This may take several minutes..."
  puts ""
  
  results = net.mesh(mesh_options)
  
  # Check results
  puts ""
  puts "Mesh job completed!"
  puts ""
  puts "Results per 2D Zone:"
  
  success_count = 0
  failure_count = 0
  
  results.each do |zone_name, success|
    if success
      puts "  ✓ #{zone_name}: SUCCESS"
      success_count += 1
    else
      puts "  ❌ #{zone_name}: FAILED"
      failure_count += 1
    end
  end
  
  puts ""
  puts "Summary: #{success_count} successful, #{failure_count} failed"
  
  # Commit changes
  puts ""
  puts "💾 Committing network..."
  net.commit("Meshed #{success_count} zones in scenario '#{SCENARIO_NAME}'")
  puts "✓ Network committed"
  
  net.close
  db.close
  
  puts ""
  puts "=" * 80
  if failure_count == 0
    puts "✓ All mesh jobs completed successfully"
  else
    puts "⚠️  Mesh completed with #{failure_count} failure(s)"
    raise "Mesh job completed with #{failure_count} failure(s)"
  end
  puts "=" * 80
  
rescue => e
  puts ""
  puts "=" * 80
  puts "❌ ERROR: #{e.message}"
  puts e.backtrace.first(5).join("\n") if e.backtrace
  puts "=" * 80
  raise  # Re-raise to signal failure to ICMExchange
end
