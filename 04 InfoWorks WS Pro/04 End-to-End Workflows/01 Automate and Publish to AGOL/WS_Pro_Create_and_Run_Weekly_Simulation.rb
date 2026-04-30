# =============================================================================
# WS Pro — Step 1: Create and run a weekly simulation (Exchange script)
# =============================================================================
#
# PURPOSE
#   Creates a new Wesnet Run inside a specified Run Group, assigns fixed network /
#   control / demand IDs, sets the simulation window (today → today + N days),
#   fires the run, and writes the new run's ID to a marker file so Step 2 can
#   find and export the correct simulation without guessing.
#
# WORKFLOW
#   Step 1  →  this script
#   Step 2  →  WS_Pro_Export_Simulation_Results_to_Shapefile.rb
#   Step 3  →  Publish_WS_Pro_Weekly_Shapefiles_to_AGOL.py
#   Orchestrate all three with Run_All_Weekly_WS_Pro_Workflow.bat
#
# QUICK START
#   1. Open your WS Pro database in Explorer and note the numeric Model Object IDs
#      for your Run Group, a reference run, the network geometry, control, and
#      demand diagram.  Update the constants in the CONFIGURATION block below.
#   2. Set DB_PATH to your InfoWorks WS Pro database connection string.
#   3. Set MARKER_FILE to a path accessible by Step 2 on the same machine.
#   4. Run via:
#        WSProExchange.exe "<path>\WS_Pro_Create_and_Run_Weekly_Simulation.rb" /WS
#
# HOW TO FIND MODEL OBJECT IDs
#   In InfoWorks WS Pro Explorer, right-click any object → Properties.
#   The numeric "ID" shown is the Model Object ID used in this script.
#
# =============================================================================

require 'date'
require 'fileutils'

# ===========================================================================
# CONFIGURATION — fill in every value below before running
# ===========================================================================

# InfoWorks WS Pro database path.
# Local file example:   'C:\WS Pro Models\MyProject.iws'
# Cloud example:        'cloud://Organisation Name@orgid/database'
DB_PATH = 'cloud://YOUR_ORG_NAME@YOUR_ORG_ID/YOUR_DATABASE'

# Model Object ID of the Wesnet Run Group where new runs will be created.
RUN_GROUP_ID = 0  # e.g. 1234

# Model Object ID of an existing run.  Used only to confirm the object exists
# before the scheduler is called; parameters are NOT copied from it.
TEMPLATE_RUN_ID = 0  # e.g. 5678

# Model Object IDs for the three fixed simulation inputs.
# These are applied to every new run created by this script.
NETWORK_ID = 0  # Network geometry   e.g. 1001
CONTROL_ID = 0  # Control            e.g. 1002
DEMAND_ID  = 0  # Demand diagram     e.g. 1003

# Length of each simulation in days (start = today 00:00, end = today + N days 00:00).
SIMULATION_DAYS = 7

# Path to the marker file shared with Step 2.
# Step 2 reads this file to export the exact run created here.
MARKER_FILE = 'C:\\WS Pro Results\\last_export_run_id.txt'

# WS Pro type strings tried in order when looking up model objects by ID.
# These rarely need changing.
RUN_GROUP_TYPES = ['Wesnet Run Group', 'Run Group'].freeze
RUN_TYPES       = ['Wesnet Run',       'Run'      ].freeze

# ===========================================================================
# END CONFIGURATION
# ===========================================================================


# Find a model object by numeric ID, trying each type string in sequence.
def find_object(db, type_names, id)
  type_names.each do |t|
    mo = db.model_object_from_type_and_id(t, id) rescue nil
    return mo if mo
  end
  nil
end

# ---------------------------------------------------------------------------
# Start-up validation
# ---------------------------------------------------------------------------
if RUN_GROUP_ID == 0 || TEMPLATE_RUN_ID == 0 || NETWORK_ID == 0 || CONTROL_ID == 0 || DEMAND_ID == 0
  puts 'ERROR: One or more IDs in the CONFIGURATION block are still set to 0.'
  puts '       Update DB_PATH, RUN_GROUP_ID, TEMPLATE_RUN_ID, NETWORK_ID, CONTROL_ID, and DEMAND_ID.'
  exit 1
end

if DB_PATH.include?('YOUR_')
  puts 'ERROR: DB_PATH has not been configured. Set it to your WS Pro database connection string.'
  exit 1
end

scheduler_cls = (Object.const_get(:WSRunScheduler) rescue nil)
if scheduler_cls.nil?
  puts 'ERROR: WSRunScheduler is not available. Run this script with WSProExchange.exe /WS.'
  exit 1
end

db = WSApplication.open(DB_PATH, false)

run_group = find_object(db, RUN_GROUP_TYPES, RUN_GROUP_ID)
if run_group.nil?
  puts "ERROR: Run Group ID #{RUN_GROUP_ID} not found in the database."
  exit 1
end
puts "Run group : #{run_group.path} (id=#{run_group.id})"

template_run = find_object(db, RUN_TYPES, TEMPLATE_RUN_ID)
if template_run.nil?
  puts "ERROR: Template run ID #{TEMPLATE_RUN_ID} not found in the database."
  exit 1
end
puts "Template  : #{template_run.path} (id=#{template_run.id})"

# ---------------------------------------------------------------------------
# Build simulation window and run title
# ---------------------------------------------------------------------------
now      = Time.now
start_dt = DateTime.new(now.year, now.mon, now.day, 0, 0, 0)
end_t    = now + (SIMULATION_DAYS * 86_400)
end_dt   = DateTime.new(end_t.year, end_t.mon, end_t.day, 0, 0, 0)

# Timestamp suffix keeps the title unique when the workflow runs more than once per day
run_title = "Weekly #{now.mon}/#{now.day}/#{now.year} (#{SIMULATION_DAYS}d) #{now.strftime('%Y%m%d_%H%M%S')}"

puts "Simulation: #{start_dt} → #{end_dt}"
puts "Title     : #{run_title}"
puts "Inputs    : Network=#{NETWORK_ID}  Control=#{CONTROL_ID}  Demand=#{DEMAND_ID}"

# ---------------------------------------------------------------------------
# Create, configure, validate, save, and run
# ---------------------------------------------------------------------------
run_opts = {
  'ro_l_geometry_id'       => NETWORK_ID,
  'ro_l_control_id'        => CONTROL_ID,
  'ro_l_demand_diagram_id' => DEMAND_ID,
  'ro_dte_start_date_time' => start_dt,
  'ro_dte_end_date_time'   => end_dt,
  'ro_s_run_title'         => run_title
}

scheduler = scheduler_cls.new
scheduler.create_new_run(run_group.id)
scheduler.set_parameters(run_opts)

# Validation log written next to this script for easy review
validation_log = File.join(File.dirname(WSApplication.script_file), 'ws_pro_weekly_run_validation.txt')
File.write(validation_log, '') rescue nil
scheduler.validate(validation_log)

scheduler.save(false)
run_mo = scheduler.get_run_mo
if run_mo.nil?
  puts 'ERROR: Scheduler returned nil after save — check the validation log.'
  exit 1
end

puts "Running   : #{run_mo.path} (id=#{run_mo.id})"
run_mo.run
puts "Status    : #{run_mo.respond_to?(:status) ? run_mo.status : 'unknown'}"

# ---------------------------------------------------------------------------
# Write marker file for Step 2
# ---------------------------------------------------------------------------
begin
  FileUtils.mkdir_p(File.dirname(MARKER_FILE))
  File.write(MARKER_FILE, run_mo.id.to_s)
  puts "Marker written: #{MARKER_FILE}"
rescue => e
  puts "WARNING: Could not write marker file: #{e.message}"
end

puts 'Done.'
