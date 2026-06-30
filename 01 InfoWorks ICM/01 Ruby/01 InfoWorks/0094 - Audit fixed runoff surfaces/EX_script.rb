# Context: Exchange (EX)
# Purpose: Audit InfoWorks networks for runoff surfaces referenced by subcatchment
#          land uses where runoff_volume_type is fixed and runoff_coefficient < 0.7.
# Output: HTML report with per-network summary and flagged detail rows.

# =============================================================================
# CONFIGURATION
# =============================================================================
# Cloud database path. Get from Help > About InfoWorks > Additional Information > Database
DATABASE_PATH = nil  # e.g. 'cloud://My Database@abc123def456/namer'

# Scenario for land use / runoff surface grid data
SCENARIO = 'Base'

# Coefficient threshold (strict less-than)
COEFFICIENT_THRESHOLD = 0.7

# Output HTML path. nil = Runoff_Surface_Audit_<timestamp>.html next to this script.
OUTPUT_PATH = nil

# Runoff slots on land use to check (1 and 2 only per requirements)
RUNOFF_SLOTS = [1, 2].freeze

# Write HTML report after each network (partial results if Exchange crashes later)
SAVE_PROGRESS_AFTER_EACH_NETWORK = true

# Each network runs in a separate ICMExchange process to avoid native crashes between networks
USE_PROCESS_ISOLATION = true

# Adjust if your ICM install path differs (used when USE_PROCESS_ISOLATION is true)
ICM_EXCHANGE_PATH = 'C:/Program Files/Autodesk/InfoWorks ICM Ultimate 2026/ICMExchange.exe'

# Optional filters (script constants only)
ONLY_NETWORK_PATH = nil   # e.g. '>MODG~Projects>NNET~My Network'
SKIP_NETWORK_PATHS = []   # array of path substrings to skip
# =============================================================================

require 'json'

@audit_log_io = nil

def log_msg(msg)
  line = "[#{Time.now.strftime('%H:%M:%S')}] #{msg}"
  puts line
  $stdout.flush
  return unless @audit_log_io

  @audit_log_io.write("#{line}\n")
  @audit_log_io.flush
rescue
  nil
end

def open_audit_log
  log_path = File.join(File.dirname(__FILE__), 'Runoff_Surface_Audit.log')
  @audit_log_io = File.open(log_path, 'a')
  log_msg("Log file: #{log_path}")
rescue => e
  puts "Warning: could not open log file: #{e.message}"
  $stdout.flush
end

def close_audit_log
  @audit_log_io.close if @audit_log_io
  @audit_log_io = nil
rescue
  nil
end

def network_selected?(network_mo, only_path, skip_paths)
  path = network_mo.path.to_s
  name = network_mo.name.to_s

  if only_path && !only_path.to_s.strip.empty?
    return false unless path.include?(only_path) || name.include?(only_path)
  end

  skip_paths.each do |skip|
    next if skip.nil? || skip.to_s.strip.empty?
    return false if path.include?(skip) || name.include?(skip)
  end

  true
end

def safe_close_network(net, network_name)
  return unless net

  net.close
  log_msg("  Closed network: #{network_name}")
rescue => e
  log_msg("  Warning: could not close network '#{network_name}': #{e.message}")
end

def html_escape(text)
  text.to_s
      .gsub('&', '&amp;')
      .gsub('<', '&lt;')
      .gsub('>', '&gt;')
      .gsub('"', '&quot;')
end

def normalize_key(value)
  value.to_s.strip
end

def valid_runoff_index?(value)
  return false if value.nil?

  str = normalize_key(value)
  return false if str.empty? || str == '0'

  true
end

def numeric_coefficient(value)
  return value if value.is_a?(Numeric)

  if value.is_a?(String)
    stripped = value.strip
    return stripped.to_f if stripped.match?(/\A-?\d+(\.\d+)?\z/)
  end

  nil
end

def flagged_surface?(surface)
  type = surface.runoff_volume_type.to_s.downcase.strip
  coeff = numeric_coefficient(surface.runoff_coefficient)
  type == 'fixed' && !coeff.nil? && coeff < COEFFICIENT_THRESHOLD
end

def table_exists?(net, table_name)
  net.tables.each do |t|
    return true if t.name == table_name
  end
  false
rescue
  false
end

def collect_model_networks(db)
  queue = []
  db.root_model_objects.each { |obj| queue << obj }
  networks = []

  until queue.empty?
    obj = queue.shift
    networks << obj if obj.type == 'Model Network'
    obj.children.each { |child| queue << child } if obj.respond_to?(:children)
  end

  networks
end

def write_text_file(path, content)
  File.open(path, 'w') { |f| f.write(content) }
end

def audit_network(network_mo)
  result = {
    name: network_mo.name,
    path: network_mo.path,
    skipped: false,
    skip_reason: nil,
    subcatchment_count: 0,
    land_use_count: 0,
    breaching_subcatchment_count: 0,
    empty_land_use_count: 0,
    flagged: [],
    issues: []
  }

  log_msg("  Opening: #{network_mo.name} (#{network_mo.path})")
  net = network_mo.open
  if net.nil?
    result[:skipped] = true
    result[:skip_reason] = 'Could not open network'
    log_msg('  Skipped: could not open network')
    return result
  end

  begin
    log_msg('  Checking for InfoWorks tables...')
    unless table_exists?(net, 'hw_subcatchment')
      result[:skipped] = true
      result[:skip_reason] = 'Not an InfoWorks network (no hw_subcatchment table)'
      log_msg('  Skipped: not an InfoWorks network')
      return result
    end

    begin
      log_msg("  Setting scenario: #{SCENARIO}")
      net.current_scenario = SCENARIO
    rescue => e
      result[:skipped] = true
      result[:skip_reason] = "Could not set scenario '#{SCENARIO}': #{e.message}"
      log_msg("  Skipped: #{result[:skip_reason]}")
      return result
    end

    land_use_to_subcatchments = Hash.new(0)
    flagged_land_uses = {}

    log_msg('  Reading subcatchments...')
    net.row_objects('hw_subcatchment').each do |sc|
      result[:subcatchment_count] += 1

      lu_id = sc.land_use_id
      if lu_id.nil? || normalize_key(lu_id).empty?
        result[:empty_land_use_count] += 1
        next
      end

      land_use_to_subcatchments[normalize_key(lu_id)] += 1
    end
    log_msg("  Subcatchments read: #{result[:subcatchment_count]}")

    result[:land_use_count] = land_use_to_subcatchments.keys.length

    log_msg('  Reading land uses...')
    land_use_by_id = {}
    net.row_objects('hw_land_use').each do |lu|
      land_use_by_id[normalize_key(lu.land_use_id)] = lu
    end
    log_msg("  Land use rows: #{land_use_by_id.length}")

    log_msg('  Reading runoff surfaces...')
    runoff_by_index = {}
    net.row_objects('hw_runoff_surface').each do |rs|
      idx = rs.runoff_index
      next if idx.nil?

      runoff_by_index[normalize_key(idx)] = rs
    end
    log_msg("  Runoff surface rows: #{runoff_by_index.length}")

    log_msg('  Evaluating flagged surfaces...')
    land_use_to_subcatchments.each do |lu_id, subcatchment_count|
      land_use = land_use_by_id[lu_id]
      if land_use.nil?
        result[:issues] << {
          type: 'missing_land_use',
          land_use_id: lu_id,
          subcatchment_count: subcatchment_count
        }
        next
      end

      RUNOFF_SLOTS.each do |slot|
        runoff_index = land_use.send("runoff_index_#{slot}")
        next unless valid_runoff_index?(runoff_index)

        runoff_key = normalize_key(runoff_index)
        surface = runoff_by_index[runoff_key]
        if surface.nil?
          result[:issues] << {
            type: 'missing_runoff_surface',
            land_use_id: lu_id,
            slot: slot,
            runoff_index: runoff_index,
            subcatchment_count: subcatchment_count
          }
          next
        end

        next unless flagged_surface?(surface)

        unless flagged_land_uses.key?(lu_id)
          flagged_land_uses[lu_id] = true
          result[:breaching_subcatchment_count] += subcatchment_count
        end

        result[:flagged] << {
          land_use_id: lu_id,
          slot: slot,
          runoff_index: runoff_index,
          runoff_volume_type: surface.runoff_volume_type,
          runoff_coefficient: numeric_coefficient(surface.runoff_coefficient),
          subcatchment_count: subcatchment_count
        }
      end
    end

    log_msg("  Done: #{result[:flagged].length} flagged surface(s), #{result[:breaching_subcatchment_count]} breaching subcatchment(s), #{result[:issues].length} issue(s)")
    result
  rescue => e
    log_msg("  Ruby error: #{e.message}")
    {
      name: network_mo.name,
      path: network_mo.path,
      skipped: true,
      skip_reason: "Error: #{e.message}",
      subcatchment_count: 0,
      land_use_count: 0,
      breaching_subcatchment_count: 0,
      empty_land_use_count: 0,
      flagged: [],
      issues: []
    }
  ensure
    safe_close_network(net, network_mo.name)
  end
end

def build_html_report(db_path, network_results, run_time, in_progress: false)
  total_networks = network_results.length
  scanned = network_results.count { |r| !r[:skipped] }
  skipped = total_networks - scanned
  total_flagged = network_results.sum { |r| r[:flagged].length }
  total_issues = network_results.sum { |r| r[:issues].length }
  total_breaching = network_results.sum { |r| r[:breaching_subcatchment_count] }
  total_empty_land_use = network_results.sum { |r| r[:empty_land_use_count] }

  html = []
  html << '<!DOCTYPE html>'
  html << '<html lang="en">'
  html << '<head>'
  html << '<meta charset="utf-8">'
  html << '<title>Fixed Runoff Surface Audit</title>'
  html << '<style>'
  html << 'body{font-family:Segoe UI,Arial,sans-serif;margin:24px;color:#222;}'
  html << 'h1,h2{color:#1a5276;border-bottom:1px solid #ccc;padding-bottom:4px;}'
  html << 'table{border-collapse:collapse;width:100%;margin:12px 0 24px;}'
  html << 'th,td{border:1px solid #bbb;padding:6px 8px;text-align:left;vertical-align:top;}'
  html << 'th{background:#d6eaf8;}'
  html << 'tr:nth-child(even){background:#f9f9f9;}'
  html << '.summary{margin:12px 0;padding:12px;background:#eafaf1;border:1px solid #abebc6;}'
  html << '.warn{margin:12px 0;padding:12px;background:#fdebd0;border:1px solid #f5b041;}'
  html << '.meta{color:#555;font-size:0.95em;}'
  html << '</style>'
  html << '</head>'
  html << '<body>'
  html << '<h1>Fixed Runoff Surface Audit</h1>'
  if in_progress
    html << '<div class="warn"><strong>In progress</strong> — partial results saved before audit completed.</div>'
  end
  html << '<p class="meta">'
  html << "Database: #{html_escape(db_path)}<br>"
  html << "Run time: #{html_escape(run_time)}<br>"
  html << "Scenario: #{html_escape(SCENARIO)}<br>"
  html << "Condition: runoff_volume_type = fixed AND runoff_coefficient &lt; #{COEFFICIENT_THRESHOLD}"
  html << '</p>'

  html << '<div class="summary">'
  html << '<strong>Database summary</strong><br>'
  html << "Model networks found: #{total_networks}<br>"
  html << "InfoWorks networks scanned: #{scanned}<br>"
  html << "Networks skipped: #{skipped}<br>"
  html << "Flagged runoff surface references: #{total_flagged}<br>"
  html << "Subcatchments breaching threshold: #{total_breaching}<br>"
  html << "Data issues: #{total_issues}<br>"
  html << "Subcatchments with empty land use: #{total_empty_land_use}"
  html << '</div>'

  html << '<h2>Per-network summary</h2>'
  html << '<table>'
  html << '<tr><th>Network</th><th>Path</th><th>Status</th><th>Subcatchments</th><th>Land uses in use</th><th>Breaching subcatchments</th><th>Flagged surfaces</th><th>Issues</th></tr>'
  network_results.each do |r|
    status = r[:skipped] ? html_escape(r[:skip_reason]) : 'Scanned'
    html << '<tr>'
    html << "<td>#{html_escape(r[:name])}</td>"
    html << "<td>#{html_escape(r[:path])}</td>"
    html << "<td>#{status}</td>"
    html << "<td>#{r[:subcatchment_count]}</td>"
    html << "<td>#{r[:land_use_count]}</td>"
    html << "<td>#{r[:breaching_subcatchment_count]}</td>"
    html << "<td>#{r[:flagged].length}</td>"
    html << "<td>#{r[:issues].length + (r[:empty_land_use_count] > 0 ? 1 : 0)}</td>"
    html << '</tr>'
  end
  html << '</table>'

  flagged_rows = network_results.flat_map do |r|
    next [] if r[:skipped]

    r[:flagged].map do |f|
      f.merge(network_name: r[:name], network_path: r[:path])
    end
  end

  html << '<h2>Flagged runoff surfaces</h2>'
  if flagged_rows.empty?
    html << '<p>No runoff surfaces matched the audit condition.</p>'
  else
    html << '<table>'
    html << '<tr><th>Network</th><th>Land use ID</th><th>Slot</th><th>Runoff surface ID</th>'
    html << '<th>Runoff volume type</th><th>Runoff coefficient</th><th>Subcatchments using land use</th></tr>'
    flagged_rows.each do |f|
      html << '<tr>'
      html << "<td>#{html_escape(f[:network_name])}</td>"
      html << "<td>#{html_escape(f[:land_use_id])}</td>"
      html << "<td>#{f[:slot]}</td>"
      html << "<td>#{html_escape(f[:runoff_index])}</td>"
      html << "<td>#{html_escape(f[:runoff_volume_type])}</td>"
      html << "<td>#{f[:runoff_coefficient]}</td>"
      html << "<td>#{f[:subcatchment_count]}</td>"
      html << '</tr>'
    end
    html << '</table>'
  end

  issue_rows = network_results.flat_map do |r|
    rows = r[:issues].map do |i|
      i.merge(network_name: r[:name], network_path: r[:path])
    end
    if r[:empty_land_use_count] > 0
      rows << {
        network_name: r[:name],
        network_path: r[:path],
        type: 'empty_land_use',
        subcatchment_count: r[:empty_land_use_count]
      }
    end
    rows
  end

  html << '<h2>Data issues</h2>'
  if issue_rows.empty?
    html << '<p>No data reference issues found.</p>'
  else
    html << '<table>'
    html << '<tr><th>Network</th><th>Issue type</th><th>Details</th></tr>'
    issue_rows.each do |i|
      details = case i[:type]
                when 'empty_land_use'
                  "#{i[:subcatchment_count]} subcatchment(s) have no land_use_id"
                when 'missing_land_use'
                  "Land use #{html_escape(i[:land_use_id])} not found in hw_land_use (#{i[:subcatchment_count]} subcatchment(s))"
                when 'missing_runoff_surface'
                  "Land use #{html_escape(i[:land_use_id])}, slot #{i[:slot]}: runoff_index #{html_escape(i[:runoff_index])} not found in hw_runoff_surface (#{i[:subcatchment_count]} subcatchment(s))"
                else
                  html_escape(i.inspect)
                end
      html << '<tr>'
      html << "<td>#{html_escape(i[:network_name])}</td>"
      html << "<td>#{html_escape(i[:type])}</td>"
      html << "<td>#{details}</td>"
      html << '</tr>'
    end
    html << '</table>'
  end

  html << '</body></html>'
  html.join("\n")
end

def resolve_output_path
  return OUTPUT_PATH unless OUTPUT_PATH.nil? || OUTPUT_PATH.to_s.strip.empty?

  timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
  File.join(File.dirname(__FILE__), "Runoff_Surface_Audit_#{timestamp}.html")
end

def resolve_progress_output_path
  File.join(File.dirname(__FILE__), 'Runoff_Surface_Audit_PROGRESS.html')
end

def resolve_database_path
  return ARGV[1] if ARGV.length > 1 && !ARGV[1].to_s.strip.empty?

  DATABASE_PATH
end

def single_network_id_from_argv
  return nil unless ARGV.length > 2

  arg = ARGV[2].to_s.strip
  return arg.to_i if arg =~ /\A\d+\z/

  nil
end

def json_output_path_from_argv
  return ARGV[3] if ARGV.length > 3 && !ARGV[3].to_s.strip.empty?

  nil
end

def hash_for_json(value)
  case value
  when Hash
    value.each_with_object({}) { |(k, v), h| h[k.to_s] = hash_for_json(v) }
  when Array
    value.map { |item| hash_for_json(item) }
  else
    value
  end
end

def symbolize_keys(value)
  case value
  when Hash
    value.each_with_object({}) { |(k, v), h| h[k.to_sym] = symbolize_keys(v) }
  when Array
    value.map { |item| symbolize_keys(item) }
  else
    value
  end
end

def load_result_json(path)
  symbolize_keys(JSON.parse(File.read(path)))
end

def write_result_json(path, result)
  write_text_file(path, JSON.generate(hash_for_json(result)))
end

def failed_network_result(network_mo, reason)
  {
    name: network_mo.name,
    path: network_mo.path,
    skipped: true,
    skip_reason: reason,
    subcatchment_count: 0,
    land_use_count: 0,
    breaching_subcatchment_count: 0,
    empty_land_use_count: 0,
    flagged: [],
    issues: []
  }
end

def spawn_single_network_audit(db_path, network_id, json_path)
  script_path = File.expand_path(__FILE__)
  cmd = "\"#{ICM_EXCHANGE_PATH}\" \"#{script_path}\" \"#{db_path}\" \"#{network_id}\" \"#{json_path}\""
  log_msg("Spawning isolated audit for network ID #{network_id}")
  system(cmd)
  File.exist?(json_path)
end

def run_single_network_audit
  db_path = resolve_database_path
  network_id = single_network_id_from_argv
  json_path = json_output_path_from_argv

  raise 'Database path required' if db_path.nil? || db_path.to_s.strip.empty?
  raise 'Network ID required for single-network mode' unless network_id
  raise 'JSON output path required for single-network mode' unless json_path

  db = WSApplication.open(db_path, false)
  raise 'Failed to open database' if db.nil?

  network_mo = db.model_object_from_type_and_id('Model Network', network_id)
  raise "Model Network ID #{network_id} not found" if network_mo.nil?

  result = audit_network(network_mo)
  write_result_json(json_path, result)
ensure
  db.close if db
end

def finalize_audit_report(db_path, networks, network_results)
  run_time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  output_path = resolve_output_path
  html = build_html_report(db_path, network_results, run_time, in_progress: false)
  write_text_file(output_path, html)

  scanned = network_results.count { |r| !r[:skipped] }
  flagged = network_results.sum { |r| r[:flagged].length }
  breaching = network_results.sum { |r| r[:breaching_subcatchment_count] }
  issues = network_results.sum { |r| r[:issues].length + (r[:empty_land_use_count] > 0 ? 1 : 0) }

  puts ''
  log_msg("Networks scanned: #{scanned}/#{networks.length}")
  log_msg("Flagged surface references: #{flagged}")
  log_msg("Subcatchments breaching threshold: #{breaching}")
  log_msg("Data issues: #{issues}")
  log_msg("Report written: #{output_path}")
  log_msg('Done.')
end

def run_orchestrator_audit
  db_path = resolve_database_path
  if db_path.nil? || db_path.to_s.strip.empty?
    puts 'ERROR: DATABASE_PATH not configured. Set DATABASE_PATH or pass as ARGV[1].'
    exit 1
  end

  log_msg("Opening database: #{db_path}")
  db = WSApplication.open(db_path, false)
  if db.nil?
    puts 'ERROR: Failed to open database'
    exit 1
  end

  log_msg("Database opened: #{db.path}")
  log_msg("Scenario: #{SCENARIO}")
  log_msg("Process isolation: #{USE_PROCESS_ISOLATION ? 'on' : 'off'}")
  log_msg("Only network filter: #{ONLY_NETWORK_PATH}") if ONLY_NETWORK_PATH && !ONLY_NETWORK_PATH.to_s.strip.empty?

  networks = collect_model_networks(db)
  networks.select! { |n| network_selected?(n, ONLY_NETWORK_PATH, SKIP_NETWORK_PATHS) }
  log_msg("Found #{networks.length} model network(s) to audit")

  progress_path = resolve_progress_output_path
  network_results = []
  results_dir = File.join(File.dirname(__FILE__), "audit_results_#{Time.now.strftime('%Y%m%d_%H%M%S')}")
  Dir.mkdir(results_dir)

  networks.each_with_index do |network_mo, index|
    log_msg("Auditing [#{index + 1}/#{networks.length}]: #{network_mo.name} (ID #{network_mo.id})")
    result = nil

    if USE_PROCESS_ISOLATION
      json_path = File.join(results_dir, "network_#{network_mo.id}.json")
      if spawn_single_network_audit(db.path, network_mo.id, json_path)
        result = load_result_json(json_path)
        log_msg("  Isolated audit completed for #{network_mo.name}")
      else
        result = failed_network_result(network_mo, 'Exchange process failed or crashed')
        log_msg("  Isolated audit failed for #{network_mo.name}")
      end
    else
      result = audit_network(network_mo)
    end

    network_results << result
    save_progress_report(db.path, network_results, progress_path, in_progress: true) if SAVE_PROGRESS_AFTER_EACH_NETWORK
  end

  finalize_audit_report(db.path, networks, network_results)
ensure
  db.close if db
end

def save_progress_report(db_path, network_results, output_path, in_progress: false)
  run_time = Time.now.strftime('%Y-%m-%d %H:%M:%S')
  html = build_html_report(db_path, network_results, run_time, in_progress: in_progress)
  write_text_file(output_path, html)
  log_msg("Progress saved: #{output_path} (#{network_results.length} network(s))")
rescue => e
  log_msg("Warning: could not save progress report: #{e.message}")
end

# =============================================================================
# MAIN
# =============================================================================

begin
  if single_network_id_from_argv
    run_single_network_audit
  else
    open_audit_log
    puts '=' * 70
    puts 'Fixed Runoff Surface Audit'
    puts '=' * 70
    run_orchestrator_audit
  end
rescue => e
  log_msg("ERROR: #{e.message}") if defined?(log_msg)
  puts "ERROR: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  exit 1
ensure
  close_audit_log
end
