# InfoWorks ICM Ruby API Reference for LLM Agents

**Source:** Exchange.pdf Version 2024.2 | **Last Updated:** December 2, 2025

**Load Priority:** 🟡 CORE - Load after Lessons_Learned.md for code generation  
**Load Condition:** ALWAYS for Exchange scripts, CONDITIONAL for UI scripts

## Purpose

This guide provides **API method reference** for InfoWorks ICM Ruby scripting. 

**For LLMs:** Use this file to:
- Look up method signatures, parameters, and return types
- Verify method availability in Exchange vs UI contexts
- Find pattern references (PAT_XXX_NNN) for implementation examples

**Prerequisite:** Read `Lessons_Learned.md` FIRST to avoid critical mistakes

**Related Files:**
- `InfoWorks_ICM_Ruby_Lessons_Learned.md` - 🔴 Read FIRST - Critical gotchas and anti-patterns
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
| WSApplication | open | Exch | WSDatabase | Open database | PAT_EXC_052 |
| WSApplication | create | Exch | WSDatabase | Create new database | PAT_EXC_052 |
| WSApplication | current_network | UI | WSOpenNetwork | Get active network | PAT_APP_ACCESS_001 |
| WSApplication | ui? | Both | Boolean | Check if running in UI | PAT_UNIVERSAL_MODE_002 |
| WSApplication | open_net | UI | WSOpenNetwork | Open network in UI | - |
| WSApplication | launch_sims | Exch | Array | Launch sims via agent | PAT_LAUNCH_SIM_050 |
| **WSDatabase** |
| WSDatabase | model_object | Both | WSModelObject | Get object by path | PAT_DATA_FETCH_004 |
| WSDatabase | model_object_from_type_and_id | Both | WSModelObject | Get object by type/ID | PAT_DATA_FETCH_004 |
| WSDatabase | list_read_write_run_fields | Exch (ICM) | Array | List custom run fields | - |
| WSDatabase | path | Both | String | Database file path | - |
| WSDatabase | close | Exch | nil | Close database | PAT_EXC_052 |
| **WSModelObject** |
| WSModelObject | [] | Exch (ICM) | Various | Get field value | - |
| WSModelObject | []= | Exch (ICM) | nil | Set field value | - |
| WSModelObject | open | Exch | WSOpenNetwork | Open network | PAT_EXC_052 |
| WSModelObject | delete | Exch | nil | Delete object | - |
| WSModelObject | deletable? | Exch | Boolean | Check if deletable | - |
| WSModelObject | export | Both | nil | Export via ODEC | PAT_EXPORT_ODEC_022 |
| WSModelObject | import | Both | nil | Import via ODIC | PAT_EXC_055 |
| WSModelObject | run | Exch (ICM) | WSSimObject | Create/run simulation | PAT_SIM_RUN_021 |
| WSModelObject | name | Both | String | Object name | - |
| WSModelObject | id | Both | Integer | Object ID | - |
| WSModelObject | type | Both | String | Object type | - |
| WSModelObject | parent_type | Both | String | Parent type | - |
| WSModelObject | parent_id | Both | Integer | Parent ID | - |
| **WSNumbatNetworkObject (ICM/InfoAsset)** |
| WSNumbatNetworkObject | open | Exch | WSOpenNetwork | Open for editing | PAT_EXC_052 |
| WSNumbatNetworkObject | branch | Exch | WSNumbatNetworkObject | Branch from commit | - |
| WSNumbatNetworkObject | commits | Exch | WSCommits | Get commit history | - |
| WSNumbatNetworkObject | latest_commit_id | Exch | Integer | Latest commit ID | - |
| WSNumbatNetworkObject | update_current | Exch | nil | Update local copy | - |
| WSNumbatNetworkObject | validate | Both | WSValidations | Validate network | - |
| **WSOpenNetwork** |
| WSOpenNetwork | row_objects | Both | WSRowObjectCollection | Get objects by table | PAT_DATA_FETCH_004 |
| WSOpenNetwork | row_object | Both | WSRowObject | Get single object | PAT_DATA_FETCH_004 |
| WSOpenNetwork | row_object_collection | Both | WSRowObjectCollection | Filtered collection | PAT_SELECTION_FALLBACK_007 |
| WSOpenNetwork | transaction_begin | Both | nil | Start transaction | PAT_TRANSACTION_010 |
| WSOpenNetwork | transaction_commit | Both | nil | Commit transaction | PAT_TRANSACTION_010 |
| WSOpenNetwork | transaction_rollback | Both | nil | Rollback transaction | PAT_TRANSACTION_010 |
| WSOpenNetwork | commit | Exch | nil | Commit to database | - |
| WSOpenNetwork | revert | Exch | nil | Revert changes | - |
| WSOpenNetwork | clear_selection | Both | nil | Clear all selections | PAT_SELECTION_CLEAR_008 |
| WSOpenNetwork | table_info | Both | WSTableInfo | Get table metadata | PAT_FIELD_DISCOVERY_005 |
| WSOpenNetwork | tables | Both | Array | List all tables | PAT_FIELD_DISCOVERY_005 |
| WSOpenNetwork | scenarios | Both | Array | List scenarios | PAT_SCENARIO_SWITCH_006 |
| WSOpenNetwork | current_scenario | Both | String | Get active scenario | PAT_SCENARIO_SWITCH_006 |
| WSOpenNetwork | set_scenario | Both | nil | Switch scenario | PAT_SCENARIO_SWITCH_006 |
| **WSSimObject (ICM)** |
| WSSimObject | run | Exch | nil | Run simulation | PAT_SIM_RUN_021 |
| WSSimObject | run_ex | Exch (ICM) | nil | Run with options | PAT_LAUNCH_SIM_050 |
| WSSimObject | results_fields | Both | Array | List results fields | PAT_RESULTS_FIELDS_ENUM_019 |
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

**See:** PAT_EXC_052, PAT_UNIVERSAL_MODE_002

---

### create
**Availability:** Exchange only  
**Returns:** WSDatabase  
**Signature:** `WSApplication.create(path, version=nil)`

Creates new database.

**Parameters:**
- `path` (String) - Database path
- `version` (String, optional) - Database version (e.g., '2024.0')

**See:** PAT_EXC_052

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
**Signature:** `WSApplication.launch_sims(array_of_sims, server=nil)`

Launches simulations via simulation agent.

**Parameters:**
- `array_of_sims` (Array) - Array of WSSimObject
- `server` (String, optional) - Agent server address

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

## WSDatabase

**Purpose:** Represents master or transportable database.

### model_object
**Availability:** Both  
**Returns:** WSModelObject (or subclass)  
**Signature:** `db.model_object(path)`

Gets model object by scripting path.

**Parameters:**
- `path` (String) - Scripting path (e.g., '>MODG~Group>NNET~Network')

**See:** PAT_DATA_FETCH_004

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

**See:** PAT_EXC_052

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

**See:** PAT_EXC_052

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

**See:** PAT_EXC_055, PAT_ODIC_OPTIONS_049

---

### run
**Availability:** Exchange only (ICM networks only)  
**Returns:** WSSimObject  
**Signature:** `mo.run(params_hash)`

Creates and optionally runs simulation.

**Parameters:**
- `params_hash` (Hash) - Run parameters (see Tutorial for key params)

**See:** PAT_SIM_RUN_021, PAT_EXC_053, PAT_EXC_054

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

## WSNumbatNetworkObject

**Purpose:** Network objects in ICM/InfoAsset (subclass of WSModelObject).  
**Note:** All WSModelObject methods also available.

### open
**Availability:** Exchange only  
**Returns:** WSOpenNetwork  
**Signature:** `net.open`

Opens network for editing.

**See:** PAT_EXC_052

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

### update_current
**Availability:** Exchange only  
**Returns:** nil  
**Signature:** `net.update_current`

Updates local copy from server.

---

### validate
**Availability:** Both  
**Returns:** WSValidations  
**Signature:** `net.validate(scenarios=[])`

Validates network.

**Parameters:**
- `scenarios` (Array, optional) - Scenarios to validate

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

## WSOpenNetwork

**Purpose:** Open network for data manipulation.

### row_objects
**Availability:** Both  
**Returns:** WSRowObjectCollection  
**Signature:** `net.row_objects(table_name)`

Gets all objects in table.

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
**Availability:** Exchange only  
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
**Signature:** `net.current_scenario`

Gets active scenario name.

**See:** PAT_SCENARIO_SWITCH_006

---

### set_scenario
**Availability:** Both  
**Returns:** nil  
**Signature:** `net.set_scenario(scenario_name)`

Switches active scenario.

**Parameters:**
- `scenario_name` (String) - Scenario name

**See:** PAT_SCENARIO_SWITCH_006

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

### navigate
**Availability:** Both  
**Returns:** nil  
**Signature:** `node.navigate(direction)`

Traces network and marks selection.

**Parameters:**
- `direction` (String) - 'us' or 'ds'

**See:** PAT_TRACE_BASIC_014

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
