# Top 10 fail / unconverge - standalone script
#
# Run from ICM Scripts. You'll be prompted for a Simulation ID (selecting a Sim in the
# database tree first does not currently feed into that prompt - see resolve_sim_mo).
# The UI branch then launches ICMExchange on this exact same file, passing it your
# database path and Sim ID as arguments. You do not open Exchange yourself; parsing,
# selection-list creation (replacing any same-named lists from a previous run against
# this network version), and the HTML summary all run in that headless pass, and the
# UI branch reports the outcome back to you via message boxes.
#
# Having the latest version of the sim's network open in GeoPlan blocks that headless
# pass from saving selection lists; older read-only versions are fine.

require 'open3'
require 'tmpdir'

ICM_EXCHANGE_PATH = nil

ICM_EXCHANGE_CANDIDATES = [
  'C:/Program Files/Autodesk/InfoWorks ICM Ultimate 2027/ICMExchange.exe',
  'C:/Program Files/Autodesk/InfoWorks ICM Ultimate 2026/ICMExchange.exe',
  'C:/Program Files/Autodesk/InfoWorks ICM Ultimate 2025/ICMExchange.exe',
  'C:/Program Files/Autodesk/InfoWorks ICM Ultimate 2024/ICMExchange.exe'
].freeze

module Top10FailUnconverge
  SELECTION_LIST_LIMIT = 10

  MARKER_LISTS = /SELECTION_LISTS_CREATED=(\d+)/
  MARKER_REPLACED = /SELECTION_LISTS_REPLACED=(\d+)/
  MARKER_CONFLICTS = /SELECTION_LISTS_CONFLICTS=(\d+)/
  MARKER_LOST = /SELECTION_LISTS_LOST=(\d+)/
  MARKER_ERROR = /TOP10_FAIL_UNCONVERGE_ERROR=(.+)/

  module ICMHelpers
    module_function

    def database_path_valid?(db_path)
      return false if db_path.nil? || db_path.to_s.strip.empty?

      db_path.to_s =~ %r{\A[a-z]+://}i ? true : File.exist?(db_path.to_s)
    end

    def open_database_from_path(db_path)
      puts "\nOpening database: #{db_path}"
      unless database_path_valid?(db_path)
        puts "ERROR: Database file not found: #{db_path}"
        return nil
      end

      begin
        db = WSApplication.open(db_path, false)
        if db
          puts "Database opened successfully: #{db.path}"
          return db
        end
      rescue => e
        puts "ERROR: Could not open database: #{db_path}"
        puts "Error: #{e.message}"
      end
      nil
    end

    def open_database_from_argv
      return nil unless ARGV.length > 1 && database_path_valid?(ARGV[1])

      puts "\nUsing database from command-line argument..."
      open_database_from_path(ARGV[1])
    end

    def sim_id_from_argv
      return nil unless ARGV.length >= 3

      arg = ARGV[2].to_s.strip
      return nil unless arg.match?(/^\d+$/)

      id = arg.to_i
      id > 0 ? id : nil
    end

    def get_simulation(db, sim_id)
      sim_mo = db.model_object_from_type_and_id('Sim', sim_id)
      if sim_mo.nil?
        puts "ERROR: Simulation with ID #{sim_id} not found in database."
        return nil
      end
      puts "\nAnalyzing simulation: #{sim_mo.name} (ID: #{sim_id})"
      sim_mo
    end

    def get_log_file_info(sim_mo, sim_id)
      results_path = sim_mo.results_path
      if results_path.nil? || results_path.empty?
        puts "ERROR: Results path not found for simulation ID #{sim_id}."
        puts "Has this simulation been run?"
        return nil
      end

      results_dir = File.dirname(results_path)
      log_file_path = File.join(results_dir, "SIM#{sim_id}.log")
      unless File.exist?(log_file_path)
        puts "ERROR: Log file not found: #{log_file_path}"
        return nil
      end

      puts "Log file found: #{log_file_path}"
      puts "File size: #{format_file_size(log_file_path)}"
      {
        log_path: log_file_path,
        results_dir: results_dir,
        file_size_mb: File.size(log_file_path) / 1024.0 / 1024.0
      }
    end

    def get_run_info(db, sim_mo)
      run_id = sim_mo.parent_id
      run_mo = db.model_object_from_type_and_id('Run', run_id)
      return nil if run_mo.nil?

      net_id = run_mo['Model Network']
      net_mo = db.model_object_from_type_and_id('Model Network', net_id)
      return nil if net_mo.nil?

      commit_id = run_mo['Model Network Commit ID']
      {
        run_mo: run_mo,
        net_mo: net_mo,
        commit_id: commit_id,
        run_parent_id: run_mo.parent_id
      }
    end

    def format_file_size(file_path)
      return 'N/A' unless File.exist?(file_path)

      size_bytes = File.size(file_path)
      if size_bytes < 1024
        "#{size_bytes} B"
      elsif size_bytes < 1024 * 1024
        "#{'%.1f' % (size_bytes / 1024.0)} KB"
      elsif size_bytes < 1024 * 1024 * 1024
        "#{'%.2f' % (size_bytes / 1024.0 / 1024.0)} MB"
      else
        "#{'%.2f' % (size_bytes / 1024.0 / 1024.0 / 1024.0)} GB"
      end
    end
  end

  module LogParse
    module_function

  def parse_log_file(log_path)
    puts "\nParsing log file..."

    data = {
      run_timestep: nil,
      diagnostic_level: nil,
      simulation_duration_min: nil,
      node_count: 0,
      has_wq: false,
      # Failures (actual problems)
      link_flow_failures: {},
      link_depth_failures: {},
      node_failures: {},
      # Unconverged (normal solver iterations)
      link_depth_unconverged: {},
      link_flow_unconverged: {},
      node_unconverged: {},
      timestep_data: [],
      timestep_occurrences: {},  # First/last-seen timing + dt values per Halving-based
                                 # failure (link depth/flow, node). Only halving events are
                                 # tracked here; unconverged counts come from the end-of-log
                                 # summary instead (see parse_end_of_log_summary).
      no_1d_data: true
    }

    lines = File.readlines(log_path)
    total_lines = lines.size
    puts "Total lines in log: #{total_lines}"

    # Parse header for run timestep
    parse_header(lines, data)

    # Parse run control parameters for WQ detection
    parse_run_control(lines, data)

    # Parse network size
    parse_network_size(lines, data)

    # Parse timestep lines for temporal data and dt values
    parse_timestep_lines(lines, data)

    # Parse end-of-log summary (primary data source)
    parse_end_of_log_summary(lines, data)

    # Check if we found any 1D data
    if data[:link_flow_failures].empty? &&
       data[:link_depth_failures].empty? &&
       data[:node_failures].empty? &&
       data[:link_depth_unconverged].empty? &&
       data[:link_flow_unconverged].empty? &&
       data[:node_unconverged].empty?
      data[:no_1d_data] = true
    else
      data[:no_1d_data] = false
    end

    puts "Parsed: #{data[:link_flow_failures].size} link flow failures"
    puts "Parsed: #{data[:link_depth_failures].size} link depth failures"
    puts "Parsed: #{data[:node_failures].size} node failures"
    puts "Parsed: #{data[:link_depth_unconverged].size} link depth unconverged"
    puts "Parsed: #{data[:link_flow_unconverged].size} link flow unconverged"
    puts "Parsed: #{data[:node_unconverged].size} node unconverged"
    puts "Parsed: #{data[:timestep_data].size} timestep entries"

    data
  end

  # Parse log header for run timestep and diagnostic level
  def parse_header(lines, data)
    # Validation warnings can push Run control parameters well past line 600
    # (e.g. ADSK model: INITIALISING at ~1390), and Run control parameters can
    # follow the INITIALISING marker. Scan until the SIMULATING phase starts.
    in_run_control = false

    lines.each do |line|
      if line =~ /^SIMULATING$/i
        break
      end

      if line =~ /Run control parameters:/
        in_run_control = true
        next
      end

      next unless in_run_control

      if m = line.match(/Run timestep \(s\)\s*-\s*(\d+)/)
        data[:run_timestep] = m[1].to_i
        puts "Found run timestep: #{data[:run_timestep]}s"
      end

      if m = line.match(/Diagnostic output level\s*-\s*(\d+)/)
        data[:diagnostic_level] = m[1].to_i
        puts "Found diagnostic level: #{data[:diagnostic_level]}"
      end

      # Run control block ends at first blank line after parameters started
      if line.strip.empty? && data[:run_timestep]
        break
      end
    end
  end

  # Parse run control parameters for WQ detection
  def parse_run_control(lines, data)
    in_run_control = false

    lines.each do |line|
      if line =~ /Run control parameters:/
        in_run_control = true
      elsif in_run_control
        # Check for WQ-specific parameters
        if line =~ /quality|constituent/i
          data[:has_wq] = true
          puts "Detected Water Quality parameters"
          break
        end

        # Exit run control section
        if line.strip.empty? || line =~ /^[A-Z]/
          break
        end
      end
    end
  end

  # Parse network size from available program options
  def parse_network_size(lines, data)
    lines.first(200).each do |line|
      if m = line.match(/(\d+)\s+nodes/i)
        data[:node_count] = m[1].to_i
        puts "Found node count: #{data[:node_count]}"
        break
      end
    end
  end

  # Parse timestep lines for temporal distribution and iteration tracking
  def parse_timestep_lines(lines, data)
    puts "Parsing timestep lines..."

    in_simulation_phase = false

    lines.each_with_index do |line, idx|
      # Detect SIMULATING phase start
      if line =~ /^SIMULATING$/i || line =~ /^Simulating\.\.\./i
        in_simulation_phase = true
        puts "Found SIMULATING phase start at line #{idx + 1}"
      elsif line =~ /^WRITING$/ || line =~ /^EXITING$/ || line =~ /^-- Proxy Engine Log --/
        in_simulation_phase = false
      end

      # Timestep: 3.88min elapsed, dt = 120.00s, 1 iteration(s).
      if m = line.match(/Timestep:\s+(\S+)min elapsed, dt = (\S+)s(?:,\s+(\d+)\s+iteration\(s\))?/)
        elapsed_min = m[1].to_f
        dt_value = m[2].to_f
        iterations = m[3] ? m[3].to_i : 1

        # Record every timestep line (tagged with is_simulation) so it's available
        # as a fallback timestep count; only SIMULATING-phase entries count toward
        # the simulation duration below.
        data[:timestep_data] << {
          elapsed_min: elapsed_min,
          dt: dt_value,
          iterations: iterations,
          is_simulation: in_simulation_phase
        }

        # Track simulation duration (only from SIMULATING phase)
        if in_simulation_phase && (data[:simulation_duration_min].nil? || elapsed_min > data[:simulation_duration_min])
          data[:simulation_duration_min] = elapsed_min
        end

        # Look ahead for Halving (failure) messages near this timestep
        # Only track SIMULATING phase for temporal metrics (to avoid initialization dt values)
        track_occurrences_from_timestep(lines, idx, elapsed_min, iterations, in_simulation_phase, data)
      end
    end

    puts "Simulation duration: #{data[:simulation_duration_min]} minutes"
  end

  # Track Halving-based failures for each object (see NOTE below on why
  # per-iteration unconverged tracking is not done here)
  # dt_value is the timestep size for this particular timestep
  # Only track SIMULATING phase to exclude initialization dt values
  def track_occurrences_from_timestep(lines, start_idx, elapsed_min, iterations, in_simulation_phase, data)
    # Skip if not in simulation phase (avoid initialization dt values)
    return unless in_simulation_phase

    # Look ahead up to 50 lines for failure/unconverged messages
    end_idx = [start_idx + 50, lines.size - 1].min

    # Get dt value from the timestep line
    timestep_line = lines[start_idx]
    tm = timestep_line.match(/dt = (\S+)s/)
    dt_value = tm ? tm[1].to_f : nil

    (start_idx + 1..end_idx).each do |i|
      line = lines[i]

      # Stop at next timestep
      break if line =~ /^Timestep:/

      # ICM log format: "Halving: H: <link><suffix>, Q: <link><suffix>, N: <node>, Reason: <reason>"
      # H: indicates link depth halving (failure) -> maps to "Link depth fail counts"
      # Q: indicates link flow halving (failure) -> maps to "Link flow fail counts"
      # N: indicates node failure -> maps to "Node fail counts"
      # Suffixes: "-" indicates halving, "<" or ">" indicates direction
      # Fields can be empty in any spacing ("H:  ,", "Q:  ,", "N: ,"), and
      # reasons can be several words ("Back Subst").
      if match = line.match(/^Halving:\s+H:\s*([^,]*),\s+Q:\s*([^,]*),\s+N:\s*([^,]*),\s+Reason:\s+(.+?)\s*$/)
        h_link_raw = match[1].strip
        q_link_raw = match[2].strip
        n_node_raw = match[3].strip

        # Extract link depth halving (H: field)
        # Use composite key to separate depth from flow failures
        unless h_link_raw.empty?
          link_id = h_link_raw.gsub(/[-<>]\s*$/, '')
          composite_key = "#{link_id}:depth"
          data[:timestep_occurrences][composite_key] ||= {
            object_id: link_id,
            first: elapsed_min,
            last: elapsed_min,
            dt_values: [],
            type: :failure
          }
          data[:timestep_occurrences][composite_key][:last] = elapsed_min
          data[:timestep_occurrences][composite_key][:dt_values] << dt_value if dt_value
        end

        # Extract link flow halving (Q: field)
        # Use composite key to separate flow from depth failures
        unless q_link_raw.empty?
          link_id = q_link_raw.gsub(/[-<>]\s*$/, '')
          composite_key = "#{link_id}:flow"
          data[:timestep_occurrences][composite_key] ||= {
            object_id: link_id,
            first: elapsed_min,
            last: elapsed_min,
            dt_values: [],
            type: :failure
          }
          data[:timestep_occurrences][composite_key][:last] = elapsed_min
          data[:timestep_occurrences][composite_key][:dt_values] << dt_value if dt_value
        end

        # Extract node failure (N: field)
        # Nodes don't need composite key since they only have one failure type
        unless n_node_raw.empty?
          node_id = n_node_raw.strip
          data[:timestep_occurrences][node_id] ||= {
            object_id: node_id,
            first: elapsed_min,
            last: elapsed_min,
            dt_values: [],
            type: :failure
          }
          data[:timestep_occurrences][node_id][:last] = elapsed_min
          data[:timestep_occurrences][node_id][:dt_values] << dt_value if dt_value
        end
      end
    end
  end

  # Parse end-of-log summary for fail/unconverged counts.
  # Parses FORWARD from the last SIMULATING marker so entries are read
  # after their section header (reverse_each mis-assigns sections).
  def parse_end_of_log_summary(lines, data)
    puts "Parsing end-of-log summary..."

    # Find the LAST SIMULATING line — the summary sections follow it
    sim_start_idx = nil
    lines.each_with_index do |line, idx|
      sim_start_idx = idx if line =~ /^SIMULATING$/i || line =~ /^Simulating\.\.\./i
    end

    unless sim_start_idx
      puts "WARNING: No SIMULATING marker found — skipping end-of-log summary"
      return
    end

    puts "Found last SIMULATING marker at line #{sim_start_idx + 1}"

    current_section = nil

    lines[sim_start_idx..-1].each do |line|
      # Detect section headers
      if    line =~ /^Link depth fail counts:/i    then current_section = :link_depth_failures
      elsif line =~ /^Link flow fail counts:/i     then current_section = :link_flow_failures
      elsif line =~ /^Node fail counts:/i          then current_section = :node_failures
      elsif line =~ /^Unconverged link depth/i     then current_section = :link_depth_unconverged
      elsif line =~ /^Unconverged link flow/i      then current_section = :link_flow_unconverged
      elsif line =~ /^Unconverged nodes/i          then current_section = :node_unconverged
      elsif line.strip.empty?
        # A blank line ends the current list block (e.g. before a
        # "Simulation statistics"-type block with no recognized header of
        # its own), so stop attributing further lines to it.
        current_section = nil
      elsif current_section && (m = line.match(/^\s+(.+?)\s+(\d+)\s*$/))
        object_id = normalize_summary_object_id(m[1].strip, current_section)
        count     = m[2].to_i
        next if line =~ /\s+-\s+/  # skip run-parameter header lines
        next if object_id =~ /#/ || object_id =~ /continuation results/i
        # Defensive: general run-statistics lines (e.g. "Number of 2D
        # timesteps :", "Number of grid cells :") can appear right after a
        # fail/unconverged list with no blank line or recognized header
        # between them. Real node/link IDs never contain a colon or start
        # with "Number of", so skip anything matching that shape rather than
        # misfiling it as a top-10 object.
        next if object_id =~ /:/ || object_id =~ /^Number of/i

        case current_section
        when :link_depth_failures   then data[:link_depth_failures][object_id]   = count
        when :link_flow_failures    then data[:link_flow_failures][object_id]    = count
        when :node_failures         then data[:node_failures][object_id]         = count
        when :link_depth_unconverged then data[:link_depth_unconverged][object_id] = count
        when :link_flow_unconverged  then data[:link_flow_unconverged][object_id]  = count
        when :node_unconverged      then data[:node_unconverged][object_id]      = count
        end
      end
    end
  end

  # Strip halving/direction suffixes from link IDs in end-of-log summaries (H:/Q: lines use the same rule).
  def normalize_summary_object_id(object_id, section)
    id = object_id.to_s.strip
    link_section = %i[
      link_depth_failures link_flow_failures
      link_depth_unconverged link_flow_unconverged
    ].include?(section)
    link_section ? id.gsub(/[-<>]\s*$/, '') : id
  end

  # Calculate estimated total timesteps for impact calculation
  def calculate_estimated_timesteps(log_data)
    if log_data[:simulation_duration_min] && log_data[:run_timestep]
      duration_seconds = log_data[:simulation_duration_min] * 60
      (duration_seconds / log_data[:run_timestep]).to_i
    else
      # Fallback: use number of parsed timestep lines
      log_data[:timestep_data].size
    end
  end

  # Extract top N failures/iterations with appropriate metrics
  # @param failures_hash [Hash] Object ID => count
  # @param estimated_timesteps [Integer] Total timesteps
  # @param occurrence_data [Hash] Composite key => {object_id, first, last, dt_values}.
  #   Unconverged entries have no matching key here, so their max/avg iterations
  #   below always report "Unknown".
  # @param limit [Integer] Number to return
  # @param is_failure [Boolean] True for failures (show first/last/min_dt), false for iterations (show max/avg)
  # @param failure_type [Symbol] :depth, :flow, or :node (for looking up correct composite key)
  # @return [Array<Hash>] Top failures with appropriate metrics
  def extract_top_failures(failures_hash, estimated_timesteps, occurrence_data, limit, is_failure = true, failure_type = nil)
    failures_hash.map do |object_id, count|
      # impact_pct/impact_level are not displayed by the report or used by the
      # selection-list code, but are included here for callers that want them.
      impact_pct = (count.to_f / estimated_timesteps * 100).round(2)

      # Look up occurrence data using composite key for link failures
      lookup_key = if failure_type == :depth
        "#{object_id}:depth"
      elsif failure_type == :flow
        "#{object_id}:flow"
      else
        object_id  # Nodes and unconverged use object_id directly
      end

      occurrence = occurrence_data[lookup_key] || {}

      # For failures, show first/last seen and min dt
      # For iterations, show max and average iterations
      if is_failure
        first_seen = occurrence[:first] ? "%.1f min" % occurrence[:first] : "Unknown"
        last_seen = occurrence[:last] ? "%.1f min" % occurrence[:last] : "Unknown"

        # Calculate minimum dt from dt_values array
        dt_values = occurrence[:dt_values] || []
        if dt_values.any?
          min_dt = "%.1f s" % dt_values.min
        else
          min_dt = "Unknown"
        end

        max_iterations = nil
        avg_iterations = nil
      else
        first_seen = nil
        last_seen = nil
        min_dt = nil

        iterations_list = occurrence[:iterations] || []
        if iterations_list.any?
          max_iterations = iterations_list.max
          avg_iterations = (iterations_list.sum.to_f / iterations_list.size).round(1)
        else
          max_iterations = "Unknown"
          avg_iterations = "Unknown"
        end
      end

      impact_level = if impact_pct > 10.0
        :critical
      elsif impact_pct > 5.0
        :warning
      elsif impact_pct > 1.0
        :info
      else
        :ok
      end

      {
        object_id: object_id,
        count: count,
        impact_pct: impact_pct,
        impact_level: impact_level,
        min_dt: min_dt,
        first_seen: first_seen,
        last_seen: last_seen,
        max_iterations: max_iterations,
        avg_iterations: avg_iterations
      }
    end.sort_by { |f| -f[:count] }.slice(0, limit || 999999)
  end
  end
  module Lists
    module_function

  def create_selection_lists(db, net, sim_mo, run_info, failure_data)
    puts "\nCreating selection lists..."

    parent_group = find_parent_group(db, run_info)

    empty_result = { created_count: 0, replaced_count: 0, conflict_count: 0, lost_count: 0, resolution: {} }

    unless parent_group
      puts 'WARNING: Could not determine parent group for selection lists'
      return empty_result
    end

    commit_id = run_info[:commit_id]

    # Create main diagnostics group
    diagnostics_group_name = "Sim#{sim_mo.id} Diagnostics"
    diagnostics_group = ensure_model_group(parent_group, diagnostics_group_name)

    unless diagnostics_group
      puts "WARNING: Could not create diagnostics group"
      return empty_result
    end

    created_count = 0
    replaced_count = 0
    conflict_count = 0
    lost_count = 0
    resolution = {}

    # All 6 categories' selection lists are saved directly into the single
    # diagnostics_group created above (no per-category sub-group).
    # Order: Link Flow, Link Depth, Node (Failures then Unconverged for each)
    categories = [
      { key: :link_flow_failures, name: 'Link Flow Failures', type: 'link' },
      { key: :link_flow_unconverged, name: 'Link Flow Unconverged', type: 'link' },
      { key: :link_depth_failures, name: 'Link Depth Failures', type: 'link' },
      { key: :link_depth_unconverged, name: 'Link Depth Unconverged', type: 'link' },
      { key: :node_failures, name: 'Node Failures', type: 'node' },
      { key: :node_unconverged, name: 'Node Unconverged', type: 'node' }
    ]

    categories.each do |category|
      data = failure_data[category[:key]].first(Top10FailUnconverge::SELECTION_LIST_LIMIT)
      next if data.empty?

      # Create selection list (same selection-save pattern used elsewhere in
      # InfoWorks Ruby scripts), saved directly under diagnostics_group.
      net.clear_selection

      missing_ids = []
      selected_count = 0
      net.transaction_begin
      begin
        data.each do |item|
          object_id = item[:object_id]

          if category[:type] == 'link'
            link_obj = net.row_object('_links', object_id)
            if link_obj
              link_obj.selected = true
              link_obj.write
              selected_count += 1
            else
              missing_ids << object_id
            end
          elsif category[:type] == 'node'
            node_obj = net.row_object('_nodes', object_id)
            if node_obj
              node_obj.selected = true
              node_obj.write
              selected_count += 1
            else
              missing_ids << object_id
            end
          end
        end
        net.transaction_commit
      rescue => e
        net.transaction_rollback
        puts "  WARNING: Transaction failed for #{category[:name]}: #{e.message}"
        resolution[category[:key]] = {
          selected: 0,
          requested: data.size,
          missing: data.map { |i| i[:object_id] }
        }
        next
      end

      resolution[category[:key]] = {
        selected: selected_count,
        requested: data.size,
        missing: missing_ids
      }

      if missing_ids.any?
        puts "  #{category[:name]}: #{selected_count}/#{data.size} in selection list." \
             " Not in latest network: #{missing_ids.join(', ')}"
      end

      next if selected_count.zero?

      # Save selection list directly under the single diagnostics group. The
      # list name is deterministic per (category, commit_id) - re-running this
      # script against the same network commit always produces this exact
      # name, so a prior run's list of the same name must be found and
      # replaced here or new_model_object below will collide with it.
      list_name = "Top #{Top10FailUnconverge::SELECTION_LIST_LIMIT} #{category[:name]}_v#{commit_id}"

      was_replacement = false
      existing_list = find_existing_selection_list(diagnostics_group, list_name)
      if existing_list
        begin
          existing_list.delete
          was_replacement = true
          puts "  Found existing list from a previous run, deleting before recreating: #{list_name}"
        rescue => e
          puts "  WARNING: Found an existing selection list named '#{list_name}' from a previous run, " \
               "but could not delete it: #{e.message}"
          conflict_count += 1
          resolution[category[:key]][:name_conflict] = true
          next
        end
      end

      begin
        sel_list = diagnostics_group.new_model_object('Selection List', list_name)
        net.save_selection(sel_list)
        puts "  #{was_replacement ? 'Replaced' : 'Created'}: #{list_name} (#{selected_count} objects)"
        created_count += 1
        replaced_count += 1 if was_replacement
      rescue => e
        puts "  WARNING: Failed to create selection list: #{e.message}"
        if was_replacement
          # The old list was already deleted above, so this category now has
          # no list at all (worse than a plain conflict, where the old list
          # is still there) - flag it separately so the caller can warn about
          # the data loss.
          resolution[category[:key]][:lost_list] = true
          lost_count += 1
        else
          # No existing list was found/deleted above, so this is most likely
          # a name collision with a list created elsewhere (e.g. a race with
          # another process).
          resolution[category[:key]][:name_conflict] = true
          conflict_count += 1
        end
      end
    end

    {
      created_count: created_count, replaced_count: replaced_count,
      conflict_count: conflict_count, lost_count: lost_count, resolution: resolution
    }
  end

  # Look for an existing Selection List child with this exact name in
  # category_group, so a prior run's list can be replaced instead of
  # colliding with it (list names are deterministic per network commit -
  # see list_name above). Also checks type, so this can't match some other
  # kind of object that happens to share the name.
  def find_existing_selection_list(category_group, list_name)
    category_group.children.each do |child|
      next unless child.name == list_name
      next if child.respond_to?(:type) && child.type.to_s != 'Selection List'

      return child
    end
    nil
  rescue
    nil
  end

  # Find the Model Group that holds the run
  def find_parent_group(db, run_info)
    parent_id = run_info[:run_parent_id] || run_info[:commit_id]
    return nil if db.nil? || parent_id.nil?

    begin
      db.model_object_from_type_and_id('Model Group', parent_id)
    rescue
      parent_net = db.model_object_from_type_and_id('Model Network', parent_id) rescue nil
      parent_net ? parent_net.parent : nil
    end
  end

  # Ensure a model group exists (create if needed)
  def ensure_model_group(parent_group, group_name)
    # Check if group already exists
    parent_group.children.each do |child|
      return child if child.name == group_name
    end

    # Create new group
    begin
      parent_group.new_model_object('Model Group', group_name)
    rescue => e
      puts "WARNING: Could not create Model Group '#{group_name}': #{e.message}"
      nil
    end
  end
  end

  module Report
    module_function

    def hash_total(hash)
      hash.values.sum
    end

    def category_pct(count, total)
      return 0.0 if total.nil? || total.zero?

      (count.to_f / total * 100).round(2)
    end

    def enrich_with_category_pct(items, source_hash)
      total = hash_total(source_hash)
      items.map do |item|
        item.merge(category_pct: category_pct(item[:count], total))
      end
    end

    def escape_html(text)
      return '' if text.nil?

      text.to_s.gsub('&', '&amp;').gsub('<', '&lt;').gsub('>', '&gt;').gsub('"', '&quot;').gsub("'", '&#39;')
    end

    def apply_list_resolution(items, category_resolution)
      return items.map { |item| item.merge(in_latest_network: nil) } unless category_resolution

      missing = category_resolution[:missing] || []
      items.map do |item|
        item.merge(in_latest_network: !missing.include?(item[:object_id]))
      end
    end

    def build_sections(failure_data, log_data, list_resolution = nil)
      [
        { key: :link_flow_failures, title: 'Link Flow Failures', items: failure_data[:link_flow_failures],
          source: log_data[:link_flow_failures], failure: true },
        { key: :link_flow_unconverged, title: 'Link Flow Unconverged', items: failure_data[:link_flow_unconverged],
          source: log_data[:link_flow_unconverged], failure: false },
        { key: :link_depth_failures, title: 'Link Depth Failures', items: failure_data[:link_depth_failures],
          source: log_data[:link_depth_failures], failure: true },
        { key: :link_depth_unconverged, title: 'Link Depth Unconverged', items: failure_data[:link_depth_unconverged],
          source: log_data[:link_depth_unconverged], failure: false },
        { key: :node_failures, title: 'Node Failures', items: failure_data[:node_failures],
          source: log_data[:node_failures], failure: true },
        { key: :node_unconverged, title: 'Node Unconverged', items: failure_data[:node_unconverged],
          source: log_data[:node_unconverged], failure: false }
      ].map do |sec|
        items = enrich_with_category_pct(sec[:items], sec[:source])
        if list_resolution && list_resolution[sec[:key]]
          items = apply_list_resolution(items, list_resolution[sec[:key]])
        end
        sec.merge(items: items)
      end
    end

    def any_missing_from_latest?(list_resolution)
      return false unless list_resolution

      list_resolution.values.any? { |r| r[:missing] && !r[:missing].empty? }
    end

    # True only if selection-list creation actually ran for at least one
    # category this pass. False when it never started at all (e.g. the
    # network couldn't be opened for writing), in which case every row's
    # "In latest network?" is unknown rather than a real Yes/No.
    def list_creation_attempted?(list_resolution)
      list_resolution && !list_resolution.empty?
    end

    def latest_network_cell(item)
      case item[:in_latest_network]
      when true then 'Yes'
      when false then 'No'
      else 'Not checked'
      end
    end

    def text_summary(sim_name, sim_id, sections, list_resolution = nil)
      lines = []
      lines << "Top 10 fail / unconverge - Sim #{sim_id} (#{sim_name})"
      lines << ''
      if !list_creation_attempted?(list_resolution)
        lines << 'No selection lists could be created this run (e.g. the network may not have been openable ' \
                 'for writing, such as being open in GeoPlan). The lists below are from the simulation log ' \
                 'only; "in latest network" is unknown for every row because that check only happens while ' \
                 'saving selection lists. Close the network elsewhere and run the script again.'
      else
        lines << '"In latest network" shows whether this script found an object with that exact ID on the ' \
                 'network\'s current latest commit when it tried to select it. "Not in latest network" can ' \
                 'mean either the network changed since this simulation ran (edits, renames, deletions), OR ' \
                 'the object still exists but under a slightly different ID than the log reports - the log ' \
                 'can include direction/halving suffixes or other decoration that this script strips before ' \
                 'looking the ID up, and that stripped-down ID does not always match the stored ID exactly. ' \
                 'If an object below looks like it should exist, check for it directly in the database before ' \
                 'assuming it was deleted. Either way, it was NOT saved to a selection list this run.'
      end
      lines << ''
      sections.each do |sec|
        lines << sec[:title]
        if sec[:items].empty?
          lines << '  (none)'
        else
          sec[:items].each_with_index do |item, idx|
            latest = item[:in_latest_network]
            latest_note = if latest == false
              ', not in latest network'
            elsif latest == true
              ', in selection list'
            else
              ''
            end
            base = "  #{idx + 1}. #{item[:object_id]} - count #{item[:count]}, #{item[:category_pct]}% of category#{latest_note}"
            if sec[:failure]
              lines << "#{base}, min dt #{item[:min_dt]}, first #{item[:first_seen]}, last #{item[:last_seen]}"
            else
              lines << base
            end
          end
        end
        lines << ''
      end
      lines.join("\n")
    end

    def write_html(path, sim_mo, sim_id, sections, log_path, list_resolution = nil)
      generated = Time.now.strftime('%Y-%m-%d %H:%M:%S')
      body = +''

      if !list_creation_attempted?(list_resolution)
        body << '<p class="note">No selection lists could be created this run &mdash; for example, the network ' \
                'may not have been openable for writing (e.g. its latest version was open in GeoPlan). The ' \
                'tables below are from the simulation log only. <strong>In latest network?</strong> shows ' \
                '&ldquo;Not checked&rdquo; for every row because that check only happens while saving ' \
                'selection lists. Close the network elsewhere, then run the script again.</p>'
      elsif any_missing_from_latest?(list_resolution)
        body << '<p class="note"><strong>In latest network?</strong> shows whether this script found an ' \
                "object with that exact ID on the network's current latest commit when it tried to select it. " \
                'A &ldquo;No&rdquo; can mean either (a) the network changed since this simulation ran (edits, ' \
                'renames, deletions), <strong>or (b) the object still exists but under a slightly different ' \
                'ID than the log reports</strong> &mdash; the log can include direction/halving suffixes ' \
                '(e.g. trailing &ldquo;-&rdquo;, &ldquo;&lt;&rdquo;, &ldquo;&gt;&rdquo;) or other decoration ' \
                'that this script strips before looking the ID up, and that stripped-down ID does not always ' \
                'match the ID actually stored on the object. If an Object ID below looks like it should exist, ' \
                'check for it directly in the database before assuming it was deleted. Either way, it was ' \
                '<strong>not</strong> saved to a selection list this run.</p>'
      end

      # Paired into a 3x2 grid: build_sections already orders these as
      # (Failures, Unconverged) per category - Link Flow, Link Depth, Node -
      # so each_slice(2) groups each category's two tables into one row
      # without reordering any data.
      sections.each_slice(2) do |pair|
        body << '<div class="row">'
        pair.each do |sec|
          body << "<section><h2>#{escape_html(sec[:title])}</h2>\n"
          if sec[:items].empty?
            body << "<p><em>No entries in log.</em></p>\n"
          else
            body << '<div class="table-wrap">'
            if sec[:failure]
              body << "<table><thead><tr><th>Rank</th><th>Object ID</th><th>Count</th><th>% of category</th>" \
                      "<th title=\"No can mean the network changed, or the log ID was decorated/normalized and no longer matches the stored ID exactly.\">In latest network?</th>" \
                      "<th>Min dt</th><th>First seen</th><th>Last seen</th></tr></thead><tbody>\n"
              sec[:items].each_with_index do |item, idx|
                body << '<tr>'
                body << "<td>#{idx + 1}</td>"
                body << "<td>#{escape_html(item[:object_id])}</td>"
                body << "<td>#{item[:count]}</td>"
                body << "<td>#{item[:category_pct]}</td>"
                body << "<td>#{latest_network_cell(item)}</td>"
                body << "<td>#{escape_html(item[:min_dt])}</td>"
                body << "<td>#{escape_html(item[:first_seen])}</td>"
                body << "<td>#{escape_html(item[:last_seen])}</td>"
                body << "</tr>\n"
              end
            else
              body << "<table><thead><tr><th>Rank</th><th>Object ID</th><th>Count</th>" \
                      "<th>% of category</th><th title=\"No can mean the network changed, or the log ID was decorated/normalized and no longer matches the stored ID exactly.\">In latest network?</th></tr></thead><tbody>\n"
              sec[:items].each_with_index do |item, idx|
                body << '<tr>'
                body << "<td>#{idx + 1}</td>"
                body << "<td>#{escape_html(item[:object_id])}</td>"
                body << "<td>#{item[:count]}</td>"
                body << "<td>#{item[:category_pct]}</td>"
                body << "<td>#{latest_network_cell(item)}</td>"
                body << "</tr>\n"
              end
            end
            body << "</tbody></table>"
            body << '</div>'
          end
          body << "</section>\n"
        end
        body << "</div>\n"
      end

      html = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8"/>
          <title>Top 10 fail / unconverge - Sim #{sim_id}</title>
          <style>
            body { font-family: Segoe UI, Arial, sans-serif; margin: 24px; color: #222; }
            h1 { font-size: 1.4rem; }
            h2 { font-size: 1.1rem; margin-top: 24px; border-bottom: 1px solid #ccc; }
            .row { display: flex; gap: 20px; align-items: flex-start; }
            .row > section { flex: 1 1 0; min-width: 0; }
            .table-wrap { overflow-x: auto; }
            table { border-collapse: collapse; width: 100%; margin-bottom: 12px; }
            th, td { border: 1px solid #ddd; padding: 6px 8px; text-align: left; font-size: 0.9rem; }
            th { background: #f5f5f5; }
            .meta { color: #555; font-size: 0.85rem; margin-bottom: 20px; max-width: 1600px; }
            .note { background: #f9f6e8; border: 1px solid #e6d9a8; padding: 10px 12px; font-size: 0.9rem; max-width: 1600px; }
          </style>
        </head>
        <body>
          <h1>Top 10 fail / unconverge</h1>
          <div class="meta">
            <div>Simulation: #{escape_html(sim_mo.name)} (ID #{sim_id})</div>
            <div>Generated: #{escape_html(generated)}</div>
            <div>Log: #{escape_html(log_path)}</div>
          </div>
          #{body}
        </body>
        </html>
      HTML

      File.write(path, html)
    end
  end

  module Headless
    module_function

    def emit(lines)
      lines.each do |line|
        puts line
        $stdout.flush
      end
      path = ENV['TOP10_RESULT_FILE']
      return unless path && !path.to_s.strip.empty?

      File.open(path, 'a') { |f| lines.each { |line| f.puts(line) } }
    rescue
      nil
    end

    def report_failure(message)
      emit([
        "TOP10_FAIL_UNCONVERGE_ERROR=#{message}",
        'SELECTION_LISTS_CREATED=0',
        'SELECTION_LISTS_REPLACED=0',
        'SELECTION_LISTS_CONFLICTS=0',
        'SELECTION_LISTS_LOST=0'
      ])
    end

    def report_success(count, report_written, replaced_count = 0, conflict_count = 0, lost_count = 0)
      lines = [
        "SELECTION_LISTS_CREATED=#{count}",
        "SELECTION_LISTS_REPLACED=#{replaced_count}",
        "SELECTION_LISTS_CONFLICTS=#{conflict_count}",
        "SELECTION_LISTS_LOST=#{lost_count}"
      ]
      lines << 'TOP10_REPORT_WRITTEN=1' if report_written
      emit(lines)
    end

    def run
      run_lists_only
    end

    def run_lists_only
      db = ICMHelpers.open_database_from_argv
      unless db
        report_failure('Could not open database (pass database path as ARGV[1])')
        return
      end

      sim_id = ICMHelpers.sim_id_from_argv
      unless sim_id
        report_failure('Simulation ID required (pass as ARGV[2])')
        return
      end

      sim_mo = ICMHelpers.get_simulation(db, sim_id)
      unless sim_mo
        report_failure("Simulation #{sim_id} not found in database")
        return
      end

      log_info = ICMHelpers.get_log_file_info(sim_mo, sim_id)
      unless log_info && log_info[:log_path] && File.exist?(log_info[:log_path])
        report_failure("Log file not found for Sim #{sim_id}")
        return
      end

      run_info = ICMHelpers.get_run_info(db, sim_mo)
      unless run_info && run_info[:net_mo]
        report_failure('Could not resolve run / network info for simulation')
        return
      end

      log_data = LogParse.parse_log_file(log_info[:log_path])
      if log_data[:no_1d_data]
        report_failure('No 1D timestep data in log')
        return
      end

      limit = SELECTION_LIST_LIMIT
      estimated = LogParse.calculate_estimated_timesteps(log_data)

      top_link_flow_failures = LogParse.extract_top_failures(
        log_data[:link_flow_failures], estimated, log_data[:timestep_occurrences], limit, true, :flow
      )
      top_link_depth_failures = LogParse.extract_top_failures(
        log_data[:link_depth_failures], estimated, log_data[:timestep_occurrences], limit, true, :depth
      )
      top_node_failures = LogParse.extract_top_failures(
        log_data[:node_failures], estimated, log_data[:timestep_occurrences], limit, true, :node
      )
      top_link_depth_unconverged = LogParse.extract_top_failures(
        log_data[:link_depth_unconverged], estimated, log_data[:timestep_occurrences], limit, false
      )
      top_link_flow_unconverged = LogParse.extract_top_failures(
        log_data[:link_flow_unconverged], estimated, log_data[:timestep_occurrences], limit, false
      )
      top_node_unconverged = LogParse.extract_top_failures(
        log_data[:node_unconverged], estimated, log_data[:timestep_occurrences], limit, false
      )

      failure_data = {
        link_flow_failures: top_link_flow_failures,
        link_flow_unconverged: top_link_flow_unconverged,
        link_depth_failures: top_link_depth_failures,
        link_depth_unconverged: top_link_depth_unconverged,
        node_failures: top_node_failures,
        node_unconverged: top_node_unconverged
      }

      empty_list_result = { created_count: 0, replaced_count: 0, conflict_count: 0, lost_count: 0, resolution: {} }
      list_result = empty_list_result
      begin
        puts "\nOpening network for selection list creation..."
        net = run_info[:net_mo].open
        list_result = Lists.create_selection_lists(
          db, net, sim_mo, run_info, failure_data
        )
      rescue => e
        puts "WARNING: Could not create selection lists: #{e.class}: #{e.message}"
        list_result = empty_list_result
      end

      selection_count = list_result[:created_count]
      replaced_count = list_result[:replaced_count].to_i
      conflict_count = list_result[:conflict_count].to_i
      lost_count = list_result[:lost_count].to_i
      list_resolution = list_result[:resolution]
      sections = Report.build_sections(failure_data, log_data, list_resolution)

      report_written = false
      report_path = ENV['TOP10_REPORT_HTML']
      if report_path && !report_path.to_s.strip.empty?
        begin
          Report.write_html(
            report_path.to_s.strip, sim_mo, sim_id, sections, log_info[:log_path], list_resolution
          )
          report_written = true
        rescue => e
          puts "WARNING: Could not write HTML report: #{e.message}"
        end
      end

      summary_text = Report.text_summary(sim_mo.name, sim_id, sections, list_resolution)
      append_text_summary(summary_text) if summary_text && !summary_text.empty?

      report_success(selection_count, report_written, replaced_count, conflict_count, lost_count)
    rescue => e
      report_failure(e.message.to_s.empty? ? 'Unexpected error' : e.message)
    end

    def append_text_summary(text)
      path = ENV['TOP10_RESULT_FILE']
      return unless path && !path.to_s.strip.empty?

      File.open(path, 'a') do |f|
        f.puts('TOP10_TEXT_SUMMARY_BEGIN')
        f.puts(text)
        f.puts('TOP10_TEXT_SUMMARY_END')
      end
    rescue
      nil
    end
  end

  module UI
    module_function

    def ws_ui?
      defined?(WSApplication) && WSApplication.respond_to?(:ui?) && WSApplication.ui?
    end

    def ws_method?(name)
      defined?(WSApplication) && WSApplication.respond_to?(name)
    end

    def message_box(text, icon = 'Information')
      if ws_method?(:message_box)
        WSApplication.message_box(text, 'OK', icon, false)
      else
        puts text
      end
    end

    def find_icm_exchange
      return ICM_EXCHANGE_PATH if ICM_EXCHANGE_PATH && !ICM_EXCHANGE_PATH.to_s.strip.empty? && File.exist?(ICM_EXCHANGE_PATH)

      ICM_EXCHANGE_CANDIDATES.each do |path|
        return path if File.exist?(path)
      end
      nil
    end

    def parse_text_summary(combined)
      return nil unless combined.to_s.include?('TOP10_TEXT_SUMMARY_BEGIN')

      combined.to_s.split('TOP10_TEXT_SUMMARY_BEGIN', 2)[1].to_s.split('TOP10_TEXT_SUMMARY_END', 2)[0].to_s.strip
    end

    def parse_worker_output(output)
      lists = nil
      replaced = nil
      conflicts = nil
      lost = nil
      err = nil
      report_written = false
      output.to_s.each_line do |line|
        if (m = line.match(MARKER_LISTS))
          lists = m[1].to_i
        elsif (m = line.match(MARKER_REPLACED))
          replaced = m[1].to_i
        elsif (m = line.match(MARKER_CONFLICTS))
          conflicts = m[1].to_i
        elsif (m = line.match(MARKER_LOST))
          lost = m[1].to_i
        elsif (m = line.match(MARKER_ERROR))
          err = m[1].strip
        elsif line.strip == 'TOP10_REPORT_WRITTEN=1'
          report_written = true
        end
      end
      [lists, err, report_written, replaced, conflicts, lost]
    end

    LIST_WRITE_FAILURE = /WARNING: (Transaction failed|Failed to create selection list|Could not create selection lists)/

    def list_write_failed?(combined)
      combined.to_s.match?(LIST_WRITE_FAILURE)
    end

    # Name of the sim's model network when GeoPlan has that network open, else nil.
    # The UI API cannot report which commit is open, so this is only checked after
    # Exchange has failed to save lists.
    def geoplan_open_sim_network(db, sim_mo)
      return nil unless ws_method?(:current_network)

      net = WSApplication.current_network
      return nil if net.nil?

      run_mo = db.model_object_from_type_and_id('Run', sim_mo.parent_id)
      return nil if run_mo.nil?

      open_mo = net.network_model_object
      return nil unless open_mo && open_mo.id == run_mo['Model Network']

      open_mo.name
    rescue
      nil
    end

    # Note appended to the "Done!" message when some of the lists created
    # this run replaced a same-named list from an earlier run against the
    # same network version (expected - see find_existing_selection_list).
    def replaced_lists_note(replaced_count)
      return '' unless replaced_count.to_i.positive?

      " (#{replaced_count} of these replaced a same-named list left over from an earlier run against " \
      'this same network version - that is expected.)'
    end

    # Message shown when zero selection lists were created AND at least one
    # category found a same-named list from a previous run that it could not
    # delete to replace it.
    def name_conflict_message(sim_id, conflict_count)
      "This script found #{conflict_count} selection list(s) already in the database from an earlier " \
      "run of this script against this same network version, but could not delete them to save fresh " \
      "ones in their place.\n\n" \
      "Your existing list(s) are untouched and still usable - look under the \"Sim#{sim_id} " \
      "Diagnostics\" group in the database tree.\n\n" \
      'If you want fresh lists instead, delete the old one(s) from that group yourself, then run the ' \
      'script again.'
    end

    # Warning for when an old same-named list was deleted to be replaced, but
    # creating the new one then failed too - so that category now has no
    # list at all. Returned with a trailing blank line (when non-empty) so
    # callers can prepend it to whichever other message they're showing,
    # since this can co-occur with partial success in other categories.
    def lost_lists_warning(lost_count)
      return '' unless lost_count.to_i.positive?

      body = if lost_count.to_i == 1
        "WARNING: 1 old selection list from a previous run was deleted so it could be replaced, but " \
        "saving the new version then failed - so that category now has no selection list at all (it " \
        'did before this run). Run the script again to try recreating it.'
      else
        "WARNING: #{lost_count} old selection lists from a previous run were deleted so they could be " \
        'replaced, but saving the new versions then failed - so those categories now have no selection ' \
        'list at all (they did before this run). Run the script again to try recreating them.'
      end

      "#{body}\n\n"
    end

    def lists_blocked_message(db, sim_mo, combined, lists_created)
      return nil unless lists_created.to_i.zero? || list_write_failed?(combined)

      name = geoplan_open_sim_network(db, sim_mo)
      return nil unless name

      "Selection lists couldn't be saved because the network \"#{name}\" is currently open for editing in " \
        "GeoPlan (the map view).\n\n" \
        "What to do:\n" \
        "  1. Close that network's map window (an older, read-only version is fine to leave open), and\n" \
        '  2. Run this script again.'
    end

    def read_result_file(path)
      return '' unless path && File.exist?(path)

      File.read(path)
    rescue
      ''
    end

    # Best-effort: WSApplication.current_selection reflects GeoPlan/network
    # selections, not database-tree clicks, so selecting a Sim in the
    # database tree does not set it. resolve_sim_mo falls through to
    # prompt_sim_id when this returns nil.
    def resolve_sim_from_selection
      return nil unless ws_method?(:current_selection)

      mo = WSApplication.current_selection
      return mo if mo && mo.respond_to?(:type) && mo.type.to_s == 'Sim'

      nil
    rescue
      nil
    end

    def prompt_sim_id
      return nil unless ws_method?(:input_box)

      raw = WSApplication.input_box(
        "Enter the ID of a completed Sim to check (right click > properties > ID, or 'show details' " \
        'in database tree, e.g. 134):',
        'Top 10 Fail / Unconverge',
        ''
      )
      return nil if raw.nil? || raw.to_s.strip.empty?

      id = raw.to_s.strip.to_i
      id > 0 ? id : nil
    end

    def resolve_sim_mo(db)
      mo = resolve_sim_from_selection
      return mo if mo

      sim_id = prompt_sim_id
      return nil unless sim_id

      db.model_object_from_type_and_id('Sim', sim_id)
    rescue => e
      message_box(
        "This script ran into a problem while looking up that simulation.\n\n" \
        "Details: #{e.message}\n\n" \
        'Double-check the Simulation ID and try again.',
        '!'
      )
      nil
    end

    def open_report_windows(path)
      return false unless path && File.exist?(path)

      if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
        system('cmd', '/c', 'start', '', path)
      else
        system('xdg-open', path)
      end
    rescue
      false
    end

    def build_text_from_report_html(path)
      return nil unless path && File.exist?(path)

      # Minimal strip for message_box fallback (tables remain readable as HTML stripped)
      text = File.read(path)
      text = text.gsub(/<style[\s\S]*?<\/style>/i, '')
      text = text.gsub(/<[^>]+>/, ' ')
      text = text.gsub(/\s+/, ' ').strip
      text.length > 3500 ? text[0, 3500] + '...' : text
    rescue
      nil
    end

    # Exits `run` quietly (no raised exception, no second error dialog) after
    # a message box has already told the user why the script stopped.
    def run
      unless ws_method?(:current_database)
        message_box(
          "This script needs to run inside the InfoWorks ICM program itself.\n\n" \
          'Open InfoWorks ICM, then run this script from the ICM Scripts list.',
          'Stop'
        )
        return
      end

      db = WSApplication.current_database
      unless db
        message_box(
          "No database is open.\n\n" \
          'Open the database containing your simulation, then run this script again.',
          'Stop'
        )
        return
      end

      sim_mo = resolve_sim_mo(db)
      unless sim_mo
        # Reaching here means the Simulation ID prompt was left blank,
        # cancelled, or given an invalid (non-numeric or zero) ID - treat it
        # as a plain cancellation, not a missing-selection error.
        message_box(
          "Cancelled - no Simulation ID was entered.\n\n" \
          'Run the script again and enter the ID of a completed Sim when prompted (the number shown ' \
          'next to it in the database tree).',
          'Information'
        )
        return
      end

      sim_id = sim_mo.id
      db_path = db.path.to_s
      if db_path.empty?
        message_box(
          "This database doesn't have a saved file location yet.\n\n" \
          'Save the database to a file on disk, then run this script again.',
          'Stop'
        )
        return
      end

      script_path = File.expand_path(__FILE__)
      icm_exchange = find_icm_exchange
      unless icm_exchange
        message_box(
          "This script couldn't find ICMExchange.exe, a part of InfoWorks ICM it needs to run in the " \
          "background.\n\n" \
          "What to try:\n" \
          "  - Make sure InfoWorks ICM is installed on this PC, or\n" \
          '  - Ask an administrator to set ICM_EXCHANGE_PATH near the top of this script to the full ' \
          'location of ICMExchange.exe.',
          'Stop'
        )
        return
      end

      if ws_method?(:message_box)
        answer = WSApplication.message_box(
          "This will scan the log for Simulation #{sim_id} and create selection lists for the top 10 " \
          "worst-performing links and nodes.\n\n" \
          "Simulation: #{sim_mo.name} (ID #{sim_id})\n" \
          "Database: #{db_path}\n\n" \
          "This runs in the background and usually takes a few seconds. The InfoWorks ICM window may " \
          "pause briefly while it works - this is normal.\n\n" \
          'Continue?',
          'YesNo', '?', false
        )
        return unless answer.to_s.downcase == 'yes'
      end

      result_file = File.join(Dir.tmpdir, "top10_fail_unconverge_#{Process.pid}.txt")
      File.delete(result_file) if File.exist?(result_file)

      report_html = File.join(Dir.tmpdir, "top10_fail_unconverge_#{sim_id}_#{Process.pid}.html")
      File.delete(report_html) if File.exist?(report_html)

      # No `puts` here: the ICM UI opens a "Script Output" console the moment
      # this UI-run script writes to stdout. All user-facing feedback for the
      # UI run goes through message_box instead, below.
      output, _status = Open3.capture2e(
        {
          'TOP10_RESULT_FILE' => result_file,
          'TOP10_REPORT_HTML' => report_html
        },
        icm_exchange, script_path, db_path, sim_id.to_s
      )

      combined = output.to_s + read_result_file(result_file)
      File.delete(result_file) if File.exist?(result_file)

      lists_created, error_line, report_written, replaced_count, conflict_count, lost_count =
        parse_worker_output(combined)
      lost_warning = lost_lists_warning(lost_count)

      if error_line && lists_created.to_i.zero?
        message_box(
          "This script couldn't finish checking Simulation #{sim_id}.\n\n" \
          "Reason: #{error_line}\n\n" \
          "What to try:\n" \
          "  - Make sure the Sim has fully finished running and its results are available on this PC " \
          "(if the results are only in the cloud, download them first), and\n" \
          '  - Run the script again.',
          '!'
        )
      elsif lists_created.nil?
        message_box(
          "This script started a background check for Simulation #{sim_id}, but it didn't finish or " \
          "report back properly - so nothing was created.\n\n" \
          "What to try:\n" \
          "  - Run the script again, and\n" \
          '  - If this keeps happening, contact whoever maintains this script for help.',
          '!'
        )
      else
        opened = false
        if report_written && File.exist?(report_html)
          opened = open_report_windows(report_html)
        end

        blocked = lists_blocked_message(db, sim_mo, combined, lists_created)

        if opened
          if blocked
            # Some, but not necessarily all, of the 6 categories may have saved
            # before the write lock collided with GeoPlan. Say so explicitly so
            # a non-zero lists_created count is never reported as a total failure.
            created_note = if lists_created.to_i.positive?
              "Good news: #{lists_created} of the 6 selection lists were already saved before this " \
              "happened - you don't need to redo those.\n\n"
            else
              ''
            end
            message_box("#{lost_warning}#{created_note}#{blocked}", '!')
          elsif lists_created.to_i.zero? && conflict_count.to_i.positive?
            message_box(
              "#{lost_warning}The summary report opened in your browser.\n\n" \
              "#{name_conflict_message(sim_id, conflict_count)}",
              '!'
            )
          elsif lists_created.to_i.zero?
            message_box(
              "#{lost_warning}The summary report opened in your browser, but no selection lists were " \
              "saved to the database this time.\n\n" \
              "You can still review the results in the report that just opened. If you'd also like the " \
              "selection lists saved, try running the script again.",
              '!'
            )
          else
            message_box(
              "#{lost_warning}Done! Created #{lists_created} selection list(s) for Simulation #{sim_id}." \
              "#{replaced_lists_note(replaced_count)}\n\n" \
              "A summary report also opened in your browser - take a look there for the full details.\n\n" \
              "To see the new selection lists in InfoWorks ICM:\n" \
              "  1. Refresh the database tree (right-click it and choose Refresh, or press F5), then\n" \
              "  2. Open the \"Sim#{sim_id} Diagnostics\" group.",
              lost_warning.empty? ? 'Information' : '!'
            )
          end
        else
          fallback = parse_text_summary(combined) || build_text_from_report_html(report_html)
          body = +if blocked
            created_note = lists_created.to_i.positive? ? "#{lists_created} of the 6 selection lists were " \
              "already saved before this happened - you don't need to redo those.\n\n" : ''
            "#{lost_warning}#{created_note}#{blocked}\n\n"
          elsif lists_created.to_i.zero? && conflict_count.to_i.positive?
            "#{lost_warning}#{name_conflict_message(sim_id, conflict_count)}\n\n"
          elsif lists_created.to_i.zero?
            "#{lost_warning}No selection lists were saved to the database this time.\n\n"
          else
            "#{lost_warning}Done! Created #{lists_created} selection list(s) for Simulation #{sim_id}." \
            "#{replaced_lists_note(replaced_count)}\n\n" \
            "To see them in InfoWorks ICM:\n" \
            "  1. Refresh the database tree (right-click it and choose Refresh, or press F5), then\n" \
            "  2. Open the \"Sim#{sim_id} Diagnostics\" group.\n\n"
          end
          body << "(The summary report didn't open automatically in your browser, so here it is instead:)\n\n"
          if fallback && !fallback.empty?
            body << "Report summary:\n#{fallback}"
          elsif report_written
            body << "You can view the full report here: #{report_html}"
          else
            body << 'No report file was written this time.'
          end
          message_box(body, 'Information')
        end
      end
    end
  end
end

def ws_ui?
  Top10FailUnconverge::UI.ws_ui?
end

# UI.run exits via `return` (not an exception) when it has already shown the
# user an explanatory message box, so no sentinel/"abort" exception needs to
# be re-raised or special-cased here. Anything caught below is a genuine,
# unexpected error.
begin
  if ws_ui?
    Top10FailUnconverge::UI.run
  else
    Top10FailUnconverge::Headless.run
  end
rescue => e
  if ws_ui?
    Top10FailUnconverge::UI.message_box(
      "Something unexpected went wrong and the script had to stop.\n\n" \
      "Technical details (useful if you need to report this):\n#{e.class}: #{e.message}\n\n" \
      'You can try running the script again. If it keeps happening, share the details above with ' \
      'whoever maintains this script.',
      'Stop'
    )
  else
    Top10FailUnconverge::Headless.report_failure("#{e.class}: #{e.message}")
  end
end
