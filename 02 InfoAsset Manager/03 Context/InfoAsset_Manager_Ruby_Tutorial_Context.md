# InfoAsset Manager Ruby Tutorial Context

**Purpose:** Multi-step worked workflows for InfoAsset Manager Ruby scripting. Each workflow demonstrates how to combine patterns from `InfoAsset_Manager_Ruby_Patterns_Extended.md` (and the `_UI/Exchange/DualMode` files) into a complete, real-world task.

**Target Audience:** LLMs generating new scripts; human reviewers verifying generated output.

**Source Conventions:**
- These are illustrative scaffolds — not production-ready scripts.
- Paths, IDs, field names, and table names are placeholders unless marked otherwise.
- Each workflow references the patterns it combines.

> **WARNING — Placeholders Only**  
> Replace every path, database address, network ID, field name, and config path with task-specific values.

---

## TUT_IAM_001 — Bulk Field Update From External CSV (Exchange)

**Task:** Read an external CSV file with an ID column and a new value column. For every matching object in the network, update a specified field and write back.

**Combines:** PAT_IAM_EX_001, PAT_IAM_EX_005, PAT_IAM_DUAL_009

```ruby
require 'csv'

# --- Configuration (replace all placeholders) ---
DB_PATH      = '//localhost:40000/Databasename'  # PLACEHOLDER
NETWORK_ID   = 1                                  # PLACEHOLDER
NETWORK_TYPE = 'Collection Network'               # PLACEHOLDER
CSV_PATH     = 'C:\\Temp\\update_data.csv'        # PLACEHOLDER — source CSV
CSV_ID_COL   = 'ASSET_ID'                         # PLACEHOLDER — CSV header for the ID
CSV_VAL_COL  = 'NEW_VALUE'                        # PLACEHOLDER — CSV header for the value
TABLE        = 'cams_manhole'                     # PLACEHOLDER — target table
ID_FIELD     = 'node_id'                          # PLACEHOLDER — object ID field
DEST_FIELD   = 'user_text_1'                      # PLACEHOLDER — field to update

# --- Load lookup hash from CSV ---
lookup = {}
CSV.foreach(CSV_PATH, headers: true) do |row|
  lookup[row[CSV_ID_COL].to_s.strip] = row[CSV_VAL_COL].to_s.strip
end
puts "Loaded #{lookup.size} rows from CSV."

# --- Open database ---
db     = WSApplication.open(DB_PATH, false)
net_mo = db.model_object_from_type_and_id(NETWORK_TYPE, NETWORK_ID)
net    = net_mo.open

# --- Update matching rows ---
updated = 0
net.transaction_begin

net.row_objects(TABLE).each do |ro|
  key = ro[ID_FIELD].to_s
  if lookup.key?(key)
    ro[DEST_FIELD] = lookup[key]
    ro.write
    updated += 1
  end
end

net.transaction_commit
puts "Updated #{updated} objects."

# --- Commit to version history ---
net_mo.commit("Bulk field update from #{File.basename(CSV_PATH)}: #{updated} rows updated.")
```

**Key steps explained:**
1. Load the CSV into a Ruby hash for O(1) lookup (avoids re-scanning the CSV per row).
2. Open the network in Exchange mode.
3. Iterate all rows of the target table — use `ro[ID_FIELD]` bracket notation so the field name is configurable.
4. Write only rows that match — skip unchanged rows for performance.
5. Commit after `transaction_commit` to persist to the database version history.

---

## TUT_IAM_002 — CCTV Survey Export for Selection (UI)

**Task:** The user selects a set of pipes on the GeoPlan. The script generates an individual CCTV survey report for each survey associated with those pipes.

**Combines:** PAT_IAM_UI_002, PAT_IAM_DUAL_008, PAT_IAM_DUAL_006, PAT_IAM_UI_004

```ruby
require 'fileutils'

# --- Configuration ---
OUTPUT_FOLDER = 'C:\\Temp\\Reports'  # PLACEHOLDER
REPORT_FORMAT = 'MSCC'               # PLACEHOLDER — nil for default, 'MSCC', 'PACP'

net = WSApplication.current_network
raise 'No open network' if net.nil?

# --- Prompt for output folder ---
vals = WSApplication.prompt(
  'CCTV Survey Report Export',
  [
    ['Output folder:', 'String', OUTPUT_FOLDER, nil, 'FOLDER', 'Select output folder'],
    ['Report format (nil/MSCC/PACP):', 'String', REPORT_FORMAT],
  ],
  false
)

if vals.nil?
  WSApplication.message_box('Cancelled.', 'OK', '!', nil)
  raise 'abort'
end

output_folder = vals[0].to_s.strip
report_format = vals[1].to_s.strip
report_format = nil if report_format.empty? || report_format.downcase == 'nil'

FileUtils.mkdir_p(output_folder) unless Dir.exist?(output_folder)

# --- Get selected pipes ---
pipes = net.row_object_collection_selection('cams_pipe')
if pipes.length == 0
  WSApplication.message_box('No pipes selected. Select at least one pipe and try again.', 'OK', '!', nil)
  raise 'abort'
end

# --- For each pipe, navigate to CCTV surveys and report ---
report_count = 0

pipes.each do |pipe|
  surveys = pipe.navigate('cctv_surveys')
  next if surveys.empty?

  surveys.each do |survey|
    net.clear_selection
    survey.selected = true

    safe_id = survey['id'].to_s.gsub(/[^0-9A-Za-z_-]/, '--')
    output_path = File.join(output_folder, "CCTV_#{safe_id}.doc")

    net.generate_report('cams_cctv_survey', report_format, survey['id'], output_path)
    report_count += 1
  end
end

WSApplication.message_box(
  "#{report_count} report(s) exported to:\n#{output_folder}",
  'OK', 'Information', nil
)
```

**Key steps explained:**
1. Prompt for output folder and report format so the script is configurable without editing source code.
2. Guard against empty selection with a clear message.
3. Navigate each selected pipe to its CCTV surveys using `navigate('cctv_surveys')`.
4. For each survey, set it as the only selected object before calling `generate_report`.
5. Sanitise the survey ID for use in the file name.

---

## TUT_IAM_003 — Database Object Inventory Report (Exchange)

**Task:** Connect to a database, list all model objects of a specified type, and write a summary CSV report showing object IDs, names, and types.

**Combines:** PAT_IAM_EX_001, PAT_IAM_DUAL_009 (Exchange pattern only)

```ruby
require 'csv'

# --- Configuration ---
DB_PATH     = '//localhost:40000/Databasename'  # PLACEHOLDER
OBJECT_TYPE = 'Collection Network'              # PLACEHOLDER — or 'Selection List', etc.
OUTPUT_CSV  = 'C:\\Temp\\db_inventory.csv'      # PLACEHOLDER

db = WSApplication.open(DB_PATH, false)

objects = db.model_object_collection(OBJECT_TYPE)

CSV.open(OUTPUT_CSV, 'w', write_headers: true, headers: ['ID', 'Name', 'Type']) do |csv|
  objects.each do |mo|
    csv << [mo.id, mo.name, mo.type]
  end
end

puts "Inventory written to #{OUTPUT_CSV} — #{objects.length} objects found."
```

**Key steps explained:**
1. `db.model_object_collection(type)` returns all objects of that type in the database.
2. Each `WSModelObject` has `.id`, `.name`, `.type` properties.
3. Writing to CSV provides a portable inventory that can be imported into Excel.
4. No `transaction_begin` needed — this script only reads.

**Variations:**
- Replace `OBJECT_TYPE` with `'Theme'`, `'Stored Query'`, `'Asset Group'`, etc. to inventory other object types.
- Add `mo.last_modified_date` (if available) to the CSV for audit trail data.

---

## TUT_IAM_004 — Conditional Field Update With Transaction and Error Handling (UI)

**Task:** Iterate all pipes in the network. If a pipe meets a condition (e.g., diameter is null or zero), apply a default value to a specified field. Report how many were updated.

**Combines:** PAT_IAM_UI_001, PAT_IAM_UI_002, PAT_IAM_DUAL_010, PAT_IAM_DUAL_011

```ruby
# --- Configuration ---
TABLE        = 'cams_pipe'     # PLACEHOLDER
CHECK_FIELD  = 'diameter'      # PLACEHOLDER — field to check
UPDATE_FIELD = 'user_text_1'   # PLACEHOLDER — field to update
UPDATE_VALUE = 'CHECK_REQUIRED' # PLACEHOLDER — value to write

net = WSApplication.current_network

# --- Prompt for confirmation ---
vals = WSApplication.prompt(
  'Conditional Update',
  [
    ['Set "' + UPDATE_FIELD + '" where "' + CHECK_FIELD + '" is blank?', 'Boolean', true],
  ],
  false
)

if vals.nil? || vals[0] != true
  WSApplication.message_box('Update cancelled.', 'OK', '!', nil)
  raise 'abort'
end

# --- Main update logic with error handling ---
begin
  updated = 0
  skipped = 0

  net.transaction_begin

  net.row_objects(TABLE).each do |ro|
    val = ro[CHECK_FIELD]
    if val.nil? || val.to_s.strip.empty? || val == 0
      ro[UPDATE_FIELD] = UPDATE_VALUE
      ro.write
      updated += 1
    else
      skipped += 1
    end
  end

  net.transaction_commit

  WSApplication.message_box(
    "Update complete.\nUpdated: #{updated}\nSkipped: #{skipped}",
    'OK', 'Information', nil
  )

rescue => e
  begin
    net.transaction_rollback
  rescue
    # rollback may fail if transaction was never opened
  end
  WSApplication.message_box("Script failed:\n#{e.message}", 'OK', 'Stop', nil)
  raise e
end
```

**Key steps explained:**
1. Prompt the user for confirmation before making changes.
2. Use `raise 'abort'` (not `exit`) to stop cleanly if cancelled.
3. Wrap the entire write loop in `begin/rescue` to catch errors and attempt rollback.
4. Call `transaction_rollback` in the rescue block to undo partial writes.
5. Use bracket notation `ro[CHECK_FIELD]` since field names come from configuration constants.
6. Check for `nil`, empty string, and zero to cover common "blank" representations.
