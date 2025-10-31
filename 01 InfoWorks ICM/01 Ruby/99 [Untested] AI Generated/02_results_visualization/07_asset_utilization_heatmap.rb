# Script: 07_asset_utilization_heatmap.rb
# Context: Exchange
# Purpose: Asset utilization heatmap (pipes, pumps, tanks as % capacity)
# Outputs: HTML heatmap
# Usage: ruby script.rb [database_path] [simulation_name]

begin
  puts "Asset Utilization Heatmap - Starting..."
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
  
  # Extract asset utilization
  net = sim_mo.open
  assets = []
  
  # Pipes
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
      util = (peak_flow.abs / capacity * 100).round
      
      status = if util > 100
        'Critical'
      elsif util > 85
        'High'
      elsif util > 70
        'Medium'
      else
        'Low'
      end
      
      assets << {
        id: pipe.id,
        type: 'Pipe',
        util: util,
        status: status
      }
    end
  end
  
  # Pumps
  net.row_objects('hw_pump').each do |pump|
    peak_flow = pump.result('flow') rescue nil
    # Try rated flow field, or use peak flow as proxy
    capacity = pump['rated_flow'] rescue pump['max_flow'] rescue nil
    if capacity.nil? && peak_flow
      capacity = peak_flow.abs * 1.2  # Use peak flow × 1.2 as capacity estimate
    end
    
    if peak_flow && capacity && capacity > 0
      util = (peak_flow.abs / capacity * 100).round
      
      status = if util > 100
        'Critical'
      elsif util > 85
        'High'
      elsif util > 70
        'Medium'
      else
        'Low'
      end
      
      assets << {
        id: pump.id,
        type: 'Pump',
        util: util,
        status: status
      }
    end
  end
  
  # Tanks/Storage
  net.row_objects('hw_storage').each do |tank|
    max_volume = tank.result('volume') rescue nil
    # Use storage volume field as capacity
    capacity = tank['storage_volume'] rescue tank['max_volume'] rescue tank['volume'] rescue nil
    
    if max_volume && capacity && capacity > 0
      util = (max_volume / capacity * 100).round
      
      status = if util > 90
        'High'
      elsif util > 70
        'Medium'
      else
        'Low'
      end
      
      assets << {
        id: tank.id,
        type: 'Tank',
        util: util,
        status: status
      }
    end
  end
  
  net.close
  
  if assets.empty?
    puts "No asset utilization data found"
    exit 0
  end
  
  # Sort by utilization
  assets.sort_by! { |a| -a[:util] }
  assets = assets[0..20]  # Limit to top 20 for display
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'asset_utilization.html')
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Asset Utilization</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1000px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#1976d2}.grid{display:grid;grid-template-columns:repeat(3,1fr);gap:15px;margin:20px 0}.asset{padding:20px;border-radius:8px;text-align:center;font-weight:bold;color:white}.critical{background:#ef5350}.high{background:#ff9800}.medium{background:#42a5f5}.low{background:#66bb6a}</style></head>"
  html += "<body><div class='container'><h1>Asset Utilization Heatmap</h1><div class='grid'>"
  
  assets.each { |a| html += "<div class='asset #{a[:status].downcase}'>#{a[:id]}<br>#{a[:type]}<br>#{a[:util]}%</div>" }
  
  html += "</div></div></body></html>"
  File.write(html_file, html)
  puts "✓ Asset utilization heatmap: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end




