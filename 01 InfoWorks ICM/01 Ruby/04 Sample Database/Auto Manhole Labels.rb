# ICM Ruby: Auto Manhole Labeling
# Golden logic intact — now with UI that’s always empty and clean

require 'set'

# ---------- POPUPS (always empty input field) ----------
APP_TITLE = ""                         # keep title blank
ZWS       = "\u200B"                   # zero-width space to make field appear empty

def _clean_return(val)
  v = (val || "").gsub(/\u200B/, "").strip
  v
end

def ask_prefix
  title  = APP_TITLE
  prompt = "Step 1/3\n\nEnter PREFIX for node names (e.g. MH).\nLeave blank for MH:"
  loop do
    raw = WSApplication.input_box(prompt, ZWS, title)
    v = _clean_return(raw)
    return "MH" if v.empty?
    return v
  end
end

def ask_mode
  title  = APP_TITLE
  prompt = "Step 2/3 - Choose naming mode (blank = 1):\n" \
           "  1) Use outfall name only\n" \
           "  2) Use outfall name + custom name\n" \
           "  3) Use custom name only\n\n" \
           "Enter 1 / 2 / 3 (or keyword):"
  loop do
    raw = WSApplication.input_box(prompt, ZWS, title)
    v = _clean_return(raw).upcase
    return "OF_ONLY"        if v == "" || v == "1" || v == "OF_ONLY"
    return "OF_PLUS_CUSTOM" if v == "2" || v == "OF_PLUS_CUSTOM" || v == "OF+CUSTOM"
    return "CUSTOM_ONLY"    if v == "3" || v == "CUSTOM_ONLY"
    WSApplication.message_box("Please enter 1, 2, or 3 (or leave blank).", "OK", "!", false)
  end
end

def ask_custom_name(mode)
  return "" unless mode == "OF_PLUS_CUSTOM" || mode == "CUSTOM_ONLY"
  title  = APP_TITLE
  prompt = "Extra Name (Optional)\n\nEnter custom name. Leave blank for CUST:"
  _clean_return(WSApplication.input_box(prompt, ZWS, title))
end

def ask_separator
  title  = APP_TITLE
  prompt = "Step 3/3 - Choose separator (blank = 1):\n" \
           "  1) Hyphen (-)\n" \
           "  2) Backslash (\\)\n" \
           "  3) Dot (.)\n\n" \
           "Enter 1 / 2 / 3:"
  loop do
    raw = WSApplication.input_box(prompt, ZWS, title)
    v = _clean_return(raw)
    return "-" if v == "" || v == "1" || v == "-"
    return "\\" if v == "2" || v == "\\"
    return "." if v == "3" || v == "."
    WSApplication.message_box("Please enter 1, 2, or 3 (or leave blank).", "OK", "!", false)
  end
end

# ---------- INPUTS ----------
PREFIX      = ask_prefix
MODE        = ask_mode
CUSTOM_NAME = ask_custom_name(MODE)
DELIM       = ask_separator

# ---------- CONSTANTS ----------
DRY_RUN               = false
KEEP_EXISTING_MAIN    = false
KEEP_EXISTING_LATERAL = false
TAG_FIELD_MAINLINE    = 'user_text_1'
TAG_VALUE_MAINLINE    = 'MAINLINE'
SYM_FIELD_INDEX       = 'user_number_2'

nw = WSApplication.current_network

# ---------- HELPERS ----------
def as_array(coll); arr=[]; coll&.each{|x|arr<<x}; arr; end
def is_outfall?(node); t=(node['node_type']||node['type']||'').to_s.downcase; t.include?('outfall'); end
def upstream_links(node); node.respond_to?(:us_links) ? as_array(node.us_links) : []; end
def link_us_node(link); link.respond_to?(:us_node) ? link.us_node : nil; end
def children_nodes(node); kids=[]; upstream_links(node).each{|l| n=link_us_node(l); kids<<n if n}; kids; end
def object_exists?(nw, table, id); begin !nw.row_object(table,id).nil? rescue false end; end

def unique_name(nw, base)
  name=base.dup; i=1
  while object_exists?(nw,'hw_node',name)
    i+=1; name=base+DELIM+i.to_s
  end
  name
end

def rename_node!(n,new_id)
  old=n['node_id'].to_s
  if old!=new_id
    n['node_id']=new_id
    n.write
  end
end

def choose_of_name(of)
  raw = of['node_id'].to_s
  of_name = raw.empty? ? 'OF?' : raw.upcase
  if MODE == "OF_ONLY"
    of_name
  elsif MODE == "OF_PLUS_CUSTOM"
    extra = (CUSTOM_NAME.nil? || CUSTOM_NAME.empty?) ? 'CUST' : CUSTOM_NAME
    of_name + DELIM + extra
  else
    extra = (CUSTOM_NAME.nil? || CUSTOM_NAME.empty?) ? 'CUST' : CUSTOM_NAME
    extra.upcase
  end
end

# ---------- CORE LOGIC ----------
def longest_path_from(node, memo_len, memo_next)
  nid=node['node_id']
  return memo_len[nid] if memo_len.key?(nid)
  ks=children_nodes(node)
  if ks.empty?
    memo_len[nid]=1; memo_next[nid]=nil; return 1
  end
  best_len=-1; best_kid=nil
  ks.each do |k|
    len=longest_path_from(k,memo_len,memo_next)
    if len>best_len; best_len=len; best_kid=k; end
  end
  memo_len[nid]=1+best_len; memo_next[nid]=best_kid; memo_len[nid]
end

def extract_mainline(of)
  memo_len={}; memo_next={}
  first_us=children_nodes(of); return [] if first_us.empty?
  best=nil; best_len=-1
  first_us.each do |k|
    len=longest_path_from(k,memo_len,memo_next)
    if len>best_len; best_len=len; best=k; end
  end
  path=[]; cur=best
  while cur
    path<<cur; cur=memo_next[cur['node_id']]
  end
  path
end

def already_mainline_format?(id_str, of_name)
  wanted = PREFIX + DELIM + of_name + DELIM
  id_str.to_s.upcase.start_with?(wanted.upcase)
end

def name_mainline!(nw, mainline_nodes, of_name)
  idx=0
  mainline_nodes.each do |n|
    idx+=1
    target = PREFIX + DELIM + of_name + DELIM + idx.to_s
    unless already_mainline_format?(n['node_id'], of_name) && KEEP_EXISTING_MAIN
      rename_node!(n, unique_name(nw, target)) unless DRY_RUN
    end
  end
end

$lat_depth_cache = {}
$lat_size_cache  = {}
def lateral_longest_depth(node, mainline_set)
  nid=node['node_id']; key=nid.to_s+"|depth"
  return $lat_depth_cache[key] if $lat_depth_cache.key?(key)
  ks=children_nodes(node).reject{ |k| mainline_set.include?(k['node_id']) }
  if ks.empty?; $lat_depth_cache[key]=1; return 1; end
  best=0
  ks.each{ |k| d=lateral_longest_depth(k,mainline_set); best=d if d>best }
  d_here=1+best; $lat_depth_cache[key]=d_here; d_here
end
def lateral_subtree_size(node, mainline_set)
  nid=node['node_id']; key=nid.to_s+"|size"
  return $lat_size_cache[key] if $lat_size_cache.key?(key)
  s=1
  children_nodes(node).reject{ |k| mainline_set.include?(k['node_id']) }.each{ |k| s+=lateral_subtree_size(k,mainline_set) }
  $lat_size_cache[key]=s; s
end
def choose_best_child(kids, mainline_set)
  best=nil; best_d=-1; best_s=-1; best_id=nil
  kids.each do |k|
    d=lateral_longest_depth(k,mainline_set)
    s=lateral_subtree_size(k,mainline_set)
    kid_id=k['node_id'].to_s
    better = d>best_d || (d==best_d && (s>best_s || (s==best_s && (best_id.nil? || kid_id>best_id))))
    if better; best_d=d; best_s=s; best_id=kid_id; best=k; end
  end
  best
end
def compute_trunk_chain(start_node, mainline_set)
  chain=[]; cur=start_node
  loop do
    break unless cur
    chain<<cur
    ks=children_nodes(cur).reject{ |k| mainline_set.include?(k['node_id']) }
    break if ks.empty?
    cur=choose_best_child(ks,mainline_set)
  end
  chain
end
def name_hierarchical_subtree!(nw, start_node, base_name, mainline_set, visited, forbidden_set)
  return if start_node.nil? || visited.include?(start_node['node_id']) || mainline_set.include?(start_node['node_id']) || forbidden_set.include?(start_node['node_id'])
  local_counter=0; q=[start_node]
  while !q.empty?
    node=q.shift; nid=node['node_id']
    next if visited.include?(nid) || mainline_set.include?(nid) || forbidden_set.include?(nid)
    local_counter+=1
    target=base_name+DELIM+local_counter.to_s
    rename_node!(node, unique_name(nw,target)) unless DRY_RUN
    visited.add(nid)
    children_nodes(node).each do |k|
      q<<k unless mainline_set.include?(k['node_id']) || forbidden_set.include?(k['node_id'])
    end
  end
end
def name_laterals_for_mainline_node!(nw, ml_node, mainline_set, visited)
  base=ml_node['node_id']
  starts=children_nodes(ml_node).reject{ |k| mainline_set.include?(k['node_id']) || visited.include?(k['node_id']) }
  return if starts.empty?
  max_depth=0; starts.each{ |st| d=lateral_longest_depth(st,mainline_set); max_depth=d if d>max_depth }
  trunk_chain=[]; trunk_set=Set.new
  if max_depth>=2
    trunk_start=choose_best_child(starts,mainline_set)
    trunk_chain=compute_trunk_chain(trunk_start,mainline_set)
    trunk_chain.each_with_index do |node,i|
      target=base+DELIM+(i+1).to_s
      rename_node!(node, unique_name(nw,target)) unless DRY_RUN
      visited.add(node['node_id']); trunk_set.add(node['node_id'])
    end
  end
  if trunk_chain.empty?
    starts.each{ |st| name_hierarchical_subtree!(nw,st,base+DELIM+"1",mainline_set,visited,Set.new) }
    return
  end
  trunk_chain.each_with_index do |node,i|
    step_base=base+DELIM+(i+1).to_s
    children_nodes(node).reject{ |k| mainline_set.include?(k['node_id']) || trunk_set.include?(k['node_id']) || visited.include?(k['node_id']) }.each do |k|
      name_hierarchical_subtree!(nw,k,step_base,mainline_set,visited,trunk_set)
    end
  end
  starts.each do |st|
    next if trunk_set.include?(st['node_id'])
    name_hierarchical_subtree!(nw,st,base+DELIM+"1",mainline_set,visited,trunk_set)
  end
end

# ---------- TAGGING ----------
def tag_nodes_mainline_with_index(nw, nodes, tag_field_main, tag_value_main, idx_field)
  idx=0
  nodes.each do |n|
    begin
      idx+=1
      n[tag_field_main] = tag_value_main
      n[idx_field]      = idx
      n.write
    rescue
    end
  end
end
def tag_links_between_chain(nw, chain_nodes, tag_field, tag_value)
  link_tables=['hw_conduit','hw_pipe']
  ids=chain_nodes.map{|n| n['node_id']}
  i=0
  while i<ids.length-1
    us=ids[i+1]; ds=ids[i]
    link_tables.each do |t|
      begin
        as_array(nw.row_objects(t)).each do |l|
          lus=(l['us_node_id']||'').to_s; lds=(l['ds_node_id']||'').to_s
          if lus==us && lds==ds
            begin; l[tag_field]=tag_value; l.write; rescue; end
          end
        end
      rescue
      end
    end
    i+=1
  end
end

# ---------- MAIN ----------
nw = WSApplication.current_network
nodes    = as_array(nw.row_objects('hw_node'))
outfalls = nodes.select{ |n| is_outfall?(n) }
if outfalls.empty?
  WSApplication.message_box('No outfalls found in hw_node.', 'OK','!',false); return
end

started_tx_here=false
begin
  begin
    nw.transaction_begin
    started_tx_here=true
  rescue => e
    raise e unless e.message.to_s.downcase.include?('transaction is already active')
  end

  outfalls.each do |of|
    of_name = choose_of_name(of).to_s.strip
    of_name = 'OF?' if of_name.empty?

    mainline = extract_mainline(of)
    name_mainline!(nw, mainline, of_name)
    mainline = extract_mainline(of)   # refresh IDs

    tag_nodes_mainline_with_index(nw, mainline, TAG_FIELD_MAINLINE, TAG_VALUE_MAINLINE, SYM_FIELD_INDEX)
    tag_links_between_chain(nw, mainline, TAG_FIELD_MAINLINE, TAG_VALUE_MAINLINE)

    mainline_set = Set.new(mainline.map{|n| n['node_id']})
    visited = Set.new
    $lat_depth_cache = {}
    $lat_size_cache  = {}

    mainline.each do |ml|
      name_laterals_for_mainline_node!(nw, ml, mainline_set, visited)
    end
  end

  DRY_RUN ? nw.transaction_cancel : nw.transaction_commit if started_tx_here
rescue => e
  begin; nw.transaction_cancel if started_tx_here; rescue; end
  WSApplication.message_box("Error: " + e.message.to_s, 'OK','!',false)
end
