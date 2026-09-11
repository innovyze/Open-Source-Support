# cloud_open.rb — Phase 2: open local results and print QA fields (ICM Exchange)
#
# Run after cloud_download.rb (phase 2).
# ICMExchange injects ARGV[0]=ADSK; optional ARGV[1]=cloud_db, ARGV[2]=sim_id

CLOUD_DB = nil  # e.g. 'cloud://My Database@orgId/region'
SIM_ID = nil    # integer Sim ID

cloud_db = ARGV[1].strip if ARGV.length >= 2 && !ARGV[1].to_s.strip.empty?
cloud_db ||= CLOUD_DB
sim_id = (ARGV[2].to_s.match?(/^\d+$/) ? ARGV[2].to_i : nil) || SIM_ID

raise 'Set CLOUD_DB or pass cloud_db as ARGV[1]' if cloud_db.to_s.strip.empty?
raise 'Set SIM_ID or pass sim_id as ARGV[2]' unless sim_id.to_i > 0

puts "ICM #{WSApplication.version} — open results (sim #{sim_id})"

db = WSApplication.open(cloud_db, false)
sim = db.model_object_from_type_and_id('Sim', sim_id)
raise "Sim #{sim_id} not found" if sim.nil?

puts "Sim: #{sim.name}"
puts "Cloud status: #{sim.status} / #{sim.success_substatus}"
puts "Rainfall event id: #{sim['Rainfall event']}"
puts "Scenario: #{sim['NetworkScenarioUID'] || 'Base'}"

net = sim.open
tc = net.timestep_count if net.respond_to?(:timestep_count)
puts 'sim.open: OK'
puts "timestep_count: #{tc}" if tc
puts "results_path: #{sim.results_path}"
