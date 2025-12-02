# InfoWorks ICM Ruby - Critical Lessons for LLM Agents

**Purpose:** High-priority warnings about InfoWorks Ruby behavior that differs from standard Ruby. Load this FIRST before generating any code.

**Load Priority:** 🔴 CRITICAL - Always load FIRST before any code generation  
**Last Updated:** December 2, 2025

## How to Use This File

**For LLMs:** Read this file FIRST before generating any InfoWorks ICM Ruby code. It contains critical anti-patterns and gotchas that will cause code to fail. After reading this file, proceed to:
1. `InfoWorks_ICM_Ruby_API_Reference.md` - For method signatures and parameters
2. `InfoWorks_ICM_Ruby_Pattern_Reference.md` - For working code templates
3. `InfoWorks_ICM_Ruby_Database_Reference.md` - For table names and object types
4. `InfoWorks_ICM_Ruby_Tutorial_Context.md` - For complete examples and workflows
5. `InfoWorks_ICM_Ruby_Error_Reference.md` - When debugging errors
6. `InfoWorks_ICM_Ruby_Glossary.md` - For terminology clarification

**Cross-References:**
- See `API_Reference.md` for WSCommits, WSModelObjectCollection, WSRowObjectCollection class documentation
- See `Pattern_Reference.md` for PAT_TRANSACTION_010, PAT_TRACE_BASIC_014 examples
- See `Error_Reference.md` for "NoMethodError: undefined method 'find'" solutions

---

## ⚠️ CRITICAL: Collection Objects Are NOT Ruby Arrays

### The Problem

InfoWorks custom collection classes look like Ruby arrays but **DO NOT** support standard Ruby Enumerable methods.

**Custom Collections:**
- `WSCommits`
- `WSModelObjectCollection` (returned by `.children`)
- `WSRowObjectCollection` (returned by `.row_objects`)

**What Works:**
```ruby
# ✅ ONLY .each is supported
commits.each do |c|
  puts c.commit_id
end

# ✅ Convert to array first if needed
children_array = parent_group.children.to_a
found = children_array.find { |c| c.name == "MyNetwork" }
```

**What FAILS:**
```ruby
# ❌ NoMethodError: undefined method 'find'
commit = commits.find { |c| c.commit_id == 123 }

# ❌ NoMethodError: undefined method 'select'
networks = children.select { |c| c.type == 'Model Network' }

# ❌ NoMethodError: undefined method 'map'
names = children.map(&:name)

# ❌ All other Enumerable methods fail
.any?, .all?, .first, .last, .count, .filter, .reject, etc.
```

### LLM Agent Rules

1. **ALWAYS use `.each` loops** for InfoWorks collections
2. **NEVER use** `.find`, `.select`, `.map`, `.any?`, `.all?`, etc.
3. **Convert to array** with `.to_a` if you need enumerable methods
4. **Don't trust API docs** that say "Returns: Array" - assume custom collection

### Code Pattern

```ruby
# Pattern: Find item in collection
found_item = nil
collection.each do |item|
  if item.property == target_value
    found_item = item
    break
  end
end

if found_item
  # Use item
else
  puts "Not found"
end
```

---

## ⚠️ CRITICAL: DateTime Class Not Available

### The Problem

Commit objects have a `.date` field documented as returning `DateTime`, but accessing it causes:
```
undefined class/module DateTime
```

**What FAILS:**
```ruby
# ❌ Causes DateTime class error
commit.date

# ❌ Even .to_s doesn't help
commit.date.to_s
```

### LLM Agent Rules

1. **AVOID** accessing `.date` fields on commit objects
2. **AVOID** any code that would instantiate DateTime
3. Use only `Time` class methods (Time.now works fine)

### Code Pattern

```ruby
# ✅ Safe - use only commit_id and user
commits.each do |c|
  puts "Commit #{c.commit_id} by #{c.user}"  # No .date
end

# ✅ For timestamps, use Time.now
timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
```

---

## ⚠️ Documentation Inaccuracies

### API Reference Issues

**Issue 1: Return type mislabeled**
```
Documentation says: "Returns: Array of WSModelObject"
Reality: Returns WSModelObjectCollection (not Array)
Method: .children
```

**Issue 2: Collection methods not explicit**
- Docs don't clearly state that collections only support `.each`
- Must infer from code examples that `.find`, `.map`, etc. don't work

**Issue 3: DateTime limitation undocumented**
- No warning that DateTime class causes errors
- Commit.date field listed without caveat

### LLM Agent Rules

1. **Trust runtime errors** over documentation when they conflict
2. **Check Context files** before assuming Ruby stdlib behavior
3. **Use defensive coding** - wrap risky operations in rescue blocks

---

## ✅ Safe API Usage Patterns

### Collections - Always Safe

```ruby
# Iterate with .each
collection.each do |item|
  # Process item
end

# Check if empty
has_items = false
collection.each do |item|
  has_items = true
  break
end

# Count items
count = 0
collection.each { |item| count += 1 }
```

### Finding Items - Safe Pattern

```ruby
# Find single item
found = nil
collection.each do |item|
  if item.property == value
    found = item
    break
  end
end

# Find multiple items
results = []
collection.each do |item|
  results << item if item.property == value
end
```

### Error Handling - Safe Pattern

```ruby
# Wrap uncertain operations
begin
  collection.each do |item|
    # Process
  end
rescue => e
  puts "Error: #{e.message}"
end

# Check for nil before using
obj = db.model_object_from_type_and_id('Model Network', id)
if obj.nil?
  puts "ERROR: Object not found"
  exit 1
end
```

---

## 🎯 LLM Agent Checklist

Before generating InfoWorks Ruby code, verify:

- [ ] All collection iterations use `.each` (not `.find`, `.map`, etc.)
- [ ] No access to `.date` fields on commits
- [ ] All object lookups checked for nil before use
- [ ] Risky operations wrapped in rescue blocks
- [ ] No assumptions about Ruby stdlib working on custom classes
- [ ] Consulted Context files for actual API behavior
- [ ] **Bulk updates wrapped in transactions** (`transaction_begin`/`transaction_commit`)
- [ ] **Parent object handling** accounts for nested networks (try 'Model Group', fallback to 'Model Network')
- [ ] **User feedback** provided with `puts` statements
- [ ] **Edge cases handled** (empty results, naming conflicts, nil checks)
- [ ] **Two-level commits** understood (transaction_commit vs database commit)

---

## ⚠️ CRITICAL: Transaction vs Database Commit

### The Problem

There are TWO different "commits" in InfoWorks and they serve different purposes.

**Transaction Commit (In-Memory):**
```ruby
net.transaction_begin
# ... make changes ...
net.transaction_commit  # Commits to network object in memory
```

**Database Commit (Version Control):**
```ruby
net.commit('Description of changes')  # Commits to database version control
```

### LLM Agent Rules

1. **For bulk updates** - ALWAYS use transactions
2. **For version control** - Use `.commit('message')` to save to database
3. **Pattern:** `transaction_begin` → modify → `transaction_commit` → `commit('message')`

### Code Pattern

```ruby
# ✅ Correct pattern for bulk updates
net.transaction_begin
net.row_objects('hw_subcatchment').each do |sub|
  sub.drying_time = 1
  sub.write
end
net.transaction_commit  # Commit to network object
net.commit('Set drying time to 1 day')  # Commit to database

# ❌ Wrong - no transaction (slow for bulk updates)
net.row_objects('hw_subcatchment').each do |sub|
  sub.drying_time = 1
  sub.write  # Each write commits individually!
end
```

---

## ⚠️ CRITICAL: Parent Object Handling

### The Problem

Networks can be nested inside other networks OR inside model groups. Assuming parent is always 'Model Group' will fail.

**What FAILS:**
```ruby
# ❌ Assumes parent is always Model Group
parent_id = network.model_object.parent_id
group = db.model_object_from_type_and_id('Model Group', parent_id)
# ^ Crashes if network is inside another network
```

### LLM Agent Rules

1. **Try 'Model Group' first** using begin/rescue
2. **Fallback to 'Model Network'** if rescue triggered
3. **Get grandparent** if parent is a network

### Code Pattern

```ruby
# ✅ Correct - handles nested networks
parent_id = net.model_object.parent_id

begin
  group = db.model_object_from_type_and_id('Model Group', parent_id)
rescue
  parent_network = db.model_object_from_type_and_id('Model Network', parent_id)
  parent_id = parent_network.parent_id
  group = db.model_object_from_type_and_id('Model Group', parent_id)
end
```

---

## ⚠️ Domain-Specific Validation

### The Problem

Not all data quality issues are errors. Some conduit types legitimately have different behavior.

**Example: Reverse Slope Pipes**
```ruby
# ❌ Incomplete - flags pressure pipes as errors
if conduit.gradient < 0
  # Report as reverse slope
end

# ✅ Correct - excludes legitimate negative gradients
if conduit.gradient < 0 && 
   conduit.solution_model != 'Pressure' && 
   conduit.solution_model != 'ForceMain'
  # Report as reverse slope
end
```

### LLM Agent Rules

1. **Understand context** - Ask what's being validated and why
2. **Check for exceptions** - Some rules have legitimate exceptions
3. **Use domain logic** - Pressure/ForceMain pipes work differently

---

## ✅ Safe User Feedback Patterns

### Check Before Creating

```ruby
# ✅ Check if any results before creating objects
found_items = false
collection.each do |item|
  if condition
    item.selected = true
    found_items = true
  end
end

unless found_items
  puts "No items found. Selection list was not created."
  return
end

# Now safe to create selection list
```

### Handle Naming Conflicts

```ruby
# ✅ Ensure unique names with counter suffix
base_name = 'My Selection List'
list_name = base_name
counter = 1

parent_group.children.each do |child|
  while child.name == list_name
    list_name = "#{base_name}_#{counter}"
    counter += 1
  end
end

# Create with unique name
sl = parent_group.new_model_object('Selection List', list_name)
```

### Validate Collections

```ruby
# ✅ Check for nil and empty collections
if net.nil?
  puts "Error: No network open"
  return
end

nodes = net.row_objects('_nodes')
if nodes.nil? || nodes.empty?
  puts "Error: No nodes found"
  return
end
```

---

## 🎯 LLM Agent Checklist

## 📚 Related Context Files

Load in this order:
1. **This file** (Lessons_Learned.md) - FIRST, ALWAYS
2. Error_Reference.md - When debugging
3. API_Reference.md - For method signatures
4. Pattern_Reference.md - For code examples
5. Database_Reference.md - For table/type names

---

## 🔄 Update Log

| Date | Change | Reason |
|------|--------|--------|
| 2025-12-02 | Initial creation | Multiple runtime errors from assuming Ruby stdlib behavior |
| 2025-12-02 | Added DateTime warning | DateTime class unavailable in Exchange environment |
| 2025-12-02 | Added collection rules | WSModelObjectCollection doesn't support .find |
| 2025-12-02 | Added network traversal patterns | Testing revealed _seen flag critical for loop prevention |
| 2025-12-02 | Added structure/blob patterns | Blob structures use .size=0, require double .write |
| 2025-12-02 | Added simulation launch patterns | Must connect_local_agent before launch_sims |
| 2025-12-02 | Added scenario management | Scenario changes require commit, flags for field changes |

---

## ⚠️ CRITICAL: Network Traversal with _seen Flag

### The Problem

Networks can contain loops. Without tracking visited objects, traversal algorithms will process the same objects infinitely.

**What FAILS:**
```ruby
# ❌ Infinite loop on networks with cycles
unprocessed = [start_link]

while unprocessed.size > 0
  link = unprocessed.shift
  us_node = link.us_node
  
  if us_node
    us_node.us_links.each { |l| unprocessed << l }  # Re-adds same links!
  end
end
```

### LLM Agent Rules

1. **ALWAYS use `_seen` flag** for network traversal
2. **Set flag before adding** to unprocessed queue
3. **Check flag before processing** to skip already-seen objects

### Code Pattern

```ruby
# ✅ Correct - prevents infinite loops
unprocessed = []

selected_nodes.each do |node|
  node.us_links.each do |link|
    if !link._seen
      unprocessed << link
      link._seen = true  # Mark immediately
    end
  end
end

while unprocessed.size > 0
  link = unprocessed.shift
  link.selected = true
  
  us_node = link.us_node
  if us_node && !us_node._seen
    us_node._seen = true
    us_node.selected = true
    
    us_node.us_links.each do |l|
      if !l._seen
        unprocessed << l
        l._seen = true
      end
    end
  end
end
```

---

## ⚠️ CRITICAL: Blob Structures (Arrays/Tables in Objects)

### The Problem

Some object properties are blob structures (arrays of data) that have special write requirements.

**Examples:** `suds_controls`, `sections`, storage arrays

**What FAILS:**
```ruby
# ❌ .clear doesn't exist on blob structures
sub.suds_controls.clear

# ❌ Forgot to write structure itself
sub.suds_controls.size = 0
sub.write  # Not enough - structure not saved!
```

### LLM Agent Rules

1. **Clear with `.size = 0`** (not `.clear`)
2. **Write structure first** with `structure.write`
3. **Write parent second** with `parent.write`

### Code Pattern

```ruby
# ✅ Clearing blob structure
sub.suds_controls.size = 0
sub.suds_controls.write  # Write structure
sub.write                # Write parent

# ✅ Modifying blob structure data
reach.sections[0].roughness = 0.035
reach.sections.write  # Write structure
reach.write           # Write parent
```

---

## ⚠️ Simulation Launching (Exchange)

### The Problem

Launching simulations via agent requires specific setup and status monitoring.

**What FAILS:**
```ruby
# ❌ Forgot to connect agent
sims = [sim1, sim2]
WSApplication.launch_sims(sims, '.', false, 0, 0)  # Fails - no agent

# ❌ No status monitoring
WSApplication.launch_sims(sims, '.', false, 0, 0)
puts "Done"  # Wrong - sims still running!
```

### LLM Agent Rules

1. **Connect agent first** with `connect_local_agent(1)`
2. **Monitor status** with while loop checking `status == 'None'`  
3. **Use sleep** to avoid busy-waiting

### Code Pattern

```ruby
# ✅ Correct simulation launch pattern
sims_array = []
run.children.each { |sim| sims_array << sim }

# Connect to local agent
WSApplication.connect_local_agent(1)

# Launch simulations
WSApplication.launch_sims(sims_array, '.', false, 0, 0)

# Wait for completion
while sims_array.any? { |sim| sim.status == 'None' }
  puts 'Simulations running...'
  sleep 1
end

puts 'All simulations complete'
```

---

## ⚠️ Scenario Field Modifications

### The Problem

When modifying fields in scenarios, you must set flags to indicate scenario-specific changes.

**What FAILS:**
```ruby
# ❌ Modified field but no flag
sub.area_absolute_1 = new_value
sub.write  # Change not marked as scenario-specific
```

### LLM Agent Rules

1. **Set field value** normally
2. **Set corresponding flag** to "SCRP" (scenario-specific)
3. **Apply to all modified fields**

### Code Pattern

```ruby
# ✅ Scenario-specific field modification
# Create/switch to scenario first
timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
net.add_scenario(timestamp, nil, timestamp)
net.current_scenario = timestamp  # Not .set_scenario!

# Modify fields with flags
net.transaction_begin
sub.area_absolute_1 = new_value
sub.area_absolute_1_flag = "SCRP"  # Mark as scenario change
sub.area_absolute_2 = new_value2
sub.area_absolute_2_flag = "SCRP"
sub.write
net.transaction_commit
```

---

## ⚠️ Performance: Pre-build Hash Maps

### The Problem

Looking up relationships repeatedly in loops is inefficient. Build hash maps first.

**What FAILS:**
```ruby
# ❌ Slow - looks up subcatchments repeatedly
nodes.each do |node|
  node.navigate('subcatchments').each do |sub|  # Expensive!
    # Process subcatchment
  end
end
```

### LLM Agent Rules

1. **Build hash maps** before main processing loop
2. **Use `Hash.new { |h, k| h[k] = [] }`** for arrays
3. **Initialize with existing keys** if needed

### Code Pattern

```ruby
# ✅ Fast - pre-build node→subcatchments map
node_sub_map = Hash.new { |h, k| h[k] = [] }

# Initialize with all nodes
net.row_objects('hw_node').each do |node|
  node_sub_map[node.node_id] = []
end

# Build relationships
net.row_objects('hw_subcatchment').each do |sub|
  if sub.node_id != ''
    node_sub_map[sub.node_id] << sub
  end
end

# Now processing is fast
nodes.each do |node|
  node_sub_map[node.node_id].each do |sub|  # Fast lookup!
    # Process subcatchment
  end
end
```

---

## ⚠️ User Experience Patterns

### Selection State Requires Write

```ruby
# ❌ Selection not saved
obj.selected = true  # Not persisted

# ✅ Correct
obj.selected = true
obj.write  # Required to persist selection
```

### Confirmation for Destructive Operations

```ruby
# ✅ Always confirm deletions
choice = WSApplication.message_box(
  "Delete #{items.length} items?",
  "YesNo",
  "?",
  false
)

return unless choice == "Yes"

# Proceed with deletion...

# Remind to commit
WSApplication.message_box(
  "Items deleted. Remember to commit changes.",
  "OK",
  "Information",
  false
)
```

### Progress Feedback for Bulk Operations

```ruby
# ✅ Timing and feedback
start_time = Time.now

count = 0
collection.each do |item|
  # Process item
  count += 1
end

end_time = Time.now
duration = end_time - start_time

puts "Processed #{count} items in #{duration.round(2)} seconds"
```

---

## 🔄 Update Log

## 💡 Key Insight for LLMs

**InfoWorks Ruby is NOT standard Ruby**

Think of it as "Ruby syntax with custom API" rather than "Ruby with InfoWorks libraries". The custom collection classes deliberately limit functionality - they are NOT drop-in replacements for Ruby Arrays despite similar syntax.

**When in doubt:**
- Use `.each` loops exclusively
- Check for nil explicitly
- Wrap in rescue blocks
- Convert to `.to_a` if you need enumerable methods
