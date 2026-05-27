# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-GeojsonExporter_Selection_List_Group.rb
# Purpose: Export one Selection List (by numeric ID) to CSV (WGS84), then
#          convert cams_pipe and cams_manhole to GeoJSON.
# Run from: Network > Run Ruby Script (Collection Network open on GeoPlan)
# Output:   User is prompted to choose a folder; CSV/ and geoJSON/ subfolders
#           are created inside the chosen folder.
# ============================================================================

require 'date'
require 'csv'
require 'fileutils'

SCRIPT_DIR = File.expand_path(File.dirname(__FILE__)).freeze
EXPORT_OBJECT_TYPES = %w[cams_pipe cams_manhole].freeze

def report(message)
  puts message
end

def decode_iam_csv_text(csv_path)
  raw = File.binread(csv_path)
  raw = raw.byteslice(3..) if raw.bytesize >= 3 && raw.byteslice(0, 3) == "\xEF\xBB\xBF"

  %w[UTF-8 Windows-1252 ISO-8859-1].each do |source_encoding|
    begin
      text = raw.dup.force_encoding(source_encoding).encode('UTF-8')
      return text if text.valid_encoding?
    rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError
      next
    end
  end

  raw.dup.force_encoding('UTF-8').encode(
    'UTF-8',
    invalid: :replace,
    undef: :replace,
    replace: "\uFFFD"
  )
end

def each_iam_csv_row(csv_path)
  text = decode_iam_csv_text(csv_path)
  CSV.parse(text, headers: true, liberal_parsing: true).each do |row|
    yield row
  end
end

def json_escape_string(value)
  value.to_s
       .gsub('\\', '\\\\')
       .gsub('"', '\\"')
       .gsub("\r", '\\r')
       .gsub("\n", '\\n')
       .gsub("\t", '\\t')
end

def network_model_object(net)
  if net.respond_to?(:network_model_object) && !net.network_model_object.nil?
    return net.network_model_object
  end
  return net.model_object if net.respond_to?(:model_object) && !net.model_object.nil?

  nil
end

def network_display_name(net)
  mo = network_model_object(net)
  if mo && mo.respond_to?(:name) && !mo.name.to_s.strip.empty?
    return mo.name.to_s.strip
  end
  return net.name.to_s.strip if net.respond_to?(:name) && !net.name.to_s.strip.empty?

  'Network'
end

def network_identifier(net)
  mo = network_model_object(net)
  return mo.id.to_s if mo && mo.respond_to?(:id) && !mo.id.nil?

  network_display_name(net).gsub(/[^\w\-]+/, '_')
end

def collection_network?(net)
  mo = network_model_object(net)
  return nil if mo.nil? || !mo.respond_to?(:table_info) || mo.table_info.nil?

  mo.table_info.name.to_s == 'Collection Network'
end

def database_for_network(net)
  if net.respond_to?(:database)
    begin
      d = net.database
      return d unless d.nil?
    rescue StandardError
      nil
    end
  end

  if WSApplication.respond_to?(:current_database)
    begin
      return WSApplication.current_database
    rescue StandardError
      nil
    end
  end

  nil
end

def parse_selection_list_id(value)
  Integer(value.to_s.strip, 10)
rescue ArgumentError, TypeError
  nil
end

def resolve_selection_list(db, selection_list_id)
  return nil if db.nil?

  %w[Selection\ List Selection\ list].each do |type_name|
    begin
      mo = db.model_object_from_type_and_id(type_name, selection_list_id)
      return mo unless mo.nil?
    rescue StandardError
      nil
    end
  end

  nil
end

def selection_list_label(mo, selection_list_id)
  if mo && mo.respond_to?(:name) && !mo.name.to_s.strip.empty?
    return "#{mo.name} (ID #{selection_list_id})"
  end

  "Selection List ID #{selection_list_id}"
end

def prompt_selection_list_id
  unless WSApplication.respond_to?(:input_box)
    raise 'ERROR: WSApplication.input_box is not available. Run from InfoAsset Manager UI.'
  end

  value = WSApplication.input_box(
    'GeoJSON export - Selection List',
    'Enter the Selection List ID (numeric):',
    ''
  )
  return nil if value.nil? || value.to_s.strip.empty?

  value.to_s.strip
end

def pick_output_base_dir
  unless WSApplication.respond_to?(:folder_dialog)
    raise 'ERROR: WSApplication.folder_dialog is not available. Run from InfoAsset Manager UI.'
  end

  chosen = WSApplication.folder_dialog(
    'Select output folder (CSV/ and geoJSON/ subfolders will be created inside)',
    ''
  )

  return nil if chosen.nil? || chosen.to_s.strip.empty?

  File.expand_path(chosen.to_s.strip)
end

def csv_export_config
  config = {}
  config['Field Descriptions'] = true
  config['Multiple Files'] = true
  config['Object Types'] = true
  config['Coordinate Arrays Format'] = 'Packed'
  config['Units Text'] = true
  config['Other Arrays Format'] = 'None'
  config['Flag Fields'] = false
  config['User Units'] = false
  config['WGS84'] = true
  config['Selection Only'] = true
  config
end

def insert_string_value(row, id_csv, id_geojson)
  if row[id_csv].nil?
    return "\"#{id_geojson}\":  null, "
  end

  "\"#{id_geojson}\": \"" + json_escape_string(row[id_csv]) + '", '
end

def insert_num_value(row, id_csv, id_geojson)
  value = row[id_csv].to_s
  value = 'null' if row[id_csv].nil?
  "\"#{id_geojson}\": " + value + ', '
end

def insert_geometry_multi_line_string(row, id_csv)
  geo_string = '}, "geometry": { "type": "MultiLineString", "coordinates": [ [ '
  points_str = row[id_csv].to_s
  points_str = points_str.tr('{}', '')
  points = points_str.split(',')

  if points.length > 200
    report row['uid'] + ' - ERROR    ======================================= too many vertices, pipe will be truncated'
  end

  index = 0
  while index < points.length
    geo_string += '[ ' + points[index] + ', '
    index += 1
    geo_string += points[index] + ' ], '
    index += 1
    break if index > 4
  end

  geo_string = geo_string.chop
  geo_string = geo_string.chop
  geo_string += '] ]'

  geo_string
end

def insert_geometry_point(row)
  x_str = row['x'].to_s
  y_str = row['y'].to_s
  '}, "geometry": { "type": "Point", "coordinates": [ ' + x_str + ', ' + y_str + ' ]'
end

def convert_pipe_row(row)
  formatted_row = ''

  formatted_row += insert_string_value(row, 'owner', 'owner')
  formatted_row += insert_string_value(row, 'siteCondition', 'siteCondition')
  formatted_row += insert_string_value(row, 'location', 'location')

  if row['asset_id'].nil?
    formatted_row += insert_string_value(row, 'uid', 'plr')
  else
    formatted_row += insert_string_value(row, 'asset_id', 'plr')
  end

  formatted_row += insert_string_value(row, 'uid', 'segment_id')
  formatted_row += insert_string_value(row, 'us_node_id', 'us_node_id')
  formatted_row += insert_string_value(row, 'ds_node_id', 'ds_node_id')
  formatted_row += insert_string_value(row, 'pipe_mater', 'pipe_mater')
  formatted_row += insert_string_value(row, 'lining_mat', 'lining_mat')
  formatted_row += insert_string_value(row, 'lining_type', 'lining_type')
  formatted_row += insert_string_value(row, 'groundType', 'groundType')
  formatted_row += insert_string_value(row, 'accessRestrictions', 'accessRestrictions')
  formatted_row += insert_string_value(row, 'systemType', 'systemType')
  formatted_row += insert_string_value(row, 'security', 'security')
  formatted_row += insert_string_value(row, 'flowControl', 'flowControl')
  formatted_row += insert_string_value(row, 'drainageCode', 'drainageCode')
  formatted_row += insert_string_value(row, 'system_type', 'system_type')
  formatted_row += insert_string_value(row, 'pipe_type', 'pipe_type')
  formatted_row += insert_string_value(row, 'pipe_shape', 'pipe_shape')
  formatted_row += insert_string_value(row, 'year_laid', 'year_laid')

  formatted_row += insert_num_value(row, 'height', 'height')
  formatted_row += insert_num_value(row, 'length', 'length')
  formatted_row += insert_num_value(row, 'gradient', 'slope')
  formatted_row += insert_num_value(row, 'width', 'width')
  formatted_row += insert_num_value(row, 'us_invert', 'us_invert')
  formatted_row += insert_num_value(row, 'ds_invert', 'ds_invert')
  formatted_row += insert_num_value(row, 'capacity', 'capacity')
  formatted_row += insert_num_value(row, 'criticalit', 'criticalit')
  formatted_row += insert_num_value(row, 'usDepthFromCover', 'usDepthFromCover')
  formatted_row += insert_num_value(row, 'dsDepthFromCover', 'dsDepthFromCover')
  formatted_row += insert_num_value(row, 'backdropDiam', 'backdropDiam')
  formatted_row += insert_num_value(row, 'pressureValue', 'pressureValue')

  formatted_row = formatted_row.gsub('.,', '.0,')
  formatted_row = formatted_row.chop
  formatted_row = formatted_row.chop
  formatted_row + insert_geometry_multi_line_string(row, 'point_array')
end

def convert_manhole_row(row)
  formatted_row = ''

  formatted_row += insert_string_value(row, 'owner', 'owner')
  formatted_row += insert_string_value(row, 'location', 'location')
  formatted_row += insert_string_value(row, 'node_id', 'node_id')
  formatted_row += insert_string_value(row, 'system_type', 'system_typ')
  formatted_row += insert_string_value(row, 'node_type', 'node_type')
  formatted_row += insert_string_value(row, 'status', 'status')
  formatted_row += insert_string_value(row, 'year_insta', 'year_insta')
  formatted_row += insert_string_value(row, 'access_typ', 'access_typ')
  formatted_row += insert_string_value(row, 'access_act', 'access_act')
  formatted_row += insert_string_value(row, 'ground_level', 'ground_level')
  formatted_row += insert_string_value(row, 'shaft_dim', 'shaft_dim')
  formatted_row += insert_string_value(row, 'chamber_floor_depth', 'chamber_floor_depth')
  formatted_row += insert_string_value(row, 'chamber_dim', 'chamber_dim')
  formatted_row += insert_string_value(row, 'location_code', 'location_code')
  formatted_row += insert_string_value(row, 'seal_condition_sound', 'seal_condition_sound')
  formatted_row += insert_num_value(row, 'cover_level', 'cover_leve')

  formatted_row = formatted_row.gsub('.,', '.0,')
  formatted_row = formatted_row.chop
  formatted_row = formatted_row.chop
  formatted_row + insert_geometry_point(row)
end

def valid_pipe?(row, imported_pipes)
  is_valid = true
  if row['asset_id'].nil?
    report row['uid'] + ' - ERROR    ======================================= No Asset ID found, skipping pipe'
    is_valid = false
  elsif imported_pipes.include?(row['asset_id'].to_s)
    report row['uid'] + ' - ERROR    ======================================= Duplicate asset_id, skipping pipe'
    is_valid = false
  end

  if is_valid
    if row['length'].nil?
      report row['uid'] + ' - ERROR    ======================================= Null length found, skipping pipe'
      is_valid = false
    end
    if row['length'] == 0.0
      report row['uid'] + ' - ERROR    ======================================= Zero length found, skipping pipe'
      is_valid = false
    end

    points_str = row['point_array'].to_s
    points_str = points_str.tr('{}', '')
    points = points_str.split(',')
    if points.length >= 4 && points[0] == points[2] && points[1] == points[3]
      report row['uid'] + '======================================= Line is a point, skipping pipe'
      is_valid = false
    end
  end

  is_valid
end

def convert_to_geojson(csv_path, selection_id, object_type, geojson_dir)
  geojson_header = "{\n\"type\": \"FeatureCollection\",\n\"name\": \"Pipes1\",\n\"crs\": { \"type\": \"name\", \"properties\": { \"name\": \"urn:ogc:def:crs:OGC:1.3:CRS84\" } },\n\"features\": ["
  geojson_row_start = '{ "type": "Feature", "properties": { '
  geojson_footer = "\n]\n}"

  geojson = geojson_header
  report 'Converting to geoJSON'

  unless File.file?(csv_path)
    report "WARNING: CSV not found, skipping GeoJSON: #{csv_path}"
    return
  end

  iter = 0
  total_pipes_to_output = 3_000_000
  imported_pipes = []

  each_iam_csv_row(csv_path) do |row|
    next unless row['ObjectTable'] == object_type

    iter += 1
    valid_asset = true
    formatted_row = ''

    if object_type == 'cams_pipe'
      valid_asset = valid_pipe?(row, imported_pipes)
      formatted_row = convert_pipe_row(row)
    end

    if object_type == 'cams_manhole'
      formatted_row = convert_manhole_row(row)
    end

    next unless valid_asset

    geojson += "\n"
    geojson += geojson_row_start
    geojson += formatted_row
    geojson += '}},'
    imported_pipes[iter] = row['asset_id'].to_s
    report row['uid'].to_s + ' - Processed'

    break if iter == total_pipes_to_output
  end

  geojson = geojson.chop
  geojson += geojson_footer

  FileUtils.mkdir_p(geojson_dir)
  geojson_path = File.join(geojson_dir, "#{object_type}-#{selection_id}.geoJSON")
  File.open(geojson_path, 'w') { |file| file.write(geojson) }
  report "Wrote #{geojson_path}"
end

def export_selection_list(net, selection_list_id, output_base)
  csv_dir = File.join(output_base, 'CSV')
  geojson_dir = File.join(output_base, 'geoJSON')
  FileUtils.mkdir_p(csv_dir)
  FileUtils.mkdir_p(geojson_dir)

  nw_id = network_identifier(net)
  config = csv_export_config

  net.load_selection(selection_list_id)
  report "Loaded Selection List #{selection_list_id}"

  csv_path = File.join(csv_dir, "#{nw_id}-#{selection_list_id}-WGS84")
  net.csv_export(csv_path, config)

  EXPORT_OBJECT_TYPES.each do |object_type|
    object_csv = "#{csv_path}_#{object_type}.csv"
    report object_csv
    convert_to_geojson(object_csv, selection_list_id, object_type, geojson_dir)
  end

  net.clear_selection

  [csv_dir, geojson_dir]
end

def run_export
  puts '=' * 72
  puts 'InfoAsset Manager - GeoJSON export (single Selection List)'
  puts '=' * 72

  net = WSApplication.current_network
  raise 'ERROR: No network is open. Open your Collection Network on the GeoPlan first.' if net.nil?

  unless net.table_names.any? { |name| name.to_s.start_with?('cams_') }
    raise 'ERROR: No InfoAsset Manager (cams_*) tables found. Is this an IAM Collection Network?'
  end

  network_name = network_display_name(net)
  is_collection = collection_network?(net)

  if is_collection == false
    raise "ERROR: The active network '#{network_name}' is not a Collection Network."
  elsif is_collection.nil?
    puts "WARNING: Could not confirm network type for '#{network_name}'. Continuing."
  else
    puts "Collection Network: #{network_name}"
  end

  db = database_for_network(net)
  raise 'ERROR: Could not access the current database from the open network.' if db.nil?

  selection_id_str = prompt_selection_list_id
  if selection_id_str.nil?
    puts 'Cancelled.'
    return
  end

  selection_list_id = parse_selection_list_id(selection_id_str)
  raise "ERROR: Selection List ID must be a positive integer (got #{selection_id_str.inspect})." if selection_list_id.nil? || selection_list_id <= 0

  selection_mo = resolve_selection_list(db, selection_list_id)
  if selection_mo.nil?
    raise "ERROR: Selection List ID '#{selection_list_id}' was not found in this database."
  end

  label = selection_list_label(selection_mo, selection_list_id)
  output_base = pick_output_base_dir
  if output_base.nil?
    puts 'Cancelled.'
    return
  end

  report "Exporting to CSV (WGS84, selection only) — output: #{output_base}"
  report "Target: #{label}"

  csv_dir, geojson_dir = export_selection_list(net, selection_list_id, output_base)

  puts '-' * 72
  puts 'SUCCESS: GeoJSON export complete.'
  puts "Selection List: #{label}"
  puts "CSV folder:     #{csv_dir}"
  puts "GeoJSON folder: #{geojson_dir}"
  puts '=' * 72

  if WSApplication.respond_to?(:message_box)
    WSApplication.message_box(
      "GeoJSON export complete.\n\n#{label}\n\nCSV: #{csv_dir}\nGeoJSON: #{geojson_dir}",
      'OK',
      'Information',
      false
    )
  end
end

run_export
