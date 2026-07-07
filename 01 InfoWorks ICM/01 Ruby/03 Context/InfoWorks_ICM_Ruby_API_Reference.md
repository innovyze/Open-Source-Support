# InfoWorks ICM Ruby API Reference for LLM Agents

**Source:** Exchange.pdf Version 2024.2 (runtime-verified against ICM 2027, July 2026) | **Last Updated:** July 7, 2026

**Load Priority:** CORE - Load after InfoWorks_ICM_Ruby_Lessons_Learned.md for code generation  
**Load Condition:** ALWAYS for Exchange scripts, CONDITIONAL for UI scripts

## Purpose

This guide provides **API method reference** for InfoWorks ICM Ruby scripting. 

**For LLMs:** Use this file to:
- Look up method signatures, parameters, and return types
- Verify method availability in Exchange vs UI contexts
- Find pattern references (PAT_XXX_NNN) for implementation examples

**Prerequisite:** Read `InfoWorks_ICM_Ruby_Lessons_Learned.md` FIRST to avoid critical mistakes

**Related Files:**
- `InfoWorks_ICM_Ruby_Lessons_Learned.md` - Read FIRST - Critical gotchas and anti-patterns
- `InfoWorks_ICM_Ruby_Pattern_Reference.md` - Working code templates for each method
- `InfoWorks_ICM_Ruby_Database_Reference.md` - Table names for row_objects() calls
- `InfoWorks_ICM_Ruby_Tutorial_Context.md` - Complete workflow examples
- `InfoWorks_ICM_Ruby_Error_Reference.md` - Debugging common errors
- `InfoWorks_ICM_Ruby_Glossary.md` - Terminology definitions

**Scope:** ICM-compatible methods only. Excludes WS Pro-only classes (WSNetworkObject, WSRunScheduler, WSRun).

---

## Method Quick Reference

| Class | Method | Avail | Returns | Intent | Pattern Ref |
|-------|--------|-------|---------|--------|-------------|
| **WSApplication** |
| WSApplication | open | Exch | WSDatabase | Open database | PAT_EXC_DB_OPEN_052 |
| WSApplication | create | Exch | WSDatabase | Create standalone database (.icmm) | PAT_EXC_DB_OPEN_052 |
| WSApplication | create_transportable | Exch | nil | Create transportable database (.icmt) | PAT_EXC_DB_OPEN_052 |
| WSApplication | current_network | UI | WSOpenNetwork | Get active network | PAT_APP_ACCESS_001 |
| WSApplication | ui? | Both | Boolean | Check if running in UI | PAT_UNIVERSAL_MODE_002 |
| WSApplication | open_net | UI | WSOpenNetwork | Open network in UI | - |
| WSApplication | launch_sims | Exch | Array | Launch sims via agent | PAT_LAUNCH_SIM_050 |
| WSApplication | connect_local_agent | Exch | nil | Connect to local sim agent | PAT_LAUNCH_SIM_050 |
| WSApplication | message_box | UI | String | Show message dialog | PAT_USER_MSGBOX_057 |
| WSApplication | prompt | UI | Array | Multi-field input dialog | PAT_USER_INPUT_043 |
| WSApplication | input_box | UI | String | Single text input | PAT_USER_INPUTBOX_058 |
| WSApplication | folder_dialog | UI | String | Folder picker dialog | - |
| WSApplication | file_dialog | UI | String/Array | File open/save dialog | - |
| **WSDatabase** |
| WSDatabase | model_object | Both | WSModelObject | Get object by path | PAT_DATA_FETCH_004 |
| WSDatabase | model_object_from_type_and_id | Both | WSModelObject | Get object by type/ID | PAT_DATA_FETCH_004 |
| WSDatabase | list_read_write_run_fields | Exch (ICM) | Array | List custom run fields | - |
| WSDatabase | path | Both | String | Database file path | - |
| WSDatabase | close | Exch | nil | Close database | PAT_EXC_DB_OPEN_052 |
| **WSModelObject** |
| WSModelObject | [] | Exch (ICM) | Various | Get field value | - |
| WSModelObject | []= | Exch (ICM) | nil | Set field value | - |
| WSModelObject | open | Exch | WSOpenNetwork | Open network | PAT_EXC_DB_OPEN_052 |
| WSModelObject | delete | Exch | nil | Delete object | - |
| WSModelObject | deletable? | Exch | Boolean | Check if deletable | - |
| WSModelObject | export | Both | nil | Export via ODEC | PAT_EXPORT_ODEC_022 |
| WSModelObject | import | Both | nil | Import via ODIC | PAT_EXC_ODIC_IMPORT_055 |
| WSModelObject | run | Exch (ICM) | WSSimObject | Create/run simulation | PAT_SIM_RUN_021 |
| WSModelObject | name | Both | String | Object name | - |
| WSModelObject | id | Both | Integer | Object ID | - |
| WSModelObject | type | Both | String | Object type | - |
| WSModelObject | parent_type | Both | String | Parent type | - |
| WSModelObject | parent_id | Both | Integer | Parent ID | - |
| **WSNumbatNetworkObject (ICM/InfoAsset)** |
| WSNumbatNetworkObject | open | Exch | WSOpenNetwork | Open for editing | PAT_EXC_DB_OPEN_052 |
| WSNumbatNetworkObject | branch | Exch | WSNumbatNetworkObject | Branch from commit | - |
| WSNumbatNetworkObject | commits | Exch | WSCommits | Get commit history | - |
| WSNumbatNetworkObject | latest_commit_id | Exch | Integer | Latest commit ID | - |
| WSNumbatNetworkObject | update | Exch | Boolean | Update local copy | - |
| **WSOpenNetwork** |
| WSOpenNetwork | row_objects | Both | Array | Get objects by table | PAT_DATA_FETCH_004 |
| WSOpenNetwork | row_object | Both | WSRowObject | Get single object | PAT_DATA_FETCH_004 |
| WSOpenNetwork | row_object_collection | Both | WSRowObjectCollection | Filtered collection | PAT_SELECTION_FALLBACK_007 |
| WSOpenNetwork | transaction_begin | Both | nil | Start transaction | PAT_TRANSACTION_010 |
| WSOpenNetwork | transaction_commit | Both | nil | Commit transaction | PAT_TRANSACTION_010 |
| WSOpenNetwork | transaction_rollback | Both | nil | Rollback transaction | PAT_TRANSACTION_010 |
| WSOpenNetwork | commit | Both | nil | Commit to database | - |
| WSOpenNetwork | revert | Exch | nil | Revert changes | - |
| WSOpenNetwork | clear_selection | Both | nil | Clear all selections | PAT_SELECTION_CLEAR_008 |
| WSOpenNetwork | table_info | Both | WSTableInfo | Get table metadata | PAT_FIELD_DISCOVERY_005 |
| WSOpenNetwork | tables | Both | Array | List all tables | PAT_FIELD_DISCOVERY_005 |
| WSOpenNetwork | scenarios | Both | Array | List scenarios | PAT_SCENARIO_SWITCH_006 |
| WSOpenNetwork | current_scenario | Both | String | Get/set active scenario | PAT_SCENARIO_SWITCH_006 |
| WSOpenNetwork | validate | Both | WSValidations | Validate network | - |
| **WSSimObject (ICM)** |
| WSSimObject | run | Exch | nil | Run simulation | PAT_SIM_RUN_021 |
| WSSimObject | run_ex | Exch (ICM) | nil | Run with options | PAT_LAUNCH_SIM_050 |
| WSSimObject | results_fields | Both | Array | List results fields | PAT_RESULTS_FIELDS_ENUM_019 |
| WSSimObject | list_results_gis_export_tables | Exch (ICM) | Array | List GIS-exportable result tables | - |
| WSSimObject | [] | Both | Various | Get field value | - |
| **WSRowObject** |
| WSRowObject | [] | Both | Various | Get field value | PAT_DATA_FETCH_004 |
| WSRowObject | []= | Both | nil | Set field value | PAT_BULK_MODIFY_011 |
| WSRowObject | selected? | Both | Boolean | Check if selected | PAT_SELECTION_FALLBACK_007 |
| WSRowObject | selected= | Both | nil | Set selection | PAT_SELECTION_MARKING_009 |
| WSRowObject | delete | Both | nil | Delete object | - |
| WSRowObject | table_info | Both | WSTableInfo | Get table metadata | PAT_FIELD_DISCOVERY_005 |
| WSRowObject | id | Both | String | Object ID | - |
| **WSNode (subclass of WSRowObject)** |
| WSNode | us_links | Both | Array | Upstream links | PAT_TRACE_BASIC_014 |
| WSNode | ds_links | Both | Array | Downstream links | PAT_TRACE_BASIC_014 |
| WSNode | navigate | Both | nil | Network navigation | PAT_TRACE_BASIC_014 |
| **WSLink (subclass of WSRowObject)** |
| WSLink | us_node | Both | WSNode | Upstream node | PAT_TRACE_BASIC_014 |
| WSLink | ds_node | Both | WSNode | Downstream node | PAT_TRACE_BASIC_014 |

---

## WSApplication

**Purpose:** Top-level application access. All methods are class methods.

### open
**Availability:** Exchange only  
**Returns:** WSDatabase  
**Signature:** `WSApplication.open(path, read_only=false)`

Opens existing database (local or cloud).

**Parameters:**
- `path` (String) - Database path (e.g., 'C:\db.icmm' or 'cloud://...')
- `read_only` (Boolean) - Open in read-only mode (default: false)

**See:** PAT_EXC_DB_OPEN_052, PAT_UNIVERSAL_MODE_002

---

### create
**Availability:** Exchange only  
**Returns:** WSDatabase  
**Signature:** `WSApplication.create(path, version=nil)`

Creates new database. Not for transportable databases — use `create_transportable`.

**Parameters:**
- `path` (String) - database file path
- `version` (String, optional) - Database version (e.g., '2024.0')

**See:** PAT_EXC_DB_OPEN_052

---

### create_transportable
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `WSApplication.create_transportable(path, version=nil)`

Creates transportable database. Open the file with `WSApplication.open` afterward.

```ruby
WSApplication.create_transportable('C:/Temp/MyDatabase.icmt')
db = WSApplication.open('C:/Temp/MyDatabase.icmt', false)
```

**Parameters:**
- `path` (String) - Absolute path including `.icmt` extension
- `version` (String, optional) - Database version (e.g., '2027.0')

**See:** PAT_EXC_DB_OPEN_052

---

### current_network
**Availability:** UI only  
**Returns:** WSOpenNetwork  
**Signature:** `WSApplication.current_network`

Returns currently open network in UI.

**See:** PAT_APP_ACCESS_001

---

### ui?
**Availability:** Both  
**Returns:** Boolean  
**Signature:** `WSApplication.ui?`

Returns true if running in UI, false if Exchange.

**See:** PAT_UNIVERSAL_MODE_002

---

### open_net
**Availability:** UI only  
**Returns:** WSOpenNetwork  
**Signature:** `WSApplication.open_net(path)`

Opens network in UI by scripting path.

**Parameters:**
- `path` (String) - Network scripting path

---

### launch_sims
**Availability:** Exchange only  
**Returns:** Array of job IDs  
**Signature:** `WSApplication.launch_sims(sims, server, results_on_server, max_threads, after)`

Launches simulations via simulation agent.

**Parameters:**
- `sims` (Array) - Array of WSSimObject
- `server` (String) - Agent server address (use `'.'` for local)
- `results_on_server` (Boolean) - Store results on agent server
- `max_threads` (Integer) - Max parallel threads
- `after` (Integer) - Delay before launch (seconds)

**See:** PAT_LAUNCH_SIM_050

---

### connect_local_agent
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `WSApplication.connect_local_agent(timeout_ms)`

Connects to local simulation agent before `launch_sims`.

**Parameters:**
- `timeout_ms` (Integer) - Connection timeout in milliseconds (e.g. `1000`)

**See:** PAT_LAUNCH_SIM_050

---

### cancel_job
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `WSApplication.cancel_job(job_id)`

Cancels simulation job.

**Parameters:**
- `job_id` (String) - Job ID from launch_sims

---

### job_status
**Availability:** Exchange only  
**Returns:** String  
**Signature:** `WSApplication.job_status(job_id)`

Returns job status ('Pending', 'Running', 'Complete', 'Failed').

---

### message_box
**Availability:** UI only  
**Returns:** String ('ok', 'cancel', 'yes', 'no' - lowercase)  
**Signature:** `WSApplication.message_box(text, buttons, icon, hard_wire_cancel)`

Displays modal message box.

**Parameters:**
- `text` (String) - Message text (use `\n` for newlines)
- `buttons` (String, nil) - 'OK', 'OkCancel', 'YesNo', 'YesNoCancel' (nil defaults to 'OkCancel')
- `icon` (String, nil) - '!', '?', 'Information', 'Stop' (nil defaults to '!')
- `hard_wire_cancel` (Boolean) - If true/nil, Cancel terminates script immediately

**See:** PAT_USER_MSGBOX_057

---

### prompt
**Availability:** UI only  
**Returns:** Array or nil  
**Signature:** `WSApplication.prompt(title, layout, hard_wire_cancel)`

Displays multi-field input dialog.

**Parameters:**
- `title` (String) - Dialog title
- `layout` (Array) - Field definitions array (see PAT_USER_INPUT_043 for field types)
- `hard_wire_cancel` (Boolean) - If true/nil, Cancel terminates script immediately

**See:** PAT_USER_INPUT_043

---

### input_box
**Availability:** UI only  
**Returns:** String or nil  
**Signature:** `WSApplication.input_box(prompt, title, default)`

Displays single-line text input dialog.

**Parameters:**
- `prompt` (String) - Prompt text (use `\n` for multiline)
- `title` (String) - Dialog title
- `default` (String) - Default value

**See:** PAT_USER_INPUTBOX_058

---

### folder_dialog
**Availability:** UI only  
**Returns:** String or nil  
**Signature:** `WSApplication.folder_dialog(title, hard_wire_cancel)`

Displays folder selection dialog.

**Parameters:**
- `title` (String) - Dialog title
- `hard_wire_cancel` (Boolean) - If true/nil, Cancel terminates script immediately

---

### file_dialog
**Availability:** UI only  
**Returns:** String, Array, or nil  
**Signature:** `WSApplication.file_dialog(open, extension, description, default, multiple, hard_wire_cancel)`

Displays file open/save dialog.

**Parameters:**
- `open` (Boolean) - true for Open dialog, false for Save dialog
- `extension` (String) - File extension without period (e.g., 'csv')
- `description` (String) - File filter description (e.g., 'CSV Files (*.csv)|*.csv')
- `default` (String) - Default filename
- `multiple` (Boolean) - Allow multiple selection (Open only)
- `hard_wire_cancel` (Boolean) - If true/nil, Cancel terminates script immediately

---

## WSDatabase

**Purpose:** Represents cloud, workgroup, standalone or transportable database.

### model_object
**Availability:** Both  
**Returns:** WSModelObject (or subclass)  
**Signature:** `db.model_object(path)`

Gets model object by scripting path.

**Parameters:**
- `path` (String) - Scripting path (e.g., '>MODG~Group>NNET~Network')

**Path Format:** `">TYPE~Name>TYPE~Name>LEAF~ObjectName"`  
**Known container type codes:** MODG (Model Group), TDBG (Transportable DB Group), NNET (Model Network), RAIN (Rainfall Event), and others.  
**Escape rules:** `\~` for literal ~, `\>` for literal >, `\\` for literal \

**See:** PAT_DATA_FETCH_004, PAT_HIERARCHY_EXPORT_059

---

### model_object_from_type_and_id
**Availability:** Both  
**Returns:** WSModelObject (or subclass)  
**Signature:** `db.model_object_from_type_and_id(type, id)`

Gets model object by type and ID.

**Parameters:**
- `type` (String) - Model object type (case-sensitive, e.g., 'Model Network')
- `id` (Integer) - Object ID

**See:** PAT_DATA_FETCH_004, Database Reference for types

---

### list_read_write_run_fields
**Availability:** Exchange only (ICM only)  
**Returns:** Array of Strings  
**Signature:** `db.list_read_write_run_fields`

Returns list of custom run fields defined in database.

---

### path
**Availability:** Both  
**Returns:** String  
**Signature:** `db.path`

Returns database file path.

---

### close
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `db.close`

Closes database connection.

**See:** PAT_EXC_DB_OPEN_052

---

### use_merge_version_control?
**Availability:** Both (WS Pro feature, informational in ICM)  
**Returns:** Boolean  
**Signature:** `db.use_merge_version_control?`

Returns true if database uses merge version control.

---

## WSModelObject

**Purpose:** Represents tree objects (networks, runs, model groups, etc.).

### []
**Availability:** Exchange only (ICM/InfoAsset only)  
**Returns:** Various (depends on field)  
**Signature:** `mo['field_name']`

Gets field value from model object.

**Parameters:**
- `field_name` (String) - Field name

**Note:** Available for Model Network, Rainfall Event, and some other types.

---

### []=
**Availability:** Exchange only (ICM/InfoAsset only)  
**Returns:** nil  
**Signature:** `mo['field_name'] = value`

Sets field value in model object.

**Parameters:**
- `field_name` (String) - Field name
- `value` (Various) - New value

---

### open
**Availability:** Exchange only  
**Returns:** WSOpenNetwork  
**Signature:** `mo.open`

Opens network for editing (networks only).

**See:** PAT_EXC_DB_OPEN_052

---

### delete
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `mo.delete`

Deletes model object. Check deletable? first.

---

### deletable?
**Availability:** Exchange only  
**Returns:** Boolean  
**Signature:** `mo.deletable?`

Returns true if object can be deleted.

---

### export
**Availability:** Both  
**Returns:** nil  
**Signature:** `mo.export(file_path, format, options_hash={})`

Exports via ODEC.

**Parameters:**
- `file_path` (String) - Export file path
- `format` (String) - Format ('CSV', 'SHP', 'MIF', etc.)
- `options_hash` (Hash) - ODEC options

**See:** PAT_EXPORT_ODEC_022, PAT_ODIC_OPTIONS_049

---

### import
**Availability:** Both  
**Returns:** nil  
**Signature:** `mo.import(file_path, format, options_hash={})`

Imports via ODIC.

**Parameters:**
- `file_path` (String) - Import file path
- `format` (String) - Format ('CSV', 'SHP', etc.)
- `options_hash` (Hash) - ODIC options

**See:** PAT_EXC_ODIC_IMPORT_055, PAT_ODIC_OPTIONS_049

---

### run
**Availability:** Exchange only (ICM networks only)  
**Returns:** WSSimObject  
**Signature:** `mo.run(params_hash)`

Creates and optionally runs simulation.

**Parameters:**
- `params_hash` (Hash) - Run parameters (see Tutorial for key params)

**See:** PAT_SIM_RUN_021, PAT_EXC_RUN_SETUP_053, PAT_EXC_RUN_SETUP_SWMM_054

---

### name
**Availability:** Both  
**Returns:** String  
**Signature:** `mo.name`

Gets object name.

---

### name=
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `mo.name = 'New Name'`

Sets object name.

---

### id
**Availability:** Both  
**Returns:** Integer  
**Signature:** `mo.id`

Gets object ID.

---

### type
**Availability:** Both  
**Returns:** String  
**Signature:** `mo.type`

Gets object type (e.g., 'Model Network', 'Sim').

---

### parent_type
**Availability:** Both  
**Returns:** String  
**Signature:** `mo.parent_type`

Gets parent object type.

---

### parent_id
**Availability:** Both  
**Returns:** Integer  
**Signature:** `mo.parent_id`

Gets parent object ID.

---

### children
**Availability:** Exchange only  
**Returns:** Array of WSModelObject  
**Signature:** `mo.children`

Gets child objects.

**Warning:** Collection does NOT refresh after `import_new_model_object()` or `new_model_object()` calls within the same script execution. Track names locally if importing multiple objects. See PAT_HIERARCHY_IMPORT_060.

---

### copy_here
**Availability:** Exchange only  
**Returns:** WSModelObject  
**Signature:** `mo.copy_here(source_object, copy_results, copy_children)`

Copies object to this location.

**Parameters:**
- `source_object` (WSModelObject) - Object to copy
- `copy_results` (Boolean) - Copy simulation results
- `copy_children` (Boolean) - Copy child objects

---

### import_new_model_object
**Availability:** Exchange only  
**Returns:** WSModelObject  
**Signature:** `parent.import_new_model_object(type, name, comment, file_path)`

Imports object as child.

**Parameters:**
- `type` (String) - Object type (e.g., 'Rainfall Event')
- `name` (String) - Name for new object
- `comment` (String) - Comment
- `file_path` (String) - Import file path

---

## WSNumbatNetworkObject

**Purpose:** Network objects in ICM/InfoAsset (subclass of WSModelObject).  
**Note:** All WSModelObject methods also available.

### open
**Availability:** Exchange only  
**Returns:** WSOpenNetwork  
**Signature:** `net.open`

Opens network for editing.

**See:** PAT_EXC_DB_OPEN_052

---

### branch
**Availability:** Exchange only  
**Returns:** WSNumbatNetworkObject  
**Signature:** `net.branch(commit_id, new_name)`

Creates branch from specific commit.

**Parameters:**
- `commit_id` (Integer) - Commit to branch from
- `new_name` (String) - Name for new branch

---

### commits
**Availability:** Exchange only  
**Returns:** WSCommits  
**Signature:** `net.commits`

Returns commit history collection.

---

### latest_commit_id
**Availability:** Exchange only  
**Returns:** Integer  
**Signature:** `net.latest_commit_id`

Returns ID of latest commit.

---

### update
**Availability:** Exchange only  
**Returns:** Boolean  
**Signature:** `net.update`

Updates local copy of the network to the latest version from the server. Not relevant for standalone databases. Returns true if successful, false if there are conflicts.

---

## WSOpenNetwork

**Purpose:** Open network for data manipulation.

### row_objects
**Availability:** Both  
**Returns:** Array of WSRowObject  
**Signature:** `net.row_objects(table_name)`

Gets all objects in table. Returns a Ruby Array (full Enumerable). For filtered custom collections use `row_object_collection`.

**Parameters:**
- `table_name` (String) - Table name (see Database Reference)

**See:** PAT_DATA_FETCH_004

---

### row_object
**Availability:** Both  
**Returns:** WSRowObject (or nil)  
**Signature:** `net.row_object(table_name, object_id)`

Gets single object by ID.

**Parameters:**
- `table_name` (String) - Table name
- `object_id` (String) - Object ID

**See:** PAT_DATA_FETCH_004

---

### row_object_collection
**Availability:** Both  
**Returns:** WSRowObjectCollection  
**Signature:** `net.row_object_collection(table_name)`

Gets collection for filtered iteration.

**Parameters:**
- `table_name` (String) - Table name

**See:** PAT_SELECTION_FALLBACK_007

---

### transaction_begin
**Availability:** Both  
**Returns:** nil  
**Signature:** `net.transaction_begin`

Starts transaction for atomic writes.

**See:** PAT_TRANSACTION_010

---

### transaction_commit
**Availability:** Both  
**Returns:** nil  
**Signature:** `net.transaction_commit`

Commits transaction.

**See:** PAT_TRANSACTION_010

---

### transaction_rollback
**Availability:** Both  
**Returns:** nil  
**Signature:** `net.transaction_rollback`

Rolls back transaction.

**See:** PAT_TRANSACTION_010

---

### commit
**Availability:** Both  
**Returns:** nil  
**Signature:** `net.commit('Commit message')`

Commits changes to database version control.

**Parameters:**
- `message` (String) - Commit message

---

### revert
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `net.revert`

Reverts uncommitted changes.

---

### clear_selection
**Availability:** Both  
**Returns:** nil  
**Signature:** `net.clear_selection`

Clears selection on all objects.

**See:** PAT_SELECTION_CLEAR_008

---

### table_info
**Availability:** Both  
**Returns:** WSTableInfo  
**Signature:** `net.table_info(table_name)`

Gets table metadata.

**Parameters:**
- `table_name` (String) - Table name

**See:** PAT_FIELD_DISCOVERY_005

---

### tables
**Availability:** Both  
**Returns:** Array of Strings  
**Signature:** `net.tables`

Lists all table names.

**See:** PAT_FIELD_DISCOVERY_005

---

### scenarios
**Availability:** Both  
**Returns:** Array of Strings  
**Signature:** `net.scenarios`

Lists scenario names.

**See:** PAT_SCENARIO_SWITCH_006

---

### current_scenario
**Availability:** Both  
**Returns:** String  
**Signature:** `net.current_scenario` / `net.current_scenario = name`

Gets or sets active scenario name. Use assignment to switch — not `set_scenario` (undocumented in Help).

**See:** PAT_SCENARIO_SWITCH_006

---

### validate
**Availability:** Both  
**Returns:** WSValidations  
**Signature:** `net.validate(scenarios=[])`

Validates network scenario(s), returning a WSValidations collection.

**Parameters:**
- `scenarios` (String, Array, nil, optional) - Scenario name, array of names, or nil for Base scenario

---

### each_selected
**Availability:** Both  
**Returns:** nil (iterator)  
**Signature:** `net.each_selected { |obj| }`

Iterates through currently selected objects in the network.

**Parameters:** None (uses current selection)

**Example:**
```ruby
net.each_selected do |selected_obj|
  node = net.row_object('hw_node', selected_obj.node_id)
  puts "Selected: #{node.node_id}"
end
```

**See:** PAT_SELECTION_FALLBACK_007

---

## WSSimObject

**Purpose:** Simulation objects in ICM (subclass of WSModelObject).

### run
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `sim.run`

Runs simulation synchronously.

**See:** PAT_SIM_RUN_021

---

### run_ex
**Availability:** Exchange only (ICM only)  
**Returns:** nil  
**Signature:** `sim.run_ex(server, threads)` or `sim.run_ex(options_hash)`

Runs simulation with options.

**Parameters:**
- `server` (String) - Agent server
- `threads` (Integer) - Thread count
- `options_hash` (Hash) - Advanced options

**See:** PAT_LAUNCH_SIM_050

---

### results_fields
**Availability:** Both  
**Returns:** Array of Strings  
**Signature:** `sim.results_fields`

Lists available results field codes.

**See:** PAT_RESULTS_FIELDS_ENUM_019, PAT_RESULTS_FIELD_048

---

### list_results_gis_export_tables
**Availability:** Exchange only (ICM Sim, Risk Analysis Results/Sim)  
**Returns:** Array of Strings  
**Signature:** `sim.list_results_gis_export_tables`

Returns table names that may be exported to GIS via `results_gis_export`.

---

### []
**Availability:** Both  
**Returns:** Various  
**Signature:** `sim['field_name']`

Gets simulation field value.

---

## WSRowObject

**Purpose:** Individual objects in network (nodes, links, subcatchments, etc.).

### []
**Availability:** Both  
**Returns:** Various  
**Signature:** `ro['field_name']`

Gets field value.

**Parameters:**
- `field_name` (String) - Field name

**See:** PAT_DATA_FETCH_004, PAT_DYNAMIC_FIELD_ACCESS_032

---

### []=
**Availability:** Both  
**Returns:** nil  
**Signature:** `ro['field_name'] = value`

Sets field value.

**Parameters:**
- `field_name` (String) - Field name
- `value` (Various) - New value

**See:** PAT_BULK_MODIFY_011

---

### selected?
**Availability:** Both  
**Returns:** Boolean  
**Signature:** `ro.selected?`

Returns true if object is selected.

**See:** PAT_SELECTION_FALLBACK_007

---

### selected=
**Availability:** Both  
**Returns:** nil  
**Signature:** `ro.selected = true`

Sets selection state.

**Parameters:**
- `value` (Boolean) - Selection state

**See:** PAT_SELECTION_MARKING_009

---

### delete
**Availability:** Both  
**Returns:** nil  
**Signature:** `ro.delete`

Deletes object from network.

---

### table_info
**Availability:** Both  
**Returns:** WSTableInfo  
**Signature:** `ro.table_info`

Gets metadata for this object's table.

**See:** PAT_FIELD_DISCOVERY_005

---

### id
**Availability:** Both  
**Returns:** String  
**Signature:** `ro.id`

Gets object ID.

---

### table
**Availability:** Both  
**Returns:** String  
**Signature:** `ro.table`

Gets table name.

---

## WSNode

**Purpose:** Node objects (subclass of WSRowObject).  
**Note:** All WSRowObject methods also available.

### us_links
**Availability:** Both  
**Returns:** Array of WSLink  
**Signature:** `node.us_links`

Gets upstream links.

**See:** PAT_TRACE_BASIC_014

---

### ds_links
**Availability:** Both  
**Returns:** Array of WSLink  
**Signature:** `node.ds_links`

Gets downstream links.

**See:** PAT_TRACE_BASIC_014

---

### navigate (tracing)
**Availability:** Both  
**Returns:** nil  
**Signature:** `node.navigate(direction)`

Traces network and marks selection.

**Parameters:**
- `direction` (String) - 'us' or 'ds'

**See:** PAT_TRACE_BASIC_014

---

### navigate (relationships)
**Availability:** Both  
**Returns:** WSRowObjectCollection  
**Signature:** `node.navigate(relationship_name)`

Navigates relationships to find connected objects.

**Parameters:**
- `relationship_name` (String) - Relationship type to navigate

**Common relationships:**
- `'subcatchments'` - Subcatchments connected to this node
- `'links'` - Links connected to this node

**Example:**
```ruby
node.navigate('subcatchments').each do |sub|
  puts "Subcatchment #{sub.id} drains to #{node.node_id}"
end
```

**See:** PAT_RELATIONSHIP_MAP_017

---

## WSLink

**Purpose:** Link objects (subclass of WSRowObject).  
**Note:** All WSRowObject methods also available.

### us_node
**Availability:** Both  
**Returns:** WSNode  
**Signature:** `link.us_node`

Gets upstream node.

**See:** PAT_TRACE_BASIC_014

---

### ds_node
**Availability:** Both  
**Returns:** WSNode  
**Signature:** `link.ds_node`

Gets downstream node.

**See:** PAT_TRACE_BASIC_014

---

## Supporting Classes

### WSCommits
**Purpose:** Collection of commit history.

**Iterator:** Use `.each` to iterate commits.

```ruby
net.commits.each do |commit|
  puts "#{commit.commit_id}: #{commit.user} - #{commit.date}"
end
```

---

### WSCommit
**Purpose:** Individual commit information.

**Fields:**
- `commit_id` (Integer) - Commit ID
- `user` (String) - Committing user
- `date` (DateTime) - Commit timestamp
- `comment` (String) - Commit message

---

### WSValidations
**Purpose:** Collection of validation results (ICM only).

**Iterator:** Use `.each` to iterate validation messages.

```ruby
validations = net.validate
validations.each do |v|
  puts "#{v.code}: #{v.description}"
end
```

---

### WSValidation
**Purpose:** Individual validation message (ICM only).

**Fields:**
- `code` (String) - Validation code
- `description` (String) - Message text
- `object_id` (String) - Object ID
- `table` (String) - Table name
- `level` (String) - Severity ('Error', 'Warning')

---

### WSTableInfo
**Purpose:** Table metadata.

**Methods:**
- `fields` - Array of WSFieldInfo
- `name` - Table name

**See:** PAT_FIELD_DISCOVERY_005

---

### WSFieldInfo
**Purpose:** Field metadata.

**Fields:**
- `name` (String) - Field name
- `data_type` (String) - Data type
- `read_only` (Boolean) - Read-only flag

**See:** PAT_FIELD_DISCOVERY_005

---

### WSStructure
**Purpose:** Structure blob data (e.g., pump curves, rating tables).

**Iterator:** Use `.each` to iterate rows.

```ruby
ro['curve'].each do |row|
  puts "X: #{row['x']}, Y: #{row['y']}"
end
```

**See:** PAT_STRUCTURE_UPDATE_012, PAT_STRUCTURE_TO_ARRAY_024

---

## Common Patterns

### Error Handling
```ruby
begin
  # Your code
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.join("\n")
end
```
**See:** PAT_ERROR_WRAP_027, PAT_SCRIPT_INIT_003

---

### Field Existence Check
```ruby
if ro.table_info.fields.any? { |f| f.name == 'my_field' }
  value = ro['my_field']
end
```
**See:** PAT_FIELD_EXISTS_030

---

### Safe Numeric Operations
```ruby
value = ro['flow'].to_f rescue 0.0
```
**See:** PAT_SAFE_NUMERIC_029, PAT_NULL_GUARD_028

---

## Version Notes

**Exchange.pdf Version 2024.2** - July 2023

**Exclusions from this reference:**
- WS Pro-only classes: WSNetworkObject, WSRunScheduler, WSRun
- Lock version control methods (WS Pro only)
- InfoAsset Manager-specific workflows (where not ICM-compatible)

For complete API documentation including all platforms, refer to the original Exchange.pdf.
