# Assign Upstream/Downstream Node IDs Based on Link Geometry
#
# Snaps link endpoints to nearest nodes using geometry (first vertex = upstream, last = downstream)
#
# Features:
# - Auto-detects InfoWorks/SWMM networks and units
# - Process only invalid node IDs or re-snap all links
# - Handles InfoWorks link ID conflicts by adjusting suffixes
# - Optional data flags to track auto-assigned values
# - Works with all link types (conduits, pumps, orifices, weirs, outlets)

require 'set'

SEARCH_RADIUS = 2.0      # Default max search distance
INITIAL_RADIUS = 0.1     # Start small for precision
RADIUS_INCREMENT = 0.1   # Expand gradually
def get_user_options(network)
  options = {}
  
  # Detect network type
  is_swmm = false
  begin
    network.row_objects('sw_node').each { is_swmm = true; break }
  rescue
  end
  options[:is_swmm] = is_swmm
  
  # Build dialog
  layout = [
    ['--- Select Links to Process ---', 'READONLY', ''],
    ['Which links to update:', 'String', 'Only links with missing/invalid node IDs', nil, 'LIST', 
     ['Only links with missing/invalid node IDs', 'All links (re-snap everything)']],
    ['', 'READONLY', ''],
    ['--- Search Settings ---', 'READONLY', ''],
    ['Model units:', 'String', 'Metric (meters)', nil, 'LIST', ['Metric (meters)', 'US (feet)']],
    ['Max search radius:', 'Number', SEARCH_RADIUS, 1],
    ['', 'READONLY', ''],
    ['--- Data Flags ---', 'READONLY', ''],
    ['Set node ID flag on updated endpoints?', 'Boolean', false],
    ['Flag value (up to 4 characters):', 'String', '']
  ]
  
  result = WSApplication.prompt('Assign Nodes by Link Geometry', layout, false)
  return nil if result.nil?
  
  options[:process_all] = (result[1] == 'All links (re-snap everything)')
  unit_system_input = result[4]
  options[:search_radius] = result[5]
  options[:set_flag] = result[8]
  options[:flag_value] = result[9].to_s.strip
  options[:units] = unit_system_input.include?('Metric') ? 'meters' : 'feet'
  
  if options[:search_radius] <= 0
    WSApplication.message_box("Invalid search radius. Using default: #{SEARCH_RADIUS} #{options[:units]}", 'OK', '!', false)
    options[:search_radius] = SEARCH_RADIUS
  end
  
  if options[:set_flag] && options[:flag_value].length > 4
    original = options[:flag_value]
    options[:flag_value] = options[:flag_value][0, 4]
    puts "NOTE: Flag value '#{original}' truncated to '#{options[:flag_value]}' (4 char limit)"
  end
  
  options
end

def set_node_id(network, link, direction, search_radius, valid_node_ids, stats, options, link_table, all_link_tables)
  node_id_key = direction == :upstream ? "us_node_id" : "ds_node_id"
  point_array = link.point_array
  
  if point_array.nil? || point_array.empty?
    stats[:no_geometry] += 1
    puts "  [WARN] Link #{link.id} has no geometry data"
    return false
  end
  
  end_vertex = direction == :upstream ? point_array[0, 2] : point_array.last(2)
  
  if end_vertex.nil? || end_vertex.length < 2
    stats[:no_geometry] += 1
    puts "  [WARN] Link #{link.id} has invalid geometry"
    return false
  end
  
  x, y = end_vertex[0], end_vertex[1]
  
  # Expand search radius gradually to find nearest node
  radius = INITIAL_RADIUS
  found_node = nil
  node_type = options[:is_swmm] ? 'sw_node' : 'hw_node'
  
  loop do
    break if radius > search_radius
    
    begin
      roc = network.search_at_point(x, y, radius, node_type)
      
      if roc && !roc.empty?
        roc.each do |ro|
          next if ro.node_id == link.us_node_id || ro.node_id == link.ds_node_id
          next unless valid_node_ids.include?(ro.node_id)
          
          found_node = ro
          break
        end
        
        break if found_node
      end
    rescue
      break
    end
    
    radius += RADIUS_INCREMENT
  end
  
  if found_node
    old_id = link[node_id_key]
    new_node_id = found_node.node_id
    
    # InfoWorks: check for link ID conflicts (link ID = us_node_id.suffix)
    if !options[:is_swmm] && direction == :upstream && old_id != new_node_id
      begin
        link_suffix = link.link_suffix
        current_link_id = link.id
        
        if link_suffix && !link_suffix.empty?
          proposed_id = "#{new_node_id}.#{link_suffix}"
          
          if proposed_id != current_link_id
            # Check for conflicts across ALL link tables (shared namespace in InfoWorks)
            conflict_found = false
            all_link_tables.each do |check_table|
              begin
                existing = network.row_object(check_table, proposed_id)
                if existing && existing.id != current_link_id
                  conflict_found = true
                  break
                end
              rescue
                # No object found in this table
              end
            end
            
            # Find unique 1-character suffix if conflict exists
            if conflict_found
              original_suffix = link_suffix
              possible_suffixes = ('1'..'9').to_a + ('A'..'Z').to_a
              new_suffix = nil
              
              possible_suffixes.each do |try_suffix|
                next if try_suffix == original_suffix
                
                proposed_id = "#{new_node_id}.#{try_suffix}"
                
                # Check this suffix across all link tables
                conflict_found = false
                all_link_tables.each do |check_table|
                  begin
                    existing = network.row_object(check_table, proposed_id)
                    if existing && existing.id != current_link_id
                      conflict_found = true
                      break
                    end
                  rescue
                    # No object found in this table
                  end
                end
                
                if !conflict_found
                  new_suffix = try_suffix
                  break
                end
              end
              
              if new_suffix
                link.link_suffix = new_suffix
                stats[:suffix_changed] += 1
                
                if options[:set_flag] && !options[:flag_value].empty?
                  begin
                    link.link_suffix_flag = options[:flag_value]
                  rescue => e
                    puts "  [WARN] Could not set link_suffix_flag: #{e.message}"
                  end
                end
                
                puts "  [INFO] Link suffix changed from '#{original_suffix}' to '#{new_suffix}' to avoid duplicate ID"
              else
                puts "  [ERROR] Could not find unique suffix for link #{current_link_id} - skipping"
                return false
              end
            end
          end
        end
      rescue => e
        puts "  [ERROR] Error handling link_suffix: #{e.message}"
        return false
      end
    end
    
    link[node_id_key] = new_node_id
    
    if options[:set_flag] && !options[:flag_value].empty?
      begin
        flag_field = direction == :upstream ? "us_node_id_flag" : "ds_node_id_flag"
        link[flag_field] = options[:flag_value]
      rescue => e
        puts "  [WARN] Could not set flag: #{e.message}"
      end
    end
    
    begin
      link.write
      
      direction_str = direction == :upstream ? "US" : "DS"
      if old_id.nil? || old_id.empty?
        puts "  [OK] Link #{link.id}: Set #{direction_str} node to #{found_node.node_id}"
        stats[:assigned] += 1
      else
        puts "  [OK] Link #{link.id}: Changed #{direction_str} node from '#{old_id}' to #{found_node.node_id}"
        stats[:changed] += 1
      end
      return true
    rescue => e
      direction_str = direction == :upstream ? "US" : "DS"
      puts "  [ERROR] Link #{link.id}: Failed to write changes for #{direction_str} - #{e.message}"
      return false
    end
  else
    direction_str = direction == :upstream ? "US" : "DS"
    puts "  [FAIL] Link #{link.id}: No valid node found within #{search_radius} #{options[:units]} for #{direction_str} (#{x.round(2)}, #{y.round(2)})"
    stats[:not_found] += 1
    return false
  end
end

begin
  network = WSApplication.current_network
  
  if network.nil?
    WSApplication.message_box('No network is currently open', 'OK', 'Stop', false)
    return
  end
  
  options = get_user_options(network)
  return if options.nil?
  
  # Validate network before starting
  valid_node_ids = Set.new
  node_table = options[:is_swmm] ? 'sw_node' : 'hw_node'
  
  begin
    network.row_objects(node_table).each do |node|
      valid_node_ids.add(node.node_id) if node.node_id
    end
  rescue => e
    WSApplication.message_box("Error accessing node table: #{e.message}", 'OK', 'Stop', false)
    return
  end
  
  if valid_node_ids.empty?
    WSApplication.message_box('No valid nodes found in network', 'OK', 'Stop', false)
    return
  end
  
  stats = {
    total_processed: 0,
    links_updated: 0,
    assigned: 0,
    changed: 0,
    not_found: 0,
    no_geometry: 0,
    skipped: 0,
    suffix_changed: 0
  }
  
  network.transaction_begin
  
  # Use appropriate link tables based on network type
  if options[:is_swmm]
    link_tables = ['sw_conduit', 'sw_pump', 'sw_orifice', 'sw_weir', 'sw_outlet']
  else
    link_tables = ['hw_conduit', 'hw_pump', 'hw_orifice', 'hw_weir']
  end
  
  # Print header now that validation is complete and transaction started
  puts "=" * 80
  puts "Assign Upstream/Downstream Nodes by Link Geometry"
  puts "=" * 80
  puts "Network Type: #{options[:is_swmm] ? 'SWMM' : 'InfoWorks'}"
  puts "Mode: #{options[:process_all] ? 'Re-snapping ALL links' : 'Only links with missing/invalid node IDs'}"
  puts "Search Radius: #{options[:search_radius]} #{options[:units]}"
  puts "Node ID Flag: #{options[:set_flag] && !options[:flag_value].empty? ? "'#{options[:flag_value]}'" : 'Disabled'}"
  puts ""
  puts "Found #{valid_node_ids.size} valid nodes"
  puts ""
  
  link_tables.each do |table|
    begin
      links = network.row_objects(table)
      link_count = 0
      links.each { link_count += 1 }
      next if link_count == 0
      
      puts "Processing #{table} (#{link_count} objects)..."
      puts "-" * 80
      
      links.each do |link|
        stats[:total_processed] += 1
        
        us_valid = valid_node_ids.include?(link.us_node_id)
        ds_valid = valid_node_ids.include?(link.ds_node_id)
        
        if !options[:process_all] && us_valid && ds_valid
          stats[:skipped] += 1
          next
        end
        
        link_updated = false
        
        if !us_valid
          link_updated = set_node_id(network, link, :upstream, options[:search_radius], valid_node_ids, stats, options, table, link_tables) || link_updated
        end
        
        if !ds_valid
          link_updated = set_node_id(network, link, :downstream, options[:search_radius], valid_node_ids, stats, options, table, link_tables) || link_updated
        end
        
        stats[:links_updated] += 1 if link_updated
      end
      
      puts ""
      
    rescue => e
      next if e.message.include?('invalid table name') || e.message.include?('no such table')
      raise
    end
  end
  
  network.transaction_commit
  puts "=" * 80
  puts "SUMMARY"
  puts "=" * 80
  puts "Total links processed:      #{stats[:total_processed]}"
  puts "Links updated:              #{stats[:links_updated]}"
  puts "  US/DS assignments (new):  #{stats[:assigned]}"
  puts "  US/DS changes (updated):  #{stats[:changed]}"
  puts "  Link suffixes changed:    #{stats[:suffix_changed]}" if stats[:suffix_changed] > 0
  puts "Endpoints not found:        #{stats[:not_found]}"
  puts "Links with no geometry:     #{stats[:no_geometry]}"
  puts "Links skipped (valid):      #{stats[:skipped]}" unless options[:process_all]
  if options[:set_flag] && !options[:flag_value].empty? && stats[:links_updated] > 0
    puts "Data flags applied:         us_node_id_flag / ds_node_id_flag / link_suffix_flag = '#{options[:flag_value]}'"
  end
  puts "=" * 80
  
  total_assignments = stats[:assigned] + stats[:changed]
  
  if stats[:links_updated] > 0
    msg = "Updated #{stats[:links_updated]} link(s)\n\n" +
          "Total US/DS assignments: #{total_assignments}"
    
    if options[:set_flag] && !options[:flag_value].empty?
      msg += "\n\nNode ID flag set: '#{options[:flag_value]}'"
    end
    
    msg += "\n\nSee Output window for details"
    
    WSApplication.message_box(msg, 'OK', 'Information', false)
  elsif stats[:total_processed] == 0
    WSApplication.message_box('No links found to process', 'OK', 'Information', false)
  else
    WSApplication.message_box(
      "No updates made\n\n" +
      "Check search radius or link geometry",
      'OK',
      '!',
      false
    )
  end
  
rescue => e
  begin
    network.transaction_rollback if network
  rescue
  end
  
  error_msg = "Error: #{e.message}\n\n#{e.backtrace.first(5).join("\n")}"
  WSApplication.message_box(error_msg, 'OK', 'Stop', false)
  return
end
