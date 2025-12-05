# ICM InfoWorks vs ICM SWMM Subcatchment Comparison Script
# Compares SWMM subcatchment data to InfoWorks runoff surfaces and land use tables

# =============================================================================
# Get the current network (ICM InfoWorks) and background network (ICM SWMM)
# =============================================================================
cn = WSApplication.current_network
bn = WSApplication.background_network

# FIX: Use .model_object.name instead of .network_name
# We also add a check to ensure the network exists (is not nil) before asking for its name

if cn
  puts "Current Network:    #{cn.model_object.name}"
else
  puts "Current Network:    [None]"
end

if bn
  puts "Background Network: #{bn.model_object.name}"
else
  puts "Background Network: [None]"
end

puts "=" * 100
puts "ICM InfoWorks vs ICM SWMM Subcatchment Comparison"
puts "=" * 100
puts ""

# =============================================================================
# DIAGNOSTIC: List available tables in each network
# =============================================================================
# Helper method to list tables safely
def list_tables(net, label)
  puts "AVAILABLE TABLES IN #{label}:"
  puts "-" * 80
  
  if net.nil?
    puts "  Network not available."
    return
  end

  begin
    # net.tables returns WSTableInfo objects. We must call .name on them.
    table_names = net.tables.map { |t| t.name }.sort
    puts "  Found #{table_names.count} tables."
    # Print first 10 just to verify without spamming console
    puts "  First 5 tables: #{table_names.first(5).join(', ')}..."
  rescue => e
    puts "  Error listing tables: #{e.message}"
  end
end

list_tables(cn, "CURRENT NETWORK")
puts ""
list_tables(bn, "BACKGROUND NETWORK")

puts ""
puts "-" * 80

# =============================================================================
# Try to access sw_subcatchment (SWMM)
# =============================================================================
puts "ATTEMPTING TO ACCESS sw_subcatchment IN BACKGROUND NETWORK:"
puts "-" * 80

if bn
  begin
    count = 0
    # SWMM Table is 'sw_subcatchment'
    bn.row_objects('sw_subcatchment').each do |sc|
      count += 1
      if count <= 3
        # FIX: SWMM objects do not have .subcatchment_id
        # Use .id (universal primary key accessor) or .name (specific to SWMM)
        puts "  Found SWMM ID: #{sc.id}" 
      end
    end
    puts "  Total sw_subcatchment count: #{count}"
  rescue => e
    puts "  ERROR accessing sw_subcatchment: #{e.message}"
    puts "  Error class: #{e.class}"
  end
else
  puts "  Background network is nil. Skipped."
end

puts ""

# =============================================================================
# Try to access hw_subcatchment (InfoWorks)
# =============================================================================
puts "ATTEMPTING TO ACCESS hw_subcatchment IN CURRENT NETWORK:"
puts "-" * 80

if cn
  begin
    count = 0
    # InfoWorks Table is 'hw_subcatchment'
    cn.row_objects('hw_subcatchment').each do |sc|
      count += 1
      if count <= 3
        # FIX: InfoWorks objects use subcatchment_id, but .id works everywhere
        puts "  Found InfoWorks ID: #{sc.subcatchment_id}" 
      end
    end
    puts "  Total hw_subcatchment count: #{count}"
  rescue => e
    puts "  ERROR accessing hw_subcatchment: #{e.message}"
    puts "  Error class: #{e.class}"
  end
else
  puts "  Current network is nil. Skipped."
end

puts ""
puts "=" * 100
puts "Diagnostic Complete"
puts "=" * 100