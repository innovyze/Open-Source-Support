# InfoWorks ICM Ruby Error Reference

**Purpose:** Quick diagnostic reference mapping common error messages to solutions and pattern IDs. Load conditionally when debugging issues.

**Load Condition:** CONDITIONAL - Load only when query contains error/debugging keywords  
**Keywords:** error, exception, fails, broken, debugging, NoMethodError, NilClass, undefined method

**Last Updated:** October 21, 2025

---

## Common Error Messages

### "undefined method 'current_network' for WSApplication:Class"

**Symptom:** Script fails immediately in Exchange context  
**Cause:** Using UI-only method in Exchange script  
**Solution:** See PAT_SCRIPT_INIT_001 (UI) vs PAT_SCRIPT_INIT_002 (Exchange)

**Quick Fix:**
```ruby
# UI Script:
net = WSApplication.current_network

# Exchange Script:
db = WSApplication.open('path/to/database.icmm', false)
net = db.model_object('>MODG~Group>NNET~Network').open
```

---

### "NoMethodError: undefined method 'write' for nil:NilClass"

**Symptom:** Script crashes when trying to modify object  
**Cause:** Object lookup returned nil (not found)  
**Solution:** See PAT_NULL_GUARD_028

**Quick Fix:**
```ruby
# Check before using:
node = net.row_object('hw_node', 'MH001')
if node.nil?
  puts "Error: Node not found"
  exit
end
node.ground_level = 125.5
node.write

# Or use safe navigation:
net.row_object('hw_node', 'MH001')&.write
```

---

### "collection modified during iteration"

**Symptom:** Script crashes partway through processing  
**Cause:** Deleting/adding to collection while iterating  
**Solution:** Convert to array first with .to_a

**Quick Fix:**
```ruby
# WRONG:
net.row_objects('hw_node').each { |n| n.delete if condition }

# CORRECT:
net.row_objects('hw_node').to_a.each { |n| n.delete if condition }
```

---

### Changes Not Being Saved

**Symptom:** Script runs without error but data unchanged  
**Cause:** Missing write() call after modifications  
**Solution:** See PAT_NETWORK_MODIFY_001, PAT_STRUCTURE_DATA_010

**Quick Fix:**
```ruby
node = net.row_object('hw_node', 'MH001')
node.ground_level = 125.5
node.write  # REQUIRED!

# For structures, write both:
reach.sections[0].roughness = 0.035
reach.sections.write  # Write structure
reach.write           # Write parent
```

---

### "Database is locked" or "Cannot open database"

**Symptom:** Cannot open database in Exchange script  
**Cause:** Database already open elsewhere  
**Solutions:**
1. Close database in InfoWorks ICM UI
2. Ensure previous scripts closed properly
3. Use ensure block to guarantee cleanup

**Quick Fix:**
```ruby
db = WSApplication.open(path, false)
begin
  # Your code...
ensure
  db.close  # Always executes
end
```

---

### "Model object not found" (Scripting Path Error)

**Symptom:** Cannot locate network/run in database  
**Cause:** Incorrect scripting path format or special character escaping  
**Solution:** See InfoWorks_ICM_Ruby_Database_Reference.md

**Quick Fix:**
```ruby
# Format: >TYPE~Name>TYPE~Name
path = '>MODG~My Group>NNET~My Network'

# Escape special characters (> ~ \) with backslash:
path = '>MODG~My\~Group>NNET~My\>Network'

# Find object paths:
db.root_model_objects.each { |mo| puts mo.path }
```

---

### "Network not found" or "Database not found"

**Symptom:** File path error in Exchange script  
**Cause:** Incorrect path format or file doesn't exist  
**Solution:** Use absolute paths with forward slashes

**Quick Fix:**
```ruby
# Test path first:
db_path = 'C:/Data/database.icmm'
if File.exist?(db_path)
  db = WSApplication.open(db_path, false)
else
  puts "File not found: #{db_path}"
end

# Use forward slashes OR escaped backslashes:
'C:/Data/db.icmm'        # Preferred
'C:\\Data\\db.icmm'      # Also works
```

---

### Field Access Errors (undefined method for field name)

**Symptom:** Field name works in UI but fails in script  
**Cause:** Field name conflicts with Ruby method or has special characters  
**Solution:** Use bracket syntax for problematic fields

**Quick Fix:**
```ruby
# Dot syntax (standard):
value = node.ground_level

# Bracket syntax (for special cases):
value = node['User Text']
value = node['Category']  # If 'Category' conflicts with method
```

---

### Transaction Commit Failures

**Symptom:** transaction_commit fails with validation error  
**Cause:** Data violates network rules (missing nodes, invalid values)  
**Solution:** See PAT_TRANSACTION_005

**Quick Fix:**
```ruby
net.transaction_begin
begin
  # Your modifications...
  net.transaction_commit
rescue => e
  puts "Transaction failed: #{e.message}"
  # Transaction automatically rolled back
end
```

---

### Simulation Won't Start or Fails Immediately

**Symptom:** sim.run or sim.run_ex doesn't execute  
**Cause:** Network validation errors, missing data, or agent issues  
**Solutions:**
1. Check simulation status
2. Validate network first
3. Connect to agent

**Quick Fix:**
```ruby
# Check status:
puts "Sim status: #{sim.status}"

# Connect agent:
WSApplication.connect_local_agent(1000)

# Run with error handling:
begin
  sim.run_ex('.', 1)
rescue => e
  puts "Run failed: #{e.message}"
end
```

---

### Can't Access Simulation Results

**Symptom:** Results methods fail or return empty  
**Cause:** Simulation not complete or results not stored  
**Solution:** Check status before accessing

**Quick Fix:**
```ruby
if sim.status != 'Complete'
  puts "Simulation incomplete: #{sim.status}"
  exit
end

# Now safe to access results
```

---

### Import/Export Fails Silently (ODIC/ODEC)

**Symptom:** No error but data not imported/exported  
**Cause:** Configuration issue or data format problem  
**Solution:** See PAT_IMPORT_EXPORT_022, PAT_IMPORT_EXPORT_023, use error file

**Quick Fix:**
```ruby
options = {
  'Error File' => './import_errors.txt',
  'Duplication Behaviour' => 'Merge'
}

net.odic_import_ex('CSV', 'config.cfg', options, 'Node', 'nodes.csv')

# Check error file:
if File.exist?('./import_errors.txt') && File.size('./import_errors.txt') > 0
  puts "Import errors:"
  puts File.read('./import_errors.txt')
end
```

---

### Script Produces No Output

**Symptom:** Script runs but no console/window output  
**Cause:** Wrong output method for environment  
**Solutions:**

**UI Scripts:**
- Output Window: View → Output Window (Ctrl+Shift+O)
- Use `puts` statements

**Exchange Scripts:**
- Output to console automatically
- Redirect to file: `ICMExchange.exe script.rb > output.txt`

---

### "syntax error, unexpected end-of-input"

**Symptom:** Script won't parse/load  
**Cause:** Mismatched block delimiters (missing `end`)  
**Solution:** Check all do/end, if/end, begin/end pairs

**Quick Fix:**
- Use editor with syntax highlighting
- Check bracket/delimiter matching
- Count `do` vs `end` statements

---

### String Interpolation Doesn't Work

**Symptom:** Variables not expanded in strings  
**Cause:** Using single quotes instead of double quotes  
**Solution:** Use double quotes for interpolation

**Quick Fix:**
```ruby
name = 'Node'

# WRONG (single quotes):
puts 'Object: #{name}'  # Prints literally: Object: #{name}

# CORRECT (double quotes):
puts "Object: #{name}"  # Prints: Object: Node
```

---

### Can't Require External Gems

**Symptom:** `require 'gem_name'` fails  
**Cause:** InfoWorks ICM uses embedded Ruby 2.4.0 - no gem support  
**Solution:** See PAT_STANDARD_LIBRARIES_046

**Workarounds:**
```ruby
# Can use standard library:
require 'csv'
require 'json'
require 'date'

# Can load local .rb files:
require 'C:/Scripts/my_utilities.rb'

# Cannot use:
require 'nokogiri'  # External gems not available
```

---

## Performance Issues

### Script Very Slow on Large Network

**Causes:**
1. Not using transactions (commits every change individually)
2. Unnecessary object lookups
3. Inefficient filtering

**Solutions:**
```ruby
# 1. USE TRANSACTIONS:
net.transaction_begin
net.row_objects('hw_conduit').each do |c|
  c.diameter += 10
  c.write
end
net.transaction_commit

# 2. CACHE LOOKUPS:
node = net.row_object('hw_node', 'MH001')  # Lookup once
x = node.x
y = node.y
# Use x and y multiple times...

# 3. FILTER EARLY:
large = net.row_objects('hw_conduit').select { |c| c.diameter > 600 }
large.each { |c| process(c) }
```

---

### Script Runs Out of Memory

**Cause:** Processing entire large network at once  
**Solution:** Process in batches

**Quick Fix:**
```ruby
batch_size = 1000
offset = 0

loop do
  batch = net.row_objects('hw_conduit').drop(offset).take(batch_size)
  break if batch.empty?
  
  net.transaction_begin
  batch.each { |c| process(c); c.write }
  net.transaction_commit
  
  offset += batch_size
  puts "Processed #{offset} conduits"
end
```

---

## Debugging Techniques

### Verify Ruby Environment

```ruby
puts "Ruby version: #{RUBY_VERSION}"        # Should be 2.4.0
puts "Platform: #{RUBY_PLATFORM}"
puts "\nWSApplication methods:"
WSApplication.methods.sort.each { |m| puts "  #{m}" }
```

### Inspect Object Details

```ruby
node = net.row_object('hw_node', 'MH001')
puts "Class: #{node.class}"
puts "Nil?: #{node.nil?}"
puts "Methods: #{node.methods.sort}"

# Check available fields:
puts node.table_info.fields.map(&:name)
```

### Full Exception Details

```ruby
begin
  # Your code...
rescue => e
  puts "Error class: #{e.class}"
  puts "Message: #{e.message}"
  puts "Backtrace:"
  puts e.backtrace.join("\n")
end
```

---

## Cross-References

For correct usage patterns, see:
- **Pattern_Reference.md** - Pattern IDs referenced above
- **Tutorial_Context.md** - Complete working examples
- **Database_Reference.md** - Table names and object types
- **Glossary.md** - Term definitions

---

**Note:** This file is designed for conditional loading during debugging. For general usage patterns, always consult the Pattern Reference and Tutorial Context first.
