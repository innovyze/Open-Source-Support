# Ruby Programming Fundamentals for InfoWorks ICM

**For Human Developers** - This file covers Ruby basics for those new to the language.

**InfoWorks ICM uses Ruby 2.4.0** with embedded interpreter (no external gem support).

---

## Variables and Data Types

### Integers vs Floating Point
```ruby
# Integer division (common mistake!)
puts 10/3        # => 3 (truncated)
puts 10.0/3      # => 3.333... (correct)
puts 10/3.0      # => 3.333... (correct)
```

### Strings
```ruby
# Single quotes - literal strings
'Hello World'

# Double quotes - with interpolation and escape sequences
"Node #{node_id} has depth #{depth.round(2)}"
"Line 1\nLine 2"  # \n for newline

# String concatenation
'Hello' + ' ' + 'World'

# Conversion to string
my_number.to_s    # Always use when building strings
```

### nil vs Zero vs Empty String
```ruby
# nil is NOT the same as 0 or empty string
node.width.nil?   # true if field is blank
node.width == 0   # false if field is nil (causes error!)
node.width == ''  # TypeError - can't compare number to string
```

---

## Control Flow

### While Loops
```ruby
# Basic while loop
i = 0
while i < 100
  puts i
  i = i + 1  # Ruby doesn't support i++
end

# Common mistake - infinite loop if increment forgotten
i = 0
while i < nodes.length
  puts nodes[i].id
  # Missing: i = i + 1  <- Causes infinite loop!
end
```

### If/Elsif/Else
```ruby
# Single condition
if width < 200
  puts 'small'
end

# If/else
if width < 200
  puts 'small'
else
  puts 'not small'
end

# If/elsif/else (NOT 'elseif' - common mistake!)
if width < 200
  puts 'small'
elsif width < 400
  puts 'medium'
else
  puts 'large'
end

# Inline if (concise form)
pipe.selected = true if width < 200

# Order matters! Tests execute sequentially
if width < 400    # WRONG - catches width < 200 too
  puts 'medium'
elsif width < 200
  puts 'small'    # Never executes!
end
```

### Logical Operators
```ruby
# AND operator (both must be true)
if width > 100 && width < 200
  puts 'medium'
end

# OR operator (at least one must be true)
if width < 100 || length < 50
  puts 'small'
end

# NOT operator
if !node.nil?
  puts node.id
end

# Handling nil in comparisons (CRITICAL!)
# WRONG - crashes if width is nil:
if pipe.width < 200
  pipe.selected = true
end

# CORRECT - check for nil first:
if !pipe.width.nil? && pipe.width < 200
  pipe.selected = true
end

# CORRECT - using || for either condition:
if (!pipe.width.nil? && pipe.width < 200) || (!pipe.length.nil? && pipe.length < 60)
  pipe.selected = true
end
```

---

## Arrays

### Array Basics
```ruby
# Create array
days = ['Monday', 'Tuesday', 'Wednesday']

# Access elements (zero-indexed!)
days[0]   # => 'Monday' (first element)
days[1]   # => 'Tuesday' (second element)
days[-1]  # => last element
days[-2]  # => second-to-last

# Array length
days.length  # => 3

# Create empty array
my_array = Array.new

# Add elements
my_array << 'value'
my_array.push 'another'

# Check membership
my_array.include?('value')  # => true

# Find index
my_array.index('value')  # => 0 (or nil if not found)

# Remove first element
first = my_array.shift
```

### Iterating Arrays
```ruby
# Old style - while loop
i = 0
while i < days.length
  puts days[i]
  i = i + 1
end

# Modern style - each (preferred!)
days.each do |day|
  puts day
end

# Ranges
(1..100).each do |i|
  puts i
end

(0...days.length).each do |i|  # Note: 3 dots = exclusive end
  puts days[i]
end
```

---

## Hashes

### Hash Basics
```ruby
# Create empty hash
counts = Hash.new

# Add key-value pairs
counts['ST'] = 48
counts['MH'] = 70

# Check for key
counts.has_key?('ST')  # => true

# Access value
counts['ST']  # => 48

# Initialize with data
defects = {
  'B' => 'Broken Pipe',
  'BJ' => 'Broken Joint',
  'CC' => 'Crack Circumferential'
}

# Iterate hash
counts.each do |key, value|
  puts "#{key}: #{value}"
end

# Get sorted keys
counts.keys.sort.each do |key|
  puts "#{key}: #{counts[key]}"
end
```

### Practical Example - Counting Codes
```ruby
net = WSApplication.current_network
code_counts = Hash.new

net.row_objects('cams_cctv_survey').each do |survey|
  survey.details.each do |detail|
    code = detail.code
    if !code_counts.has_key?(code)
      code_counts[code] = 0
    end
    code_counts[code] += 1
  end
end

# Output sorted results
code_counts.keys.sort.each do |code|
  puts "#{code}: #{code_counts[code]}"
end
```

---

## Operators and Shortcuts

```ruby
# Increment operators
i = i + 1   # Full form
i += 1      # Shortcut (Ruby does NOT support i++)

# Other compound operators
x -= 5      # x = x - 5
x *= 2      # x = x * 2
x /= 3      # x = x / 3

# Comparison operators
<   # less than
<=  # less than or equal to
==  # equal to (NOT =)
!=  # not equal to
>   # greater than
>=  # greater than or equal to

# Logical operators
&&  # AND
||  # OR
!   # NOT
```

---

## Code Formatting and Indentation

Indent code blocks using consistent spacing (2 spaces or 1 tab per level):

```ruby
# HARD TO READ - No indentation
net.row_objects('hw_node').each do |node|
if !node.ground_level.nil?
if node.ground_level < 100
node.selected = true
end
end
end

# READABLE - Proper indentation
net.row_objects('hw_node').each do |node|
  if !node.ground_level.nil?
    if node.ground_level < 100
      node.selected = true
    end
  end
end
```

---

## Code Comments

Ruby comments begin with `#`:

```ruby
# This is a comment on its own line

i = i + 1  # This is a comment after code

# This comment spans
# multiple lines
```

**Best Practices:**
- **Don't just repeat the code:** `i = i + 1  # Add 1 to i` is useless
- **Explain WHY, not WHAT:** `i += 1  # Track number of nodes processed` is helpful
- **Keep comments current:** Update comments when code changes

---

## Common Beginner Mistakes

```ruby
# Using = instead of == for comparison
if width = 200  # WRONG - assigns 200 to width!
if width == 200  # Correct

# Forgetting .to_s when concatenating
puts 'Value: ' + my_number  # TypeError!
puts "Value: #{my_number}"  # Correct

# Off-by-one errors with array indices
days = ['Mon', 'Tue', 'Wed']
puts days[3]  # nil (array has indices 0, 1, 2)
puts days[-1] # 'Wed' (last element)

# Comparing nil without checking first
if node.width < 200  # Crashes if width is nil!
if !node.width.nil? && node.width < 200  # Correct

# Using 'elseif' instead of 'elsif'
elseif x < 20  # WRONG
elsif x < 20   # Correct

# Forgetting loop increment
i = 0
while i < 100
  puts i
  # Missing i += 1 causes infinite loop!
end
```

---

**Last Updated:** January 16, 2026
