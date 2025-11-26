# Get the nodes of the model
#
# @param manhole_data [Array] Array of the rows from manhole.dbf
# @param wwell_data [Array] Array of the rows from wwell.dbf
# @param node_data [Hash] Hash of the rows from node.dbf, which contains the geometry
# @return [Hash] Hash of the nodes in the model, ID:{:type, :x, :y, :z}
#
# Note: Imports ALL nodes from MANHOLE.DBF/WWELL.DBF to ensure complete BASE network.
#       Does NOT filter by ANODE.DBF (which contains scenario-specific active elements).

def get_model_nodes(manhole_data, wwell_data, node_data)
  nodes = Hash.new
  
  # Iterate through each row in the manhole data
  manhole_data.each do |row|
    id = row['ID']
    
    # Determine the type of node based on the 'TYPE' field
    case row['TYPE']
    when 2, '2'  # Outfall
      nodes[id] = {type: 'outlet'}
    else         # Standard manhole (InfoSewer only has manholes and outfalls in MANHOLE.DBF)
      nodes[id] = {type: 'manhole'}
    end
  end
  
  # Iterate wwell.dbf to identify wetwells
  wwell_data.each do |row|
    id = row['ID']
    nodes[id] = {type: 'wetwell'}
  end
  
  # Append geometry from node.dbf
  missing_geometry = []
  nodes_to_delete = []
  
  nodes.each do |id, hash|
    geo = node_data[id]
    if geo.nil?
      missing_geometry << id
      nodes_to_delete << id
      next
    end
    
    hash[:x] = geo['X']
    hash[:y] = geo['Y']
    hash[:z] = geo['Z']
  end
  
  # Remove nodes without geometry
  nodes_to_delete.each { |id| nodes.delete(id) }
  
  # Report missing geometry
  if missing_geometry.length > 0
    puts ""
    puts "DATA QUALITY WARNING"
    puts "#{missing_geometry.length} node(s) have no geometry (X/Y/Z) in NODE.DBF and will be SKIPPED:"
    missing_geometry.first(10).each { |id| puts "  - #{id}" }
    puts "  ... and #{missing_geometry.length - 10} more" if missing_geometry.length > 10
    puts ""
  end
  
  return nodes
end

# Get the links of the model, including their connectivity to nodes
#
# Find a node ID with case-insensitive matching
# Returns the actual node ID from the nodes hash, or nil if not found
#
# @param node_id [String] The node ID to search for
# @param nodes [Hash] Hash of nodes, keyed by node ID
# @return [String, nil] The actual node ID (with correct case), or nil

def find_node_case_insensitive(node_id, nodes)
  # Try exact match first (fastest)
  return node_id if nodes.has_key?(node_id)
  
  # Try case-insensitive match
  upper_id = node_id.to_s.upcase
  actual_id = nodes.keys.find { |key| key.to_s.upcase == upper_id }
  
  # Track case correction if found
  if actual_id && actual_id != node_id
    $case_corrections ||= []
    $case_corrections << {original: node_id, corrected: actual_id}
  end
  
  return actual_id
end

# @param vertex_data [Array] Array of the rows from vertex.dbf
# @param link_data [Hash] Hash of the rows from link.dbf (connectivity)
# @param pipe_data [Array] Array of the rows from pipe.dbf
# @param pump_data [Array] Array of the rows from pump.dbf
# @param nodes [Hash] Hash of nodes for case-insensitive lookup
# @return [Hash] Hash of the links in the model, ID:{:type, :from, :to, :bends}
#
# Note: Imports ALL links from PIPE.DBF/PUMP.DBF to ensure complete BASE network.
#       Does NOT filter by ALINK.DBF (which contains scenario-specific active elements).

def get_model_links(vertex_data, link_data, pipe_data, pump_data, nodes)
  links = Hash.new
  
  # Build connectivity lookup from pipe and pump data
  # InfoSewer stores connectivity in PIPE.DBF and PUMP.DBF, not LINK.DBF
  connectivity_data = {}
  
  # Iterate pipe.dbf to identify forcemains and pipes AND get connectivity
  pipe_data.each do |row|
    id = row['ID']
    
    case row['TYPE']
    when 1, '1'
      links[id] = {type: 'forcemain'}
    else
      links[id] = {type: 'pipe'}
    end
    
    # Store connectivity from PIPE.DBF fields (UPMANHOLE/DNMANHOLE)
    connectivity_data[id] = {
      'FROM' => row['UPMANHOLE'],
      'TO' => row['DNMANHOLE']
    }
  end
  
  # Iterate pump.dbf to identify pumps AND get connectivity
  pump_data.each do |row|
    id = row['ID']
    links[id] = {type: 'pump'}
    
    # Store connectivity from PUMP.DBF fields (FROM/TO or UPMANHOLE/DNMANHOLE)
    connectivity_data[id] = {
      'FROM' => row['FROM'] || row['UPMANHOLE'],
      'TO' => row['TO'] || row['DNMANHOLE']
    }
  end
  
  # Use LINK.DBF as fallback for connectivity if PIPE/PUMP don't have it
  # (Some models may have connectivity only in LINK.DBF)
  links.keys.each do |id|
    if connectivity_data[id].nil? || connectivity_data[id]['FROM'].nil? || connectivity_data[id]['TO'].nil?
      if link_data && link_data[id]
        connectivity_data[id] = {
          'FROM' => link_data[id]['FROM'],
          'TO' => link_data[id]['TO']
        }
      end
    end
  end
  
  # Sort vertex rows by link ID
  verts = vertex_data.group_by { |row| row['ID'] }
  
  # Track links with missing vertex data and invalid connectivity
  missing_vertex_links = []
  missing_connectivity = []
  invalid_connectivity = []
  links_to_delete = []
  
  # Append geometry from vertex.dbf and connectivity
  links.each do |id, hash|
    connectivity = connectivity_data[id]
    
    # Check if connectivity data exists
    if connectivity.nil?
      missing_connectivity << id
      links_to_delete << id
      next
    end
    
    bends = make_bends_array(verts[id])
    missing_vertex_links << id if bends.nil?
    
    # Sanitize and resolve FROM/TO node IDs
    # 1. Apply string sanitization (dots → underscores)
    # 2. Apply case-insensitive lookup to match actual node IDs
    from_sanitized = make_string_filesafe(connectivity['FROM'])
    to_sanitized = make_string_filesafe(connectivity['TO'])
    
    from_node = find_node_case_insensitive(from_sanitized, nodes) || from_sanitized
    to_node = find_node_case_insensitive(to_sanitized, nodes) || to_sanitized
    
    # Check if both nodes exist (might have been removed due to missing geometry)
    unless nodes.key?(from_node) && nodes.key?(to_node)
      invalid_connectivity << id
      links_to_delete << id
      next
    end
    
    hash[:from] = from_node
    hash[:to] = to_node
    hash[:bends] = bends unless bends.nil?
  end
  
  # Remove links with invalid connectivity
  links_to_delete.each { |id| links.delete(id) }
  
  # Report missing connectivity
  if missing_connectivity.length > 0
    puts ""
    puts "DATA QUALITY WARNING"
    puts "#{missing_connectivity.length} link(s) have no connectivity data in LINK.DBF and will be SKIPPED:"
    missing_connectivity.first(10).each { |id| puts "  - #{id}" }
    puts "  ... and #{missing_connectivity.length - 10} more" if missing_connectivity.length > 10
    puts ""
  end
  
  # Report invalid connectivity (references non-existent nodes)
  if invalid_connectivity.length > 0
    puts ""
    puts "DATA QUALITY WARNING"
    puts "#{invalid_connectivity.length} link(s) reference nodes that don't exist (likely missing geometry) and will be SKIPPED:"
    invalid_connectivity.first(10).each { |id| puts "  - #{id}" }
    puts "  ... and #{invalid_connectivity.length - 10} more" if invalid_connectivity.length > 10
    puts ""
  end
  
  # Print consolidated warning for missing vertices
  if missing_vertex_links.any?
    puts ""
    puts "Note: #{missing_vertex_links.length} link(s) missing vertex data (will import as straight lines):"
    missing_vertex_links.first(10).each { |id| puts "  - #{id}" }
    puts "  ... and #{missing_vertex_links.length - 10} more" if missing_vertex_links.length > 10
    puts ""
  end
  
  return links
end

# Create an ICM-style X, Y, X, Y bends array from an array of verts (from vertex.dbf)
#
# @param verts [Array] An array of rows from vertex.dbf, filtered by link ID
# @return [Array] Array of [X, Y, X, Y] etc, or nil if insufficient data

def make_bends_array(verts)
  return nil if verts.nil? || verts.size < 2
  
  # Sort the verts by the SEQ column (treat as integer)
  sort = verts.sort_by { |row| row['SEQ'].to_i }
  
  # Create the bends array
  bends = Array.new
  sort.each do |row|
    bends << row['X']
    bends << row['Y']
  end
  
  return bends
end

# Validate connectivity between nodes and links
#
# @param nodes [Hash] Hash of nodes
# @param links [Hash] Hash of links
# @return [Boolean] true if validation passes

def validate_connectivity(nodes, links)
  raise 'Connectivity validation failed - no nodes found' if nodes.empty?
  raise 'Connectivity validation failed - no links found' if links.empty?
  
  # Check that all links have valid US and DS nodes
  # Remove invalid links rather than failing the entire import
  invalid_links = []
  links.each do |id, data|
    unless nodes.has_key?(data[:from]) && nodes.has_key?(data[:to])
      invalid_links << id
    end
  end
  
  if invalid_links.any?
    puts ""
    puts "="*70
    puts "DATA QUALITY WARNING"
    puts "="*70
    puts "#{invalid_links.length} link(s) have invalid connectivity and will be REMOVED from import:"
    puts ""
    invalid_links.first(10).each { |id| puts "  - #{id}" }
    puts "  ... and #{invalid_links.length - 10} more" if invalid_links.length > 10
    puts ""
    puts "Reason: These links reference upstream or downstream nodes that do not"
    puts "        exist in the InfoSewer model. They cannot be imported to ICM."
    puts ""
    puts "Action: Links removed from import. Check InfoSewer model if these are"
    puts "        legitimate links that need missing node data added."
    puts ""
    puts "Continuing with #{links.length - invalid_links.length} valid links..."
    puts "="*70
    puts ""
    
    # Remove invalid links from the hash
    invalid_links.each { |id| links.delete(id) }
  end
  
  return true
end

# Create a new node in a network
#
# @param network [WSOpenNetwork] the network object
# @param id [String] node ID
# @param table [String] ICM table name (e.g. 'hw_node')
# @param x [Float] X coordinate
# @param y [Float] Y coordinate
# @param z [Float] Z coordinate (ground level)
# @param flag [String] flag to set on imported fields
# @return [WSRowObject] the created node object

def new_node(network, id, table, x, y, z, flag)
  begin
    node = network.new_row_object(table)    
    node.id = id    
    set_field_on_object(node, 'asset_id', id, flag)    
    set_field_on_object(node, 'x', x, flag)    
    set_field_on_object(node, 'y', y, flag)    
    set_field_on_object(node, 'ground_level', z, flag)
    return node    
  rescue => err
    puts "ERROR: Failed to create Node ID #{id}"    
    raise err
  end
end

# Create a new subcatchment in a network
#
# @param network [WSOpenNetwork] the network object
# @param id [String] subcatchment ID
# @param x [Float] X coordinate
# @param y [Float] Y coordinate
# @param flag [String] flag to set on imported fields
# @return [WSRowObject] the created subcatchment object

def new_subcatchment(network, id, x, y, flag)
  subcatchment = network.new_row_object('hw_subcatchment')
  subcatchment.id = id
  set_field_on_object(subcatchment, 'node_id', id, flag)
  set_field_on_object(subcatchment, 'x', x, flag)
  set_field_on_object(subcatchment, 'y', y, flag)
  return subcatchment
end

# Create a new link in a network
#
# @param network [WSOpenNetwork] the network object
# @param id [String] link asset_id
# @param table [String] ICM table name (e.g. 'hw_conduit', 'hw_pump')
# @param us_node [String] upstream node ID
# @param ds_node [String] downstream node ID
# @param bends [Array] array of X,Y coordinates for bends
# @param flag [String] flag to set on imported fields
# @return [WSRowObject] the created link object

def new_link(network, id, table, us_node, ds_node, bends, flag)
  begin
    link = network.new_row_object(table)
    set_field_on_object(link, 'asset_id', id, flag, overwrite: true)
    set_field_on_object(link, 'us_node_id', us_node, flag, overwrite: true)
    set_field_on_object(link, 'ds_node_id', ds_node, flag, overwrite: true)
    set_field_on_object(link, 'point_array', bends, overwrite: true) unless bends.nil?
    
    # Try to write the link - if another link has the same US/DS nodes, try different suffixes
    (1..6).each do |i|
      begin
        set_field_on_object(link, 'link_suffix', i, overwrite: true)
        link.write
        break
      rescue => err
        raise err if i == 6  # Fail on last attempt
      end
    end
    
    return link
  rescue => err
    puts "ERROR: Failed to create Link ID #{id}"
    raise err
  end
end

# Set a field value on an ICM object
#
# @param object [WSRowObject] the object to modify
# @param field [String] field name
# @param value [Object] value to set
# @param flag [String, nil] optional flag text (not used, kept for compatibility)
# @param overwrite [Boolean] whether to overwrite existing values

def set_field_on_object(object, field, value, flag = nil, overwrite: false)
  return if value.nil?
  
  begin
    if !object[field].nil? && !overwrite
      return  # Don't overwrite existing value
    end
    
    object[field] = value
  rescue => err
    # Field probably doesn't exist, which is okay
    return
  end
end

# Apply field mappings from YAML to an ICM object
#
# @param object [WSRowObject] the object to modify
# @param id [String] the object ID (for looking up data in InfoSewer files)
# @param fields [Hash] field mapping from YAML
# @param config [Hash] configuration hash (unused but kept for compatibility)

def apply_fields_to_object(object, id, fields, config)
  return if object.nil? || id.nil? || fields.nil?
  
  # Set default values for the object
  # Defaults should ALWAYS be applied to override ICM defaults
  if fields.has_key?('defaults')
    fields['defaults'].each do |field, value|
      set_field_on_object(object, field, value, nil, overwrite: true)
    end
  end
  
  # For each source table under 'import', import the fields from that data file
  if fields.has_key?('import')
    fields['import'].each do |table_name, field_map|
      data = get_csv(table_name)
      row = data[id]
      
      if row.nil?
        # This is okay - not all objects have data in all tables
        next
      end
      
      field_map.each do |icm_field, source_field|
        # Check if source_field is a column in the data
        if row.has_key?(source_field)
          # Import from data field
          value = row[source_field]
        else
          # Use as literal value (for setting fixed strings like 'Manhole', 'WetWell')
          value = source_field
        end
        set_field_on_object(object, icm_field, value, nil, overwrite: true)  
      end
    end
  end
  
  object.write
end

# Check if a network is empty (has no nodes, subcatchments, or links)
#
# @param network [WSOpenNetwork] the network to check
# @return [Boolean] true if the network is empty

def is_network_empty?(network)
  count = 0
  types = ['_nodes', '_subcatchments', '_links']
  types.each { |type| count += network.row_objects(type).size }
  return count == 0
end

# Delete all nodes, subcatchments, and links in a network
# Assumes a transaction is already active
#
# @param network [WSOpenNetwork] the network to clear

def clear_network(network)
  types = ['_nodes', '_subcatchments', '_links']
  types.each do |type|
    network.row_objects(type).each { |object| object.delete }
  end
end

