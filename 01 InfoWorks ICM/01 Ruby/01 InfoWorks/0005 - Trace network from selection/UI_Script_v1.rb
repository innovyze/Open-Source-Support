# Get the current network
net = WSApplication.current_network

# Get the current selection of nodes
roc = net.row_object_collection_selection('_nodes')

# Initialize an empty array to hold the unprocessed links
unprocessedLinks = Array.new

# Iterate over each node in the selection
roc.each do |ro|
  # Iterate over each downstream link of the node
  ro.ds_links.each do |l|
    # If the link has not been seen (processed) before
    if !l._seen
      # Add the link to the unprocessedLinks array
      unprocessedLinks << l
      # Mark the link as seen
      l._seen=true
    end
  end

  # Enter a loop that continues until all links have been processed
  while unprocessedLinks.size>0
    # Remove the first link from unprocessedLinks
    working = unprocessedLinks.shift
    # Mark the link as selected
    working.selected=true
    # Get the downstream node of the link
    workingDSNode = working.ds_node
    # If the downstream node exists and has not been seen before
    if !workingDSNode.nil? && !workingDSNode._seen
      # Mark the node as selected
      workingDSNode.selected=true
      # Iterate over each downstream link of the node
      workingDSNode.ds_links.each do |l|
        # If the link has not been seen before
        if !l._seen
          # Add the link to unprocessedLinks
          unprocessedLinks << l
          # Mark the link as selected
          l.selected=true
          # Mark the link as seen
          l._seen=true
        end
      end
    end
  end
end