# Context: Exchange
# Purpose: Validate an InfoWorks network and print all validation messages
# Method: Opens the network, runs validate for the specified scenario,
#         and reports errors, warnings, and informational messages

# =============================================================================
# CONFIGURATION
# =============================================================================
NETWORK_ID    = 123    # Required: Integer ID of the Model Network to validate
DATABASE_PATH = nil    # nil = last opened database
                       # or e.g. 'snumbat://localhost:40000/My Database' or 'C:/Data/model.icmm'
SCENARIO      = 'Base' # Scenario name to validate
# =============================================================================

db = nil

begin
  puts "=" * 60
  puts "Network Validation"
  puts "=" * 60

  if NETWORK_ID.nil?
    puts "ERROR: NETWORK_ID not configured. Edit the script and set NETWORK_ID."
    exit 1
  end

  if DATABASE_PATH.nil?
    db = WSApplication.open
  else
    db = WSApplication.open(DATABASE_PATH, false)
  end

  raise 'Could not open database' if db.nil?
  puts "Database : #{db.path}"

  network = db.model_object_from_type_and_id('Model Network', NETWORK_ID)
  raise "No 'Model Network' found with ID #{NETWORK_ID}" if network.nil?
  puts "Network  : #{network.name} (ID: #{network.id})"
  puts "Scenario : #{SCENARIO}"
  puts ""

  net = network.open
  raise 'Could not open network' if net.nil?

  validations = net.validate(SCENARIO)

  puts "Errors   : #{validations.error_count}"
  puts "Warnings : #{validations.warning_count}"
  puts "Total    : #{validations.length}"
  puts ""

  if validations.length == 0
    puts "Network is valid - no messages."
  else
    puts "-" * 60
    validations.each { |v| puts v.message }
    puts "-" * 60
  end

rescue => e
  puts "ERROR: #{e.message}"
ensure
  db.close if db
end
