# InfoWorks ICM Ruby Database Fields Guide for LLM Agents

**Last Updated:** July 7, 2026

**Load Priority:** LOOKUP - Load when querying field names or distinguishing InfoWorks vs SWMM fields  
**Load Condition:** CONDITIONAL - When script reads/writes row object fields or user asks about field differences

**Related Files:**
- `Instructions.md` - Loading priorities and network-type policy
- `InfoWorks_ICM_Ruby_Lessons_Learned.md` - Read FIRST - Includes field name gotchas
- `InfoWorks_ICM_Ruby_Database_Reference.md` - Table names and **Data Fields Topic** values for MCP queries
- `InfoWorks_ICM_Ruby_Pattern_Reference.md` - Working code templates using field names (PAT_FIELD_EXISTS_030, PAT_DYNAMIC_FIELD_ACCESS_032)
- `InfoWorks_ICM_Ruby_API_Reference.md` - Row object and WSStructure methods

## Overview

This guide helps LLM agents find accurate **Database field** names for InfoWorks ICM Ruby scripts.

**Use order:**
1. Look up **Database Table Name** and **Data Fields Topic** in `InfoWorks_ICM_Ruby_Database_Reference.md` (network section only)
2. Call Autodesk Help MCP using the **Data Fields Topic** as the query (Step 2 below)
3. Use the **Database field** column from MCP results in Ruby row object access

**CRITICAL DISTINCTION:**
- Users refer to **"Field Name"** (the display name in the UI)
- Ruby scripts **MUST use the "Database field"** name (the actual column name)
- These are often different (e.g., "Width" vs `conduit_width`)

**NETWORK TYPES:**
InfoWorks ICM supports two distinct network types with **different field names**:
- **InfoWorks Networks** - Traditional InfoWorks network objects (`hw_*` tables; default when network type is not specified)
- **SWMM Networks** - SWMM-compatible network objects (`sw_*` tables; when specified or clearly indicated)

**If a Help page header does NOT contain "(SWMM)", it refers to InfoWorks networks.**

## How to Find Database Fields - LLM Workflow

### Step 1: Determine Object Type and Network Type

From the user's query, identify:
- **Object type:** Conduit, Node, Subcatchment, Pump, etc.
- **Network type:** InfoWorks (default) or SWMM (if specified or clearly indicated)

In `InfoWorks_ICM_Ruby_Database_Reference.md`, find the matching row in the confirmed network section:
- **Database Table Name** — for `net.row_objects('TABLE_NAME')`
- **Data Fields Topic** — for the MCP query in Step 2

### Step 2: Autodesk Help MCP lookup

If the Autodesk Product Help MCP is available, call `search_help_content` ([MCP setup](https://help.autodesk.com/view/ADSKMCP/ENU/?guid=ADSKMCP_KnowledgeMcp_autodesk_product_help_mcp_server_html)) with:
- `product_code=IWICMS`
- `locale=en_US` (unless user specifies another locale)
- `release_code` from the user's ICM version or latest release (on or after April 1 → `current_year + 1`; before April 1 → `current_year`)
- `query` = the **Data Fields Topic** from Step 1

Examples:
- `Conduit Data Fields (InfoWorks)` → InfoWorks Conduit
- `Conduit Data Fields (SWMM)` → SWMM Conduit
- `Node Data Fields (InfoWorks)` → InfoWorks Node
- `Subcatchment Data Fields (SWMM)` → SWMM Subcatchment

Use the returned `body` text — the **Database field** column, not Field Name. If MCP is unavailable, state unknown. Do not browse Help URLs or load `00 Reference/`.

### Step 3: Navigate the Data Fields Table

Each Help page contains a table with these columns:
1. **Field Name** - Display name shown in the UI (e.g., "Width", "Upstream Node ID")
2. **Database field** - **← THIS IS WHAT RUBY NEEDS** (e.g., `conduit_width`, `us_node_id`)
3. **Data Type** - TEXT, REAL, INTEGER, BLOB, etc.
4. **Description** - What the field represents

**ALWAYS use the "Database field" column value in Ruby, NOT the "Field Name"!**

### Step 4: Access Fields in Ruby

Use the exact spelling from the **Database field** column:

```ruby
# Bracket notation (preferred for dynamic/validated field names)
ro['conduit_width'] = 0.5
width = ro['conduit_width']

# Dot notation (works when field name is a valid Ruby identifier)
ro.conduit_width = 0.5
width = ro.conduit_width
```

Include underscores and correct prefixes: `us_node_id` not `upstream_node_id`.

**WSStructure / blob fields (SWMM):** Nested structures are accessed via sub-collections, not simple attribute accessors. See `InfoWorks_ICM_Ruby_Database_Reference.md` § SWMM WSStructure (Blob / Nested) Fields and `InfoWorks_ICM_Ruby_Pattern_Reference.md` PAT_STRUCTURE_UPDATE_012.

## Working Examples

### Example 1: InfoWorks Conduit Fields

**User asks:** "Set conduit width and height for all selected conduits"

**LLM Process:**
1. Object type: Conduit (InfoWorks)
2. Table: `hw_conduit` (from Database_Reference)
3. MCP query: `Conduit Data Fields (InfoWorks)`
4. In the returned table, find:
   - Field Name: "Width" → **Database field:** `conduit_width`
   - Field Name: "Height" → **Database field:** `conduit_height`

**Generated Ruby:**
```ruby
net = WSApplication.current_network
net.transaction_begin
net.row_objects('hw_conduit').each do |ro|
  next unless ro.selected?
  ro['conduit_width'] = 0.5
  ro['conduit_height'] = 0.3
  ro.write
end
net.transaction_commit
```

### Example 2: SWMM Node Fields

**User asks:** "List SWMM nodes with maximum depth greater than 3m"

**LLM Process:**
1. Object type: Node (SWMM)
2. Table: `sw_node` (from Database_Reference)
3. MCP query: `Node Data Fields (SWMM)`
4. In the returned table, find:
   - Field Name: "Maximum Depth" → **Database field:** `maximum_depth`

**Generated Ruby:**
```ruby
net = WSApplication.current_network
net.row_objects('sw_node').each do |ro|
  depth = ro['maximum_depth']
  puts "#{ro.node_id}: #{depth}" if depth && depth > 3.0
end
```

## Key Differences: InfoWorks vs SWMM

| Concept | InfoWorks Database Field | SWMM Database Field | Notes |
|---------|-------------------------|---------------------|-------|
| Pipe width | `conduit_width` | `conduit_width` | Same in both ICM network types |
| Pipe height | `conduit_height` | `conduit_height` | Same in both ICM network types |
| Pipe length | `conduit_length` | `length` | InfoWorks channel (`hw_channel`) also uses `length` |
| Node invert | `chamber_floor` | `invert_elevation` | UI label "Chamber Floor Level" — not `chamber_floor_level` |
| Node depth | — | `maximum_depth` | SWMM only |
| Catchment area | `contributing_area` | `area` | |
| Imperviousness | `area_percent_1`–`area_percent_12`; land use `p_area_1`–`p_area_12` | `percent_impervious` | Not `runoff_index` (runoff surface ID) |
| Runoff surface ID | `runoff_index` | — | On `hw_runoff_surface` object |

Always verify network type before providing field names. Never mix InfoWorks and SWMM field names in the same script.

## Universal Fields (All Network Objects)

These fields exist on **all** network objects regardless of type (see Database_Reference § Universal Fields):
- `user_text_1` through `user_text_10`
- `user_number_1` through `user_number_10`
- `oid`

## Critical Reminders for LLM Agents

**DO:**
- Use the **"Database field"** column from MCP results, NOT "Field Name"
- Look up **Data Fields Topic** in Database_Reference before calling MCP
- Use bracket notation when field names are dynamic or uncertain (PAT_DYNAMIC_FIELD_ACCESS_032)
- Check field existence before access when compatibility matters (PAT_FIELD_EXISTS_030)
- Verify network type before providing field names

**DON'T:**
- Use display names from the UI in Ruby scripts
- Assume field names — always check via MCP
- Mix InfoWorks and SWMM field names
- Load `00 Reference/` or browse Help URLs when MCP is unavailable — state unknown instead

## Integration with Ruby Context Files

- **Database_Reference** — WHAT tables to query (`row_objects`) and which MCP topic to use
- **Database Fields Guide (this file)** — HOW to resolve field names via MCP and access them in Ruby
- **Pattern_Reference** — Working templates for field access, bulk modify, and WSStructure updates
