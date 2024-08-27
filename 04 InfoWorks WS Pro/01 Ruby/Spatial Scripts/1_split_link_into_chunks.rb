require_relative 'spatial'

# Prompt user for options
options = [
  ['Distance between segments', 'NUMBER', 10.0, 2],
  ['Normalize segments (avoids small tails)', 'BOOLEAN', true],
  ['Update customer allocation', 'BOOLEAN', true],
  ['Flag for updated customer points', 'STRING', 'SPLT']
]
response = WSApplication.prompt('Split Link Options', options, true)
chunk_size = response[0]
normalize = response[1]
fix_customer_allocation = response[2]
flag_customer_points = response[3]

network = WSApplication.current_network()
network.transaction_begin

links_split = {}
network.row_objects_selection('wn_pipe').each do |link|
  original_id = link.id
  new_links = AdskSpatial.split_link_into_chunks(network, link, chunk_size, normalize)
  links_split[original_id] = new_links
end

AdskSpatial.cleanup_customer_allocation(network, links_split, flag_customer_points) if fix_customer_allocation

network.transaction_commit
