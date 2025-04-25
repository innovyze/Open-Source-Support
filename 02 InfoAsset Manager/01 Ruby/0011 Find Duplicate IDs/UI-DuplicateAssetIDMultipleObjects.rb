## Identify objects which have a duplicated Asset ID accross multiple object tables

net = WSApplication.current_network

objects = []
asset_count = Hash.new(0)

# Collecting IDs, asset_ids, and table names
net.row_objects('cams_manhole').each do |ro|
  unless ro.asset_id.empty?
    objects << [ro.node_id, ro.asset_id, 'cams_manhole']
    asset_count[ro.asset_id] += 1
  end
end

net.row_objects('cams_outlet').each do |ro|
  unless ro.asset_id.empty?
    objects << [ro.node_id, ro.asset_id, 'cams_outlet']
    asset_count[ro.asset_id] += 1
  end
end

net.row_objects('cams_pipe').each do |ro|
  unless ro.asset_id.empty?
    objects << [ro.us_node_id + '.' + ro.ds_node_id + '.' + ro.link_suffix, ro.asset_id, 'cams_pipe']
    asset_count[ro.asset_id] += 1
  end
end

net.row_objects('cams_connection_pipe').each do |ro|
  unless ro.asset_id.empty?
    objects << [ro.id, ro.asset_id, 'cams_connection_pipe']
    asset_count[ro.asset_id] += 1
  end
end


# Filtering objects with asset_id count greater than 1
filtered_objects = objects.select { |obj| asset_count[obj[1]] > 1 }

# Sorting objects by asset_id
sorted_objects = filtered_objects.sort_by { |obj| obj[1] }

# Printing each object's details with headers for each new asset_id
current_asset_id = nil
sorted_objects.each do |obj|
  if obj[1] != current_asset_id
    current_asset_id = obj[1]
    puts "Asset ID: #{current_asset_id}"
  end
  puts "  #{obj[2]}: #{obj[0]}"
end