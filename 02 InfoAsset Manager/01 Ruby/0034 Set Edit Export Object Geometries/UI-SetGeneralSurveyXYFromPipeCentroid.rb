# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-SetGeneralSurveyXYFromPipeCentroid.rb
# Purpose: Set X and Y coordinate fields on General Survey point objects from
#          the centroid of a related Pipe's polyline geometry (point_array).
#
# Run from: Network > Run Ruby Script (Collection network open)
# ============================================================================

SURVEY_TABLE = 'cams_general_survey'
PIPE_TABLE = 'cams_pipe'

ASSET_TYPE_PIPE = {
  'cams_pipe' => PIPE_TABLE,
  'pipe' => PIPE_TABLE
}.freeze

UPDATE_MODES = ['Fill blanks only', 'Overwrite existing'].freeze

def non_blank?(value)
  !value.nil? && !value.to_s.strip.empty?
end

def safe_to_f(value)
  return nil if value.nil?
  return value.to_f if value.is_a?(Numeric)

  if value.is_a?(String)
    s = value.strip
    return nil if s.empty?
    return s.to_f
  end

  nil
rescue StandardError
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
  rescue StandardError
  end

  begin
    if entry.respond_to?(:x) && entry.respond_to?(:y)
      x = safe_to_f(entry.x)
      y = safe_to_f(entry.y)
      return [x, y] if x && y
    end
  rescue StandardError
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

# Centroid of a uniform polyline: the point at half the total arc length
# (including intermediate vertices from point_array).
def polyline_centroid_xy(pts)
  return [nil, nil] if pts.nil? || pts.length < 2

  total_len = 0.0
  (0...(pts.length - 1)).each do |i|
    dx = pts[i + 1][0] - pts[i][0]
    dy = pts[i + 1][1] - pts[i][1]
    total_len += Math.hypot(dx, dy)
  end

  return [pts[0][0], pts[0][1]] if total_len <= 0.0

  target = total_len / 2.0
  accum = 0.0
  cx = pts[0][0]
  cy = pts[0][1]

  (0...(pts.length - 1)).each do |i|
    x1 = pts[i][0]
    y1 = pts[i][1]
    x2 = pts[i + 1][0]
    y2 = pts[i + 1][1]
    dx = x2 - x1
    dy = y2 - y1
    seg = Math.hypot(dx, dy)
    next if seg <= 0.0

    if accum + seg >= target
      t = (target - accum) / seg
      cx = x1 + t * dx
      cy = y1 + t * dy
      break
    end
    accum += seg
  end

  [cx, cy]
end

def pipe_polyline_centroid(pipe)
  pts = point_array_to_xy_pairs(pipe.point_array)
  cx, cy = polyline_centroid_xy(pts)
  return [cx, cy] if cx && cy

  usn = pipe.us_node rescue nil
  dsn = pipe.ds_node rescue nil
  if usn && dsn
    ux = safe_to_f(usn.x)
    uy = safe_to_f(usn.y)
    dx = safe_to_f(dsn.x)
    dy = safe_to_f(dsn.y)
    return [(ux + dx) / 2.0, (uy + dy) / 2.0] if ux && uy && dx && dy
  end

  [nil, nil]
end

def find_pipe(net, pipe_id)
  id = pipe_id.to_s.strip
  return nil if id.empty?

  begin
    pipe = net.row_object(PIPE_TABLE, id)
    return pipe unless pipe.nil?
  rescue StandardError
  end

  begin
    matches = net.row_objects_from_asset_id(PIPE_TABLE, id)
    return matches.first if matches && !matches.empty?
  rescue StandardError
  end

  net.row_objects(PIPE_TABLE).each do |row|
    next if row.nil?
    return row if row.id.to_s.strip.casecmp?(id)
  end

  nil
end

def pipe_from_asset_fields(net, survey)
  return nil unless survey.respond_to?(:asset_type) && survey.respond_to?(:asset_id)
  return nil unless non_blank?(survey.asset_type) && non_blank?(survey.asset_id)

  table = ASSET_TYPE_PIPE[survey.asset_type.to_s.strip.downcase]
  table ||= ASSET_TYPE_PIPE[survey.asset_type.to_s.strip]
  return nil unless table == PIPE_TABLE

  find_pipe(net, survey.asset_id)
end

def pipe_from_link_fields(net, survey)
  return nil unless survey.respond_to?(:us_node_id) &&
                    survey.respond_to?(:ds_node_id) &&
                    survey.respond_to?(:link_suffix)
  return nil unless non_blank?(survey.us_node_id) && non_blank?(survey.ds_node_id)

  pipe_id = "#{survey.us_node_id}.#{survey.ds_node_id}.#{survey.link_suffix}"
  find_pipe(net, pipe_id)
end

def resolve_related_pipe(net, survey)
  begin
    pipe = survey.navigate1('pipe')
    return pipe unless pipe.nil?
  rescue StandardError
  end

  pipe_from_asset_fields(net, survey) || pipe_from_link_fields(net, survey)
end

def coordinates_blank?(survey)
  safe_to_f(survey.x).nil? || safe_to_f(survey.y).nil?
end

def coords_unchanged?(survey, new_x, new_y)
  old_x = safe_to_f(survey.x)
  old_y = safe_to_f(survey.y)
  return false if old_x.nil? || old_y.nil?

  eps = 1e-9
  (old_x - new_x).abs < eps && (old_y - new_y).abs < eps
end

def table_has_xy?(net, table_name)
  fields = net.table(table_name).fields.map { |f| f.name.downcase }
  fields.include?('x') && fields.include?('y')
rescue StandardError
  false
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net = WSApplication.current_network
if net.nil?
  WSApplication.message_box(
    "No open network found.\n\nOpen a Collection Network, then run via Network > Run Ruby Script.",
    'OK', '!', false
  )
  raise 'abort'
end

unless net.table(SURVEY_TABLE)
  WSApplication.message_box(
    "This network does not contain table '#{SURVEY_TABLE}'.",
    'OK', '!', false
  )
  raise 'abort'
end

unless table_has_xy?(net, SURVEY_TABLE)
  WSApplication.message_box(
    "Table '#{SURVEY_TABLE}' does not have X and Y coordinate fields.",
    'OK', '!', false
  )
  raise 'abort'
end

val = WSApplication.prompt(
  'Set General Survey X/Y from Pipe centroid',
  [
    ['Run on', 'String', 'Selected General Surveys', nil, 'LIST', ['Whole Network', 'Selected General Surveys']],
    ['Update mode', 'String', 'Fill blanks only', nil, 'LIST', UPDATE_MODES]
  ],
  false
)
raise 'abort' if val.nil?

use_selection = val[0] == 'Selected General Surveys'
fill_blanks_only = val[1] == 'Fill blanks only'

surveys = if use_selection
            net.row_objects_selection(SURVEY_TABLE)
          else
            net.row_objects(SURVEY_TABLE)
          end

if use_selection && (surveys.nil? || surveys.length == 0)
  WSApplication.message_box(
    'No General Survey objects are selected on the GeoPlan.',
    'OK', '!',
    false
  )
  raise 'abort'
end

updated = 0
skipped_no_pipe = 0
skipped_no_geometry = 0
skipped_has_coords = 0
skipped_unchanged = 0
errors = 0

net.transaction_begin
surveys.each do |survey|
  next if survey.nil?

  if fill_blanks_only && !coordinates_blank?(survey)
    skipped_has_coords += 1
    next
  end

  pipe = resolve_related_pipe(net, survey)
  if pipe.nil?
    skipped_no_pipe += 1
    puts "SKIP: Survey '#{survey.id}' - no related pipe (navigate, asset link, or link fields)."
    next
  end

  cx, cy = pipe_polyline_centroid(pipe)
  unless cx && cy
    skipped_no_geometry += 1
    puts "SKIP: Survey '#{survey.id}' - pipe '#{pipe.id}' has no usable polyline or node coordinates."
    next
  end

  if coords_unchanged?(survey, cx, cy)
    skipped_unchanged += 1
    next
  end

  begin
    survey.x = cx
    survey.y = cy
    survey.write
    updated += 1
    puts "OK: Survey '#{survey.id}' <- (#{cx}, #{cy}) from pipe '#{pipe.id}'"
  rescue StandardError => e
    errors += 1
    puts "ERROR: Survey '#{survey.id}' - #{e.message}"
  end
end
net.transaction_commit

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

summary = [
  "General Surveys processed: #{surveys.length}",
  "Updated: #{updated}",
  "Skipped (already have X/Y): #{skipped_has_coords}",
  "Skipped (no related pipe): #{skipped_no_pipe}",
  "Skipped (no pipe geometry): #{skipped_no_geometry}",
  "Skipped (coordinates unchanged): #{skipped_unchanged}",
  "Errors: #{errors}",
  '',
  "Time taken: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"
].join("\n")

puts "\n#{summary}"
WSApplication.message_box(summary, 'OK', 'Information', false)
