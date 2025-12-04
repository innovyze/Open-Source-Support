################################################################################
# Script Name: 3d_clash_detection.rb
# Description: 3D Clash Detection for Pipes
#              - Uses full polyline geometry (bends array with all vertices)
#              - Interpolates Z coordinate along pipe length
#              - Works on selection if present, otherwise entire network
#              - Detects vertical clearance violations between pipes
#              - Clearance = IL_upper - (IL_lower + Diameter_lower)
#              - Clash if clearance <= minimum clearance threshold
#
# Requirements:
#              - Network must be open in the UI
#              - Pipes must have elevation and diameter/height data
#
# User Options (prompted at runtime):
#   Include shared nodes  - Check pipes that share a node (default: false)
#   Output to console     - Print clash results to console (default: true)
#   Export to CSV         - Save results to CSV in temp folder (default: true)
#   Minimum clearance (m) - Buffer distance for clash detection (default: 0)
#
# Source: Autodesk
#
################################################################################

require 'set'

# ---------- user input ----------
prompt_fields = [
  ['Include shared nodes?', 'BOOLEAN', false],
  ['Output results to console?', 'BOOLEAN', true],
  ['Export results to CSV?', 'BOOLEAN', true],
  ['Minimum clearance (m)', 'STRING', '0'],
  ['Clashes detected when pipes intersect within this buffer.', 'READONLY', 'Use 0 to only return touching/overlapping pipes.']
]

values = WSApplication.prompt("Clash Detection Options", prompt_fields, false)
exit if values.nil?

INCLUDE_SHARED_NODES = values[0]
OUTPUT_TO_CONSOLE    = values[1]
EXPORT_CSV           = values[2]

# Parse minimum clearance (default 0 if invalid)
MIN_CLR = begin
  v = values[3].to_s.strip
  v.empty? ? 0.0 : Float(v)
rescue
  0.0
end

VERT_TOL = 0.005   # numerical tolerance (m)

# ---------- helpers ----------
def to_f_or(v, d = nil)
  return d if v.nil?
  Float(v) rescue d
end

def safe_get(ro, arr)
  arr.each do |n|
    begin
      x = ro[n]
      return x unless x.nil?
    rescue
    end
  end
  nil
end

def node_xy(n)
  [
    to_f_or(safe_get(n, %w[X x lon Lon Longitude]), 0.0),
    to_f_or(safe_get(n, %w[Y y lat Lat Latitude]), 0.0)
  ]
end

PIPE_US_FIELDS = %w[
  us_invert us_invert_level invert_us us_invert_level_m
  start_level start_invert_level
]
PIPE_DS_FIELDS = %w[
  ds_invert ds_invert_level invert_ds ds_invert_level_m
  end_level end_invert_level
]

NODE_LEVEL_FIELDS = %w[
  invert_level invert_level_m invert Invert
  elevation Elevation level Level z Z
]

# --- inverts: pipe fields first, then node levels (for WS Pro) ----
def pipe_inverts(l)
  us = to_f_or(safe_get(l, PIPE_US_FIELDS), nil)
  ds = to_f_or(safe_get(l, PIPE_DS_FIELDS), nil)

  # if pipe doesn’t have inverts (typical WS Pro) → use node levels
  if us.nil? || ds.nil?
    begin
      us_node = l.us_node
      ds_node = l.ds_node
      usn = to_f_or(safe_get(us_node, NODE_LEVEL_FIELDS), nil)
      dsn = to_f_or(safe_get(ds_node, NODE_LEVEL_FIELDS), nil)
      return nil if usn.nil? || dsn.nil?
      return [usn, dsn]
    rescue
      return nil
    end
  end

  [us, ds]
end

def pipe_level_at_param(us, ds, r)
  us + r * (ds - us)
end

def diameter_m(l)
  v = safe_get(l, %w[diameter Diameter])
  if v && v.to_f > 0
    d = v.to_f
    return (d > 20 ? d / 1000.0 : d)
  end
  v = safe_get(l, %w[conduit_height section_height section_height_full rise pipe_height])
  return 0.0 if v.nil?
  d = v.to_f
  (d > 20 ? d / 1000.0 : d)
end

# ---- polyline from bends array ----
# The 'bends' field is a flat array: [x1, y1, x2, y2, x3, y3, ...]
# It includes ALL vertices including start (US node) and end (DS node) points.
def get_bends_as_points(l)
  pts = []
  begin
    bends = l['bends']
    if bends && bends.is_a?(Array) && bends.length >= 4
      # Convert flat array to [[x1,y1], [x2,y2], ...] pairs
      bends.each_slice(2) do |xy|
        if xy.length == 2
          x = xy[0].to_f
          y = xy[1].to_f
          pts << [x, y]
        end
      end
    end
  rescue => e
    # bends not available, fall back to node coordinates
  end
  pts
end

def build_polyline(l)
  us = l.us_node
  ds = l.ds_node
  return nil if us.nil? || ds.nil?

  # First try to get vertices from the bends array (includes all vertices)
  pts = get_bends_as_points(l)
  
  # If bends is empty or not available, fall back to just US/DS node coordinates
  if pts.empty? || pts.size < 2
    pts = []
    pts << node_xy(us)
    pts << node_xy(ds)
  end

  pts = pts.select { |p| p[0].is_a?(Numeric) && p[1].is_a?(Numeric) }
  return nil if pts.size < 2

  segs = []
  lens = []
  total = 0.0

  minx = maxx = pts[0][0]
  miny = maxy = pts[0][1]

  (0...pts.length - 1).each do |i|
    a = pts[i]
    b = pts[i + 1]
    len = Math.hypot(b[0] - a[0], b[1] - a[1])
    next if len <= 0
    segs << [a, b]
    lens << len
    total += len
    minx = [minx, a[0], b[0]].min
    maxx = [maxx, a[0], b[0]].max
    miny = [miny, a[1], b[1]].min
    maxy = [maxy, a[1], b[1]].max
  end

  return nil if segs.empty? || total <= 0

  cum = []
  acc = 0.0
  lens.each do |ln|
    cum << acc
    acc += ln
  end

  {
    segments:    segs,
    seg_lengths: lens,
    cum_lengths: cum,
    total_len:   total,
    bbox:        [minx, miny, maxx, maxy]
  }
end

def bbox_overlap?(b1, b2)
  !(b1[2] < b2[0] || b2[2] < b1[0] || b1[3] < b2[1] || b2[3] < b1[1])
end

# strict segment intersection (interior only)
def seg_inter(a, b, c, d)
  ax, ay = a; bx, by = b
  cx, cy = c; dx, dy = d
  rx = bx - ax; ry = by - ay
  sx = dx - cx; sy = dy - cy
  rxs = rx*sy - ry*sx
  return [false, nil, nil, nil, nil] if rxs.abs < 1e-9
  qpx = cx - ax; qpy = cy - ay
  t = (qpx*sy - qpy*sx) / rxs
  u = (qpx*ry - qpy*rx) / rxs
  return [false, nil, nil, nil, nil] unless t > 1e-6 && t < 1 - 1e-6 && u > 1e-6 && u < 1 - 1e-6
  [true, t, u, ax + t*rx, ay + t*ry]
end

def pick_table(net)
  # WS Pro أولاً، بعدين ICM
  %w[wn_pipe WN_Pipe hw_conduit HW_Conduit hw_pipe HW_Pipe].each do |t|
    begin
      r = net.row_objects(t)
      return [t, r] if r && r.length > 0
    rescue
    end
  end
  nil
end

# ---------- main ----------
net = WSApplication.current_network
picked = pick_table(net)
raise "No pipe table found" if picked.nil?
ltable, all = picked

sels = []
begin
  all.each { |r| sels << r.id if r.selected }
rescue
end
use = sels.any? ? all.select { |r| sels.include?(r.id) } : all
raise "No links to process (selection empty?)" if use.empty?

links  = []
geoms  = []
usvals = []
dsvals = []
diams  = []

use.each do |l|
  inv = pipe_inverts(l)
  g   = build_polyline(l)
  next if inv.nil? || g.nil?
  links  << l
  geoms  << g
  usvals << inv[0]
  dsvals << inv[1]
  diams  << diameter_m(l)
end

n = links.size
raise "No valid pipes" if n == 0

res   = []
total = n * (n - 1) / 2
done  = 0

(0...n).each do |i|
  l1   = links[i]
  g1   = geoms[i]
  us1  = usvals[i]
  ds1  = dsvals[i]
  d1   = diams[i]
  segs1 = g1[:segments]
  lens1 = g1[:seg_lengths]
  cum1  = g1[:cum_lengths]
  tot1  = g1[:total_len]
  b1    = g1[:bbox]

  ((i + 1)...n).each do |j|
    l2   = links[j]
    g2   = geoms[j]
    us2  = usvals[j]
    ds2  = dsvals[j]
    d2   = diams[j]
    b2   = g2[:bbox]

    unless bbox_overlap?(b1, b2)
      done += 1
      next
    end

    unless INCLUDE_SHARED_NODES
      if ([l1.us_node_id, l1.ds_node_id] & [l2.us_node_id, l2.ds_node_id]).any?
        done += 1
        next
      end
    end

    best = nil

    segs1.each_with_index do |s1, k|
      g2[:segments].each_with_index do |s2, m|
        ok, t, u, x, y = seg_inter(s1[0], s1[1], s2[0], s2[1])
        next unless ok

        r1 = (cum1[k] + t * lens1[k]) / tot1
        r2 = (g2[:cum_lengths][m] + u * g2[:seg_lengths][m]) / g2[:total_len]

        inv1 = pipe_level_at_param(us1, ds1, r1)
        inv2 = pipe_level_at_param(us2, ds2, r2)

        # clearance = IL_upper - (IL_lower + Diameter_lower)
        if inv1 >= inv2
          clearance = inv1 - (inv2 + d2)
        else
          clearance = inv2 - (inv1 + d1)
        end

        if clearance <= MIN_CLR + VERT_TOL
          best = { l1: l1.id, l2: l2.id, clr: clearance, x: x, y: y } if best.nil? || clearance < best[:clr]
        end
      end
    end

    res << best if best
    done += 1
  end
end

# ---------- console output ----------
if OUTPUT_TO_CONSOLE
  puts ""
  puts "=== CLASH DETECTION RESULTS ==="
  puts "Minimum clearance threshold: #{MIN_CLR} m"
  puts "Clashes found: #{res.size}"
  puts ""
  
  if res.any?
    # Calculate column widths for alignment
    max_l1 = res.map { |r| r[:l1].to_s.length }.max
    max_l2 = res.map { |r| r[:l2].to_s.length }.max
    max_l1 = [max_l1, 8].max  # minimum width for "Link 1"
    max_l2 = [max_l2, 8].max  # minimum width for "Link 2"
    
    # Header
    header = sprintf("%-4s  %-#{max_l1}s  %-#{max_l2}s  %12s  %14s  %14s",
                     "#", "Link 1", "Link 2", "Clearance(m)", "X", "Y")
    puts header
    puts "-" * header.length
    
    # Data rows
    res.each_with_index do |r, i|
      puts sprintf("%-4d  %-#{max_l1}s  %-#{max_l2}s  %12.4f  %14.2f  %14.2f",
                   i + 1, r[:l1], r[:l2], r[:clr], r[:x], r[:y])
    end
    puts ""
  end
end

# ---------- selection + CSV ----------
if res.any?
  net.transaction_begin
  begin
    # selection
    ids = res.flat_map { |r| [r[:l1], r[:l2]] }.uniq
    begin
      sel = Selection.new
      ids.each { |id| sel.add(ltable, id) }
      sel.commit("Clash_#{Time.now.to_i}")
    rescue
      net.clear_selection rescue nil
      ids.each do |id|
        begin
          ro = net.row_object(ltable, id)
          ro.selected = true rescue nil
          ro.write     rescue nil
        rescue
        end
      end
    end

    net.transaction_commit
  rescue
    net.transaction_rollback rescue nil
    raise
  end

  # CSV export
  if EXPORT_CSV
    begin
      require 'tmpdir'
      path = File.join(Dir.tmpdir, "clash_detection_#{Time.now.to_i}.csv")
      File.open(path, "w") do |f|
        f.puts "link1,link2,clearance_m,x,y"
        res.each do |r|
          f.puts "#{r[:l1]},#{r[:l2]},#{sprintf('%.6f', r[:clr])},#{r[:x]},#{r[:y]}"
        end
      end
      puts "CSV saved: #{path}" if OUTPUT_TO_CONSOLE
    rescue => e
      puts "CSV export failed: #{e.message}" if OUTPUT_TO_CONSOLE
    end
  end
end
