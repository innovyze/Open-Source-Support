# ============================================================================
# Query Set Import Module
# ============================================================================
#
# PURPOSE:
#   Creates ICM selection lists from InfoSewer query sets (FAC_TYPE=2)
#
# WHAT THIS MODULE DOES:
#   1. Reads InfoSewer query set definitions (QRYSET, QUERY, QSETDATA)
#   2. Evaluates queries against InfoSewer source data
#   3. Creates ICM selection lists with matching elements
#
# QUERY SYNTAX SUPPORTED:
#   - Simple conditions: TABLE->FIELD OPERATOR VALUE
#   - Operators: =, <>, <, >, <=, >=
#   - Logical operators: .AND., .OR.
#   - String, numeric, and date comparisons
#
# ============================================================================

require 'date'

# Parse a simple query condition (TABLE->FIELD OPERATOR VALUE)
def parse_query_condition(condition_str)
  condition_str = condition_str.strip
  
  # Remove outer parentheses if present
  if condition_str.start_with?('(') && condition_str.end_with?(')')
    condition_str = condition_str[1..-2].strip
  end
  
  # Match: TABLE->FIELD OPERATOR VALUE
  if condition_str =~ /^(\w+)->(\w+)\s*([<>=!]+)\s*(.+)$/
    table = $1.upcase
    field = $2.upcase
    operator = $3
    value = $4.strip
    
    # Clean up value (remove quotes, convert to appropriate type)
    is_string = false
    if value =~ /^'(.+)'$/
      value = $1.strip  # String value - remove quotes AND strip whitespace
      is_string = true
    elsif value =~ /^\d+$/
      value = value.to_i  # Integer
    elsif value =~ /^\d+\.\d+$/
      value = value.to_f  # Float
    end
    
    return {table: table, field: field, operator: operator, value: value, is_string: is_string}
  end
  
  return nil
end

# Evaluate a condition against a data row
def evaluate_query_condition(condition, row)
  return false if condition.nil? || row.nil?
  
  field_value = row[condition[:field]]
  return false if field_value.nil?
  
  # Convert field value to same type as comparison value
  if condition[:value].is_a?(Integer)
    field_value = field_value.to_i
  elsif condition[:value].is_a?(Float)
    field_value = field_value.to_f
  else
    field_value = field_value.to_s.strip
  end
  
  # For string comparisons with = or <>, use case-insensitive matching
  if condition[:is_string] && (condition[:operator] == '=' || condition[:operator] == '<>')
    comparison_value = condition[:value].to_s.strip.upcase
    field_value_upper = field_value.to_s.strip.upcase
    
    case condition[:operator]
    when '='
      return field_value_upper == comparison_value
    when '<>'
      return field_value_upper != comparison_value
    end
  end
  
  # Evaluate operator
  case condition[:operator]
  when '='
    return field_value == condition[:value]
  when '<>'
    return field_value != condition[:value]
  when '<'
    return field_value < condition[:value]
  when '>'
    return field_value > condition[:value]
  when '<='
    return field_value <= condition[:value]
  when '>='
    return field_value >= condition[:value]
  else
    return false
  end
end

# Evaluate a query and return matching IDs
def evaluate_infosewer_query(query, pipe_data, manhole_data, pump_data, wwell_data)
  query_string = query['QUERY']
  element_type = query['ELEMENT'].to_i
  
  return {ids: [], table: nil} if query_string.nil? || query_string.empty?
  
  # Determine primary table from element type
  primary_table = case element_type
  when 0 then 'MANHOLE'
  when 2 then 'PIPE'
  when 3 then 'PUMP'
  when 4 then 'WWELL'
  else nil
  end
  
  return {ids: [], table: primary_table} if primary_table.nil?
  
  # Get the appropriate dataset
  dataset = case primary_table
  when 'PIPE' then pipe_data
  when 'MANHOLE' then manhole_data
  when 'PUMP' then pump_data
  when 'WWELL' then wwell_data
  else return {ids: [], table: primary_table}
  end
  
  # Handle .OR. operator (simple implementation - split by .OR. first, then .AND. within each)
  if query_string.include?('.OR.')
    # Remove outer parentheses if present
    query_string = query_string[1..-2].strip if query_string.start_with?('(') && query_string.end_with?(')')
    
    # Split by .OR.
    or_parts = query_string.split('.OR.').map(&:strip)
    all_matching_ids = []
    
    or_parts.each do |or_part|
      # Each OR part might have .AND. conditions
      if or_part.include?('.AND.')
        and_parts = or_part.split('.AND.').map(&:strip)
        conditions = and_parts.map { |c| parse_query_condition(c) }.compact.select { |c| c[:table] == primary_table }
        
        # Evaluate AND conditions
        dataset.each do |id, row|
          if conditions.all? { |cond| evaluate_query_condition(cond, row) }
            all_matching_ids << id
          end
        end
      else
        # Single condition in this OR part
        condition = parse_query_condition(or_part)
        next if condition.nil? || condition[:table] != primary_table
        
        dataset.each do |id, row|
          if evaluate_query_condition(condition, row)
            all_matching_ids << id
          end
        end
      end
    end
    
    return {ids: all_matching_ids.uniq, table: primary_table}
  end
  
  # Handle .AND. operator
  if query_string.include?('.AND.')
    conditions_str = query_string.split('.AND.').map(&:strip)
    conditions = conditions_str.map { |c| parse_query_condition(c) }.compact.select { |c| c[:table] == primary_table }
    
    # Filter dataset - all conditions must match
    matching_ids = []
    dataset.each do |id, row|
      if conditions.all? { |cond| evaluate_query_condition(cond, row) }
        matching_ids << id
      end
    end
    
    return {ids: matching_ids, table: primary_table}
  end
  
  # Single condition
  condition = parse_query_condition(query_string)
  return {ids: [], table: primary_table} if condition.nil? || condition[:table] != primary_table
  
  # Filter dataset
  matching_ids = []
  dataset.each do |id, row|
    if evaluate_query_condition(condition, row)
      matching_ids << id
    end
  end
  
  return {ids: matching_ids, table: primary_table}
end

# Import query sets and create selection lists
def import_query_sets(network, iedb_path, parent_object)
  puts ""
  puts "=" * 70
  puts "Importing Query Set Selection Lists"
  puts "=" * 70
  puts ""
  
  # Read query set data
  qryset_path = File.join(iedb_path, 'QRYSET.DBF')
  unless File.exist?(qryset_path)
    puts "[SKIP] No QRYSET.DBF found - no query sets to import"
    return
  end
  
  qrysets = read_dbf(qryset_path, false, make_id_safe: false)
  queries = read_dbf(File.join(iedb_path, 'QUERY.DBF'), false, make_id_safe: false)
  qsetdata = read_dbf(File.join(iedb_path, 'QSETDATA.DBF'), false, make_id_safe: false)
  
  if qrysets.length == 0
    puts "[SKIP] No query sets found in this model"
    return
  end
  
  puts "Found #{qrysets.length} query set(s), #{queries.length} query/queries"
  
  # Read InfoSewer source data (for query evaluation)
  pipe_data = read_dbf(File.join(iedb_path, 'PIPE.DBF'), true, make_id_safe: true)
  manhole_data = read_dbf(File.join(iedb_path, 'MANHOLE.DBF'), true, make_id_safe: true)
  pump_data = read_dbf(File.join(iedb_path, 'PUMP.DBF'), true, make_id_safe: true)
  wwell_data = read_dbf(File.join(iedb_path, 'WWELL.DBF'), true, make_id_safe: true)
  
  # Build link ID mapping (InfoSewer asset ID -> ICM us_node.suffix)
  link_id_map = {}
  network.row_objects('hw_conduit').each do |link|
    link_suffix = link.link_suffix
    us_node_id = link.us_node_id
    icm_link_id = "#{us_node_id}.#{link_suffix}"
    link_id_map[link.asset_id] = icm_link_id if link.asset_id
  end
  network.row_objects('hw_pump').each do |link|
    link_suffix = link.link_suffix
    us_node_id = link.us_node_id
    icm_link_id = "#{us_node_id}.#{link_suffix}"
    link_id_map[link.asset_id] = icm_link_id if link.asset_id
  end
  
  puts ""
  
  # Process each query set
  created_count = 0
  skipped_count = 0
  
  qrysets.each do |qs|
    qs_id = qs['ID']
    next if qs_id.nil?
    
    # Find all queries in this set
    query_ids = qsetdata.select { |qd| qd['ID'] == qs_id }.map { |qd| qd['QUERY_ID'] }
    
    if query_ids.empty?
      puts "[SKIP] #{qs_id}: No queries defined"
      skipped_count += 1
      next
    end
    
    # Evaluate each query and collect matching IDs
    all_node_ids = []
    all_link_ids = []
    
    query_ids.each do |query_id|
      query_def = queries.find { |q| q['ID'] == query_id }
      next if query_def.nil?
      
      result = evaluate_infosewer_query(query_def, pipe_data, manhole_data, pump_data, wwell_data)
      matching_ids = result[:ids]
      table = result[:table]
      
      if table == 'MANHOLE' || table == 'WWELL'
        all_node_ids.concat(matching_ids)
      elsif table == 'PIPE' || table == 'PUMP'
        # Map InfoSewer asset IDs to ICM link IDs
        icm_link_ids = matching_ids.map { |id| link_id_map[id] }.compact
        all_link_ids.concat(icm_link_ids)
      end
    end
    
    # Remove duplicates
    all_node_ids.uniq!
    all_link_ids.uniq!
    
    # Create selection list
    if all_node_ids.length > 0 || all_link_ids.length > 0
      list_name = "QS_#{qs_id}"
      
      # Clear current selection
      network.clear_selection
      
      # Build lookups
      id_to_node = {}
      network.row_objects('_nodes').each { |node| id_to_node[node.node_id] = node if node.node_id }
      
      id_to_link = {}
      network.row_objects('_links').each { |link| id_to_link[link.id] = link }
      
      id_to_subcatchment = {}
      network.row_objects('_subcatchments').each { |sub| id_to_subcatchment[sub.subcatchment_id] = sub if sub.subcatchment_id }
      
      # Select nodes
      nodes_selected = 0
      all_node_ids.each do |node_id|
        if node = id_to_node[node_id]
          node.selected = true
          node.write
          nodes_selected += 1
        end
        
        # Also select subcatchment if it exists
        if sub = id_to_subcatchment[node_id]
          sub.selected = true
          sub.write
        end
      end
      
      # Select links (using compound IDs)
      links_selected = 0
      all_link_ids.each do |link_id|
        if link = id_to_link[link_id]
          link.selected = true
          link.write
          links_selected += 1
        end
      end
      
      # Create selection list
      begin
        selection_list = parent_object.new_model_object('Selection List', list_name)
        network.save_selection(selection_list)
        
        puts "[OK] #{list_name} (#{nodes_selected} nodes, #{links_selected} links)"
        created_count += 1
      rescue => err
        if err.message.include?("already") || err.message.include?("exist")
          puts "[SKIP] #{list_name}: Already exists"
          skipped_count += 1
        else
          puts "[ERROR] #{list_name}: #{err.message}"
          skipped_count += 1
        end
      end
      
      # Clear selection
      network.clear_selection
    else
      puts "[SKIP] #{qs_id}: No matching elements"
      skipped_count += 1
    end
  end
  
  puts ""
  puts "Query Set import complete: #{created_count} created, #{skipped_count} skipped"
  puts ""
end

