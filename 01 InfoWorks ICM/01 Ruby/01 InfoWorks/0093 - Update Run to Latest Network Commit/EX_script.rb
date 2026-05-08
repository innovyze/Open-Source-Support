# Context: Exchange (EX)
# Purpose: Demonstrate how to update an existing run to the latest network commit
#          using update_to_latest. This has the same effect as pressing the
#          "Update to Latest Version of Network" button in the Run view in the ICM UI.

# ============================================================================
# CONFIGURATION
# ============================================================================
# Database path - set to nil to use the most recently opened database
DATABASE_PATH = nil  # e.g., 'C:/MyProject/Database.icmm', or 'cloud://myorg@12345/My Cloud Database'

# ID of the run to update.
RUN_ID = nil  # e.g., 42
# ============================================================================

begin
  puts '=' * 70
  puts 'Update Run to Latest Network Commit'
  puts '=' * 70

  # Open database
  if DATABASE_PATH.nil?
    puts "\nOpening most recently used database..."
    db = WSApplication.open
  else
    puts "\nOpening database: #{DATABASE_PATH}"
    db = WSApplication.open(DATABASE_PATH, false)
  end

  if db.nil?
    puts 'ERROR: Failed to open database'
    exit 1
  end

  puts "Database opened: #{db.path}"

  # All three conditions below must be satisfied before calling update_to_latest, otherwise an exception will be raised by Exchange:
  #   a) The run's 'Working' field must be set to true
  #   b) There must be no uncommitted changes for the run's network
  #   c) All scenarios set up for the run must still exist and be valid

  if RUN_ID.nil?
    puts 'ERROR: RUN_ID not configured. Set RUN_ID at the top of this script.'
    exit 1
  end

  run_obj = db.model_object_from_type_and_id('Run', RUN_ID)

  if run_obj.nil?
    puts "ERROR: Run with ID #{RUN_ID} not found"
    exit 1
  end

  puts "Found run: #{run_obj.name} (ID: #{RUN_ID})"

  unless run_obj['Working']
    puts "ERROR: The run's 'Working' field is false."
    puts "       Set 'Working' to true on the run before calling update_to_latest."
    exit 1
  end

  run_obj.update_to_latest

  puts "Run updated successfully."
  puts "The run now tracks the latest commit (shown as '(latest commit)' in the UI)."

  puts "\nDone."

rescue => e
  puts "\nERROR: #{e.message}"
  puts e.backtrace.first(5).join("\n")
end
