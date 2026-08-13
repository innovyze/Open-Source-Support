# Storage and pond flood type correction (InfoWorks hw_* UI script)
#
# Adjusts ground level or the last storage-array level so the engine-derived
# flood type matches the target (stored, lost, or sealed).
#
# Pair with UI_audit_script.rb to identify nodes first.
#
# Run from the ICM UI. Select storage nodes or ponds on the GeoPlan before running.

DEFAULT_SEPARATION_M = 0.01
STORAGE_NODE_TYPES = %w[storage pond].freeze
TARGET_TYPES = %w[stored lost sealed].freeze
ADJUST_FIELDS = ['Ground level', 'Top storage-array level'].freeze

def last_storage_level(storage_array)
  return nil if storage_array.nil? || storage_array.length.zero?

  storage_array[storage_array.length - 1]['level']
end

def expected_flood_type(ground_level, top_level)
  return 'unknown' if ground_level.nil? || top_level.nil?

  delta = top_level.to_f - ground_level.to_f
  if delta.positive?
    'stored'
  elsif delta.zero?
    'lost'
  else
    'sealed'
  end
end

def storage_node?(node)
  node_type = node.node_type
  return false if node_type.nil?

  STORAGE_NODE_TYPES.include?(node_type.to_s.downcase)
end

def target_levels(current_ground, current_top, target_type, adjust_field, separation_m)
  ground = current_ground.to_f
  top = current_top.to_f
  sep = separation_m.to_f
  sep = DEFAULT_SEPARATION_M if sep <= 0.0

  case target_type
  when 'stored'
    if adjust_field == 'Ground level'
      [top - sep, top]
    else
      [ground, ground + sep]
    end
  when 'lost'
    if adjust_field == 'Ground level'
      [top, top]
    else
      [ground, ground]
    end
  when 'sealed'
    if adjust_field == 'Ground level'
      [top + sep, top]
    else
      [ground, ground - sep]
    end
  else
    [ground, top]
  end
end

def set_last_storage_level(storage_array, new_level)
  return false if storage_array.nil? || storage_array.length.zero?

  storage_array[storage_array.length - 1]['level'] = new_level
  storage_array.write
  true
end

catch(:stop) do
  net = WSApplication.current_network
  unless net
    WSApplication.message_box('No network is open. Open a network and run again.', 'OK', 'Stop', false)
    throw :stop
  end

  selected = net.row_objects_selection('hw_node')
  scope_nodes = selected.select { |node| storage_node?(node) }

  if scope_nodes.empty?
    WSApplication.message_box(
      'Select one or more storage or pond nodes on the GeoPlan, then run this script.',
      'OK', 'Stop', false
    )
    throw :stop
  end

  prompt_layout = [
    ['Target flood type', 'STRING', 'stored', nil, 'LIST', TARGET_TYPES],
    ['Adjust field', 'STRING', 'Top storage-array level', nil, 'LIST', ADJUST_FIELDS],
    ['Stored/sealed separation margin (m)', 'NUMBER', DEFAULT_SEPARATION_M]
  ]

  begin
    user_input = WSApplication.prompt('Storage and Pond Flood Type Correction', prompt_layout, false)
  rescue StandardError => e
    puts "Prompt cancelled: #{e.message}"
    throw :stop
  end

  throw :stop unless user_input

  target_type = user_input[0].to_s.downcase
  adjust_field = user_input[1]
  separation_m = user_input[2]
  separation_m = DEFAULT_SEPARATION_M if separation_m.nil? || separation_m <= 0.0

  unless TARGET_TYPES.include?(target_type)
    WSApplication.message_box("Invalid target flood type: #{target_type}", 'OK', 'Stop', false)
    throw :stop
  end

  plan = []
  skipped = []

  scope_nodes.each do |node|
    ground = node.ground_level
    storage_array = node.storage_array
    top = last_storage_level(storage_array)

    if ground.nil?
      skipped << { node_id: node.id, reason: 'Ground level is blank' }
      next
    end
    if top.nil?
      skipped << { node_id: node.id, reason: 'Storage array missing or last level is blank' }
      next
    end

    current_type = expected_flood_type(ground, top)
    next if current_type == target_type

    new_ground, new_top = target_levels(ground, top, target_type, adjust_field, separation_m)

    change = {
      node_id: node.id,
      current_type: current_type,
      target_type: target_type,
      old_ground: ground,
      old_top: top,
      new_ground: new_ground,
      new_top: new_top,
      adjust_field: adjust_field,
      node: node,
      storage_array: storage_array
    }
    plan << change
  end

  if plan.empty? && skipped.empty?
    WSApplication.message_box(
      "All #{scope_nodes.length} selected nodes already match flood type \"#{target_type}\".",
      'OK', 'Information', false
    )
    throw :stop
  end

  preview_lines = []
  preview_lines << "Target: #{target_type} (adjust #{adjust_field})"
  preview_lines << "Nodes to update: #{plan.length}"
  preview_lines << "Nodes skipped: #{skipped.length}"
  preview_lines << ''
  plan.first(8).each do |c|
    preview_lines << "#{c[:node_id]}: #{c[:current_type]} -> #{c[:target_type]} | GL #{c[:old_ground]} -> #{c[:new_ground]} | top #{c[:old_top]} -> #{c[:new_top]}"
  end
  preview_lines << '...' if plan.length > 8
  skipped.first(5).each do |s|
    preview_lines << "Skip #{s[:node_id]}: #{s[:reason]}"
  end

  puts preview_lines.join("\n")

  if plan.empty?
    WSApplication.message_box(
      "No nodes could be updated.\n\n#{preview_lines.join("\n")}",
      'OK', 'Information', false
    )
    throw :stop
  end

  confirm = WSApplication.message_box(
    "#{preview_lines.join("\n")}\n\nApply these changes?",
    'YesNo', '?', true
  )
  throw :stop unless confirm == 'Yes'

  updated = 0
  errors = []

  net.transaction_begin
  begin
    plan.each do |change|
      node = change[:node]
      if change[:adjust_field] == 'Ground level'
        node.ground_level = change[:new_ground]
      else
        unless set_last_storage_level(change[:storage_array], change[:new_top])
          errors << "#{change[:node_id]}: could not update storage array"
          next
        end
      end
      node.write
      updated += 1
    rescue StandardError => e
      errors << "#{change[:node_id]}: #{e.message}"
    end

    if updated.zero?
      net.transaction_rollback
    else
      net.transaction_commit
    end
  rescue StandardError => e
    net.transaction_rollback
    WSApplication.message_box("Update failed: #{e.message}", 'OK', 'Stop', false)
    throw :stop
  end

  summary = []
  summary << "Updated #{updated} of #{plan.length} planned nodes."
  summary << "#{skipped.length} nodes were skipped before planning." if skipped.any?
  errors.first(10).each { |msg| summary << msg }
  summary << '...' if errors.length > 10

  puts summary.join("\n")
  WSApplication.message_box(summary.join("\n"), 'OK', 'Information', false)
end
