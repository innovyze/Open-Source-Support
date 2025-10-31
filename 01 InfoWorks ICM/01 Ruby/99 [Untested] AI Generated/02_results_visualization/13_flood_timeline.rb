# Script: 13_flood_timeline.rb
# Context: Exchange
# Purpose: Time series animation (mermaid timeline of flood progression)
# Outputs: HTML with mermaid timeline
# Usage: ruby script.rb [database_path] [simulation_name]
#        Creates timeline of flood events from simulation results

begin
  puts "Flood Timeline Animator - Starting..."
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
  
  # Extract flood timeline
  net = sim_mo.open
  timesteps = sim_mo.list_timesteps rescue []
  
  events = []
  
  if timesteps && timesteps.length > 0
    # Sample timesteps to track flood progression
    sample_timesteps = timesteps.select.with_index { |_, i| i % (timesteps.length / 6) == 0 }
    
    prev_flooding_nodes = []
    
    sample_timesteps.each_with_index do |ts, idx|
      net.current_timestep = ts
      
      # Find nodes with flooding
      flooding_nodes = []
      net.row_objects('hw_node').each do |node|
        flood_vol = node.results('flood_volume') rescue nil
        if flood_vol && flood_vol > 0
          flooding_nodes << node.id
        end
      end
      
      # Detect flood events
      if idx == 0 && flooding_nodes.length > 0
        events << {
          time: Time.at(ts).strftime('%H:%M') rescue "#{ts.round(0)}s",
          node: flooding_nodes.first,
          event: 'Initial ponding'
        }
      elsif flooding_nodes.length > prev_flooding_nodes.length
        events << {
          time: Time.at(ts).strftime('%H:%M') rescue "#{ts.round(0)}s",
          node: flooding_nodes.first,
          event: 'Flooding begins'
        }
      elsif flooding_nodes.length > prev_flooding_nodes.length * 1.5
        events << {
          time: Time.at(ts).strftime('%H:%M') rescue "#{ts.round(0)}s",
          node: flooding_nodes.first,
          event: 'Critical depth reached'
        }
      elsif flooding_nodes.length == prev_flooding_nodes.length && flooding_nodes.length > 0
        events << {
          time: Time.at(ts).strftime('%H:%M') rescue "#{ts.round(0)}s",
          node: flooding_nodes.first,
          event: 'Peak flood level'
        }
      elsif flooding_nodes.length < prev_flooding_nodes.length && prev_flooding_nodes.length > 0
        events << {
          time: Time.at(ts).strftime('%H:%M') rescue "#{ts.round(0)}s",
          node: prev_flooding_nodes.first,
          event: 'Water receding'
        }
      end
      
      prev_flooding_nodes = flooding_nodes
    end
    
    # Check if flooding cleared
    if prev_flooding_nodes.length == 0 && events.length > 0
      events << {
        time: Time.at(timesteps.last).strftime('%H:%M') rescue "#{timesteps.last.round(0)}s",
        node: events.last[:node],
        event: 'Flooding cleared'
      }
    end
  end
  
  net.close
  
  if events.empty?
    puts "No flood events detected"
    exit 0
  end
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  html_file = File.join(output_dir, 'flood_timeline.html')
  
  mermaid = "timeline\n    title Flood Progression Event Timeline\n"
  events.each { |e| mermaid += "    #{e[:time]} : #{e[:node]} - #{e[:event]}\n" }
  
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Flood Timeline</title>"
  html += "<script src='https://cdn.jsdelivr.net/npm/mermaid/dist/mermaid.min.js'></script>"
  html += "<script>mermaid.initialize({startOnLoad:true});</script>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#2196f3}.mermaid{background:#fafafa;padding:20px;border-radius:5px;margin:20px 0}</style></head>"
  html += "<body><div class='container'><h1>Flood Progression Timeline</h1><div class='mermaid'>\n#{mermaid}</div></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Flood timeline: #{html_file}"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



