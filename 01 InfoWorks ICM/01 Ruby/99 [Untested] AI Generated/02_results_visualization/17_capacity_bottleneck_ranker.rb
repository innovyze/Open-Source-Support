# Script: 17_capacity_bottleneck_ranker.rb
# Context: Exchange
# Purpose: Network capacity bottleneck ranker (top 20 critical assets)
# Outputs: HTML ranked list + CSV
# Usage: ruby script.rb [database_path] [simulation_name]

begin
  puts "Capacity Bottleneck Ranker - Starting..."
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
  
  # Extract bottleneck data
  net = sim_mo.open
  bottlenecks = []
  
  net.row_objects('hw_conduit').each do |pipe|
    peak_flow = pipe.result('flow') rescue nil
    # Calculate capacity from geometry: Q = A × V
    width = pipe['conduit_width'] rescue nil
    height = pipe['conduit_height'] rescue width rescue nil
    if width && height && width > 0 && height > 0
      area = (width / 1000.0) * (height / 1000.0)  # Convert mm to m
      capacity = area * 5.0  # Typical max velocity 5 m/s
    else
      capacity = nil
    end
    
    if peak_flow && capacity && capacity > 0
      peak_flow = peak_flow.abs
      util_pct = (peak_flow / capacity * 100).round(1)
      
      bottlenecks << {
        asset: pipe.id,
        util_pct: util_pct,
        capacity: capacity.round(3),
        peak_flow: peak_flow.round(3)
      }
    end
  end
  
  net.close
  
  if bottlenecks.empty?
    puts "No bottleneck data found"
    exit 0
  end
  
  # Sort by utilization and take top 20
  bottlenecks.sort_by! { |b| -b[:util_pct] }
  bottlenecks = bottlenecks[0..19]
  bottlenecks.each_with_index { |b, i| b[:rank] = i + 1 }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'bottlenecks.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Rank,Asset,Utilization(%),Capacity,PeakFlow"
    bottlenecks.each { |b| f.puts "#{b[:rank]},#{b[:asset]},#{b[:util_pct]},#{b[:capacity]},#{b[:peak_flow]}" }
  end
  
  html_file = File.join(output_dir, 'bottlenecks.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Bottlenecks</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:900px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#c62828}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:center}th{background:#c62828;color:white}.critical{background:#ffcdd2}.high{background:#ffe0b2}.rank{font-weight:bold;font-size:18px;color:#c62828}</style></head>"
  html += "<body><div class='container'><h1>⚠️ Capacity Bottlenecks (Top 20)</h1><table><tr><th>Rank</th><th>Asset</th><th>Utilization (%)</th><th>Capacity</th><th>Peak Flow</th></tr>"
  
  bottlenecks[0..19].each do |b|
    row_class = b[:util_pct] > 110 ? 'critical' : (b[:util_pct] > 95 ? 'high' : '')
    html += "<tr class='#{row_class}'><td class='rank'>#{b[:rank]}</td><td>#{b[:asset]}</td><td>#{b[:util_pct]}</td><td>#{b[:capacity]}</td><td>#{b[:peak_flow]}</td></tr>"
  end
  
  html += "</table><p><strong>CSV:</strong> bottlenecks.csv</p></div></body></html>"
  File.write(html_file, html)
  puts "✓ Bottleneck ranking: #{html_file}"
  puts "  - Pipes analyzed: #{bottlenecks.length}"
  puts "  - Top bottleneck: #{bottlenecks[0][:asset]} (#{bottlenecks[0][:util_pct]}%)"
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



