# UI-odic_delta_import_multiple_shp.rb
#
# Import several ESRI shapefiles into the same InfoAsset node table using a
# delta column (NEW / UPDATED / DELETED). Useful when GIS publishes one layer
# per asset type but IAM stores them in a single table (e.g. cams_manhole).
#
# Run from: Network → Run Ruby Script… (Collection network open on GeoPlan)
#
# Prerequisites:
#   - One ODIC import .cfg per shapefile (DBI002 header, no UTF-8 BOM)
#   - Each shapefile includes a delta field and the ID field used for matching
#   - See Readme.md and example_manhole_delta_import.cfg in this folder

# ---------------------------------------------------------------------------
# Configuration — edit for your project
# ---------------------------------------------------------------------------

WORKING_FOLDER = File.join(File.dirname(WSApplication.script_file), 'delta_import_data')
CONFIG_FOLDER  = File.join(File.dirname(WSApplication.script_file), 'delta_import_configs')
ERROR_LOG      = File.join(WORKING_FOLDER, 'odic_delta_import_errors.txt')

# Source shapefile attribute names (first match wins)
DELTA_FIELD_NAMES = ['DELTA_TYPE', 'delta_type', 'Delta_Type'].freeze

# Normalised (uppercase) delta values — edit if your GIS uses other codes
IMPORT_DELTA_VALUES = ['NEW', 'UPDATED'].freeze
DELETE_DELTA_VALUES = ['DELETED'].freeze

# When delta is blank, treat row as import (legacy full files). Set false to skip.
IMPORT_WHEN_DELTA_BLANK = true

# IAM row lookup for deletions (full table name) and source ID field(s) on shapefile
DELETE_NODE_TABLE = 'cams_manhole'
DELETE_ID_SOURCE_FIELDS = ['node_id'].freeze

# ODIC target table (UI name) and matching options for creates/updates
ODIC_NODE_TABLE = 'Node'
ODIC_OPTIONS = {
  'Allow Multiple Asset IDs' => false,
  'Blob Merge' => false,
  'Delete Missing Objects' => false,
  'Update Based On Asset ID' => false,
  'Update Only' => false,
  'Update Links From Points' => false,
  'Use Network Naming Conventions' => false,
  'Duplication Behaviour' => 'Overwrite',
  'Units Behaviour' => 'Native',
  'Set Value Flag' => 'SHP',
  'Default Value Flag' => 'SHP',
  'Error File' => ERROR_LOG
}.freeze

# ---------------------------------------------------------------------------
# Delta helpers (shared by all sources)
# ---------------------------------------------------------------------------

$delta_deleted_node_ids = []

def delta_field_value(obj)
  DELTA_FIELD_NAMES.each do |name|
    val = obj[name]
    next if val.nil?
    s = val.to_s.strip
    return s unless s.empty?
  end
  nil
end

def normalised_delta(obj)
  v = delta_field_value(obj)
  v.nil? ? '' : v.upcase
end

def delta_import_row?(obj)
  d = normalised_delta(obj)
  return true if d.empty? && IMPORT_WHEN_DELTA_BLANK
  IMPORT_DELTA_VALUES.include?(d)
end

def delta_delete_row?(obj)
  DELETE_DELTA_VALUES.include?(normalised_delta(obj))
end

def source_id_for_delete(obj)
  DELETE_ID_SOURCE_FIELDS.each do |field|
    val = obj[field]
    next if val.nil?
    s = val.to_s.strip
    return s unless s.empty?
  end
  nil
end

class DeltaNodeImporter
  def DeltaNodeImporter.OnBeginRecordNode(obj)
    obj.writeRecord = false
    if delta_delete_row?(obj)
      id = source_id_for_delete(obj)
      $delta_deleted_node_ids.push(id) unless id.nil?
    elsif delta_import_row?(obj)
      obj.writeRecord = true
    end
  end
end

# Optional: per-source callbacks with extra field logic (subtype → node_type, etc.)
# class LayerANodeImporter
#   def LayerANodeImporter.OnBeginRecordNode(obj)
#     DeltaNodeImporter.OnBeginRecordNode(obj)
#   end
#   def LayerANodeImporter.onEndRecordNode(obj)
#     obj['node_type'] = 'Manhole' if obj['Subtype'] == '7'
#   end
# end

# Each source: label, shapefile file name, config file name, callback class
IMPORT_SOURCES = [
  {
    label: 'Source layer A',
    shapefile: 'layer_a.shp',
    config: 'layer_a_import.cfg',
    callback_class: DeltaNodeImporter
  },
  {
    label: 'Source layer B',
    shapefile: 'layer_b.shp',
    config: 'layer_b_import.cfg',
    callback_class: DeltaNodeImporter
  }
].freeze

# ---------------------------------------------------------------------------
# Import and delete
# ---------------------------------------------------------------------------

def log_line(msg)
  puts msg
  $stdout.flush
end

def delete_nodes_by_id(open_net, node_ids)
  deleted = 0
  not_found = 0
  node_ids.each do |node_id|
    next if node_id.nil? || node_id.to_s.strip.empty?
    nid = node_id.to_s.strip
    ro = open_net.row_object(DELETE_NODE_TABLE, nid)
    if ro.nil?
      not_found += 1
      log_line "Delta delete: no row in #{DELETE_NODE_TABLE} for node_id #{nid}"
      next
    end
    ro.delete
    deleted += 1
  end
  [deleted, not_found]
end

net = nil

begin
  net = WSApplication.current_network
  raise 'Open a network on the GeoPlan before running this script.' if net.nil?

  Dir.mkdir(WORKING_FOLDER) unless File.directory?(WORKING_FOLDER)
  Dir.mkdir(CONFIG_FOLDER) unless File.directory?(CONFIG_FOLDER)

  options = ODIC_OPTIONS.dup
  options['Error File'] = ERROR_LOG

  IMPORT_SOURCES.each_with_index do |source, index|
    shp_path = File.join(WORKING_FOLDER, source[:shapefile])
    cfg_path = File.join(CONFIG_FOLDER, source[:config])
    raise "Missing shapefile: #{shp_path}" unless File.exist?(shp_path)
    raise "Missing config: #{cfg_path}" unless File.exist?(cfg_path)

    log_line "#{index + 1}. Import #{source[:label]} — #{source[:shapefile]}"
    options['Callback Class'] = source[:callback_class]

    net.odic_import_ex('SHP', cfg_path, options, ODIC_NODE_TABLE, shp_path)
    log_line "   Completed #{source[:label]}"
  end

  delete_ids = $delta_deleted_node_ids.uniq
  unless delete_ids.empty?
    log_line 'Applying delta deletions…'
    open_net = net.respond_to?(:open) ? net.open : net
    open_net.transaction_begin
    deleted, not_found = delete_nodes_by_id(open_net, delete_ids)
    open_net.transaction_commit
    log_line "Delta delete summary: deleted=#{deleted}, not_found=#{not_found}"
  end

  log_line 'Delta import finished.'

rescue Exception => e
  log_line "FAILED: #{e.message}"
  log_line e.backtrace[0].to_s if e.backtrace
  log_line "ODIC error log (if written): #{ERROR_LOG}" if defined?(ERROR_LOG)
end
