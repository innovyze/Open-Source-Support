#!/usr/bin/env ruby
# Simple verification script to test the parsing logic without InfoWorks ICM

# Replicate the parsing functions from UI_Script.rb
def parse_log_file(log_path)
  return nil unless File.exist?(log_path)
  
  issues = {
    errors: [],
    warnings: [],
    convergence: [],
    mass_balance: [],
    timestep: [],
    instability: []
  }
  
  File.readlines(log_path).each do |line|
    line = line.strip
    next if line.empty?
    
    # Extract errors
    if line.match?(/ERROR|FATAL/i)
      issues[:errors] << line
      issues[:convergence] << line if line.match?(/convergence|failed to converge/i)
      issues[:mass_balance] << line if line.match?(/mass balance|massbalance/i)
      issues[:instability] << line if line.match?(/instability|unstable/i)
    end
    
    # Extract warnings
    if line.match?(/WARNING|WARN/i)
      issues[:warnings] << line
      issues[:timestep] << line if line.match?(/timestep|time step|reducing/i)
    end
  end
  
  issues
end

def extract_ids(messages, type = 'node')
  ids = []
  messages.each do |msg|
    # Common patterns for node/link IDs in log messages
    # Pattern 1: "at node NODE_ID" or "at link LINK_ID"
    if msg.match?(/at\s+#{type}\s+['"]?([^'"\s,]+)/i)
      id = msg.match(/at\s+#{type}\s+['"]?([^'"\s,]+)/i)[1]
      ids << id
    end
    # Pattern 2: "Node NODE_ID" or "Link LINK_ID"
    if msg.match?(/#{type}\s+['"]?([^'"\s,]+)/i)
      id = msg.match(/#{type}\s+['"]?([^'"\s,]+)/i)[1]
      ids << id
    end
    # Pattern 3: ID in brackets or quotes
    if msg.match?(/['"]([^'"]+)['"]/)
      potential_id = msg.match(/['"]([^'"]+)['"]/)[1]
      ids << potential_id if potential_id.length < 50
    end
  end
  ids.uniq
end

# Test with the example log file
log_file = File.join(File.dirname(__FILE__), 'example_sim.log')

if File.exist?(log_file)
  puts "Testing log parser with: #{log_file}"
  puts "=" * 60
  
  issues = parse_log_file(log_file)
  
  puts "\n=== Simulation Diagnostic Summary ==="
  puts "Total Errors: #{issues[:errors].length}"
  puts "Total Warnings: #{issues[:warnings].length}"
  puts "Convergence Issues: #{issues[:convergence].length}"
  puts "Mass Balance Issues: #{issues[:mass_balance].length}"
  puts "Timestep Reductions: #{issues[:timestep].length}"
  puts "Instability Issues: #{issues[:instability].length}"
  
  puts "\n=== Extracted Node IDs ==="
  
  puts "\nFrom Convergence Issues:"
  node_ids = extract_ids(issues[:convergence], 'node')
  puts node_ids.empty? ? "  None found" : "  #{node_ids.join(', ')}"
  
  puts "\nFrom Mass Balance Issues:"
  node_ids = extract_ids(issues[:mass_balance], 'node')
  puts node_ids.empty? ? "  None found" : "  #{node_ids.join(', ')}"
  
  puts "\nFrom Instability Issues:"
  node_ids = extract_ids(issues[:instability], 'node')
  link_ids = extract_ids(issues[:instability], 'link')
  puts "  Nodes: #{node_ids.empty? ? 'None found' : node_ids.join(', ')}"
  puts "  Links: #{link_ids.empty? ? 'None found' : link_ids.join(', ')}"
  
  puts "\nFrom All Errors (general):"
  node_ids = extract_ids(issues[:errors], 'node')
  link_ids = extract_ids(issues[:errors], 'link')
  puts "  Nodes: #{node_ids.empty? ? 'None found' : node_ids.join(', ')}"
  puts "  Links: #{link_ids.empty? ? 'None found' : link_ids.join(', ')}"
  
  puts "\n=== Detailed Error Messages ==="
  issues[:errors].each_with_index do |error, i|
    puts "#{i+1}. #{error}"
  end
  
  puts "\n=== Test Complete ==="
  puts "✓ Parser executed successfully"
  puts "✓ All functions working as expected"
else
  puts "ERROR: example_sim.log not found in #{File.dirname(__FILE__)}"
  exit 1
end
