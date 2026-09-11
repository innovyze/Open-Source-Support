# cloud_download.rb — Phase 1: queue cloud result download (ICM Exchange)
#
# Run cloud_open.rb in a separate Exchange process (phase 2).
# ICMExchange injects ARGV[0]=ADSK; optional ARGV[1]=cloud_db, ARGV[2]=sim_id

CLOUD_DB = nil  # e.g. 'cloud://My Database@orgId/region'
SIM_ID = nil    # integer Sim ID
DOWNLOAD_SELECTION = 'ALL_RESULTS'
AGENT_TIMEOUT_MS = 5000
WAIT_TIMEOUT_MS = 3_600_000

cloud_db = ARGV[1].strip if ARGV.length >= 2 && !ARGV[1].to_s.strip.empty?
cloud_db ||= CLOUD_DB
sim_id = (ARGV[2].to_s.match?(/^\d+$/) ? ARGV[2].to_i : nil) || SIM_ID

raise 'Set CLOUD_DB or pass cloud_db as ARGV[1]' if cloud_db.to_s.strip.empty?
raise 'Set SIM_ID or pass sim_id as ARGV[2]' unless sim_id.to_i > 0

puts "ICM #{WSApplication.version} — cloud download (sim #{sim_id})"

db = WSApplication.open(cloud_db, false)
sim = db.model_object_from_type_and_id('Sim', sim_id)
raise "Sim #{sim_id} not found" if sim.nil?

puts "Sim: #{sim.name} | cloud: #{sim.status}/#{sim.success_substatus}"

WSApplication.connect_local_agent(AGENT_TIMEOUT_MS)

t0 = Time.now
job_ids = WSApplication.launch_sims_ex([sim], { 'DownloadSelection' => DOWNLOAD_SELECTION })
puts "launch_sims_ex: #{job_ids.inspect}"

if job_ids && !job_ids.compact.empty?
  result = WSApplication.wait_for_jobs(job_ids, true, WAIT_TIMEOUT_MS)
  elapsed = ((Time.now - t0) * 1000).round
  puts result.nil? ? "wait_for_jobs: timeout after #{WAIT_TIMEOUT_MS} ms" : "wait_for_jobs: returned in #{elapsed} ms"
end

puts 'Phase 1 complete. Run cloud_open.rb in a new Exchange process.'
