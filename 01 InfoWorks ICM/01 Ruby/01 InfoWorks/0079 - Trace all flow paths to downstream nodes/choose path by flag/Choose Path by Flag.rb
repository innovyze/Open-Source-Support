# Choose Path by Flag
#
# Finds the downstream routes between two nodes, ranks them by the number of 
# links that carry a given user flag, and selects the route you choose.
# Designed for documenting proposed measures (for example flag "OP") so the
# selected route can be used for a longitudinal profile.
#
# Inspired by the path tracing script of Marcos Perez, whose script is the
# base this one builds on. Thanks Marco!
#
# Instructions:
# 1. Select the two end nodes in GeoPlan (order does not matter), or leave
#    the selection empty and type the node IDs when prompted
# 2. Run this script and enter the flag value (for example P1). Leave it
#    blank to ignore flags and simply list the routes by length
# 3. Choose a route number from the ranked table
# 4. The chosen route is selected in GeoPlan
# 5. When asked, save the chosen route or all routes as Selection Lists in
#    the network's Model Group (Cancel to skip)
#
# Notes:
# - Traversal follows flow direction only (downstream)
# - Only the flag fields listed in FLAG_FIELDS are checked. Add entries to
#   FLAG_FIELDS to count flags on other link types (weirs, orifices, ...)
# - Parallel links (for example a weir and an orifice at a tank) are kept as
#   separate routes

class ChoosePathByFlag
  # ---------------------------------------------------------------------
  # Settings
  # ---------------------------------------------------------------------

  # Flag fields to check, by link type (lower case, as returned by link_type).
  # Example of an addition for another link type (check the link type and
  # field names for your model): 'orifice' => ['diameter_flag']
  FLAG_FIELDS = {
    'cond' => ['conduit_width_flag', 'conduit_height_flag']
  }

  MAX_ROUTES = 10     # Routes listed in the table
  MAX_STEPS = 20000  # Search steps allowed when listing alternative routes
  MAX_DEPTH = 100    # Longest route (in nodes) the search will follow

  Edge = Struct.new(:link, :link_id, :link_type, :to_id, :to_node,
                    :flagged, :flag_field, :length)

  def initialize
    @net = WSApplication.current_network
    @db = WSApplication.current_database
    @flag_value = ''
    @steps = 0
    @capped = false
    @depth_hit = false
  end

  # ---------------------------------------------------------------------
  # Field access helpers
  # ---------------------------------------------------------------------

  # Read a field, returning nil if the object does not have it.
  def safe_field(obj, name)
    obj[name]
  rescue NoMethodError, RuntimeError, ArgumentError, IndexError
    nil
  end

  def xy_distance(from_node, to_node)
    dx = safe_field(to_node, 'x').to_f - safe_field(from_node, 'x').to_f
    dy = safe_field(to_node, 'y').to_f - safe_field(from_node, 'y').to_f
    Math.sqrt(dx * dx + dy * dy)
  end

  # Conduit length where available, otherwise straight-line node distance.
  def edge_length(link, type, from_node, to_node)
    if type == 'cond'
      len = safe_field(link, 'conduit_length')
      return len.to_f if !len.nil? && len.to_f > 0.0
    end
    xy_distance(from_node, to_node)
  end

  # Returns [flagged, field_name_that_matched]
  def flag_check(link, type)
    # A blank flag value means "ignore flags" (routes are ranked by length)
    return [false, nil] if @flag_value.empty?
    fields = FLAG_FIELDS[type]
    return [false, nil] if fields.nil?

    fields.each do |field|
      value = safe_field(link, field)
      next if value.nil?
      return [true, field] if value.to_s.strip.casecmp(@flag_value) == 0
    end
    [false, nil]
  end

  def build_edge(raw, from_node)
    link = raw[:link]
    type = link.link_type.to_s.strip
    flagged, field = flag_check(link, type.downcase)
    length = edge_length(link, type.downcase, from_node, raw[:to_node])
    Edge.new(link, raw[:link_id], type, raw[:to_id], raw[:to_node],
             flagged, field, length)
  end

  # ---------------------------------------------------------------------
  # Graph building
  # ---------------------------------------------------------------------

  # Walk downstream from start_node, recording every link once.
  # Returns [out, nodes]: out[node_id] = raw edges, nodes[node_id] = node object
  def explore_downstream(start_node)
    out = {}
    nodes = { start_node.id => start_node }
    queue = [start_node]
    head = 0

    while head < queue.size
      node = queue[head]
      head += 1
      raws = []

      node.ds_links.each do |link|
        to_node = link.ds_node
        next if to_node.nil?
        raws << { :link => link, :link_id => link.id.to_s,
                  :to_node => to_node, :to_id => to_node.id }
        unless nodes.has_key?(to_node.id)
          nodes[to_node.id] = to_node
          queue << to_node
        end
      end

      out[node.id] = raws
    end

    [out, nodes]
  end

  # Keep only nodes that can be reached from the start AND can reach the
  # destination. Edges out of the destination are dropped (routes end there).
  def prune(out, nodes, start_node, dest_node)
    reverse = {}
    out.each do |from_id, raws|
      next if from_id == dest_node.id
      raws.each do |raw|
        (reverse[raw[:to_id]] ||= []) << from_id
      end
    end

    keep = { dest_node.id => true }
    stack = [dest_node.id]
    until stack.empty?
      id = stack.pop
      (reverse[id] || []).each do |parent_id|
        next if keep.has_key?(parent_id)
        keep[parent_id] = true
        stack << parent_id
      end
    end
    return nil unless keep.has_key?(start_node.id)

    pruned = {}
    keep.each_key do |id|
      if id == dest_node.id
        pruned[id] = []
        next
      end
      edges = []
      out[id].each do |raw|
        next unless keep.has_key?(raw[:to_id])
        next if raw[:to_id] == id
        edges << build_edge(raw, nodes[id])
      end
      # Flagged links first so the capped search meets good routes early
      pruned[id] = edges.sort_by { |e| [e.flagged ? 0 : 1, e.length, e.link_id] }
    end
    pruned
  end

  # Returns a graph hash, or nil if dest_node is not downstream of start_node.
  def build_graph(start_node, dest_node)
    return nil if start_node.id == dest_node.id
    out, nodes = explore_downstream(start_node)
    return nil unless nodes.has_key?(dest_node.id)

    pruned = prune(out, nodes, start_node, dest_node)
    return nil if pruned.nil?

    { :start => start_node, :dest => dest_node,
      :start_id => start_node.id, :dest_id => dest_node.id,
      :nodes => nodes, :pruned => pruned }
  end

  # Returns node ids in topological order, or nil if the graph has a loop.
  def topological_order(pruned)
    indegree = {}
    pruned.each_key { |id| indegree[id] = 0 }
    pruned.each_value do |edges|
      edges.each { |e| indegree[e.to_id] += 1 }
    end

    ready = []
    indegree.each { |id, d| ready << id if d == 0 }

    order = []
    head = 0
    while head < ready.size
      id = ready[head]
      head += 1
      order << id
      pruned[id].each do |e|
        indegree[e.to_id] -= 1
        ready << e.to_id if indegree[e.to_id] == 0
      end
    end

    order.size == pruned.size ? order : nil
  end

  # ---------------------------------------------------------------------
  # Routes
  # ---------------------------------------------------------------------

  def make_route(start_node, edges)
    flags = 0
    length = 0.0
    ids = []
    edges.each do |e|
      flags += 1 if e.flagged
      length += e.length
      ids << e.link_id
    end
    { :start => start_node, :edges => edges, :flags => flags,
      :length => length, :hops => edges.size, :key => ids.join('|') }
  end

  # Ranking: most flagged links, then shortest, then fewer links, then link
  # IDs so that the order is repeatable. Length differences under 0.1 m are
  # ignored.
  def route_sort_key(route)
    [-route[:flags], route[:length].round(1), route[:hops], route[:key]]
  end

  # Comparison key for the best-route calculation (same 0.1 m precision)
  def score_key(score)
    [score[0], score[1].round(1), score[2]]
  end

  # Exact best route (most flagged links) when the graph has no loops.
  def exact_best(graph, order)
    best = {}
    best[graph[:start_id]] = { :score => [0, 0.0, 0], :edge => nil, :from => nil }

    order.each do |id|
      current = best[id]
      next if current.nil?
      graph[:pruned][id].each do |e|
        score = [current[:score][0] + (e.flagged ? 1 : 0),
                 current[:score][1] - e.length,
                 current[:score][2] - 1]
        old = best[e.to_id]
        if old.nil? || (score_key(score) <=> score_key(old[:score])) > 0
          best[e.to_id] = { :score => score, :edge => e, :from => id }
        end
      end
    end

    return nil if best[graph[:dest_id]].nil?

    edges = []
    id = graph[:dest_id]
    while !best[id][:edge].nil?
      edges.unshift(best[id][:edge])
      id = best[id][:from]
    end
    make_route(graph[:start], edges)
  end

  # Number of distinct routes when the graph has no loops.
  def count_routes(graph, order)
    counts = { graph[:start_id] => 1 }
    order.each do |id|
      c = counts[id]
      next if c.nil?
      graph[:pruned][id].each do |e|
        counts[e.to_id] = (counts[e.to_id] || 0) + c
      end
    end
    counts[graph[:dest_id]] || 0
  end

  # Depth-first listing of routes, within the limits set at the top.
  def enumerate_routes(graph)
    routes = []
    @steps = 0
    @capped = false
    @depth_hit = false
    visited = { graph[:start_id] => true }
    walk(graph, graph[:start_id], [], [graph[:start_id]], visited, routes)
    routes
  end

  def walk(graph, node_id, edges, path_ids, visited, routes)
    return if @capped

    if node_id == graph[:dest_id]
      routes << make_route(graph[:start], edges.dup)
      @capped = true if routes.size >= MAX_ROUTES
      return
    end

    @steps += 1
    if @steps > MAX_STEPS
      @capped = true
      return
    end
    if path_ids.size > MAX_DEPTH
      @depth_hit = true
      return
    end

    graph[:pruned][node_id].each do |e|
      next if visited.has_key?(e.to_id)
      visited[e.to_id] = true
      edges << e
      path_ids << e.to_id
      walk(graph, e.to_id, edges, path_ids, visited, routes)
      path_ids.pop
      edges.pop
      visited.delete(e.to_id)
      break if @capped
    end
  end

  # Returns { :routes, :total, :exact, :found }
  #   total is nil when the network has a loop (count not known)
  def find_routes(graph)
    order = topological_order(graph[:pruned])
    routes = enumerate_routes(graph)
    total = nil
    exact = false

    unless order.nil?
      exact = true
      total = count_routes(graph, order)
      best = exact_best(graph, order)
      routes << best unless best.nil?
    end

    unique = {}
    routes.each { |r| unique[r[:key]] = r unless unique.has_key?(r[:key]) }
    ranked = unique.values.sort_by { |r| route_sort_key(r) }

    { :routes => ranked.first(MAX_ROUTES), :total => total,
      :exact => exact, :found => ranked.size }
  end

  # ---------------------------------------------------------------------
  # Reporting
  # ---------------------------------------------------------------------

  def route_node_ids(route)
    ids = [route[:start].id.to_s]
    route[:edges].each { |e| ids << e.to_id.to_s }
    ids
  end

  def link_type_summary(route)
    counts = {}
    route[:edges].each do |e|
      type = e.link_type.empty? ? 'Unknown' : e.link_type
      counts[type] = 0 unless counts.has_key?(type)
      counts[type] += 1
    end
    counts.keys.sort.map { |type| "#{type} (#{counts[type]})" }.join(', ')
  end

  def same_rank?(a, b)
    a[:flags] == b[:flags] &&
      a[:length].round(1) == b[:length].round(1) &&
      a[:hops] == b[:hops]
  end

  # Returns "" or "ties with route N"
  def tie_note(routes, index)
    first = index
    first -= 1 while first > 0 && same_rank?(routes[first - 1], routes[index])
    first == index ? '' : "ties with route #{first + 1}"
  end

  def print_unflagged(route, label)
    unflagged = route[:edges].select { |e| !e.flagged }
    if unflagged.empty?
      puts "#{label}: all #{route[:hops]} links carry the flag"
    else
      list = unflagged.map { |e| "#{e.link_id} (#{e.link_type})" }.join(', ')
      puts "#{label}: #{unflagged.size} unflagged link(s): #{list}"
    end
  end

  def print_routes(routes)
    routes.each_with_index do |r, i|
      note = tie_note(routes, i)
      note = " [#{note}]" unless note.empty?
      puts "Route #{i + 1}: #{r[:flags]}/#{r[:hops]} flagged, " \
           "#{r[:length].round(1)} m#{note}"
      puts "  Nodes: #{route_node_ids(r).join(' > ')}"
    end
  end

  def status_note(result)
    shown = result[:routes].size
    no_flags = result[:routes][0][:flags] == 0
    if result[:exact]
      if @flag_value.empty?
        text = "#{result[:total]} route(s) exist, ranked by length (no flag entered)."
      elsif no_flags
        text = "#{result[:total]} route(s) exist. No links carry the flag " \
               "'#{@flag_value}' on any route, so routes are ranked by length."
      else
        text = "#{result[:total]} route(s) exist. Route 1 has the most flagged links."
      end
      text += " Showing the first #{shown}." if result[:total] > shown
    elsif @flag_value.empty?
      text = "Loop found between the nodes. Routes ranked by length (no flag " \
             "entered). Showing #{shown}."
    elsif no_flags
      text = "Loop found between the nodes. No links carry the flag " \
             "'#{@flag_value}' on any route found, so routes are ranked by " \
             "length. Showing #{shown}."
    else
      text = "Loop found between the nodes: route 1 is the best found within " \
             "the search limits, not guaranteed. Showing #{shown}."
    end
    text += ' Search depth limit reached.' if @depth_hit
    text
  end

  # ---------------------------------------------------------------------
  # Selection and Selection Lists
  # ---------------------------------------------------------------------

  def select_route(route)
    @net.clear_selection
    route[:start].selected = true
    route[:edges].each do |e|
      e.link.selected = true
      e.to_node.selected = true
    end
  end

  # Model Group that holds the network (same pattern as the other 0079 scripts)
  def get_parent_group
    return nil if @db.nil?
    parent_id = @net.model_object.parent_id
    begin
      @db.model_object_from_type_and_id('Model Group', parent_id)
    rescue StandardError
      # The ICM API does not document the error type for a wrong object type.
      # Parent is a Model Network, so use that object's parent group
      parent_object = @db.model_object_from_type_and_id('Model Network', parent_id)
      @db.model_object_from_type_and_id('Model Group', parent_object.parent_id)
    end
  end

  def create_unique_name(group, base_name)
    existing = {}
    group.children.each { |child| existing[child.name] = true }

    name = base_name
    counter = 1
    while existing.has_key?(name)
      name = "#{base_name}_#{counter}"
      counter += 1
    end
    name
  end

  def clean_name(text)
    text.to_s.gsub(/[^A-Za-z0-9_.\-]/, '_')
  end

  # Ask whether to save the chosen route or all routes as Selection Lists.
  # Returns :chosen, :all, or nil (Cancel, or an unreadable answer).
  def ask_save_choice(route_count)
    title = "Save as selection list? (#{route_count} routes, Cancel to skip)"
    result = nil
    begin
      result = WSApplication.prompt(
        title,
        [['Save', 'STRING', 'Chosen route', nil, 'LIST', ['Chosen route', 'All routes']]],
        false
      )
    rescue StandardError
      # Drop-down lists may not be available in every ICM version, so fall
      # back to a typed answer (the error type is not documented).
      result = WSApplication.prompt(
        title,
        [['Save (type chosen or all)', 'STRING', 'chosen']],
        false
      )
    end
    return nil if result.nil?

    answer = result[result.size - 1].to_s.strip.downcase
    return :all if answer.include?('all')
    return :chosen if answer.include?('chosen')

    WSApplication.message_box('Please choose "Chosen route" or "All routes".',
                              'OK', '!', false)
    nil
  end

  # Offer to save the chosen route or all routes, then restore the selection.
  def offer_save_lists(graph, routes, chosen_index)
    choice = ask_save_choice(routes.size)
    return if choice.nil?

    group = nil
    begin
      group = get_parent_group
    rescue StandardError => e
      puts "Could not find the Model Group: #{e.message}"
    end
    if group.nil?
      puts 'Selection Lists cannot be saved (no Model Group found).'
      return
    end

    base = "Route_#{clean_name(graph[:start_id])}_to_#{clean_name(graph[:dest_id])}"
    indexes = choice == :all ? (0...routes.size).to_a : [chosen_index]
    saved = 0

    begin
      indexes.each do |i|
        select_route(routes[i])
        name = create_unique_name(group, "#{base}_#{i + 1}")
        begin
          list = group.new_model_object('Selection List', name)
          @net.save_selection(list)
          saved += 1
          puts "Created selection list '#{name}' for route #{i + 1}"
        rescue StandardError => e
          puts "ERROR: could not create selection list for route #{i + 1}: #{e.message}"
        end
      end
    ensure
      select_route(routes[chosen_index])
    end

    puts 'Refresh the database tree to see the new selection lists.' if saved > 0
  end

  # ---------------------------------------------------------------------
  # User interaction
  # ---------------------------------------------------------------------

  # Returns [node_a, node_b] or nil. Sets @flag_value.
  def get_inputs
    nodes = []
    @net.row_objects_selection('_nodes').each { |n| nodes << n }

    if nodes.size == 2
      values = WSApplication.prompt(
        'Choose Path by Flag',
        [['Flag value (leave blank to ignore flags)', 'STRING', '']],
        false
      )
      return nil if values.nil?
      @flag_value = values[0].to_s.strip
      pair = [nodes[0], nodes[1]]
    else
      values = WSApplication.prompt(
        'Choose Path by Flag (tip: select two nodes in GeoPlan instead)',
        [['First node ID', 'STRING', ''],
         ['Second node ID', 'STRING', ''],
         ['Flag value (leave blank to ignore flags)', 'STRING', '']],
        false
      )
      return nil if values.nil?
      first_id = values[0].to_s.strip
      second_id = values[1].to_s.strip
      @flag_value = values[2].to_s.strip
      if first_id.empty? || second_id.empty?
        WSApplication.message_box('Please enter both node IDs.', 'OK', '!', false)
        return nil
      end
      first = @net.row_object('_nodes', first_id)
      second = @net.row_object('_nodes', second_id)
      if first.nil? || second.nil?
        WSApplication.message_box('One or both node IDs were not found.', 'OK', '!', false)
        return nil
      end
      pair = [first, second]
    end

    if pair[0].id == pair[1].id
      WSApplication.message_box('Please choose two different nodes.', 'OK', '!', false)
      return nil
    end
    pair
  end

  # Works out which node is upstream. Returns a graph, or nil.
  def resolve_direction(node_a, node_b)
    a_to_b = build_graph(node_a, node_b)
    b_to_a = build_graph(node_b, node_a)

    if a_to_b.nil? && b_to_a.nil?
      WSApplication.message_box(
        "No downstream route found between #{node_a.id} and #{node_b.id}.",
        'OK', '!', false)
      return nil
    end
    return a_to_b if b_to_a.nil?
    return b_to_a if a_to_b.nil?

    # Both directions are possible: ask rather than guess
    result = WSApplication.prompt(
      'Routes exist in both directions',
      [["1", 'READONLY', "#{node_a.id} (upstream) to #{node_b.id} (downstream)"],
       ["2", 'READONLY', "#{node_b.id} (upstream) to #{node_a.id} (downstream)"],
       ['Enter 1 or 2', 'STRING', '1']],
      false
    )
    return nil if result.nil?
    choice = result[result.size - 1].to_s.strip
    return a_to_b if choice == '1'
    return b_to_a if choice == '2'
    WSApplication.message_box('Enter 1 or 2.', 'OK', '!', false)
    nil
  end

  def choose_route(routes, note)
    header = sprintf("%-8s | %-12s | %s", 'Flagged', 'Length (m)', 'Link types')
    rows = [['ROUTE', 'READONLY', header]]
    rows << ['NOTE', 'READONLY', note]

    routes.each_with_index do |r, i|
      tie = tie_note(routes, i)
      data = sprintf("%-8s | %-12.1f | %s", "#{r[:flags]}/#{r[:hops]}",
                     r[:length], link_type_summary(r))
      data += "  [#{tie}]" unless tie.empty?
      rows << [(i + 1).to_s, 'READONLY', data]
    end
    rows << ['Enter route number', 'STRING', '1']

    result = WSApplication.prompt("#{routes.size} route(s) - Choose Route", rows, false)
    return nil if result.nil?

    number = result[result.size - 1].to_s.strip.to_i
    if number < 1 || number > routes.size
      WSApplication.message_box("Enter a route number from 1 to #{routes.size}.",
                                'OK', '!', false)
      return nil
    end
    number - 1
  end

  # ---------------------------------------------------------------------
  # Main
  # ---------------------------------------------------------------------

  def doit
    pair = get_inputs
    return if pair.nil?

    graph = resolve_direction(pair[0], pair[1])
    return if graph.nil?

    puts "Upstream node: #{graph[:start_id]}"
    puts "Downstream node: #{graph[:dest_id]}"
    if @flag_value.empty?
      puts 'Flag value: none (routes ranked by length)'
    else
      puts "Flag value: #{@flag_value} (fields checked: " \
           "#{FLAG_FIELDS.map { |t, f| "#{t}: #{f.join('/')}" }.join('; ')})"
    end
    puts ''

    result = find_routes(graph)
    routes = result[:routes]
    if routes.empty?
      WSApplication.message_box('No route could be listed within the search limits.',
                                'OK', '!', false)
      return
    end

    note = status_note(result)
    puts note
    print_routes(routes)
    print_unflagged(routes[0], 'Route 1') unless @flag_value.empty?
    puts ''

    index = choose_route(routes, note)
    return if index.nil?

    select_route(routes[index])
    chosen = routes[index]
    puts "Selected route #{index + 1}: #{chosen[:flags]}/#{chosen[:hops]} " \
         "flagged, #{chosen[:length].round(1)} m"
    print_unflagged(chosen, "Route #{index + 1}") if index > 0 && !@flag_value.empty?

    offer_save_lists(graph, routes, index)
  end
end

begin
  ChoosePathByFlag.new.doit
rescue StandardError => e
  puts "FATAL ERROR: #{e.message}"
  puts e.backtrace.join("\n") if e.backtrace
end
