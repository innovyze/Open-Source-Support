# Script: 09_hgl_discontinuity_finder.rb
# Context: Exchange
# Purpose: Find hydraulic grade line discontinuities at nodes
# Outputs: CSV + HTML report
# Usage: ruby script.rb [database_path] [simulation_name]
#        Detects HGL discontinuities at nodes by comparing upstream/downstream HGL

begin
  puts "HGL Discontinuity Finder - Starting..."
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
  
  # Detect HGL discontinuities
  net = sim_mo.open
  
  # Get final timestep for analysis
  timesteps = sim_mo.list_timesteps rescue []
  if timesteps && timesteps.length > 0
    net.current_timestep = timesteps.last
  end
  
  discontinuities = []
  
  net.row_objects('hw_node').each do |node|
    node_id = node.id
    node_hgl = node['invert_level'] rescue nil
    node_hgl = (node_hgl.to_f + (node.results('depth') rescue 0.0)) if node_hgl
    
    # Check upstream and downstream HGL from connected conduits
    upstream_hgl = nil
    downstream_hgl = nil
    
    # Find upstream connections
    net.row_objects('hw_conduit').each do |conduit|
      if conduit.ds_node_id == node_id
        us_node = net.row_object('hw_node', conduit.us_node_id) rescue nil
        if us_node
          us_invert = us_node['invert_level'] rescue nil
          us_depth = us_node.results('depth') rescue nil
          if us_invert && us_depth
            upstream_hgl = us_invert.to_f + us_depth
          end
        end
      end
    end
    
    # Find downstream connections
    net.row_objects('hw_conduit').each do |conduit|
      if conduit.us_node_id == node_id
        ds_node = net.row_object('hw_node', conduit.ds_node_id) rescue nil
        if ds_node
          ds_invert = ds_node['invert_level'] rescue nil
          ds_depth = ds_node.results('depth') rescue nil
          if ds_invert && ds_depth
            downstream_hgl = ds_invert.to_f + ds_depth
          end
        end
      end
    end
    
    if upstream_hgl && downstream_hgl && node_hgl
      diff = (upstream_hgl - downstream_hgl).abs
      
      if diff > 0.5  # Threshold for discontinuity
        type = upstream_hgl > downstream_hgl ? 'Drop' : 'Jump'
        discontinuities << {
          node: node_id,
          upstream_hgl: upstream_hgl.round(2),
          downstream_hgl: downstream_hgl.round(2),
          diff: diff.round(2),
          type: type
        }
      end
    end
  end
  
  net.close
  
  if discontinuities.empty?
    puts "No significant HGL discontinuities detected"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  # Write CSV
  csv_file = File.join(output_dir, 'hgl_discontinuities.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Node,Upstream_HGL,Downstream_HGL,Difference,Type"
    discontinuities.each { |d| f.puts "#{d[:node]},#{d[:upstream_hgl]},#{d[:downstream_hgl]},#{d[:diff]},#{d[:type]}" }
  end
  
  html_file = File.join(output_dir, 'hgl_discontinuities.html')
  html = <<-HTML
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>HGL Discontinuity Finder</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 900px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
    h1 { color: #333; border-bottom: 3px solid #1976d2; padding-bottom: 10px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #1976d2; color: white; }
    .type-drop { color: #c62828; font-weight: bold; }
    .type-jump { color: #2e7d32; font-weight: bold; }
    .summary { padding: 15px; background: #e3f2fd; border-radius: 5px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <h1>HGL Discontinuity Analysis</h1>
    <div class="summary">
      <strong>Total Discontinuities:</strong> #{discontinuities.length} | 
      <strong>Drops:</strong> #{discontinuities.count { |d| d[:type] == 'Drop' }} | 
      <strong>Jumps:</strong> #{discontinuities.count { |d| d[:type] == 'Jump' }}
    </div>
    <table>
      <tr><th>Node</th><th>Upstream HGL (m)</th><th>Downstream HGL (m)</th><th>Difference (m)</th><th>Type</th></tr>
  HTML
  
  discontinuities.each do |d|
    type_class = "type-#{d[:type].downcase}"
    html += "      <tr><td>#{d[:node]}</td><td>#{d[:upstream_hgl]}</td><td>#{d[:downstream_hgl]}</td><td>#{d[:diff]}</td><td class=\"#{type_class}\">#{d[:type]}</td></tr>\n"
  end
  
  html += <<-HTML
    </table>
    <p><strong>CSV Export:</strong> hgl_discontinuities.csv</p>
    <h2>Interpretation</h2>
    <ul>
      <li><strong>Drops:</strong> May indicate energy losses at structures or numerical issues</li>
      <li><strong>Jumps:</strong> Can represent hydraulic jumps or model convergence problems</li>
      <li>Large discontinuities (>1m) warrant investigation</li>
    </ul>
  </div>
</body>
</html>
  HTML
  
  File.write(html_file, html)
  puts "✓ HGL discontinuity analysis complete:"
  puts "  - CSV: #{csv_file}"
  puts "  - HTML: #{html_file}"
  puts "  - Discontinuities found: #{discontinuities.length}"
  $stdout.flush
  
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end













