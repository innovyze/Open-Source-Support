# Some parts of this code were adapted from the Turf.js library
# https://turfjs.org/
# https://github.com/Turfjs/turf

module AdskSpatial
  extend self

  # Splits all links around a node.
  #
  # @param network [WSOpenNetwork]
  # @param node [WSNode]
  # @param distance [Numeric] actual distance from the node to split
  def split_links_around_node(network, node, distance)
    node.us_links.each { |link| split_link_at_distance(network, link, link_length(link) - distance) }
    node.ds_links.each { |link| split_link_at_distance(network, link, distance) }
  end

  # Splits a link into chunks / segments. Optionally normalizes the size so that they are evenly spaced out, rather
  # than leaving an arbitrary short section at the end.
  #
  # @param network [WSOpenNetwork]
  # @param link [WSLink]
  # @chunk_size [Numeric] length of each chunk
  # @param normalize [Boolean] whether to normalize the chunk sizes (avoid annoying small lines at the ends)
  def split_link_into_chunks(network, link, chunk_size, normalize = true)
    length = link_length(link)

    if chunk_size >= length
      puts format("Cannot split link %s of length %0.2fm into chunks of size %0.2fm", link.id, length, chunk_size)
      return
    end

    # Get segment count & chunk size, based on whether we're normalising
    segments = (length / chunk_size).floor
    if normalize      
      chunk_size_use = (length / segments)
      segments -= 1
    else
      chunk_size_use = chunk_size
    end

    # Split the link, filling the new links array, change our current link to the post-split from the last operation
    new_links = [link]
    segments.times do |i|
      us, ds = split_link_at_distance(network, new_links.last, chunk_size_use, i + 1)
      new_links << ds      
    end

    return new_links
  end

  # Tidies up customer allocation from splitting a link - simply allocates to the first/last pipe in the split for now
  # 
  # @param network [WSOpenNetwork]
  # @param split_links [Hash<String, Array<WSLink>>] hash of the split link's original ID, and an array of the new links (WSLink)
  #   e.g. {"30493.20302.1" => [WSlink, WSlink, WSlink]}
  def cleanup_customer_allocation(network, split_links, flag = nil)
    network.row_objects('wn_address_point').each do |customer|
      split = split_links[customer['allocated_pipe_id']]
      if split
        customer['allocated_pipe_id'] = customer['demand_at_us_node'] ? split.first.id : split.last.id
        customer['demand_at_us_node_flag'] = flag
        customer.write
      end
    end
  end

  # Splits a link at the specified distance. A new node is generated using the link asset_id e.g. Badger_1
  #
  # @param network [WSOpenNetwork]
  # @param link [WSLink] the link to split, this becomes the post link (i.e. after the split)
  # @param distance [Numeric] actual distance along the link to make the split
  # @param node_i [Integer] optional index for the new node name, useful when chaining splits
  def split_link_at_distance(network, link, distance, node_i = 1)
    # Validate we're not trying to do something daft
    link_length = link_length(link)
    if distance >= link_length
      puts format("Link %s has length of %0.2f, cannot split with distance of %0.2f", link.id, link_length, distance)
      return nil, nil
    end

    index = 0 # Current vertex index, so we know where we split
    split_node = nil # The new node at the split
    travelled = 0 # Distance travelled so far as we iterate the link segments

    iterate_link_segments(link) do |seg|
      # Calculate the length of this segment and check if this is the segment we need to split at
      length = distance(*seg)

      if travelled + length > distance
        # Split at this segment
        percent = (distance - travelled) / length # How far along this segment are we?

        # Create the node
        split_node = network.new_row_object('wn_node')
        split_node.id = format("%s_%i", link['asset_id'], node_i)
        split_node['x'] = lerp(seg[0], seg[2], percent)
        split_node['y'] = lerp(seg[1], seg[3], percent)
        split_node['z'] = lerp(link.us_node['z'], link.ds_node['z'], distance / link_length) # Lerp between US and DS elevation
        split_node['ground_level'] = lerp(link.us_node['ground_level'], link.ds_node['ground_level'], distance / link_length) # Lerp between US and DS elevation
        split_node.write
        break
      else
        # Haven't reached distance yet
        travelled += length
        index += 1
      end
    end

    # Create a new bends array for the pre and post links
    pre_bends, post_bends = [], []
    link['bends'].each_slice(2).with_index do |xy, i|
      if i > index
        post_bends = post_bends + xy
      elsif i == index
        split_xy = [split_node['x'], split_node['y']]
        pre_bends = pre_bends + xy + split_xy
        post_bends = post_bends + split_xy
      else
        pre_bends = pre_bends + xy
      end
    end

    # Create a new link, copy all fields across
    new_link = network.new_row_object('wn_pipe')
    link.table_info.fields.each do |field|
      new_link[field.name] = link[field.name]
    end

    # The existing link is US
    link['bends'] = pre_bends
    link['ds_node_id'] = split_node.id
    link.write

    # The new link is DS
    new_link['bends'] = post_bends
    new_link['us_node_id'] = split_node.id
    new_link.write

    # Return the US, DS
    return link, new_link
  end

  # Calculate the euclidean length of a link.
  #
  # @param link [WSLink]
  # @return [Numeric] the length
  def link_length(link)
    length = 0

    iterate_link_segments(link) do |segment|
      length += distance(*segment)
    end

    return length
  end

  # Find the euclidean (i.e. 2D) distance between two xy coordinates.
  #
  # @param ax [Numeric]
  # @param ay [Numeric]
  # @param bx [Numeric]
  # @param by [Numeric]
  # @return [Numeric] distance between the points
  def distance(ax, ay, bx, by)
    return Math.sqrt((ax - bx) ** 2 + (ay - by) ** 2)
  end

  # Iterates over link segments with overlap, yielding the array of coordinates
  # i.e. [ax, ay, bx, by], [bx, by, cx, cy]
  #
  # @param link [WSLink]
  def iterate_link_segments(link)
    bends = link['bends']
    i = 0

    while i < bends.length - 2
      s = bends[i,4]
      yield(s)
      i += 2
    end
  end

  # Lerp between two floats
  #
  # @param a [Numeric]
  # @param b [Numeric]
  # @param percent [Numeric] value (clamped between 0-1)
  # @return [Numeric]
  def lerp(a, b, percent)
    pct = percent.clamp(0, 1)
    return (1 - pct) * a + pct * b
  end

  def navigate_us(ro)
    return navigate(ro, :us)
  end

  def navigate_ds(ro)
    return navigate(ro, :ds)
  end

  def navigate(ro, dir = :us)
    case ro
    when WSNode
      return (dir == :us ? ro.us_links : ro.ds_links)
    when WSLink
      node = (dir == :us ? ro.us_node : ro.ds_node)
      links = []
      node&.us_links.each { |link| links << link unless link.id == ro.id }
      node&.ds_links.each { |link| links << link unless link.id == ro.id }
      return links
    else
      return []
    end
  end

end
