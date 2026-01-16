# ICM InfoWorks vs ICM SWMM Subcatchment Comparison Script
# Compares SWMM subcatchment data to InfoWorks runoff surfaces and land use tables

# =============================================================================
# Get the current network (ICM InfoWorks) and background network (ICM SWMM)
# =============================================================================
cn = WSApplication.current_network
bn = WSApplication.background_network

puts "=" * 100
puts "ICM InfoWorks vs ICM SWMM Subcatchment Comparison"
puts "=" * 100
puts ""

# =============================================================================
# DIAGNOSTIC: Show network information
# =============================================================================
puts "NETWORK INFORMATION:"
puts "-" * 80

if cn.nil?
  puts "Current Network: NOT FOUND"
else
  puts "Current Network:"
  puts "  Object: #{cn}"
  puts "  Class:  #{cn.class}"
  begin; puts "  Name:   #{cn.name}"; rescue => e; puts "  Name:   (error: #{e.message})"; end
  begin; puts "  Path:   #{cn.path}"; rescue => e; puts "  Path:   (error: #{e.message})"; end
  begin; puts "  Type:   #{cn.type}"; rescue => e; puts "  Type:   (error: #{e.message})"; end
end

puts ""

if bn.nil?
  puts "Background Network: NOT FOUND"
else
  puts "Background Network:"
  puts "  Object: #{bn}"
  puts "  Class:  #{bn.class}"
  begin; puts "  Name:   #{bn.name}"; rescue => e; puts "  Name:   (error: #{e.message})"; end
  begin; puts "  Path:   #{bn.path}"; rescue => e; puts "  Path:   (error: #{e.message})"; end
  begin; puts "  Type:   #{bn.type}"; rescue => e; puts "  Type:   (error: #{e.message})"; end
end

puts ""
puts "-" * 80

# =============================================================================
# DIAGNOSTIC: List available tables in each network
# =============================================================================
puts "AVAILABLE TABLES IN CURRENT NETWORK:"
puts "-" * 80
begin
  cn.tables.each do |table|
    puts "  #{table}"
  end
rescue => e
  puts "  Error listing tables: #{e.message}"
  # Try alternate method
  begin
    cn.table_names.each do |name|
      puts "  #{name}"
    end
  rescue => e2
    puts "  Alternate method also failed: #{e2.message}"
  end
end

puts ""
puts "AVAILABLE TABLES IN BACKGROUND NETWORK:"
puts "-" * 80
begin
  bn.tables.each do |table|
    puts "  #{table}"
  end
rescue => e
  puts "  Error listing tables: #{e.message}"
  # Try alternate method
  begin
    bn.table_names.each do |name|
      puts "  #{name}"
    end
  rescue => e2
    puts "  Alternate method also failed: #{e2.message}"
  end
end

puts ""
puts "-" * 80

# =============================================================================
# Try to access sw_subcatchment directly and show any errors
# =============================================================================
puts "ATTEMPTING TO ACCESS sw_subcatchment IN BACKGROUND NETWORK:"
puts "-" * 80
begin
  count = 0
  bn.row_objects('sw_subcatchment').each do |sc|
    count += 1
    if count <= 3
      puts "  Found: #{sc.subcatchment_id}"
    end
  end
  puts "  Total sw_subcatchment count: #{count}"
rescue => e
  puts "  ERROR accessing sw_subcatchment: #{e.message}"
  puts "  Error class: #{e.class}"
end

puts ""
puts "ATTEMPTING TO ACCESS hw_subcatchment IN CURRENT NETWORK:"
puts "-" * 80
begin
  count = 0
  cn.row_objects('hw_subcatchment').each do |sc|
    count += 1
    if count <= 3
      puts "  Found: #{sc.subcatchment_id}"
    end
  end
  puts "  Total hw_subcatchment count: #{count}"
rescue => e
  puts "  ERROR accessing hw_subcatchment: #{e.message}"
  puts "  Error class: #{e.class}"
end

puts ""
puts "=" * 100
puts "Diagnostic Complete"
puts "=" * 100