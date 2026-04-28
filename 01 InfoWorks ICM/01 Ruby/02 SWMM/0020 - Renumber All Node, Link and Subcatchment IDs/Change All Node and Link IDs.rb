net = WSApplication.current_network
raise "No network is currently open." if net.nil?

confirm = WSApplication.prompt(
  'Rename all IDs? This will overwrite every node, link, and subcatchment ID in the network ' \
  '(N1/N2..., L1/L2..., S1/S2...). This action cannot be undone. Type YES to proceed.',
  [['Confirm', 'STRING', '']],
  false
)
return if confirm.nil? || confirm[0] != 'YES'

begin
  net.transaction_begin

  node_number = 1
  net.row_objects('_nodes').each do |node|
    node.node_id = "N#{node_number}"
    node.write
    node_number += 1
  end

  link_number = 1
  net.row_objects('_links').each do |link|
    link.id = "L#{link_number}"
    link.write
    link_number += 1
  end

  subcatchment_number = 1
  net.row_objects('_subcatchments').each do |sub|
    sub.id = "S#{subcatchment_number}"
    sub.write
    subcatchment_number += 1
  end

  net.transaction_commit

  puts "Node IDs renamed:         #{node_number - 1}"
  puts "Link IDs renamed:         #{link_number - 1}"
  puts "Subcatchment IDs renamed: #{subcatchment_number - 1}"

rescue => e
  net.transaction_rollback
  puts "Error: #{e.message}"
end
