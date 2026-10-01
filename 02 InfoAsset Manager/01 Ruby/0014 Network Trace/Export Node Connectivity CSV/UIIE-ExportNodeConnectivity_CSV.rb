# ============================================================================
# InfoAsset Manager UI / Exchange Script
# Script: UIIE-ExportNodeConnectivity_CSV.rb
# Purpose: For each seed node, trace upstream and downstream on the collection
#          network and export connected nodes of selected types to CSV.
# Run from: Network > Run Ruby Script (Collection Network open), or IExchange
# Writes:   CSV only (read-only against the network; no database updates)
#
# Customise the USER CONFIGURATION block below for your field names, node types,
# operational filter, and CSV column headings.
# ============================================================================

require 'csv'
require 'date'
require 'fileutils'

# --- User configuration (customise for your network) ---
NODE_TABLE = 'cams_manhole'.freeze

# Fields on the seed node and on nodes listed in Upstream / Downstream
REFERENCE_FIELD = 'user_text_11'.freeze
NAME_FIELD = 'user_text_12'.freeze
OPERATIONAL_STATUS_FIELD = 'user_text_19'.freeze

# First comma-separated token in OPERATIONAL_STATUS_FIELD must match (case insensitive)
OPERATIONAL_STATUS_TOKEN = 'LIVE'.freeze

# node_type values to include in Upstream and Downstream columns (not used for traversal)
MAJOR_NODE_TYPES = %w[STW PST CSO DTK].freeze

# Do not trace through links with this pipe status (typical: abandoned)
PIPE_STATUS_EXCLUDE = 'AB'.freeze

# Each list entry: "{NAME_FIELD}/{node_type}" when true; NAME_FIELD only when false
APPEND_NODE_TYPE_TO_LABEL = true

# Separator between multiple upstream/downstream entries in one CSV cell
LIST_SEPARATOR = ';'.freeze

# Skip seed nodes that fail the operational status check
SKIP_INELIGIBLE_SEEDS = true

# CSV column headings (order defines export column order)
CSV_COLUMNS = [
  'Reference',
  'Name',
  'Node_ID',
  'Node_Type',
  'Upstream',
  'Downstream',
].freeze
# --- End user configuration ---

# --- Exchange configuration (ignored when run from the UI) ---
exchange_database = '//localhost:40000/IA'
collection_network_id = 1
use_current_selection = false
selection_list_ids = ''
output_folder = 'C:\\Temp'
output_filename = ''
# --- End Exchange configuration ---

def report(message)
  puts message
end

def prompt_val(prompt_result, index, default = nil)
  return default if prompt_result.nil?
  return prompt_result[index] if prompt_result.is_a?(Array)

  default
end

def prompt_bool(value)
  value == true || value.to_s.strip.downcase == 'true'
end

def win_join(*parts)
  parts.map { |p| p.to_s.strip.gsub('/', '\\').chomp('\\') }
       .reject(&:empty?)
       .join('\\')
end

def default_output_filename
  "Node_Connectivity_#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"
end

def operational_status_ok?(value)
  text = value.to_s.strip
  return false if text.empty?

  first_token = text.split(',', 2).first.to_s.strip
  first_token.casecmp(OPERATIONAL_STATUS_TOKEN).zero?
end

def pipe_traversable?(link)
  return false if link.nil?

  link.status.to_s.strip.upcase != PIPE_STATUS_EXCLUDE.to_s.strip.upcase
end

def major_node?(node)
  MAJOR_NODE_TYPES.include?(node['node_type'].to_s.strip.upcase)
end

def connectivity_label(node)
  name = node[NAME_FIELD].to_s.strip
  node_type = node['node_type'].to_s.strip
  return nil if name.empty?

  if APPEND_NODE_TYPE_TO_LABEL
    return nil if node_type.empty?

    "#{name}/#{node_type}"
  else
    name
  end
end

def reset_link_seen(net)
  net.row_objects('_links').each { |link| link._seen = false }
end

def trace_connected_major(start_node, upstream, net)
  reset_link_seen(net)
  found = {}
  start_node_id = start_node['node_id'].to_s

  queue = []
  seed_links = upstream ? start_node.us_links : start_node.ds_links
  seed_links.each do |link|
    next unless pipe_traversable?(link)
    next if link._seen

    link._seen = true
    queue << link
  end

  while queue.size > 0
    link = queue.shift
    node = upstream ? link.us_node : link.ds_node
    next if node.nil?

    node_id = node['node_id'].to_s
    if node_id != start_node_id && major_node?(node) && operational_status_ok?(node[OPERATIONAL_STATUS_FIELD])
      label = connectivity_label(node)
      found[node_id] = label unless label.nil? || label.empty?
    end

    next_links = upstream ? node.us_links : node.ds_links
    next_links.each do |next_link|
      next unless pipe_traversable?(next_link)
      next if next_link._seen

      next_link._seen = true
      queue << next_link
    end
  end

  found.values.sort
end

def database_for_network(net)
  if net.respond_to?(:database)
    begin
      db = net.database
      return db unless db.nil?
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

def parse_selection_list_ids(text)
  text.to_s.split(/[,;\s]+/).map(&:strip).reject(&:empty?).map do |part|
    Integer(part, 10)
  end
rescue ArgumentError
  []
end

def resolve_selection_list(db, selection_list_id)
  return nil if db.nil?

  ['Selection List', 'Selection list'].each do |type_name|
    begin
      mo = db.model_object_from_type_and_id(type_name, selection_list_id)
      return mo unless mo.nil?
    rescue StandardError
      nil
    end
  end

  nil
end

def seed_nodes_from_selection(net)
  rows = []
  if net.respond_to?(:row_objects_selection)
    rows = net.row_objects_selection(NODE_TABLE)
  elsif net.respond_to?(:row_object_collection_selection)
    rows = net.row_object_collection_selection(NODE_TABLE)
  end
  rows = rows.to_a if rows.respond_to?(:to_a)
  rows
end

def seed_nodes_from_selection_lists(net, db, list_ids)
  nodes_by_object_id = {}

  list_ids.each do |list_id|
    mo = resolve_selection_list(db, list_id)
    if mo.nil?
      report "WARNING: Selection List ID #{list_id} was not found — skipped."
      next
    end

    list_name = mo.respond_to?(:name) ? mo.name.to_s.strip : ''
    report "Loading Selection List #{list_id}#{list_name.empty? ? '' : " (#{list_name})"}"

    net.clear_selection
    net.load_selection(list_id)

    seed_nodes_from_selection(net).each do |node|
      nodes_by_object_id[node.id] = node
    end
  end

  net.clear_selection
  nodes_by_object_id.values
end

def open_collection_network
  if WSApplication.ui?
    net = WSApplication.current_network
    raise 'ERROR: No network is open. Open a Collection Network on the GeoPlan first.' if net.nil?

    return [net, database_for_network(net)]
  end

  db = WSApplication.open(exchange_database)
  dbnet = db.model_object_from_type_and_id('Collection Network', collection_network_id)
  raise "ERROR: Collection Network ID #{collection_network_id} was not found." if dbnet.nil?

  current_commit_id = dbnet.current_commit_id
  latest_commit_id = dbnet.latest_commit_id
  if latest_commit_id > current_commit_id
    report "Updating network from commit #{current_commit_id} to #{latest_commit_id}"
    dbnet.update
  else
    report 'Network is up to date'
  end

  [dbnet.open, db]
end

def ui_run_settings
  default_folder = begin
    WSApplication.local_root.to_s.strip
  rescue StandardError
    'C:\\Temp'
  end

  default_folder = 'C:\\Temp' if default_folder.empty?

  prompt = WSApplication.prompt(
    'Export node connectivity to CSV',
    [
      ['Use current GeoPlan node selection?', 'Boolean', true],
      ['Selection List ID(s), comma-separated (when not using selection)', 'String', ''],
      ['Output folder:', 'String', default_folder, nil, 'FOLDER', 'Select output folder'],
      ['Output filename:', 'String', default_output_filename],
    ],
    false
  )

  if prompt.nil?
    WSApplication.message_box('Dialog closed — script cancelled.', 'OK', '!', false) if WSApplication.respond_to?(:message_box)
    raise 'abort'
  end

  {
    use_current_selection: prompt_bool(prompt_val(prompt, 0, true)),
    selection_list_ids: parse_selection_list_ids(prompt_val(prompt, 1, '')),
    output_folder: prompt_val(prompt, 2, default_folder).to_s.strip,
    output_filename: prompt_val(prompt, 3, default_output_filename).to_s.strip,
  }
end

def exchange_run_settings
  filename = output_filename.to_s.strip
  filename = default_output_filename if filename.empty?

  {
    use_current_selection: use_current_selection,
    selection_list_ids: parse_selection_list_ids(selection_list_ids),
    output_folder: output_folder.to_s.strip,
    output_filename: filename,
  }
end

def normalize_output_path(folder, filename)
  name = filename.to_s.strip
  name = default_output_filename if name.empty?
  name += '.csv' unless name.downcase.end_with?('.csv')

  folder = folder.to_s.strip
  raise 'ERROR: Output folder is required.' if folder.empty?

  win_join(folder, name)
end

def collect_seed_nodes(net, db, settings)
  if settings[:use_current_selection]
    nodes = seed_nodes_from_selection(net)
    report "Seed source: current GeoPlan selection (#{nodes.length} node(s))"
    return nodes
  end

  if settings[:selection_list_ids].empty?
    raise 'ERROR: Turn on current selection or enter one or more Selection List ID(s).'
  end

  nodes = seed_nodes_from_selection_lists(net, db, settings[:selection_list_ids])
  report "Seed source: Selection List ID(s) #{settings[:selection_list_ids].join(', ')} (#{nodes.length} unique node(s))"
  nodes
end

def build_export_rows(net, seed_nodes)
  rows = []
  skipped_ineligible = 0

  seed_nodes.each do |seed|
    unless operational_status_ok?(seed[OPERATIONAL_STATUS_FIELD])
      skipped_ineligible += 1
      if SKIP_INELIGIBLE_SEEDS
        report "Skipping node #{seed['node_id']} — operational status is not #{OPERATIONAL_STATUS_TOKEN}."
        next
      end
    end

    upstream = trace_connected_major(seed, true, net)
    downstream = trace_connected_major(seed, false, net)

    rows << {
      'Reference' => seed[REFERENCE_FIELD].to_s,
      'Name' => seed[NAME_FIELD].to_s,
      'Node_ID' => seed['node_id'].to_s,
      'Node_Type' => seed['node_type'].to_s,
      'Upstream' => upstream.join(LIST_SEPARATOR),
      'Downstream' => downstream.join(LIST_SEPARATOR),
    }
  end

  [rows, skipped_ineligible]
end

def write_csv(output_path, rows)
  FileUtils.mkdir_p(File.dirname(output_path))

  CSV.open(output_path, 'w', write_headers: true, headers: CSV_COLUMNS) do |csv|
    rows.each do |row|
      csv << CSV_COLUMNS.map { |column| row[column].to_s }
    end
  end
end

# ---------------------------------------------------------------------------
start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

net, db = open_collection_network

unless net.table_names.any? { |name| name.to_s.start_with?('cams_') }
  raise 'ERROR: No cams_* tables found. Open a Collection Network.'
end

settings = WSApplication.ui? ? ui_run_settings : exchange_run_settings
output_csv = normalize_output_path(settings[:output_folder], settings[:output_filename])

report "Output file: #{output_csv}"

seed_nodes = collect_seed_nodes(net, db, settings)
raise 'ERROR: No seed nodes found for the chosen input.' if seed_nodes.empty?

export_rows, skipped_ineligible = build_export_rows(net, seed_nodes)
write_csv(output_csv, export_rows)

elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time

report '-' * 72
report 'Node connectivity export complete.'
report "Rows written: #{export_rows.length}"
report "Seed nodes skipped (operational filter): #{skipped_ineligible}"
report "Output: #{output_csv}"
report "Elapsed: #{Time.at(elapsed).utc.strftime('%H:%M:%S')}"

if WSApplication.ui? && WSApplication.respond_to?(:message_box)
  WSApplication.message_box(
    "Node connectivity export complete.\n\nRows: #{export_rows.length}\n\n#{output_csv}",
    'OK',
    'Information',
    false
  )
end
