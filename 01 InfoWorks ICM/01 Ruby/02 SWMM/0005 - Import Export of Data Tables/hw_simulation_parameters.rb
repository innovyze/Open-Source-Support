# Debug script to find how to access parameter tables in InfoWorks ICM

begin
  cn = WSApplication.current_network
  raise "No network loaded." if cn.nil?
rescue => e
  puts "ERROR: Could not get current network: #{e.message}"
  exit
end

puts "=== Debugging Parameter Table Access Methods ==="
puts "Network object class: #{cn.class}"
puts ""

# Check what methods are available on the network object
puts "--- Network object methods containing 'sim' or 'param' ---"
cn.methods.grep(/sim|param/i).sort.each { |m| puts "  cn.#{m}" }
puts ""

# Check for current_sim
if cn.respond_to?(:current_sim)
  puts "--- current_sim is available ---"
  current_sim = cn.current_sim
  if current_sim
    puts "current_sim class: #{current_sim.class}"
    puts "current_sim methods containing 'param' or 'row':"
    current_sim.methods.grep(/param|row/i).sort.each { |m| puts "  current_sim.#{m}" }
    
    # Try to access hw_sim_parameters through current_sim
    if current_sim.respond_to?(:hw_sim_parameters)
      puts "\nSUCCESS: current_sim.hw_sim_parameters is available!"
      obj = current_sim.hw_sim_parameters
      puts "Object class: #{obj.class}"
      puts "Sample methods: #{obj.methods.first(10)}"
    end
  else
    puts "current_sim is nil"
  end
else
  puts "--- current_sim is NOT available ---"
end
puts ""

# Check for options
if cn.respond_to?(:options)
  puts "--- options is available ---"
  options = cn.options
  if options
    puts "options class: #{options.class}"
    puts "options methods containing 'default':"
    options.methods.grep(/default/i).sort.each { |m| puts "  options.#{m}" }
  end
else
  puts "--- options is NOT available ---"
end
puts ""

# Test row_object with different arguments
puts "--- Testing row_object methods ---"
test_table = 'hw_sim_parameters'

# Test 1: row_object with one argument
begin
  obj = cn.row_object(test_table)
  puts "SUCCESS: cn.row_object('#{test_table}') works!"
  puts "Object class: #{obj.class}"
rescue ArgumentError => e
  puts "FAILED: cn.row_object('#{test_table}') - #{e.message}"
end

# Test 2: row_object with empty string
begin
  obj = cn.row_object(test_table, '')
  puts "SUCCESS: cn.row_object('#{test_table}', '') works!"
  puts "Object class: #{obj.class}"
rescue ArgumentError => e
  puts "FAILED: cn.row_object('#{test_table}', '') - #{e.message}"
end

# Test 3: row_object with nil
begin
  obj = cn.row_object(test_table, nil)
  puts "SUCCESS: cn.row_object('#{test_table}', nil) works!"
  puts "Object class: #{obj.class}"
rescue ArgumentError => e
  puts "FAILED: cn.row_object('#{test_table}', nil) - #{e.message}"
end
puts ""

# Test row_objects (plural)
puts "--- Testing row_objects (plural) ---"
begin
  objects = cn.row_objects(test_table)
  if objects
    puts "SUCCESS: cn.row_objects('#{test_table}') returned something"
    puts "Objects class: #{objects.class}"
    count = 0
    objects.each { count += 1 }
    puts "Number of objects: #{count}"
    if count > 0
      puts "First object class: #{objects.first.class}"
    end
  end
rescue => e
  puts "FAILED: cn.row_objects('#{test_table}') - #{e.message}"
end
puts ""

# Check for table_info or similar methods
puts "--- Checking for table info methods ---"
if cn.respond_to?(:table_info)
  puts "cn.table_info is available"
  begin
    info = cn.table_info(test_table)
    puts "Table info: #{info.inspect}"
  rescue => e
    puts "Error getting table info: #{e.message}"
  end
end

if cn.respond_to?(:tables)
  puts "cn.tables is available"
  begin
    tables = cn.tables
    puts "Available tables: #{tables.inspect}"
  rescue => e
    puts "Error getting tables: #{e.message}"
  end
end
puts ""

# Try to find parameter tables through inspection
puts "--- Searching for parameter-related properties ---"
param_tables = ['hw_sim_parameters', 'hw_manhole_defaults', 'hw_conduit_defaults', 
                'hw_subcatchment_defaults', 'hw_wq_params']

param_tables.each do |table|
  puts "\nChecking for '#{table}':"
  
  # Direct property on cn
  if cn.respond_to?(table.to_sym)
    puts "  ✓ cn.#{table} exists"
  end
  
  # Property on current_sim
  if cn.respond_to?(:current_sim) && cn.current_sim && cn.current_sim.respond_to?(table.to_sym)
    puts "  ✓ cn.current_sim.#{table} exists"
  end
  
  # Property on options
  if cn.respond_to?(:options) && cn.options && cn.options.respond_to?(table.to_sym)
    puts "  ✓ cn.options.#{table} exists"
  end
end

puts "\n=== End of Debug ==="