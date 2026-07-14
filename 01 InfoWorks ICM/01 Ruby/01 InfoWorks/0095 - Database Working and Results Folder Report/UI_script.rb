# Working and Results Folder Report
# Scans ICM Working Folder and Results Folder subfolders, reads DBVER.dat metadata,
# reports folder sizes, and optionally checks standalone .icmm files and workgroup
# databases via .sndb / .d folder mapping under a user-supplied SNumbatData root.
#
# Run from the ICM UI (Scripts) or Exchange. Windows only (uses win32ole for folder sizes).

require 'csv'
require 'fileutils'
require 'win32ole'

# --- Optional Exchange defaults (used when UI prompts are unavailable) ---
CHECK_STANDALONE_DEFAULT = true
CHECK_WORKGROUP_DEFAULT  = false
WORKGROUP_DATA_ROOT_DEFAULT = nil  # e.g. '\\\\server\\share\\SNumbatData'

FSO = WIN32OLE.new('Scripting.FileSystemObject')
UUID_PATTERN = /\A[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}\z/i
CSV_COLUMNS = %i[
  id database version db_type working_mb results_mb total_mb
  workgroup_host workgroup_logical_path cloud_name cloud_org_id cloud_region resolved_data_path
  db_found db_check_method db_check_detail notes
].freeze

def ws_ui?
  defined?(WSApplication) && WSApplication.respond_to?(:ui?) && WSApplication.ui?
end

def ws_method?(name)
  defined?(WSApplication) && WSApplication.respond_to?(name)
end

def resolve_innovyze_dir(folder_name, ws_method)
  if ws_method?(ws_method)
    WSApplication.public_send(ws_method)
  else
    local = ENV['LOCALAPPDATA']
    raise 'LOCALAPPDATA is not set' if local.nil? || local.empty?

    File.join(local, 'Innovyze', folder_name)
  end
end

def folder_size_bytes(path)
  return 0 unless path && File.directory?(path)

  FSO.GetFolder(path.tr('/', '\\')).Size
rescue
  0
end

def mb(bytes)
  (bytes.to_f / (1024 * 1024)).round(2)
end

def parse_dbver(path)
  return nil unless path && File.exist?(path)

  database = nil
  version = nil

  File.foreach(path) do |line|
    case line
    when /^Database:\s*(.*)/ then database = Regexp.last_match(1).strip
    when /^Version:\s*(.*)/  then version  = Regexp.last_match(1).strip
    end
  end

  return nil if database.nil? || database.empty?

  { database: database, version: version }
end

def dbver_for_id(working_dir, results_dir, id)
  [working_dir, results_dir].each do |root|
    info = parse_dbver(File.join(root, id, 'DBVER.dat'))
    return info if info
  end
  nil
end

def classify_db_path(path)
  return 'unknown' if path.nil? || path.strip.empty?

  p = path.strip
  return 'cloud' if p.start_with?('cloud://')
  return 'standalone' if p.match?(/\.icmm\z/i)
  return 'workgroup' if p.match?(/\Asnumbat:\/\//i) || p.match?(%r{\A//}) ||
                        p.match?(%r{\A[^/\\]+:\d+[/\\]})

  'unknown'
end

def parse_database_details(db_type, path)
  case db_type
  when 'cloud'
    body = path.to_s.sub(/\Acloud:\/\//i, '')
    if body =~ /\A(.+)@([^\/]+)\/(.+)\z/
      { cloud_name: Regexp.last_match(1), cloud_org_id: Regexp.last_match(2), cloud_region: Regexp.last_match(3) }
    else
      { cloud_name: body, cloud_org_id: nil, cloud_region: nil }
    end
  when 'workgroup'
    normalized = path.to_s.strip.sub(/\Asnumbat:\/\//i, '').sub(%r{\A//}, '')
    if normalized =~ /\A([^\/\\]+(?::\d+)?)[\/\\](.+)\z/m
      { workgroup_host: Regexp.last_match(1), workgroup_logical_path: Regexp.last_match(2).tr('\\', '/') }
    else
      { workgroup_host: nil, workgroup_logical_path: nil }
    end
  else
    {}
  end
end

def resolve_workgroup_data_path(data_root, logical_path)
  return nil if data_root.nil? || logical_path.nil? || logical_path.strip.empty?

  segments = logical_path.split('/').reject(&:empty?)
  return nil if segments.empty?

  segments.each_with_index.reduce(data_root) do |path, (segment, index)|
    suffix = index == segments.length - 1 ? '.sndb' : '.d'
    File.join(path, "#{segment}#{suffix}")
  end
end

def read_guid_from_master_wdb(master_wdb_path)
  target = File.join(Dir.tmpdir, "master_#{Process.pid}_#{File.basename(master_wdb_path)}")

  begin
    FileUtils.cp(master_wdb_path, target)
    File.open(target, 'rb') do |file|
      file.seek(16_344)
      guid = file.read(36).to_s.strip
      return guid.upcase if guid.match?(UUID_PATTERN)
    end
  ensure
    File.delete(target) if File.exist?(target)
  end

  nil
rescue
  nil
end

def scan_workgroup_catalog(workgroup_data_root)
  empty = { databases: {}, guids: {}, detail: 'Workgroup data root does not exist or is not a directory' }
  return empty unless File.directory?(workgroup_data_root)

  databases = {}
  guids = {}
  errors = []

  scan_sndb_tree = lambda do |current_dir, logical_parts|
    Dir.children(current_dir).each do |entry|
      full_path = File.join(current_dir, entry)
      next unless File.directory?(full_path)

      if entry.match?(/\.sndb\z/i)
        logical_path = (logical_parts + [entry.sub(/\.sndb\z/i, '')]).join('/')
        databases[logical_path] = full_path

        master_wdb = File.join(full_path, 'master.wdb')
        if File.file?(master_wdb)
          guid = read_guid_from_master_wdb(master_wdb)
          guid ? guids[guid] = logical_path : errors << "Could not read GUID from #{master_wdb}"
        end
      elsif entry.match?(/\.d\z/i)
        scan_sndb_tree.call(full_path, logical_parts + [entry.sub(/\.d\z/i, '')])
      end
    end
  rescue => e
    errors << "Error scanning #{current_dir}: #{e.message}"
  end

  scan_sndb_tree.call(workgroup_data_root, [])

  detail = if databases.empty?
             errors.empty? ? 'No .sndb database folders found under workgroup data root' : errors.first
           elsif errors.empty?
             "#{databases.length} workgroup database folder(s), #{guids.length} GUID(s) indexed"
           else
             "#{databases.length} database folder(s); #{errors.length} warning(s)"
           end

  { databases: databases, guids: guids, detail: detail }
end

def list_folder_ids(*roots)
  roots.flat_map do |root|
    next [] unless File.directory?(root)

    Dir.children(root).select { |name| File.directory?(File.join(root, name)) }
  end.uniq.sort
end

def ask_yes_no(question, default_yes: true)
  return default_yes unless ws_method?(:message_box)

  WSApplication.message_box(question, 'YesNo', '?', true) == 'Yes'
end

def ask_report_options
  check_standalone = ask_yes_no(
    'Check standalone databases by verifying .icmm files exist on disk?',
    default_yes: CHECK_STANDALONE_DEFAULT
  )

  check_workgroup = ask_yes_no(
    'Check workgroup databases by scanning a SNumbatData root for .sndb database folders and .d group folders?',
    default_yes: CHECK_WORKGROUP_DEFAULT
  )

  workgroup_data_root = nil
  if check_workgroup
    if ws_method?(:prompt)
      response = WSApplication.prompt(
        'Workgroup Database Location',
        [['Workgroup data root (SNumbatData)', 'String', WORKGROUP_DATA_ROOT_DEFAULT.to_s, nil, 'FOLDER',
          'Select the SNumbatData folder on the workgroup server (local or UNC path)']],
        true
      )
      return nil if response.nil?

      workgroup_data_root = response[0]
    else
      workgroup_data_root = WORKGROUP_DATA_ROOT_DEFAULT
    end

    if workgroup_data_root.nil? || workgroup_data_root.strip.empty?
      puts 'Workgroup check disabled: no data root supplied.'
      check_workgroup = false
    end
  end

  output_dir = nil
  if ws_method?(:folder_dialog)
    output_dir = WSApplication.folder_dialog('Select folder for report output', true)
    return nil if output_dir.nil? || output_dir.empty?
  end

  {
    check_standalone: check_standalone,
    check_workgroup: check_workgroup,
    workgroup_data_root: workgroup_data_root,
    output_dir: output_dir
  }
end

def resolve_output_dir(explicit_dir)
  return explicit_dir if explicit_dir && !explicit_dir.empty?
  return File.dirname(WSApplication.script_file) if ws_method?(:script_file) && !WSApplication.script_file.to_s.empty?

  Dir.pwd
end

def assess_standalone(database_path, check_standalone)
  return ['not_checked', 'none', 'Standalone check not requested', ''] unless check_standalone

  normalized = database_path.to_s.tr('\\', '/')
  if File.file?(normalized) || File.file?(database_path)
    ['found', 'file', '', normalized]
  else
    ['missing', 'file', 'File not found', normalized]
  end
end

def assess_workgroup(folder_id, wg_logical_path, check_workgroup, workgroup_catalog)
  return ['not_checked', 'none', 'Workgroup check not requested', ''] unless check_workgroup
  return ['not_checked', 'workgroup_data_path', 'Workgroup catalog not available', ''] if workgroup_catalog.nil?
  return ['not_checked', 'workgroup_data_path', 'Could not parse workgroup database path', ''] if wg_logical_path.to_s.empty?

  data_path = workgroup_catalog[:databases][wg_logical_path] ||
              resolve_workgroup_data_path(workgroup_catalog[:data_root], wg_logical_path)

  if data_path && File.directory?(data_path)
    guid_note = ''
    if folder_id.match?(UUID_PATTERN)
      expected_logical = workgroup_catalog[:guids][folder_id.upcase]
      guid_note = " (GUID maps to #{expected_logical})" if expected_logical && expected_logical != wg_logical_path
    end
    ['found', 'workgroup_data_path', "Matched #{wg_logical_path}.sndb/.d path#{guid_note}", data_path]
  else
    expected = resolve_workgroup_data_path(workgroup_catalog[:data_root], wg_logical_path)
    ['missing', 'workgroup_data_path', "No .sndb folder for logical path #{wg_logical_path}", expected.to_s]
  end
end

def assess_database(db_type, database_path, folder_id, options, workgroup_catalog, wg_logical_path)
  case db_type
  when 'standalone' then assess_standalone(database_path, options[:check_standalone])
  when 'workgroup'  then assess_workgroup(folder_id, wg_logical_path, options[:check_workgroup], workgroup_catalog)
  when 'cloud'      then ['manual_check_required', 'none',
                          'Verify in ICM Connect to database, Modelling Cloud admin, or external tooling', '']
  else                 ['not_checked', 'none', 'Unknown database path format', '']
  end
end

def build_rows(working_dir, results_dir, options, workgroup_catalog)
  list_folder_ids(working_dir, results_dir).map do |id|
    working_path = File.join(working_dir, id)
    results_path = File.join(results_dir, id)
    dbver = dbver_for_id(working_dir, results_dir, id)

    database = dbver ? dbver[:database] : ''
    version = dbver ? dbver[:version] : ''
    db_type = classify_db_path(database)
    details = parse_database_details(db_type, database)

    working_bytes = folder_size_bytes(working_path)
    results_bytes = folder_size_bytes(results_path)
    total_mb = mb(working_bytes + results_bytes)

    db_found, check_method, check_detail, resolved_path = assess_database(
      db_type, database, id, options, workgroup_catalog, details[:workgroup_logical_path]
    )

    notes = []
    notes << 'no working folder' unless File.directory?(working_path)
    notes << 'no results folder' unless File.directory?(results_path)
    notes << 'missing DBVER.dat' unless dbver

    {
      id: id, database: database, version: version, db_type: db_type,
      workgroup_host: details[:workgroup_host].to_s,
      workgroup_logical_path: details[:workgroup_logical_path].to_s,
      cloud_name: details[:cloud_name].to_s,
      cloud_org_id: details[:cloud_org_id].to_s,
      cloud_region: details[:cloud_region].to_s,
      resolved_data_path: resolved_path.to_s,
      working_mb: mb(working_bytes), results_mb: mb(results_bytes), total_mb: total_mb,
      db_found: db_found, db_check_method: check_method, db_check_detail: check_detail,
      notes: notes.join('; ')
    }
  end
end

def write_csv(path, rows)
  headers = %w[
    ID Database Version DbType Working_MB Results_MB Total_MB
    WorkgroupHost WorkgroupLogicalPath CloudName CloudOrgId CloudRegion ResolvedDataPath
    DbFound DbCheckMethod DbCheckDetail Notes
  ]

  CSV.open(path, 'w') do |csv|
    csv << headers
    rows.each { |row| csv << CSV_COLUMNS.map { |key| row[key] } }

    totals = {
      working_mb: rows.sum { |r| r[:working_mb] }.round(2),
      results_mb: rows.sum { |r| r[:results_mb] }.round(2),
      total_mb: rows.sum { |r| r[:total_mb] }.round(2)
    }
    csv << CSV_COLUMNS.map do |key|
      case key
      when :id then 'Total'
      when :working_mb then totals[:working_mb]
      when :results_mb then totals[:results_mb]
      when :total_mb then totals[:total_mb]
      else ''
      end
    end
  end
end

def notify_report_complete(csv_path, row_count)
  message = "Report complete (#{row_count} row(s)).\n\nCSV:\n#{csv_path}"
  WSApplication.message_box(message, 'OK', 'information', false) if ws_method?(:message_box)
  puts message
end

# --- Main ---
working_dir = resolve_innovyze_dir('Working Folder', :working_folder)
results_dir = resolve_innovyze_dir('Results Folder', :results_folder)

unless File.directory?(working_dir) || File.directory?(results_dir)
  raise "Neither working nor results folder exists:\n  #{working_dir}\n  #{results_dir}"
end

options = if ws_ui?
            ask_report_options
          else
            {
              check_standalone: CHECK_STANDALONE_DEFAULT,
              check_workgroup: CHECK_WORKGROUP_DEFAULT && !WORKGROUP_DATA_ROOT_DEFAULT.to_s.empty?,
              workgroup_data_root: WORKGROUP_DATA_ROOT_DEFAULT,
              output_dir: nil
            }
          end

if options.nil?
  puts 'Report cancelled.'
  exit 0
end

workgroup_catalog = nil
if options[:check_workgroup]
  workgroup_catalog = scan_workgroup_catalog(options[:workgroup_data_root])
  workgroup_catalog[:data_root] = options[:workgroup_data_root]
end

rows = build_rows(working_dir, results_dir, options, workgroup_catalog)
output_dir = resolve_output_dir(options[:output_dir])
csv_path = File.join(output_dir, 'working_results_folder_report.csv')

write_csv(csv_path, rows)
notify_report_complete(csv_path, rows.length)
