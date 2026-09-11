require 'csv'

# Use the active network
net = WSApplication.current_network

if net.nil?
  puts 'Error: No active network. Open a Collection Network and retry.'
  exit
end

# Capture active network ID and Name for deep links and filenames
active_network_id = nil
active_network_name = nil
begin
  mo = net.model_object rescue nil
  if mo
    begin active_network_id = mo.id rescue nil end
    begin active_network_name = mo.name rescue nil end
  end
rescue
end
if active_network_name.nil? || active_network_name.to_s.strip == ''
  begin
    active_network_name = net.network_name if net.respond_to?(:network_name)
  rescue
    active_network_name = nil
  end
end
active_network_name ||= 'ActiveNetwork'
puts "Active network: #{active_network_name} (ID: #{active_network_id || 'unknown'})"

# Load EPSG entries from CSV (optional; fallback list used if missing)
epsg_csv = 'C:/temp/ESPG.csv'
epsg_entries = []
begin
  if File.exist?(epsg_csv)
    CSV.foreach(epsg_csv, headers: true) do |row|
      code = (row['epsg_code'] || row['EPSG_CODE'] || row[0]).to_s.strip
      name = (row['name'] || row['NAME'] || row[1]).to_s.strip
      next if code.empty?
      label = name.empty? ? "EPSG:#{code}" : "EPSG:#{code} - #{name}"
      epsg_entries << { code: code, name: name, label: label }
    end
  end
rescue => e
  puts "Warning: failed to read #{epsg_csv}: #{e.message}"
end

# Fallback entries if CSV missing/empty
if epsg_entries.empty?
  fallback = [
    ['31370', 'Belge 1972 / Belgian Lambert 72'],
    ['29902', 'Irish Grid (TM65)'],
    ['27700', 'British National Grid (OSGB36)'],
    ['3857', 'Web Mercator'],
    ['4326', 'WGS84 (lon/lat)']
  ]
  epsg_entries = fallback.map { |code, name| { code: code, name: name, label: "EPSG:#{code} - #{name}" } }
end

def extract_epsg_code(selection)
  return '' if selection.nil?
  m = selection.to_s.upcase.sub(/^EPSG:/, '')
  code = m[/\d{3,6}/]
  code.to_s.strip
end

epsg_choices = epsg_entries.map { |e| e[:label] }
default_epsg_choice = epsg_choices.find { |s| s =~ /EPSG:\s*31370\b/i } ||
                      epsg_choices.find { |s| s =~ /EPSG:\s*29902\b/i } ||
                      epsg_choices.first

# Prompt for parameters
server_address = 'localhost'
iao_workspace = ''
chosen_epsg_label = default_epsg_choice
output_dir_ui = ''
process_selection_only = false
begin
  val = WSApplication.prompt 'InfoAsset Online URL and Projection Parameters',
  [
    ['The IAO Server Address', 'String', 'localhost'],
    ['The IAO Workspace ID', 'String', ''],
    ['Coordinate System', 'String', chosen_epsg_label, nil, 'LIST', epsg_choices],
    ['HTML output folder (optional):', 'String', '', nil, 'FOLDER', 'Output folder'],
    ['Process SELECTION only?', 'Boolean', false]
  ], false
  if !val.nil?
    server_address = (val[0] || '').to_s.strip
    iao_workspace = (val[1] || '').to_s.strip
    chosen_epsg_label = (val[2] || '').to_s.strip
    output_dir_ui = (val[3] || '').to_s.strip
    process_selection_only = val[4] ? true : false
  else
    WSApplication.message_box("Parameters dialog closed\nScript cancelled", 'OK', '!', nil) rescue nil
    abort('Invalid parameters.')
  end
rescue
end
host_for_url = server_address.to_s.strip.downcase
write_html = !output_dir_ui.to_s.strip.empty?

epsg_input = extract_epsg_code(chosen_epsg_label)
epsg_input = '31370' if epsg_input.empty?

# Utilities
def deg_to_rad(d) d * Math::PI / 180.0 end
def rad_to_deg(r) r * 180.0 / Math::PI end

def safe_to_f(value)
  return nil if value.nil?
  return value.to_f if value.is_a?(Numeric)
  if value.is_a?(String)
    s = value.strip
    return nil if s.empty?
    return s.to_f
  end
  nil
rescue
  nil
end

def point_xy_from_entry(entry)
  return nil if entry.nil?

  begin
    if entry.respond_to?(:[])
      x = safe_to_f(entry['x'])
      y = safe_to_f(entry['y'])
      return [x, y] if x && y
    end
  rescue
  end

  begin
    if entry.respond_to?(:x) && entry.respond_to?(:y)
      x = safe_to_f(entry.x)
      y = safe_to_f(entry.y)
      return [x, y] if x && y
    end
  rescue
  end

  nil
end

def point_array_to_xy_pairs(pa)
  return [] if pa.nil? || !pa.respond_to?(:length) || pa.length < 1

  pairs = []
  pa.each do |entry|
    xy = point_xy_from_entry(entry)
    pairs << xy if xy && xy[0] && xy[1]
  end
  return pairs if pairs.length >= 2

  pairs = []
  i = 0
  while i + 1 < pa.length
    x = safe_to_f(pa[i])
    y = safe_to_f(pa[i + 1])
    pairs << [x, y] if x && y
    i += 2
  end
  pairs
end

def detect_geometry_type(net, table_name, selection_only = false)
  sample = nil
  begin
    if selection_only
      sel = net.row_objects_selection(table_name)
      sample = sel.first if sel
    end
    sample ||= net.row_objects(table_name).first
  rescue
    sample = nil
  end
  return 'unknown' if sample.nil?
  begin
    pa = sample.point_array
    pts = point_array_to_xy_pairs(pa)
    if pts.length >= 2
      fx, fy = pts.first
      lx, ly = pts.last
      eps = 1e-6
      return 'polygon' if (fx - lx).abs < eps && (fy - ly).abs < eps
      return 'line'
    end
  rescue
  end
  begin
    x = safe_to_f(sample.x)
    y = safe_to_f(sample.y)
    return 'point' if x && y
  rescue
  end
  begin
    return 'line' if sample.respond_to?(:us_node) || sample.respond_to?(:ds_node) || sample.respond_to?(:us_node_id) || sample.respond_to?(:ds_node_id)
  rescue
  end
  'unknown'
end

def compute_center_line(obj)
  begin
    pa = obj.point_array
  rescue NoMethodError
    pa = nil
  end
  pts = point_array_to_xy_pairs(pa)
  if pts.length >= 2
    total_len = 0.0
    (0...(pts.length - 1)).each do |i|
      dx = pts[i + 1][0] - pts[i][0]
      dy = pts[i + 1][1] - pts[i][1]
      total_len += Math.hypot(dx, dy)
    end
    target = total_len / 2.0
    accum = 0.0
    cx = pts[0][0]; cy = pts[0][1]
    (0...(pts.length - 1)).each do |i|
      x1 = pts[i][0]; y1 = pts[i][1]
      x2 = pts[i + 1][0]; y2 = pts[i + 1][1]
      dx = x2 - x1; dy = y2 - y1
      seg = Math.hypot(dx, dy)
      if accum + seg >= target && seg > 0
        t = (target - accum) / seg
        cx = x1 + t * dx
        cy = y1 + t * dy
        break
      end
      accum += seg
    end
    return [cx, cy]
  end
  begin
    usn = obj.us_node rescue nil
    dsn = obj.ds_node rescue nil
    if usn && dsn
      ux = safe_to_f(usn.x); uy = safe_to_f(usn.y)
      dx = safe_to_f(dsn.x); dy = safe_to_f(dsn.y)
      return [(ux + dx) / 2.0, (uy + dy) / 2.0] if ux && uy && dx && dy
    end
  rescue
  end
  [nil, nil]
end

def compute_center_point(obj)
  begin
    x = safe_to_f(obj.x)
    y = safe_to_f(obj.y)
    return [x, y] if x && y
  rescue NoMethodError
  end
  [nil, nil]
end

def compute_center_polygon(obj)
  begin
    pa = obj.point_array
  rescue NoMethodError
    pa = nil
  end
  pts = point_array_to_xy_pairs(pa)
  return [nil, nil] if pts.length < 3
  fx, fy = pts.first; lx, ly = pts.last
  pts = pts + [[fx, fy]] if fx != lx || fy != ly
  a = 0.0; cx = 0.0; cy = 0.0
  (0...(pts.length - 1)).each do |i|
    x0, y0 = pts[i]; x1, y1 = pts[i + 1]
    cross = x0 * y1 - x1 * y0
    a += cross
    cx += (x0 + x1) * cross
    cy += (y0 + y1) * cross
  end
  a *= 0.5
  if a.abs < 1e-12
    sx = 0.0; sy = 0.0
    (0...(pts.length - 1)).each do |i|
      sx += pts[i][0]; sy += pts[i][1]
    end
    n = pts.length - 1
    return [sx / n, sy / n]
  end
  [cx / (6.0 * a), cy / (6.0 * a)]
end

# Belgian Lambert 72 (EPSG:31370) to WGS84 via inverse Lambert conic and Helmert transform
def lambert72_to_wgs84(x, y)
  a = 6378388.0
  f = 1.0 / 297.0
  b = a * (1.0 - f)
  e = Math.sqrt((a**2 - b**2) / a**2)

  lat1 = 51.16666723333333 * Math::PI / 180.0
  lat2 = 49.8333339 * Math::PI / 180.0
  lat0 = 90.0 * Math::PI / 180.0
  lon0 = 4.367486666666666 * Math::PI / 180.0

  x0 = 150000.013
  y0 = 5400088.438

  m1 = Math.cos(lat1) / Math.sqrt(1.0 - (e**2) * (Math.sin(lat1)**2))
  m2 = Math.cos(lat2) / Math.sqrt(1.0 - (e**2) * (Math.sin(lat2)**2))

  t0 = Math.tan(Math::PI / 4.0 - lat0 / 2.0) / (((1.0 - e * Math.sin(lat0)) / (1.0 + e * Math.sin(lat0)))**(e / 2.0))
  t1 = Math.tan(Math::PI / 4.0 - lat1 / 2.0) / (((1.0 - e * Math.sin(lat1)) / (1.0 + e * Math.sin(lat1)))**(e / 2.0))
  t2 = Math.tan(Math::PI / 4.0 - lat2 / 2.0) / (((1.0 - e * Math.sin(lat2)) / (1.0 + e * Math.sin(lat2)))**(e / 2.0))

  n = Math.log(m1 / m2) / Math.log(t1 / t2)
  f_proj = m1 / (n * (t1**n))
  rho0 = a * f_proj * (t0**n)

  dx = x.to_f - x0
  dy = rho0 - (y.to_f - y0)
  rho = Math.sqrt(dx**2 + dy**2)

  if n < 0
    rho = -rho
    dx = -dx
    dy = -dy
  end

  theta = Math.atan2(dx, dy)
  lon_bd72 = lon0 + theta / n
  t = (rho / (a * f_proj))**(1.0 / n)

  lat_bd72 = Math::PI / 2.0 - 2.0 * Math.atan(t)

  5.times do
    con = e * Math.sin(lat_bd72)
    lat_bd72 = Math::PI / 2.0 - 2.0 * Math.atan(
      t * (((1.0 - con) / (1.0 + con))**(e / 2.0))
    )
  end

  n_radius = a / Math.sqrt(1.0 - e**2 * Math.sin(lat_bd72)**2)

  x_ecef = n_radius * Math.cos(lat_bd72) * Math.cos(lon_bd72)
  y_ecef = n_radius * Math.cos(lat_bd72) * Math.sin(lon_bd72)
  z_ecef = n_radius * (1.0 - e**2) * Math.sin(lat_bd72)

  dx_h = -106.8686
  dy_h = 52.2978
  dz_h = -103.7239

  rx = (0.3366 / 3600.0) * Math::PI / 180.0
  ry = (-0.457 / 3600.0) * Math::PI / 180.0
  rz = (1.8422 / 3600.0) * Math::PI / 180.0

  scale = 1.0 + (-1.2747 / 1000000.0)

  x_wgs = dx_h + scale * (x_ecef - rz * y_ecef + ry * z_ecef)
  y_wgs = dy_h + scale * (rz * x_ecef + y_ecef - rx * z_ecef)
  z_wgs = dz_h + scale * (-ry * x_ecef + rx * y_ecef + z_ecef)

  a_w = 6378137.0
  f_w = 1.0 / 298.257223563
  b_w = a_w * (1.0 - f_w)

  e_w = Math.sqrt((a_w**2 - b_w**2) / a_w**2)
  e_prime_w = Math.sqrt((a_w**2 - b_w**2) / b_w**2)

  p = Math.sqrt(x_wgs**2 + y_wgs**2)
  theta_w = Math.atan2(z_wgs * a_w, p * b_w)

  lat_wgs84 = Math.atan2(
    z_wgs + (e_prime_w**2) * b_w * (Math.sin(theta_w)**3),
    p - (e_w**2) * a_w * (Math.cos(theta_w)**3)
  )

  lon_wgs84 = Math.atan2(y_wgs, x_wgs)

  [lat_wgs84 * 180.0 / Math::PI, lon_wgs84 * 180.0 / Math::PI]
end

def to_wgs84_from_epsg(x, y, epsg_code)
  code = epsg_code.to_s.strip.upcase
  code = code.sub(/^EPSG:/, '')
  case code
  when '31370' # Belge 1972 / Belgian Lambert 72
    return lambert72_to_wgs84(x, y)
  when '29902' # Irish Grid TM65
    a = 6377340.189; b = 6356034.447; lat0 = 53.5; lon0 = -8.0; k0 = 1.000035; fe = 200000.0; fn = 250000.0
    lat_tm65, lon_tm65 = tmerc_inverse_to_geodetic(x, y, a, b, lat0, lon0, k0, fe, fn)
    dx, dy, dz = 482.5, -130.6, 564.6; rx, ry, rz = -1.042, -0.214, -0.631; s_ppm = 8.15
    lat_wgs, lon_wgs = helmert_to_wgs84(lat_tm65, lon_tm65, 0.0, a, b, dx, dy, dz, rx, ry, rz, s_ppm)
    return [rad_to_deg(lat_wgs), rad_to_deg(lon_wgs)]
  when '27700' # British National Grid OSGB36
    a = 6377563.396; b = 6356256.909; lat0 = 49.0; lon0 = -2.0; k0 = 0.9996012717; fe = 400000.0; fn = -100000.0
    lat_osgb, lon_osgb = tmerc_inverse_to_geodetic(x, y, a, b, lat0, lon0, k0, fe, fn)
    dx, dy, dz = 446.448, -125.157, 542.06; rx, ry, rz = 0.1502, 0.2470, 0.8421; s_ppm = -20.4894
    lat_wgs, lon_wgs = helmert_to_wgs84(lat_osgb, lon_osgb, 0.0, a, b, dx, dy, dz, rx, ry, rz, s_ppm)
    return [rad_to_deg(lat_wgs), rad_to_deg(lon_wgs)]
  when '3857'
    r = 6378137.0
    lon = x / r; lat = 2.0 * Math.atan(Math.exp(y / r)) - Math::PI / 2.0
    return [rad_to_deg(lat), rad_to_deg(lon)]
  when '4326'
    return [y.to_f, x.to_f]
  else
    raise "Unsupported EPSG code: #{epsg_code}"
  end
end

def tmerc_inverse_to_geodetic(easting, northing, a, b, lat0_deg, lon0_deg, k0, fe, fn)
  lat0 = deg_to_rad(lat0_deg); lon0 = deg_to_rad(lon0_deg)
  e2 = (a * a - b * b) / (a * a); n_ab = (a - b) / (a + b)
  target = northing - fn; phi = lat0 + target / (a * k0)
  compute_m = lambda do |phi_arg|
    a0 = b * k0 * (1.0 + n_ab + (5.0 / 4.0) * n_ab ** 2 + (5.0 / 4.0) * n_ab ** 3)
    b0 = b * k0 * (3.0 * n_ab + 3.0 * n_ab ** 2 + (21.0 / 8.0) * n_ab ** 3)
    c0 = b * k0 * ((15.0 / 8.0) * n_ab ** 2 + (15.0 / 8.0) * n_ab ** 3)
    d0 = b * k0 * ((35.0 / 24.0) * n_ab ** 3); dphi = phi_arg - lat0
    a0 * dphi - b0 * Math.sin(dphi) * Math.cos(phi_arg + lat0) + c0 * Math.sin(2.0 * dphi) * Math.cos(2.0 * (phi_arg + lat0)) - d0 * Math.sin(3.0 * dphi) * Math.cos(3.0 * (phi_arg + lat0))
  end
  10.times do
    m = compute_m.call(phi); phi_next = phi + (target - m) / (a * k0); break if (phi_next - phi).abs < 1e-12; phi = phi_next
  end
  m = compute_m.call(phi); nu = a * k0 / Math.sqrt(1.0 - e2 * Math.sin(phi) ** 2)
  rho = a * k0 * (1.0 - e2) / (1.0 - e2 * Math.sin(phi) ** 2) ** 1.5; eta2 = nu / rho - 1.0
  de = easting - fe; tan_phi = Math.tan(phi); sec_phi = 1.0 / Math.cos(phi)
  vii = tan_phi / (2.0 * rho * nu)
  viii = tan_phi / (24.0 * rho * nu ** 3) * (5.0 + 3.0 * tan_phi ** 2 + eta2 - 9.0 * tan_phi ** 2 * eta2)
  ix = tan_phi / (720.0 * rho * nu ** 5) * (61.0 + 90.0 * tan_phi ** 2 + 45.0 * tan_phi ** 4)
  x = sec_phi / nu; xi = sec_phi / (6.0 * nu ** 3) * (nu / rho + 2.0 * tan_phi ** 2)
  xii = sec_phi / (120.0 * nu ** 5) * (5.0 + 28.0 * tan_phi ** 2 + 24.0 * tan_phi ** 4)
  lat = phi - vii * de ** 2 + viii * de ** 4 - ix * de ** 6; lon = lon0 + x * de - xi * de ** 3 + xii * de ** 5
  [lat, lon]
end

def helmert_to_wgs84(lat_src, lon_src, h, a_src, b_src, dx, dy, dz, rx_sec, ry_sec, rz_sec, s_ppm)
  e2_src = (a_src * a_src - b_src * b_src) / (a_src * a_src)
  sin_phi = Math.sin(lat_src); cos_phi = Math.cos(lat_src)
  sin_lam = Math.sin(lon_src); cos_lam = Math.cos(lon_src)
  nu = a_src / Math.sqrt(1.0 - e2_src * Math.sin(lat_src) ** 2)
  x1 = (nu + h) * cos_phi * cos_lam; y1 = (nu + h) * cos_phi * sin_lam; z1 = ((1.0 - e2_src) * nu + h) * sin_phi
  rx = deg_to_rad(rx_sec / 3600.0); ry = deg_to_rad(ry_sec / 3600.0); rz = deg_to_rad(rz_sec / 3600.0); s = s_ppm * 1e-6
  x2 = dx + (1.0 + s) * x1 + (-rz) * y1 + (ry) * z1
  y2 = dy + (rz) * x1 + (1.0 + s) * y1 + (-rx) * z1
  z2 = dz + (-ry) * x1 + (rx) * y1 + (1.0 + s) * z1
  a_wgs = 6378137.0; b_wgs = 6356752.314245; e2_wgs = (a_wgs * a_wgs - b_wgs * b_wgs) / (a_wgs * a_wgs)
  p = Math.sqrt(x2 * x2 + y2 * y2); lat = Math.atan2(z2, p * (1.0 - e2_wgs))
  10.times do
    nu_w = a_wgs / Math.sqrt(1.0 - e2_wgs * Math.sin(lat) ** 2); lat_next = Math.atan2(z2 + e2_wgs * nu_w * Math.sin(lat), p)
    break if (lat_next - lat).abs < 1e-12; lat = lat_next
  end
  lon = Math.atan2(y2, x2); [lat, lon]
end

def double_url_encode_iao(str)
  str.to_s
     .gsub('%', '%2525')
     .gsub('|', '%25257C')
     .gsub('=', '%25253D')
     .gsub('/', '%252F')
     .gsub('?', '%253F')
     .gsub('&', '%2526')
     .gsub('#', '%2523')
     .gsub('+', '%252B')
     .gsub(' ', '%2520')
end

def build_active_object_suffix(network_id, table_name, object_id)
  return '' if network_id.nil? || table_name.to_s.empty? || object_id.to_s.empty?
  encoded_id = double_url_encode_iao(object_id)
  "/activeObject;uri=mo%252Fcnn%252Fcnn.#{network_id}%252Fro%253Ftable%253D#{table_name}&id%253D#{encoded_id}"
end

# Determine timestamp and safe names for optional HTML export
ts = Time.now.strftime('%Y%m%d_%H%M%S')
safe_net_name = active_network_name.gsub(/[^0-9A-Za-z_ -]/, '_').gsub(/[ ]+/, '_')

# Iterate all IAM tables
tables = []
begin
  tables = net.table_names.select { |t| t.start_with?('cams_') }
rescue
  tables = []
end

header = ['object_id', 'center_x', 'center_y', 'latitude', 'longitude', 'url']

# Collect per-table rows for optional combined HTML export
per_table_rows = []
processed_count = 0

puts "Processing mode: #{process_selection_only ? 'selection only' : 'all objects'}"

net.transaction_begin
begin
  tables.each do |table|
    geom_type = detect_geometry_type(net, table, process_selection_only)
    rows = []

    begin
      objs = process_selection_only ? net.row_objects_selection(table) : net.row_objects(table)
      next if objs.nil?

      table_count = 0
      objs.each do |o|
        begin
          display_id = nil
          begin
            us_id = o.us_node_id rescue nil
            ds_id = o.ds_node_id rescue nil
            link_suffix = o.link_suffix rescue nil
            if us_id || ds_id || link_suffix
              display_id = [us_id, ds_id, link_suffix].map { |v| v.to_s }.join('.')
            end
          rescue
          end
          display_id = o.id.to_s if display_id.nil? || display_id == '..'

          cx, cy = nil, nil
          case geom_type
          when 'line' then cx, cy = compute_center_line(o)
          when 'point' then cx, cy = compute_center_point(o)
          when 'polygon' then cx, cy = compute_center_polygon(o)
          else
            cx, cy = compute_center_point(o)
            cx, cy = compute_center_line(o) if cx.nil? || cy.nil?
            cx, cy = compute_center_polygon(o) if cx.nil? || cy.nil?
          end

          lat, lon = nil, nil
          if cx && cy
            begin
              lat, lon = to_wgs84_from_epsg(cx.to_f, cy.to_f, epsg_input)
            rescue => conv_e
              puts "Warning: conversion failed for #{display_id} (#{table}) (EPSG:#{epsg_input}): #{conv_e.message}"
            end
          end

          url = nil
          if lat && lon && !host_for_url.empty? && !iao_workspace.to_s.empty?
            lat_str = format('%.5f', lat)
            lon_str = format('%.5f', lon)
            base = "https://#{host_for_url}:30303/InfoAssetOnline/en-us/workspaces/webwsp.#{iao_workspace}#map;zoom=17.5;lat=#{lat_str};lon=#{lon_str}"
            suffix = build_active_object_suffix(active_network_id, table, display_id)
            url = base + suffix
          end

          rows << [display_id, cx, cy, lat, lon, url] if write_html

          if url
            begin
              hyperlinks = o.hyperlinks
              if hyperlinks
                idx = nil
                if hyperlinks.size > 0
                  (0...hyperlinks.size).each do |i|
                    desc = nil
                    begin desc = hyperlinks[i].description rescue nil end
                    if desc && desc.to_s.strip.downcase == 'iao url link'
                      idx = i
                      break
                    end
                  end
                end
                if idx.nil?
                  n = hyperlinks.length
                  hyperlinks.length = n + 1
                  idx = n
                end
                hyperlinks[idx].description = 'IAO url Link'
                hyperlinks[idx].url = url
                hyperlinks.write
                o.write
              end
            rescue => eh
              puts "Warning: failed to update hyperlinks for #{table} object #{display_id}: #{eh.message}"
            end
          end
        rescue => obj_e
          obj_id = o.id rescue 'unknown'
          puts "Warning: skipped #{table} object #{obj_id}: #{obj_e.message}"
        end
        table_count += 1
      end

      next if process_selection_only && table_count == 0

      processed_count += table_count
      per_table_rows << { table: table, geom: geom_type, rows: rows } if write_html && !rows.empty?
    rescue => e
      puts "Error processing table #{table}: #{e.message}"
    end
  end
  net.transaction_commit
rescue => e
  net.transaction_rollback rescue nil
  puts "Error: transaction rolled back: #{e.message}"
  raise
end

# Optional combined HTML export
if write_html && !per_table_rows.empty?
  begin
    aggregated_html = File.join(output_dir_ui, "#{safe_net_name}(#{active_network_id || 'unknown'})_ALL_IAO(#{iao_workspace})#{ts}.html")
    File.open(aggregated_html, 'w') do |f|
    f.puts '<!DOCTYPE html>'
    f.puts '<html lang="en">'
    f.puts '<head>'
    f.puts '  <meta charset="UTF-8">'
    f.puts '  <meta name="viewport" content="width=device-width, initial-scale=1.0">'
    f.puts "  <title>#{safe_net_name}(#{active_network_id || 'unknown'})_ALL_IAO(#{iao_workspace})#{ts}</title>"
    f.puts '  <style>'
    f.puts '    body{font-family:Arial,Helvetica,sans-serif}'
    f.puts '    .tabs{display:block;margin:0 0 8px 0}'
    f.puts '    .tabs-nav{display:flex;gap:8px;align-items:flex-end;border-bottom:1px solid #ccc}'
    f.puts '    .tabs-nav label{padding:8px 12px;border:1px solid #ccc;border-bottom:none;background:#f5f5f5;cursor:pointer;border-radius:4px 4px 0 0;display:inline-block}'
    f.puts '    input[type=radio]{display:none}'
    f.puts '    .panels{border:1px solid #ccc;border-top:none;border-radius:0 4px 4px 4px}'
    f.puts '    .tab-panel{display:none;padding:8px}'
    f.puts '    table{border-collapse:collapse;width:100%}'
    f.puts '    th,td{border:1px solid #ccc;padding:6px 8px;text-align:left}'
    f.puts '    th{background:#f5f5f5}'
    f.puts '    a{color:#06c;text-decoration:none}'
    per_table_rows.each_with_index do |t, idx|
      tab_id = "tab_#{idx}"
      f.puts "    ##{tab_id}:checked ~ .tabs-nav label[for=\"#{tab_id}\"]{background:#fff;border-bottom:1px solid #fff}"
      f.puts "    ##{tab_id}:checked ~ .panels #panel_#{tab_id}{display:block}"
    end
    f.puts '  </style>'
    f.puts '</head>'
    f.puts '<body>'
    f.puts '  <h1>InfoAsset Online Links</h1>'
    f.puts "  <p>Network: #{active_network_name} (ID: #{active_network_id || 'unknown'}) &middot; EPSG: #{epsg_input} &middot; Workspace: #{iao_workspace} &middot; Server: #{host_for_url}</p>"

    f.puts '  <div class="tabs">'
    per_table_rows.each_with_index do |t, idx|
      tab_id = "tab_#{idx}"
      checked = idx == 0 ? ' checked' : ''
      f.puts "    <input type=\"radio\" name=\"tabs\" id=\"#{tab_id}\"#{checked}>"
    end
    f.puts '    <div class="tabs-nav">'
    per_table_rows.each_with_index do |t, idx|
      tab_id = "tab_#{idx}"
      label = "#{t[:table]} (#{t[:geom]})"
      f.puts "      <label for=\"#{tab_id}\">#{label}</label>"
    end
    f.puts '    </div>'
    f.puts '    <div class="panels">'
    per_table_rows.each_with_index do |t, idx|
      tab_id = "tab_#{idx}"
      f.puts "      <div class=\"tab-panel\" id=\"panel_#{tab_id}\">"
      f.puts '        <table><thead><tr>'
      header.each { |h| f.puts "          <th>#{h}</th>" }
      f.puts '        </tr></thead><tbody>'
      t[:rows].each do |r|
        f.puts '          <tr>'
        f.puts "            <td>#{r[0]}</td><td>#{r[1]}</td><td>#{r[2]}</td><td>#{r[3]}</td><td>#{r[4]}</td>"
        if r[5] && r[5].to_s.strip != ''
          f.puts "            <td><a href=\"#{r[5]}\" target=\"_blank\" rel=\"noopener noreferrer\">Open</a></td>"
        else
          f.puts "            <td></td>"
        end
        f.puts '          </tr>'
      end
      f.puts '        </tbody></table>'
      f.puts '      </div>'
    end
    f.puts '    </div>'
    f.puts '  </div>'

    f.puts '</body></html>'
    end
    puts "HTML written to: #{aggregated_html}"
  rescue => e
    puts "Error writing HTML: #{e.message}"
  end
elsif write_html
  puts 'No object data found; HTML file not created.'
end

if process_selection_only && processed_count == 0
  puts 'No selected objects were found in any cams_* table.'
else
  puts "Processed #{processed_count} object(s)."
end
