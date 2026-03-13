# ===============================================================
# Clash Detection — ICM & WS Pro (fast, stable)
# - Grid-based proximity to limit pairs
# - Works on Selection if present
# - WS Pro: uses wn_pipe + 'diameter'
# - ICM   : supports hw_* + 'conduit_height'
# ===============================================================

require 'set'

def ask_float(prompt, default)
  begin
    s = WSApplication.input_box(prompt, "", "")
    s = s.to_s.strip
    return default if s.empty?
    Float(s)
  rescue
    default
  end
end

THRESHOLD_M = ask_float("Minimum vertical clearance (m)\nCLASH if <= value (e.g. 0.20)\nUse 0 for touch/overlap only.", 0.20)
XY_TOL_M    = ask_float("2D proximity tolerance (m) for candidate pairs (e.g. 0.05).", 0.05)

VERT_TOL = 0.001
INCLUDE_SHARED_NODES = false
CREATE_LABEL_POINTS  = true

# ---------------- Helpers ----------------
def to_f_or(v, d=0.0)
  v.nil? ? d : v.to_f
end

def safe_get(ro, names)
  names.each do |n|
    begin
      x = ro[n]
      return x unless x.nil?
    rescue
    end
  end
  nil
end

# Optional progress (no-op if API missing)
def set_progress(p)
  begin
    WSApplication.progress_value = p
  rescue
  end
end

PIPE_US_LEVEL_FIELDS = %w[
  us_invert us_invert_level invert_us us_invert_level_m
  start_level start_invert_level StartLevel StartInvertLevel
  inlet_invert upstream_invert upstream_level
]
PIPE_DS_LEVEL_FIELDS = %w[
  ds_invert ds_invert_level invert_ds ds_invert_level_m
  end_level end_invert_level EndLevel EndInvertLevel
  outlet_invert downstream_invert downstream_level
]
NODE_LEVEL_FIELDS = %w[
  invert_level invert_level_m invert Invert
  ground_level cover_level cover depth
  elevation Elevation level Level z Z
]

def pipe_level_at_param(link, r)
  us = to_f_or(safe_get(link, PIPE_US_LEVEL_FIELDS))
  ds = to_f_or(safe_get(link, PIPE_DS_LEVEL_FIELDS), us)

  if us == 0.0 && ds == 0.0
    begin
      us_node = link.us_node
      ds_node = link.ds_node
      usn = to_f_or(safe_get(us_node, NODE_LEVEL_FIELDS))
      dsn = to_f_or(safe_get(ds_node, NODE_LEVEL_FIELDS), usn)
      us = usn
      ds = dsn
    rescue
    end
  end

  us + (ds - us) * r
end

def diameter_m(link)
  v = safe_get(link, %w[diameter Diameter])
  if v && v.to_f > 0.0
    val = v.to_f
    return (val > 5.0) ? val / 1000.0 : val
  end

  v = safe_get(link, %w[conduit_height])
  if v && v.to_f > 0.0
    return v.to_f / 1000.0
  end

  v = safe_get(link, %w[height Height section_height section_height_full rise pipe_height])
  return 0.0 if v.nil?
  val = v.to_f
  (val > 5.0) ? val / 1000.0 : val
end

def link_seg_and_len(link)
  us = link.us_node
  ds = link.ds_node
  raise "Link #{link.id}: missing US/DS node" if us.nil? || ds.nil?

  usx = to_f_or(safe_get(us, %w[X x lon Lon Longitude longitude]))
  usy = to_f_or(safe_get(us, %w[Y y lat Lat Latitude latitude]))
  dsx = to_f_or(safe_get(ds, %w[X x lon Lon Longitude longitude]))
  dsy = to_f_or(safe_get(ds, %w[Y y lat Lat Latitude latitude]))

  [ [ [usx, usy], [dsx, dsy] ], Math.hypot(dsx - usx, dsy - usy) ]
end

def closest_params_2d(a, b, c, d)
  ax, ay = a; bx, by = b; cx, cy = c; dx, dy = d
  ux, uy = bx - ax, by - ay
  vx, vy = dx - cx, dy - cy
  wx, wy = ax - cx, ay - cy

  uu = ux*ux + uy*uy
  vv = vx*vx + vy*vy
  uv = ux*vx + uy*vy
  uw = ux*wx + uy*wy
  vw = vx*wx + vy*wy

  denom = uu*vv - uv*uv

  if denom.abs < 1e-12
    r = (uu > 0) ? (-uw / uu) : 0.0
    r = [[r, 0.0].max, 1.0].min
    s = (vv > 0) ? ((uv*r + vw) / vv) : 0.0
    s = [[s, 0.0].max, 1.0].min
  else
    r = (uv*vw - vv*uw) / denom
    s = (uu*vw - uv*uw) / denom
    r = [[r, 0.0].max, 1.0].min
    s = [[s, 0.0].max, 1.0].min
  end

  ix = ax + r*ux
  iy = ay + r*uy
  jx = cx + s*vx
  jy = cy + s*vy
  d_xy = Math.hypot(ix - jx, iy - jy)

  [r, s, 0.5*(ix + jx), 0.5*(iy + jy), d_xy]
end

def pick_table(net)
  %w[
    wn_pipe WN_Pipe wn_connection WN_Connection wn_valve WN_Valve wn_pump WN_Pump
    hw_pipe HW_Pipe hw_conduit HW_Conduit hw_link HW_Link hw_connection HW_Connection
  ].each do |t|
    begin
      ros = net.row_objects(t)
      if ros && ros.respond_to?(:length) && ros.length > 0
        return [t, ros]
      end
    rescue
    end
  end
  nil
end

def pick_point_table(net)
  %w[
    wn_user_point WN_User_Point wn_point WN_Point
    hw_user_point HW_User_Point hw_point HW_Point hw_flags HW_Flags
  ].each do |t|
    begin
      test = net.row_objects(t)
      if test && test.respond_to?(:length)
        return t
      end
    rescue
    end
  end
  nil
end

def add_label_point(net, pt_table, x, y, text)
  return unless pt_table
  begin
    p = net.new_row_object(pt_table)
    begin
      p['X'] = x
    rescue
      p['x'] = x
    end
    begin
      p['Y'] = y
    rescue
      p['y'] = y
    end
    tag = "[CLR]"
    %w[label name text comment description user_text user_text_1 user_text_2].each do |fld|
      begin
        p[fld] = "#{tag} #{text}"
        break
      rescue
      end
    end
    p.write
  rescue
  end
end

def delete_old_labels(net, pt_table)
  return unless pt_table
  begin
    ros = net.row_objects(pt_table)
    ros.each do |r|
      begin
        labelish = nil
        %w[label name text comment description user_text user_text_1 user_text_2].each do |fld|
          begin
            labelish ||= r[fld]
          rescue
          end
        end
        if labelish && labelish.to_s.start_with?("[CLR]")
          r.delete
        end
      rescue
      end
    end
  rescue
  end
end

def cells_around(minx, miny, maxx, maxy, cell)
  xi0 = (minx / cell).floor
  xi1 = (maxx / cell).floor
  yi0 = (miny / cell).floor
  yi1 = (maxy / cell).floor

  out = []
  x = xi0
  while x <= xi1
    y = yi0
    while y <= yi1
      out << [x, y]
      y += 1
    end
    x += 1
  end
  out
end

# ---------------- Main ----------------
net = WSApplication.current_network
picked = pick_table(net)
raise "No usable link table found." if picked.nil?
link_table, all_links = picked

# Use selection if available
sel_ids = []
begin
  all_links.each do |ro|
    begin
      sel_ids << ro.id if ro.selected
    rescue
    end
  end
rescue
end
links = sel_ids.any? ? all_links.select { |ro| sel_ids.include?(ro.id) } : all_links
raise "No links to process (selection empty?)" if links.empty?

pt_table = CREATE_LABEL_POINTS ? pick_point_table(net) : nil
delete_old_labels(net, pt_table) if pt_table

CELL = [XY_TOL_M * 2.0, 1.0].max

segs   = []
bboxes = []
grid   = Hash.new { |h, k| h[k] = [] }

links.each_with_index do |l, idx|
  seg = nil
  len = 0.0
  begin
    seg, len = link_seg_and_len(l)
  rescue
  end
  next if seg.nil? || len <= 0.0

  ax, ay = seg[0]
  bx, by = seg[1]
  minx = [ax, bx].min - XY_TOL_M
  maxx = [ax, bx].max + XY_TOL_M
  miny = [ay, by].min - XY_TOL_M
  maxy = [ay, by].max + XY_TOL_M

  segs << seg
  bboxes << [minx, miny, maxx, maxy]

  xi0 = (minx / CELL).floor
  xi1 = (maxx / CELL).floor
  yi0 = (miny / CELL).floor
  yi1 = (maxy / CELL).floor

  x = xi0
  while x <= xi1
    y = yi0
    while y <= yi1
      grid[[x, y]] << idx
      y += 1
    end
    x += 1
  end
end

# Candidate pairs
candidates = Hash.new { |h, k| h[k] = [] }
segs.each_index do |i|
  minx, miny, maxx, maxy = bboxes[i]
  seen = Set.new
  cells_around(minx, miny, maxx, maxy, CELL).each do |key|
    (grid[key] || []).each do |j|
      next if j <= i
      next if seen.include?(j)
      seen << j
      candidates[i] << j
    end
  end
end

results = []
total_pairs = candidates.values.map(&:length).inject(0, :+)
done = 0

begin
  WSApplication.long_running_operation_begin
rescue
end

segs.each_index do |i|
  l1 = links[i]
  seg1 = segs[i]
  next if seg1.nil?

  (candidates[i] || []).each do |j|
    l2 = links[j]
    seg2 = segs[j]
    next if seg2.nil?

    unless INCLUDE_SHARED_NODES
      shared = false
      begin
        ids1 = [l1.us_node_id, l1.ds_node_id]
        ids2 = [l2.us_node_id, l2.ds_node_id]
        shared = (ids1 & ids2).any?
      rescue
      end
      if shared
        done += 1
        set_progress(100.0 * done / [total_pairs, 1].max)
        next
      end
    end

    r1, r2, ix, iy, d_xy = closest_params_2d(seg1[0], seg1[1], seg2[0], seg2[1])
    if d_xy <= XY_TOL_M
      inv1 = pipe_level_at_param(l1, r1)
      inv2 = pipe_level_at_param(l2, r2)
      h1   = diameter_m(l1)
      h2   = diameter_m(l2)

      top1 = inv1 + h1
      top2 = inv2 + h2
      clear_tb = (inv1 < inv2) ? (inv2 - top1) : (inv1 - top2)

      c1 = inv1 + 0.5*h1
      c2 = inv2 + 0.5*h2
      clear_center = ( (c1 - c2).abs - 0.5*(h1 + h2) )

      clearance = [clear_tb, clear_center].min

      clash = if THRESHOLD_M <= 0.0
                (clearance <= 0.0)
              else
                (clearance <= (THRESHOLD_M + VERT_TOL))
              end
      if clash
        results << { l1: l1.id, l2: l2.id, clr: clearance, x: ix, y: iy }
      end
    end

    done += 1
    set_progress(100.0 * done / [total_pairs, 1].max)
  end
end

begin
  WSApplication.long_running_operation_end
rescue
end

puts "---------------------------------------------------------"
puts "Clash Detection Report (ICM / WS Pro)"
puts "Link table: #{link_table}"
puts "Links processed: #{links.length}"
puts "Candidate pairs: #{total_pairs}"
puts "Clashes found: #{results.size} (threshold = #{THRESHOLD_M} m)"
results.each_with_index do |r, k|
  puts "%2d. %-16s × %-16s | clearance = % .6f m" % [k+1, r[:l1], r[:l2], r[:clr]]
end

if results.any?
  ids = results.flat_map { |r| [r[:l1], r[:l2]] }.uniq
  begin
    sel = Selection.new
    ids.each do |id|
      sel.add(link_table, id)
    end
    sel.commit("Clash_Selection_#{Time.now.strftime('%Y%m%d_%H%M')}")
  rescue
    begin
      net.clear_selection
    rescue
    end
    ids.each do |id|
      begin
        ro = net.row_object(link_table, id)
        begin
          ro.selected = true
        rescue
        end
        begin
          ro.write
        rescue
        end
      rescue
      end
    end
  end
end

if CREATE_LABEL_POINTS && results.any?
  delete_old_labels(net, pt_table)
  results.each do |r|
    txt = "CLR=#{sprintf('%.3f', r[:clr])} m  (#{r[:l1]} vs #{r[:l2]})"
    add_label_point(net, pt_table, r[:x], r[:y], txt)
  end
end

if results.any?
  begin
    require 'tmpdir'
    path = File.join(Dir.tmpdir, "clash_fast_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv")
    File.open(path, 'w') do |f|
      f.puts "link1_id,link2_id,clearance_m,x,y"
      results.each do |r|
        f.puts "#{r[:l1]},#{r[:l2]},#{sprintf('%.6f', r[:clr])},#{r[:x]},#{r[:y]}"
      end
    end
    puts "CSV saved: #{path}"
  rescue
  end
end

puts "---------------------------------------------------------"
