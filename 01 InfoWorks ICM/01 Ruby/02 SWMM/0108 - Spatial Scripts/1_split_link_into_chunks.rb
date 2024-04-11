require_relative 'spatial'

DEFAULT_CHUNK_SIZE = 10.0
size = DEFAULT_CHUNK_SIZE

# Prompt user for size
# size = WSApplication.input_box("Specify a chunk size", "Split Lines into Chunks", DEFAULT_CHUNK_SIZE.to_s)
# size = size.to_f

network = WSApplication.current_network()
network.transaction_begin

network.row_objects_selection('wn_pipe').each do |link|
  InnoSpatial.split_link_into_chunks(network, link, size)
end

network.transaction_commit
