# InfoAsset Manager Ruby Patterns

**Purpose:** Complete IAM Ruby pattern library — production-quality patterns extracted from actual repository scripts.  
**Source Scripts:** `02 InfoAsset Manager/01 Ruby/` folders as indicated per pattern.

> **WARNING — Placeholders Only**  
> Paths, database addresses, network IDs, config file paths, and output paths are illustrative placeholders. Replace every value with task-specific inputs. Do not copy verbatim into production scripts.

---

## PAT_IAM_UI_001 — Open Current Network

**Intent:** Start a UI script from the active network.

```ruby
net = WSApplication.current_network
raise 'No open network' if net.nil?
```

**Use when:** The script runs from Network → Run Ruby Script inside InfoAsset Manager.

**Do not use when:** The script is Exchange-only.

---

## PAT_IAM_UI_002 — Prompt Then Validate

**Intent:** Collect UI input and stop cleanly if the user cancels.

```ruby
net = WSApplication.current_network

values = WSApplication.prompt(
  'Run Options',
  [
    ['Output folder', 'String', nil, nil, 'FOLDER', 'Choose output folder'],
    ['Selection only', 'Boolean', true]
  ],
  false
)

if values.nil?
  WSApplication.message_box('Parameters dialog closed\nScript cancelled', 'OK', '!', nil)
  raise 'abort'
end

output_folder, selection_only = values
```

**Source style:** `0022 Rename Exported Image & Attachment Files`, `0035 Export CCTV Surveys to WSAA XML`, `0040 Convert Coordinate Values`

---

## PAT_IAM_UI_003 — UI Export Wrapper

**Intent:** Run an export from the current network using UI-owned context.

```ruby
net = WSApplication.current_network

options = {}
options['Error File'] = 'C:\\Temp\\export-errors.txt' # PLACEHOLDER

net.odec_export_ex(
  'CSV',
  'C:\\Temp\\export.cfg', # PLACEHOLDER
  options,
  'Pipe',
  'C:\\Temp\\pipe.csv'    # PLACEHOLDER
)
```

---

## PAT_IAM_EX_001 — Open Database And Network

**Intent:** Start an Exchange script with explicit database access.

```ruby
db = WSApplication.open('localhost:40000/database', false) # PLACEHOLDER
network_mo = db.model_object_from_type_and_id('Collection Network', 1) # PLACEHOLDER
net = network_mo.open
```

**Shortcut variant — re-open the most recently used database (no path required):**

```ruby
db = WSApplication.open
```

**Use when:** The script is designed for InfoAsset Exchange.

**Do not use when:** The script runs from the UI and already has an open network.

---

## PAT_IAM_EX_002 — Exchange Import Wrapper

**Intent:** Run an import with an options hash and config file.

```ruby
db = WSApplication.open('localhost:40000/database', false) # PLACEHOLDER
network_mo = db.model_object_from_type_and_id('Collection Network', 1) # PLACEHOLDER
net = network_mo.open

options = {}
options['Error File'] = 'C:\\Temp\\ImportErrorLog.txt' # PLACEHOLDER

net.odic_import_ex(
  'CSV',
  'C:\\Temp\\CSVConfig.cfg', # PLACEHOLDER
  options,
  'pipe',
  'C:\\Temp\\pipe.csv'       # PLACEHOLDER
)
```

**Source style:** `0002 ODIC Import`

---

## PAT_IAM_EX_003 — Exchange Export Wrapper

**Intent:** Run an export in unattended Exchange flow.

```ruby
db = WSApplication.open('localhost:40000/database', false) # PLACEHOLDER
network_mo = db.model_object_from_type_and_id('Collection Network', 1) # PLACEHOLDER
net = network_mo.open

options = {}
options['Error File'] = 'C:\\Temp\\ExportErrors.txt' # PLACEHOLDER

net.odec_export_ex(
  'CSV',
  'C:\\Temp\\export.cfg', # PLACEHOLDER
  options,
  'Pipe',
  'C:\\Temp\\pipe.csv'    # PLACEHOLDER
)
```

**Source style:** `0001 ODEC Export`

---

## PAT_IAM_DUAL_001 — Early Runtime Branch

**Intent:** Split UI and Exchange setup immediately.

```ruby
if WSApplication.ui?
  net = WSApplication.current_network
else
  db = WSApplication.open('localhost:40000/database', false) # PLACEHOLDER
  network_mo = db.model_object_from_type_and_id('Collection Network', 1) # PLACEHOLDER
  net = network_mo.open
end
```

**Use when:** One script must genuinely support both runtimes.

**Do not use when:** Separate `UI-` and `IE-` examples already cover the task cleanly.

> **Exchange setup:** Call `net.revert` after opening to discard any prior uncommitted changes before beginning a fresh creation workflow. `commit` and `revert` can be called on either the model object or the open network.

---

## PAT_IAM_DUAL_002 — Keep UI Interaction In UI Branch

**Intent:** Avoid leaking prompts or dialogs into Exchange.

```ruby
if WSApplication.ui?
  values = WSApplication.prompt('Export Options', [['Selection only', 'Boolean', true]], false)
  return if values.nil?
  selection_only = values[0]
else
  selection_only = false
end
```

**Source style:** `0001 ODEC Export`, `0009 Import-Export MACP-PACP Survey Data`, `0035 Export CCTV Surveys to WSAA XML`

---

## PAT_IAM_DUAL_003 — Shared Network Method After Branch

**Intent:** Branch once, then call a shared network method.

```ruby
if WSApplication.ui?
  net = WSApplication.current_network
else
  db = WSApplication.open('localhost:40000/database', false) # PLACEHOLDER
  network_mo = db.model_object_from_type_and_id('Collection Network', 1) # PLACEHOLDER
  net = network_mo.open
end

options = {}
options['Error File'] = 'C:\\Temp\\export-errors.txt' # PLACEHOLDER

net.odec_export_ex('CSV', 'C:\\Temp\\export.cfg', options, 'Pipe', 'C:\\Temp\\pipe.csv') # PLACEHOLDER
```

---

## PAT_IAM_EX_004 — IE Multi-Network Loop

**Intent:** Iterate over a list of network IDs in Exchange mode and run an operation on each.

**Source:** `0001 ODEC Export/IE-odec_export_ex-CSV-MultipleNetworks.rb`

```ruby
db = WSApplication.open('//localhost:40000/Databasename', false) # PLACEHOLDER

networks = [8, 6] # PLACEHOLDER — list of Collection Network IDs

networks.each do |n|
  net_mo = db.model_object_from_type_and_id('Collection Network', n)
  net    = net_mo.open

  params = {}
  params['Error File'] = "C:\\Temp\\errors_#{n}.txt"  # PLACEHOLDER

  net.odec_export_ex(
    'CSV',
    'C:\\Temp\\export.cfg',         # PLACEHOLDER — config file
    params,
    'Pipe',
    "C:\\Temp\\network_#{n}.csv"    # PLACEHOLDER — output path
  )

  net.close
end
```

**Key points:**
- Call `net.close` after each iteration to release resources (observed in repo examples; not formally documented).
- Use a separate output path per network to avoid overwriting.

---

## PAT_IAM_EX_005 — Row Update With External CSV Lookup + Transaction

**Intent:** Read an external CSV into a lookup hash, then update a field on each matching row object.

**Source:** `0013 Update from external CSV/UI-UpdateFromExternalCSV.rb`

```ruby
require 'csv'

lookup = {}
CSV.foreach('C:\\Temp\\input.csv', headers: true) do |row|  # PLACEHOLDER
  lookup[row['ID']] = row['NewValue']                        # PLACEHOLDER — header names
end

net = WSApplication.current_network  # or use IE open pattern
net.transaction_begin

net.row_objects('cams_manhole').each do |ro|  # PLACEHOLDER — table name
  if lookup.key?(ro['node_id'])
    ro['user_text_1'] = lookup[ro['node_id']]  # PLACEHOLDER — field name
    ro.write
  end
end

net.transaction_commit
```

**Key points:**
- Wrap all writes in `transaction_begin` / `transaction_commit`.
- `ro.write` is required after setting any field — fields are not auto-persisted.
- Use bracket notation `ro['field_name']` for dynamic field names; use `ro.field_name` for fixed ones.
- Prefer `CSV.foreach(path, headers: true)` — this skips the header row automatically and allows `row['ColumnName']` access by header name.

---

## PAT_IAM_EX_006 — Schema Introspection With WSTableInfo / WSFieldInfo

**Intent:** Inspect available tables and their fields programmatically, including BLOB sub-fields.

**Source:** `0024 Edit rows of a BLOB field/UI-ReverseOrderCCTVSurveyDefectCodes.rb`, `0015 Export Choice List values/`

```ruby
net = WSApplication.current_network

# List all fields on a table
ti = net.table('cams_cctv_survey')  # PLACEHOLDER — table name
ti.fields.each do |f|
  puts "#{f.name} (#{f.data_type})"
end

# Find a BLOB field and list its sub-fields
blob_field_names = []
blob_field_index = {}

ti.fields.each do |f|
  if f.name == 'details'     # PLACEHOLDER — BLOB field name
    n = 0
    f.fields.each do |bf|
      blob_field_names << bf.name
      blob_field_index[bf.name] = n
      n += 1
    end
    break
  end
end

puts "BLOB sub-fields: #{blob_field_names.inspect}"
```

**Key points:**
- `net.table(name)` returns a `WSTableInfo` object.
- `ti.fields` returns an array of `WSFieldInfo` objects.
- For BLOB-type fields, `f.fields` returns an array of sub-field `WSFieldInfo` objects.

---

## PAT_IAM_EX_007 — BLOB Field Read and Modify (All Rows)

**Intent:** Read every row in a BLOB field, transform values, write back.

**Source:** `0024 Edit rows of a BLOB field/UI-ReverseOrderCCTVSurveyDefectCodes.rb`

```ruby
# Collect blob sub-field names first (see PAT_IAM_EX_006)
blob_fields = ['defect_code', 'remarks']  # PLACEHOLDER — actual sub-field names

net.transaction_begin

net.row_objects('cams_cctv_survey').each do |survey|  # PLACEHOLDER — table
  details = survey.details   # PLACEHOLDER — BLOB field name (property accessor)
  next if details.size == 0

  # Read all rows into a Ruby array of arrays
  all_rows = (0...details.size).map do |i|
    blob_fields.map { |f| details[i][f] }
  end

  # Modify (example: reverse order)
  all_rows.reverse!

  # Write back
  all_rows.each_with_index do |row_vals, i|
    blob_fields.each_with_index do |f, j|
      details[i][f] = row_vals[j]
    end
  end

  details.write   # persist the BLOB
  survey.write    # persist the parent row
end

net.transaction_commit
```

**Key points:**
- `details.write` and then `survey.write` are both required.
- Read into a plain Ruby array first — do not iterate and write simultaneously through the BLOB enumerator.

---

## PAT_IAM_EX_008 — BLOB Field Append New Row

**Intent:** Grow a BLOB field (e.g., `attachments`) and add a new record.

**Source:** `0019 Distribute attachment details by a shared value/UIIE-PDFDistribute_Single.rb`

```ruby
net.transaction_begin

net.row_objects('cams_cctv_survey').each do |ro|  # PLACEHOLDER — table
  attachments = ro.attachments   # PLACEHOLDER — BLOB field name
  n = attachments.length

  attachments.length = n + 1            # grow by 1 row
  attachments[n].purpose     = 'Report'    # PLACEHOLDER — sub-field name
  attachments[n].filename    = 'report.pdf' # PLACEHOLDER
  attachments[n].description = 'Auto-attached' # PLACEHOLDER
  attachments[n].db_ref      = 'C:\\Temp\\report.pdf' # PLACEHOLDER

  attachments.write
  ro.write
end

net.transaction_commit
```

**Key points:**
- Set `attachments.length = n + 1` before writing to the new index.
- Sub-field names are accessed as property accessors on the BLOB row object.

---

## PAT_IAM_EX_009 — BLOB Field Filter / Shrink

**Intent:** Remove rows from a BLOB field that match a condition.

**Source:** `0024 Edit rows of a BLOB field/UI-DeleteRowsFromAttachmentsBlob.rb`

```ruby
blob_fields = ['purpose', 'filename', 'description', 'db_ref']  # PLACEHOLDER

net.transaction_begin

net.row_objects('cams_cctv_survey').each do |ro|  # PLACEHOLDER — table
  blb = ro.attachments  # PLACEHOLDER — BLOB field name

  # Collect rows that pass the filter (keep all except matching condition)
  kept = (0...blb.size).reject { |i| blb[i].description == 'DELETE_ME' }  # PLACEHOLDER condition
               .map { |i| blob_fields.map { |f| blb[i][f] } }

  # Resize and write back only the kept rows
  blb.length = kept.length
  kept.each_with_index do |row_vals, i|
    blob_fields.each_with_index { |f, j| blb[i][f] = row_vals[j] }
  end

  blb.write
  ro.write
end

net.transaction_commit
```

---

## PAT_IAM_UI_004 — Individual Report Per Selected Object

**Intent:** Generate one report document per selected object, with a sanitised filename.

**Source:** `0020 Generate Individual Reports for a Selection of Objects/UI-Reports-CreateIndividualForSelection.rb`

```ruby
net = WSApplication.current_network

net.row_objects_selection('cams_cctv_survey').each do |ro|  # PLACEHOLDER — table
  net.clear_selection
  ro.selected = true

  safe_id = ro.id.to_s.gsub(/[^0-9A-Za-z_-]/, '--')
  output_path = "C:\\Temp\\Report_#{safe_id}.doc"  # PLACEHOLDER

  net.generate_report(
    'cams_cctv_survey',   # PLACEHOLDER — table name
    nil,                  # report sub-type: nil = default; 'MSCC', 'PACP' for survey reports
    ro.id,                # title/header shown on report (typically the object ID)
    output_path
  )
end

WSApplication.message_box('Reports exported.', 'OK', 'Information', nil)
```

**Key points:**
- `ro.selected = true` before `generate_report` is required — reports target the current selection.
- `net.clear_selection` before each loop iteration ensures only one object is selected.
- For CCTV surveys: `generate_report('cams_cctv_survey', 'MSCC', ...)` for MSCC format, `'PACP'` for PACP format.
- For manhole surveys: `generate_report('cams_manhole_survey', nil, ...)`.

---

## PAT_IAM_UI_005 — Choice List Lookup Table

**Intent:** Build a hash mapping raw database codes to display text for a choice-list field.

**Source:** `0015 Export Choice List values/UI-ExportObjectValuesChoiceDescriptions.rb`

```ruby
net = WSApplication.current_network

codes = net.field_choices('cams_pipe', 'system_type')             # PLACEHOLDER — table/field
descs = net.field_choice_descriptions('cams_pipe', 'system_type') # PLACEHOLDER

lookup = {}
codes.each_with_index { |code, i| lookup[code] = descs[i] }

# Resolve a field value at row level (with fallback)
net.row_objects('cams_pipe').each do |ro|
  display = lookup.key?(ro['system_type']) ? lookup[ro['system_type']] : ro['system_type']
  puts "#{ro['id']}: #{display}"
end
```

**Key points:**
- `field_choices` and `field_choice_descriptions` return parallel arrays — index position maps code to description.
- Include a fallback (raw value) in case a stored value is not in the current choice list.

---

## PAT_IAM_UI_006 — Save and Load a Selection List

**Intent:** Persist the current selection as a named Selection List database object, then reload it.

**Source:** `0027 Selection Lists/UI-CreateSelectionList.rb`, `UI-LoadSelectionList.rb`

```ruby
# Save
db    = WSApplication.current_database
net   = WSApplication.current_network
group = db.model_object_from_type_and_id('Asset Group', 3)  # PLACEHOLDER — group ID
sl    = group.new_model_object('Selection List', 'My Selection')  # PLACEHOLDER — name
net.save_selection(sl)

# Load (in a later script or after re-opening the network)
net.clear_selection
net.load_selection(1778)  # PLACEHOLDER — Selection List database ID

selected = net.row_object_collection_selection('cams_manhole')  # PLACEHOLDER — table
selected.each { |ro| puts ro['node_id'] }
```

**Key points:**
- `net.save_selection(sl)` saves the current GeoPlan selection into the given Selection List model object.
- `net.load_selection(id)` restores the selection by database ID of the Selection List.
- For dynamic naming (e.g., per-pipe trace results): `sl = group.new_model_object('Selection List', "Trace_#{ro.id}")`

> **Convention:** Most repository examples do NOT call `clear_selection` before selecting objects from a data-driven loop. This means selections are additive to any existing selection. Only call `clear_selection` first when the script is explicitly meant to replace the current selection.

---

## PAT_IAM_UI_007 — Dynamic Field Write With Flag Field

**Intent:** Write a value to a dynamic field (name from variable) plus its corresponding flag field.

**Source:** `0016 Update an object with values of another object through comparison/UI-UpdateObjectFromObject_ByPrompt_3.rb`

```ruby
net.transaction_begin

net.row_objects('cams_manhole').each do |ro|  # PLACEHOLDER — table
  key = ro['user_text_1']                      # PLACEHOLDER — lookup field
  next unless lookup.key?(key)

  ro['user_text_2'] = lookup[key]              # PLACEHOLDER — destination field
  ro.write

  ro['user_text_2_flag'] = 'MY_FLAG'           # PLACEHOLDER — flag field name (field_name + '_flag')
  ro.write
end

net.transaction_commit
```

**Key points:**
- Flag fields follow the convention: `{field_name}_flag` (e.g., `diameter_flag`).
- Two separate `ro.write` calls are needed if both the field and its flag are written separately; or write once after setting both.

---

## PAT_IAM_UI_008 — Prompt With File and Folder Pickers

**Intent:** Show a dialog with a folder picker, a file picker, and a plain text field.

**Source:** `0022 Rename Exported Image & Attachment Files/UI-FileRename_v4.rb`

```ruby
vals = WSApplication.prompt(
  'File Operation',  # PLACEHOLDER — dialog title
  [
    ['Output folder:',    'String', nil, nil, 'FOLDER', 'Select output folder'],
    ['Input CSV file:',   'String', nil, nil, 'FILE', true, 'csv', 'Hint text', false],
    ['Text input:',       'String'],
    ['Enable option:',    'Boolean', true],
    ['Pick from list:',   'String', '', nil, 'LIST', ['OptionA', 'OptionB']],  # PLACEHOLDER
    ['Number value:',     'NUMBER', 0],
  ],
  false  # false = show Cancel button
)

return if vals.nil?  # user cancelled

output_folder = vals[0].to_s
input_file    = vals[1].to_s
text_val      = vals[2].to_s
flag          = vals[3]            # true/false Boolean
selected_opt  = vals[4].to_s
number_val    = vals[5].to_f
```

**Field type reference:**

| Type string | UI widget | Example default |
|---|---|---|
| `'String'` | Text input | `''` |
| `'NUMBER'` | Number input | `0` |
| `'Boolean'` | Checkbox | `true` / `false` |
| `'String', nil, nil, 'FOLDER', 'hint'` | Folder picker | — |
| `'String', nil, nil, 'FILE', writable, ext, hint, false` | File picker | — |
| `'String', '', nil, 'LIST', [values]` | Dropdown | — |

---

## PAT_IAM_EX_010 — ODEC Callback Export Filter

**Intent:** Filter records at export time using a callback class — return `true` to include, `nil`/`false` to exclude.

**Source:** `0001A ODEC Callback Examples/ODEC_Exporter_Filter_CCTVSurveyCurrent.rb`

```ruby
class Exporter
  # Called once per record before export
  # Return true to include; return nil or false to exclude
  def Exporter.onFilterRecordCCTVSurvey(obj)  # PLACEHOLDER — method suffix = table display name, no spaces
    obj['current'] == true
  end

  # Called once per record to transform a field value before export
  def Exporter.PipeConditionScore(obj)         # PLACEHOLDER — method name = field column name
    if obj['condition_score_flag'] == 'KT1' && !obj['condition_score'].nil?
      obj['condition_score']
    else
      nil  # nil = skip this field
    end
  end
end

options = {}
options['Callback Class'] = Exporter

net.odec_export_ex('CSV', 'C:\\Temp\\export.cfg', options, 'CCTVSurvey', 'C:\\Temp\\out.csv')  # PLACEHOLDER
```

**Key points:**
- Filter method name: `onFilterRecord{TableDisplayNameNoSpaces}` (e.g., `onFilterRecordCCTVSurvey`).
- Field transform method name: the database field column name (e.g., `PipeConditionScore`).
- Set `options['Callback Class']` to the class itself (not an instance).

---

## PAT_IAM_EX_011 — ODIC Callback Import Filter

**Intent:** Filter or transform records at import time using a callback class.

**Source:** `0002A ODIC Callback Examples/ODIC_Importer_Filter_SourceFieldValues.rb`, `ODIC_Importer_ImportField.rb`

```ruby
class Importer
  # Called at start of each record — set obj.writeRecord = false to skip
  def Importer.OnBeginRecordNode(obj)   # PLACEHOLDER — suffix = table display name, no spaces
    obj.writeRecord = false
    if obj['node_type'] == 'G' && obj['system_type'] == 'F'  # PLACEHOLDER conditions
      obj.writeRecord = true
    end
  end

  # Called at end of each record — can write derived values
  def Importer.onEndRecordNode(obj)     # PLACEHOLDER
    obj['user_text_2'] = obj['SYSTEMDATE'].to_s  # PLACEHOLDER — read source field, write target field
  end
end

options = {}
options['Callback Class'] = Importer

net.odic_import_ex('CSV', 'C:\\Temp\\import.cfg', options, 'node', 'C:\\Temp\\data.csv')  # PLACEHOLDER
```

**Key points:**
- `OnBeginRecord{TableName}`: filter records (set `writeRecord`).
- `onEndRecord{TableName}`: post-process values after the mapping config runs.
- Source CSV column names are accessed via `obj['COLUMN_HEADER']` (case-sensitive per file).

---

## PAT_IAM_EX_012 — csv_export With Options Hash

**Intent:** Export the full network or a single table to CSV with configurable options.

**Source:** `0007 Export to CSV/UIIE-CSV_export.rb`

```ruby
net = WSApplication.current_network  # or IE open pattern

opts = {}
# opts['Use Display Precision'] = true
# opts['Field Descriptions']    = false
# opts['Field Names']           = true
# opts['Flag Fields']          = true
# opts['Multiple Files']        = false    # true = one file per table
# opts['Selection Only']        = false
# opts['Coordinate Arrays Format'] = 'Packed'  # 'Packed', 'None', 'Separate'
# opts['Other Arrays Format']      = 'Packed'
# opts['WGS84']                    = false

net.csv_export(
  'C:\\Temp\\network_export.csv',  # PLACEHOLDER — output path
  opts
)
```

**Key points:**
- Without `'Multiple Files' => true`, all tables export into a single CSV file.
- The `table` parameter is NOT used here; `csv_export` exports the full network. To export a single table, use `odec_export_ex` with a CSV config instead.

---

## PAT_IAM_DUAL_004 — Upstream Network Trace

**Intent:** Breadth-first upstream trace from a selected manhole, marking all upstream pipes and nodes as selected.

**Source:** `0014 Network Trace/UI-NodeTraceUpstream.rb`, `UI-PipesTraceUpstream_SumPipeLengths_WriteToField.rb`

```ruby
net = WSApplication.current_network

roc = net.row_object_collection_selection('cams_manhole')
if roc.length != 1
  WSApplication.message_box('Select exactly one manhole.', 'OK', '!', nil)
  raise 'abort'
end

start_node = roc[0]
start_node.selected = true

queue = []
start_node.us_links.each { |l| queue << l unless l._seen }

while queue.size > 0
  link = queue.shift
  link.selected = true
  link._seen = true

  us_node = link.navigate1('us_node')
  next if us_node.nil?

  us_node.selected = true
  us_node.us_links.each do |l|
    queue << l unless l._seen
  end
end

puts 'Trace complete.'
```

**Key points:**
- `_seen` is a transient per-session flag on `WSRowObject` — safe to use as a visited marker.
- `us_links` returns the upstream link objects directly (shorthand for `navigate('us_links')`).
- Use `raise 'abort'` rather than `exit` to stop a UI script cleanly without showing an error dialog.

---

## PAT_IAM_DUAL_005 — Navigate From Survey To Parent Pipe/Node

**Intent:** For each survey record, navigate to its parent pipe or node.

**Source:** `ruby_icm_help.md` navigate type documentation

```ruby
net.row_objects('cams_cctv_survey').each do |survey|  # or row_objects_selection
  parent_pipe = survey.navigate1('pipe')     # → parent cams_pipe row object
  next if parent_pipe.nil?

  puts "Survey #{survey['id']} → Pipe #{parent_pipe['id']}, " \
       "Diameter: #{parent_pipe['diameter']}"
end

net.row_objects('cams_manhole_survey').each do |survey|
  parent_node = survey.navigate1('node')     # → parent cams_manhole row object
  next if parent_node.nil?

  puts "Survey #{survey['id']} → Node #{parent_node['node_id']}"
end
```

---

## PAT_IAM_DUAL_006 — Navigate From Pipe To Child Survey Records

**Intent:** For each pipe, navigate to all its associated survey records.

**Source:** navigate type table in `InfoAsset_Manager_Ruby_API_Full.md`

```ruby
net.row_objects('cams_pipe').each do |pipe|
  surveys = pipe.navigate('cctv_surveys')   # returns Array (may be empty)
  next if surveys.empty?

  surveys.each do |s|
    puts "Pipe #{pipe['id']}: Survey #{s['id']}, date #{s['survey_date']}"
  end
end

# Distribution — hydrant tests from hydrant
net.row_objects('wams_hydrant').each do |hydrant|
  hydrant.navigate('hydrant_tests').each do |test|
    puts "Hydrant #{hydrant['id']}: test #{test['id']}"
  end
end
```

---

## PAT_IAM_DUAL_007 — Attachments Iterate / Read

**Intent:** Iterate the attachments BLOB on a row object and process each file reference.

**Source:** `0019 Distribute attachment details by a shared value/UIIE-PDFDistribute_Single.rb`

```ruby
net.row_objects('cams_cctv_survey').each do |ro|  # PLACEHOLDER — table
  attachments = ro.attachments  # BLOB field accessor
  next if attachments.length == 0

  attachments.each do |a|
    next unless a.db_ref.to_s.downcase.end_with?('.pdf')  # PLACEHOLDER — filter condition
    puts "Survey #{ro['id']}: #{a.filename} → #{a.db_ref}"
    # sub-fields: a.purpose, a.filename, a.description, a.db_ref
  end
end
```

**Key points:**
- BLOB sub-fields for `attachments`: `purpose`, `filename`, `description`, `db_ref`.
- `db_ref` is the file path or reference stored in the database.

---

## PAT_IAM_DUAL_008 — Selection Count Guard

**Intent:** Stop cleanly if the selection is empty or contains too many objects.

**Source:** `0014 Network Trace/` scripts

```ruby
net = WSApplication.current_network

roc = net.row_object_collection_selection('cams_manhole')  # PLACEHOLDER

if roc.length == 0
  WSApplication.message_box('No manholes selected.', 'OK', '!', nil)
  raise 'abort'
end

if roc.length > 1
  WSApplication.message_box("Select exactly one manhole (#{roc.length} selected).", 'OK', '!', nil)
  raise 'abort'
end

ro = roc[0]
```

---

## PAT_IAM_DUAL_009 — IE Commit After Write

**Intent:** In Exchange mode, commit changes with a descriptive message after completing writes.

**Source:** `0019 Distribute attachment details by a shared value/UIIE-PDFDistribute_Single.rb`

```ruby
if WSApplication.ui?
  net = WSApplication.current_network
else
  db     = WSApplication.open('//localhost:40000/Databasename', false)  # PLACEHOLDER
  net_mo = db.model_object_from_type_and_id('Collection Network', 2)    # PLACEHOLDER
  net    = net_mo.open
end

net.transaction_begin
# ... writes ...
net.transaction_commit

unless WSApplication.ui?
  net_mo.commit('Script completed: describe what changed here.')  # PLACEHOLDER — message
end
```

**Key points:**
- `transaction_begin`/`transaction_commit` are always required for writes.
- `net_mo.commit(message)` is an additional step required only in IE mode to persist to the database history.

---

## PAT_IAM_DUAL_010 — Dynamic Field Read and Write With Bracket Notation

**Intent:** Read and write row object fields where the field name comes from a variable at runtime.

**Source:** `0016 Update an object with values of another object through comparison/`

```ruby
source_field = 'diameter'   # PLACEHOLDER — determined at runtime
dest_field   = 'user_text_1'  # PLACEHOLDER

net.transaction_begin

net.row_objects('cams_pipe').each do |ro|  # PLACEHOLDER — table
  value = ro[source_field]                  # bracket read — works with any field name
  next if value.nil?

  ro[dest_field] = value.to_s              # bracket write
  ro.write
end

net.transaction_commit
```

**Key points:**
- Bracket notation `ro['field_name']` and `ro['field_name'] = value` works for any field name including dynamically determined ones.
- Property accessor notation (`ro.diameter`) only works for known, fixed field names.
- Always call `ro.write` after setting values — nothing persists automatically.

---

## PAT_IAM_DUAL_011 — Clean Abort Without Error Dialog

**Intent:** Stop a script without showing the ugly SystemExit error dialog that `exit` triggers in UI mode.

**Source:** Based on ICM Ruby Lessons and repository convention

```ruby
def run_script(net)
  roc = net.row_object_collection_selection('cams_pipe')

  if roc.length == 0
    WSApplication.message_box('No pipes selected. Script cancelled.', 'OK', '!', nil)
    raise 'abort'  # use raise, NOT exit
  end

  # ... main logic ...
end

begin
  net = WSApplication.current_network
  raise 'No open network' if net.nil?
  run_script(net)
rescue => e
  WSApplication.message_box("Script failed: #{e.message}", 'OK', 'Stop', nil) if WSApplication.ui?
  raise e
end
```

**Key points:**
- `exit` in UI mode throws `SystemExit` and shows an error dialog. Use `raise 'abort'` instead.
- Wrap the main body in `begin/rescue` to show a friendly error and re-raise if needed.
- `WSApplication.message_box` signature: `(text, buttons, icon, hard_wire_cancel)`. Buttons: `'OK'`, `'OkCancel'`, `'YesNo'`, `'YesNoCancel'`. Icon: `'!'`, `'?'`, `'Information'`, `'Stop'`.

---

## Pattern Index

| Pattern ID | Category | Summary |
|---|---|---|
| PAT_IAM_UI_001 | UI | Open current network |
| PAT_IAM_UI_002 | UI | Prompt then validate |
| PAT_IAM_UI_003 | UI | UI export wrapper |
| PAT_IAM_UI_004 | UI | Individual report per selected object |
| PAT_IAM_UI_005 | UI | Choice list lookup table |
| PAT_IAM_UI_006 | UI | Save and load selection list |
| PAT_IAM_UI_007 | UI | Dynamic field write with flag field |
| PAT_IAM_UI_008 | UI | Prompt with file and folder pickers |
| PAT_IAM_EX_001 | Exchange | Open database and network |
| PAT_IAM_EX_002 | Exchange | Exchange import wrapper |
| PAT_IAM_EX_003 | Exchange | Exchange export wrapper |
| PAT_IAM_EX_004 | Exchange | IE multi-network loop |
| PAT_IAM_EX_005 | Exchange | Row update with CSV lookup + transaction |
| PAT_IAM_EX_006 | Exchange | Schema introspection (WSTableInfo/WSFieldInfo) |
| PAT_IAM_EX_007 | Exchange | BLOB field read and modify |
| PAT_IAM_EX_008 | Exchange | BLOB field append new row |
| PAT_IAM_EX_009 | Exchange | BLOB field filter and shrink |
| PAT_IAM_EX_010 | Exchange | ODEC callback export filter |
| PAT_IAM_EX_011 | Exchange | ODIC callback import filter |
| PAT_IAM_EX_012 | Exchange | csv_export with options hash |
| PAT_IAM_DUAL_001 | Dual | Early runtime branch |
| PAT_IAM_DUAL_002 | Dual | Keep UI interaction in UI branch |
| PAT_IAM_DUAL_003 | Dual | Shared network method after branch |
| PAT_IAM_DUAL_004 | Dual | Upstream network trace |
| PAT_IAM_DUAL_005 | Dual | Navigate from survey to parent pipe/node |
| PAT_IAM_DUAL_006 | Dual | Navigate from pipe to child surveys |
| PAT_IAM_DUAL_007 | Dual | Attachments iterate and read |
| PAT_IAM_DUAL_008 | Dual | Selection count guard |
| PAT_IAM_DUAL_009 | Dual | IE commit after write |
| PAT_IAM_DUAL_010 | Dual | Dynamic field read/write with bracket notation |
| PAT_IAM_DUAL_011 | Dual | Clean abort without error dialog |
