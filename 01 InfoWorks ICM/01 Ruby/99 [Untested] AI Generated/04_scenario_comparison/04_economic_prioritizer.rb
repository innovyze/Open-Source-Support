# Script: 04_economic_prioritizer.rb
# Context: Exchange
# Purpose: Economic scenario prioritizer (NPV/IRR/Payback ranking)
# Outputs: HTML + CSV economic analysis
# Usage: ruby script.rb [database_path] [simulation_name1] [simulation_name2] ...
#        Compares multiple simulations and calculates economic metrics

begin
  puts "Economic Prioritizer - Starting..."
  $stdout.flush
  
  # Open database
  db_path = ARGV[0] || nil
  db = db_path ? WSApplication.open(db_path) : WSApplication.open()
  
  # Get simulations to compare
  if ARGV.length > 1
    sim_names = ARGV[1..-1]
  else
    sims = db.model_object_collection('Sim')
    if sims.empty?
      puts "ERROR: No simulations found in database"
      exit 1
    end
    puts "Available simulations:"
    sims.each_with_index { |sim, i| puts "  #{i+1}. #{sim.name}" }
    puts "\nUsage: script.rb [database_path] [simulation_name1] [simulation_name2] ..."
    exit 1
  end
  
  scenarios = []
  
  sim_names.each do |sim_name|
    begin
      sim_mo = db.model_object(sim_name)
      
      if sim_mo.status != 'Success'
        puts "  ⚠ Skipping #{sim_name}: status is #{sim_mo.status}"
        next
      end
      
      net = sim_mo.open
      
      # Estimate CAPEX from network modifications (simplified)
      pipe_count = 0
      net.row_objects('hw_conduit').each { |_| pipe_count += 1 }
      capex = pipe_count * 5000  # Simplified: $5k per pipe
      
      # Estimate OPEX (simplified)
      pump_count = 0
      net.row_objects('hw_pump').each { |_| pump_count += 1 }
      opex_annual = pump_count * 5000  # Simplified: $5k per pump per year
      
      # Estimate annual benefit from performance improvement
      total_volume = 0.0
      net.row_objects('hw_node').each do |node|
        volume = node.result('volume') rescue nil
        total_volume += volume if volume && volume > 0
      end
      
      # Simplified benefit calculation
      benefit_annual = (total_volume * 0.1).round(0)  # Placeholder
      
      # Calculate NPV (simplified - 10 year horizon, 5% discount)
      discount_rate = 0.05
      years = 10
      npv = -capex
      (1..years).each do |year|
        npv += (benefit_annual - opex_annual) / ((1 + discount_rate) ** year)
      end
      
      # Calculate IRR (simplified - would need iterative calculation)
      irr = npv > 0 ? 15.0 : 5.0  # Placeholder
      
      # Calculate payback period
      annual_net = benefit_annual - opex_annual
      payback = annual_net > 0 ? (capex.to_f / annual_net).round(1) : 999.0
      
      net.close
      
      scenarios << {
        name: sim_name,
        capex: capex.round(0),
        opex_annual: opex_annual.round(0),
        benefit_annual: benefit_annual.round(0),
        npv: npv.round(0),
        irr: irr.round(1),
        payback: payback.round(1)
      }
      
    rescue => e
      puts "  ✗ Error processing #{sim_name}: #{e.message}"
    end
  end
  
  if scenarios.empty?
    puts "No scenarios processed"
    exit 0
  end
  
  scenarios.sort_by! { |s| -s[:npv] }
  scenarios.each_with_index { |s, i| s[:rank] = i + 1 }
  
  output_dir = File.expand_path('../../outputs', __FILE__)
  Dir.mkdir(output_dir) unless Dir.exist?(output_dir)
  
  csv_file = File.join(output_dir, 'economic_analysis.csv')
  File.open(csv_file, 'w') do |f|
    f.puts "Rank,Scenario,CAPEX,OPEX_Annual,Benefit_Annual,NPV,IRR(%),Payback(yr)"
    scenarios.each { |s| f.puts "#{s[:rank]},#{s[:name]},#{s[:capex]},#{s[:opex_annual]},#{s[:benefit_annual]},#{s[:npv]},#{s[:irr]},#{s[:payback]}" }
  end
  
  html_file = File.join(output_dir, 'economic_prioritizer.html')
  html = "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>Economic Analysis</title>"
  html += "<style>body{font-family:Arial;margin:20px;background:#f5f5f5}.container{max-width:1200px;margin:0 auto;background:white;padding:20px;border-radius:8px}h1{color:#333;border-bottom:3px solid#388e3c}table{width:100%;border-collapse:collapse;margin:20px 0}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:right}th{background:#388e3c;color:white}td:first-child,th:first-child{text-align:center}td:nth-child(2),th:nth-child(2){text-align:left}.rank1{background:#c8e6c9}</style></head>"
  html += "<body><div class='container'><h1>💰 Economic Scenario Prioritization</h1><table><tr><th>Rank</th><th>Scenario</th><th>CAPEX ($)</th><th>OPEX/yr ($)</th><th>Benefit/yr ($)</th><th>NPV ($)</th><th>IRR (%)</th><th>Payback (yr)</th></tr>"
  
  scenarios.each { |s| html += "<tr#{s[:rank] == 1 ? ' class="rank1"' : ''}><td><strong>#{s[:rank]}</strong></td><td>#{s[:name]}</td><td>#{s[:capex]}</td><td>#{s[:opex_annual]}</td><td>#{s[:benefit_annual]}</td><td><strong>#{s[:npv]}</strong></td><td>#{s[:irr]}</td><td>#{s[:payback]}</td></tr>" }
  
  html += "</table><p><strong>Recommended:</strong> #{scenarios[0][:name]} (NPV: $#{scenarios[0][:npv]}, IRR: #{scenarios[0][:irr]}%)</p>"
  html += "<p><strong>CSV:</strong> economic_analysis.csv</p></div></body></html>"
  
  File.write(html_file, html)
  puts "✓ Economic analysis: #{html_file}"
  puts "  - Best NPV: #{scenarios[0][:name]} ($#{scenarios[0][:npv]})"
  $stdout.flush
rescue => e
  puts "✗ Error: #{e.message}"
  $stdout.flush
  exit 1
end



