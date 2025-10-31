# Script: 03_flow_capacity_comparison.rb
# Context: Exchange
# Purpose: Compare peak flows vs pipe capacity with color-coded severity
# Outputs: HTML + CSV
# Usage: ruby script.rb [database_path] [simulation_name]

begin
  puts "Flow vs Capacity Comparison - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulation
  sim_name = ARGV[1]
  unless sim_name
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_name]"
    exit 1
  end
  
  sim_mo = db.model_object(sim_name)
  
  if sim_mo.status != 'Success'
    puts "ERROR: Simulation '#{sim_name}' status is #{sim_mo.status}"
    exit 1
  end
  
  # Extract flow vs capacity data
  net = sim_mo.open
  pipes = []
  
  net.row_objects('hw_conduit').each do |pipe|
    peak_flow = pipe.result('flow') rescue nil
    # Calculate capacity from geometry: Q = A × V
    # Area = width × height (convert mm to m), V = typical max velocity (5 m/s)
    width = pipe['conduit_width'] rescue nil
    height = pipe['conduit_height'] rescue width rescue nil
    if width && height && width > 0 && height > 0
      area = (width / 1000.0) * (height / 1000.0)  # Convert mm to m
      max_velocity = 5.0  # Typical max velocity for sewer systems (m/s)
      capacity = area * max_velocity
    else
      capacity = nil
    end
    
    if peak_flow && capacity && capacity > 0
      peak_flow = peak_flow.abs
      util_pct = (peak_flow / capacity * 100).round(1)
      
      severity = if util_pct > 100
        'Critical'
      elsif util_pct > 85
        'High'
      elsif util_pct > 70
        'Medium'
      else
        'Low'
      end
      
      pipes << {
        id: pipe.id,
        peak_flow: peak_flow.round(3),
        capacity: capacity.round(3),
        util_pct: util_pct,
        severity: severity
      }
    end
  end
  
  net.close
  
  if pipes.empty?
    puts "No pipe flow/capacity data found"
    exit 0
  end
  
  # Sort by utilization
  pipes.sort_by! { |p| -p[:util_pct] }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'flow_capacity.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "PipeID,PeakFlow,Capacity,Utilization,Severity"
    pipes.each { |p| f.puts "#{p[:id]},#{p[:peak_flow]},#{p[:capacity]},#{p[:util_pct]},#{p[:severity]}" }
  end
  
  html_file = File.join(output_dir, 'flow_capacity.html')
  html = <<-HTML
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>Flow Capacity</title>
<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid #1976d2}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd}th{background:#1976d2;color:white}.critical{background:#ffcdd2}.high{background:#ffe0b2}.medium{background:#fff9c4}.low{background:#c8e6c9}</style></head>
<body><div class="container"><h1>Flow vs Capacity Analysis</h1><table><tr><th>Pipe ID</th><th>Peak Flow</th><th>Capacity</th><th>Utilization</th><th>Severity</th></tr>
  HTML
  
  pipes.each { |p| html += "<tr class='#{p[:severity].downcase}'><td>#{p[:id]}</td><td>#{p[:peak_flow]}</td><td>#{p[:capacity]}</td><td>#{p[:util_pct]}%</td><td>#{p[:severity]}</td></tr>" }
  html += "</table><p><strong>CSV:</strong> flow_capacity.csv</p></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Analysis complete: #{html_file}"
  puts "  - Pipes analyzed: #{pipes.length}"
  puts "  - Critical pipes: #{pipes.count { |p| p[:severity] == 'Critical' }}"
  puts "  - High utilization: #{pipes.count { |p| p[:severity] == 'High' }}"
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













