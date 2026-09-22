# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-HTMLReport-AttachmentLinks.rb
# Purpose: Export an HTML table of attachment and video file references in the
#          open network. Links open in a new browser tab (read-only).
#
# Based on the flat-table HTML approach; extended for videos, image fields,
# runtime prompts, and IAM API compatibility (row_object_collection).
#
# Run from: Network > Run Ruby Script (with any open IAM network: Collection,
#           Distribution, or Asset Network)
# ============================================================================

require 'cgi'
require 'uri'
require 'fileutils'

IMAGE_REF_FIELDS = %w[
  detail_image ds_image ds_photo external_photo injection_point_image
  internal_image internal_photo location_image location_photo location_sketch
  other_image photo plan_sketch sketch us_image us_photo
].freeze

VIDEO_REF_FIELDS = %w[video_file_in video_file_out].freeze

# Optional fallbacks when db.file_root is empty. Add your UNC workgroup path if needed, e.g.
# '//fileserver/InfoWorks/Workgroups/Your_Workgroup'
SNUMBATDATA_CANDIDATES = [
  'C:\\ProgramData\\Autodesk\\SNumbatData',
  'C:\\ProgramData\\Innovyze\\SNumbatData'
].freeze

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def html_escape(value)
  CGI.escapeHTML(value.to_s)
end

def file_href(path)
  return '' if path.nil? || path.to_s.strip.empty?
  normalized = path.to_s.gsub('\\', '/')
  if normalized.start_with?('//')
    "file:#{URI::DEFAULT_PARSER.escape(normalized)}"
  else
    "file:///#{URI::DEFAULT_PARSER.escape(normalized)}"
  end
end

def report_html_style_lines
  [
    '    body { font-family: Arial, sans-serif; margin: 16px; }',
    '    h1 { margin: 0 0 8px 0; }',
    '    h2 { margin: 12px 0 8px 0; font-size: 1.1em; }',
    '    .meta { margin: 0 0 16px 0; color: #555; }',
    '    table.data { border-collapse: collapse; width: 100%; }',
    '    table.data th, table.data td { border: 1px solid #ccc; padding: 6px 8px; text-align: left; vertical-align: top; }',
    '    table.data th { background: #f3f3f3; position: sticky; top: 0; }',
    '    .missing { color: #b00020; font-weight: bold; }',
    '    .type-att { color: #0078d4; font-weight: bold; }',
    '    .type-vid { color: #7b1fa2; font-weight: bold; }',
    '    .type-img { color: #2e7d32; font-weight: bold; }',
    '    .tab-bar { display: flex; flex-wrap: wrap; gap: 4px; margin: 16px 0 0 0; border-bottom: 2px solid #ccc; }',
    '    .tab-bar button { margin: 0; padding: 8px 12px; border: 1px solid #ccc; border-bottom: none; background: #eee; cursor: pointer; font-size: 13px; border-radius: 4px 4px 0 0; max-width: 280px; text-align: left; }',
    '    .tab-bar button.active { background: #fff; font-weight: bold; margin-bottom: -2px; border-bottom: 2px solid #fff; }',
    '    .tab-panel { display: none; padding-top: 8px; }',
    '    .tab-panel.active { display: block; }',
    '    .panel-meta { color: #666; margin: 0 0 8px 0; font-size: 13px; }',
    '    .empty-tab { color: #666; font-style: italic; padding: 12px 0; }'
  ]
end

def append_export_row_tr(html, row, show_table_column)
  type_class = case row['file_type']
               when 'Video' then 'type-vid'
               when 'Image' then 'type-img'
               else 'type-att'
               end
  exists_html = row['exists'] ? 'Yes' : '<span class="missing">No</span>'
  href = file_href(row['full_path'])
  link_html = if href.empty?
                '<span class="missing">Path not configured</span>'
              else
                "<a href=\"#{html_escape(href)}\" target=\"_blank\" rel=\"noopener noreferrer\">Open</a>"
              end

  html << '      <tr>'
  if show_table_column
    html << "        <td>#{html_escape(row['table_label'])}<br><small>#{html_escape(row['table_name'])}</small></td>"
  end
  html << "        <td>#{html_escape(row['object_id'])}</td>"
  html << "        <td class=\"#{type_class}\">#{html_escape(row['file_type'])}</td>"
  html << "        <td>#{html_escape(row['purpose'])}</td>"
  html << "        <td>#{html_escape(row['filename'])}</td>"
  html << "        <td>#{html_escape(row['description'])}</td>"
  html << "        <td>#{html_escape(row['db_ref'])}</td>"
  html << "        <td>#{exists_html}</td>"
  html << "        <td>#{link_html}</td>"
  html << '      </tr>'
end

def append_export_data_table(html, rows, show_table_column)
  html << '  <table class="data">'
  html << '    <thead>'
  html << '      <tr>'
  html << '        <th>Table</th>' if show_table_column
  html << '        <th>Object ID</th>'
  html << '        <th>Type</th>'
  html << '        <th>Purpose / Field</th>'
  html << '        <th>Filename</th>'
  html << '        <th>Description</th>'
  html << '        <th>DB Ref</th>'
  html << '        <th>File Exists</th>'
  html << '        <th>Link</th>'
  html << '      </tr>'
  html << '    </thead>'
  html << '    <tbody>'
  if rows.empty?
    col_span = show_table_column ? 9 : 8
    html << "      <tr><td colspan=\"#{col_span}\" class=\"empty-tab\">No file references for this table.</td></tr>"
  else
    rows.each { |row| append_export_row_tr(html, row, show_table_column) }
  end
  html << '    </tbody>'
  html << '  </table>'
end

def build_attachments_report_html(network_name, meta_lines, table_groups)
  html = []
  html << '<!doctype html>'
  html << '<html lang="en">'
  html << '<head>'
  html << '  <meta charset="utf-8">'
  html << '  <meta name="viewport" content="width=device-width, initial-scale=1">'
  html << "  <title>Attachment &amp; Video Report - #{html_escape(network_name)}</title>"
  html << '  <style>'
  report_html_style_lines.each { |line| html << line }
  html << '  </style>'
  html << '</head>'
  html << '<body>'
  html << "  <h1>Attachment &amp; Video Report - #{html_escape(network_name)}</h1>"
  html << '  <p class="meta">'
  meta_lines.each_with_index do |line, idx|
    html << '<br>' if idx > 0
    html << line
  end
  html << '</p>'

  use_tabs = table_groups.size > 1
  if use_tabs
    html << '  <div class="tab-bar" role="tablist">'
    table_groups.each_with_index do |group, idx|
      rows = group['rows']
      missing = rows.count { |r| !r['exists'] }
      tab_label = "#{group['table_label']} (#{rows.size})"
      tab_label += ", #{missing} missing" if missing > 0
      active = idx.zero? ? ' active' : ''
      html << "    <button type=\"button\" class=\"tab-btn#{active}\" role=\"tab\" aria-selected=\"#{idx.zero? ? 'true' : 'false'}\" onclick=\"showReportTab(#{idx}, this)\">#{html_escape(tab_label)}</button>"
    end
    html << '  </div>'
    table_groups.each_with_index do |group, idx|
      rows = group['rows']
      missing = rows.count { |r| !r['exists'] }
      active = idx.zero? ? ' active' : ''
      html << "  <div id=\"report-tab-panel-#{idx}\" class=\"tab-panel#{active}\" role=\"tabpanel\">"
      html << "    <h2>#{html_escape(group['table_label'])}</h2>"
      html << "    <p class=\"panel-meta\">Internal table: <code>#{html_escape(group['table_name'])}</code> &mdash; #{rows.size} reference(s)"
      html << " &mdash; <span class=\"missing\">#{missing} missing on disk</span>" if missing > 0
      html << '</p>'
      append_export_data_table(html, rows, false)
      html << '  </div>'
    end
    html << '  <script>'
    html << '    function showReportTab(index, btn) {'
    html << '      var panels = document.querySelectorAll(".tab-panel");'
    html << '      for (var i = 0; i < panels.length; i++) { panels[i].classList.remove("active"); }'
    html << '      var buttons = document.querySelectorAll(".tab-btn");'
    html << '      for (var j = 0; j < buttons.length; j++) { buttons[j].classList.remove("active"); buttons[j].setAttribute("aria-selected", "false"); }'
    html << '      var panel = document.getElementById("report-tab-panel-" + index);'
    html << '      if (panel) { panel.classList.add("active"); }'
    html << '      if (btn) { btn.classList.add("active"); btn.setAttribute("aria-selected", "true"); }'
    html << '    }'
    html << '  </script>'
  else
    group = table_groups.first
    rows = group ? group['rows'] : []
    append_export_data_table(html, rows, false)
  end

  html << '</body>'
  html << '</html>'
  html.join("\n")
end

def win_join(*parts)
  parts.map { |p| p.to_s.strip.gsub('/', '\\').chomp('\\') }
       .reject(&:empty?)
       .join('\\')
end

def normalise_snumbatdata_root(path)
  root = path.to_s.strip.gsub('/', '\\').chomp('\\')
  return '' if root.empty?
  lower = root.downcase
  root = root[0, root.length - 12] if lower.end_with?('\\attachments')
  root = root[0, root.length - 7]  if lower.end_with?('\\videos')
  root.chomp('\\')
end

def detect_snumbatdata_root(db_file_root, guid)
  root = normalise_snumbatdata_root(db_file_root)
  return root unless root.empty?
  SNUMBATDATA_CANDIDATES.each do |candidate|
    return candidate if File.directory?(win_join(candidate, 'Attachments', guid))
  end
  SNUMBATDATA_CANDIDATES.each { |c| return c if File.directory?(c) }
  ''
end

def prompt_bool(val)
  val == true || val.to_s.strip.downcase == 'true'
end

def prompt_val(prompt_result, index, default = nil)
  return default if prompt_result.nil?
  return prompt_result[index] if prompt_result.is_a?(Array)
  default
end

def network_rows(net, table_name, selection_only)
  if selection_only
    if net.respond_to?(:row_object_collection_selection)
      return net.row_object_collection_selection(table_name)
    end
    if net.respond_to?(:row_objects_selection)
      return net.row_objects_selection(table_name)
    end
    return []
  end
  return net.row_object_collection(table_name) if net.respond_to?(:row_object_collection)
  return net.row_objects(table_name) if net.respond_to?(:row_objects)
  nil
end

def network_display_name(net)
  begin
    mo = net.model_object if net.respond_to?(:model_object)
    return mo.name.to_s if mo && mo.respond_to?(:name)
  rescue
  end
  begin
    return net.name.to_s if net.respond_to?(:name)
  rescue
  end
  '(current network)'
end

def row_id(ro)
  return ro.id.to_s if ro.respond_to?(:id)
  return ro['id'].to_s if ro.respond_to?(:[])
  ''
rescue
  ''
end

def row_field(ro, field_name)
  return ro[field_name] if ro.respond_to?(:[])
  nil
rescue TypeError
  nil
rescue
  nil
end

def row_has_field?(ro, field_name)
  return ro.field(field_name) if ro.respond_to?(:field)
  ro.respond_to?(:[])
rescue
  false
end

def abs_path?(val)
  s = val.to_s.strip
  return true if s.length >= 2 && s[1, 1] == ':' &&
                 ((s[0] >= 'A' && s[0] <= 'Z') || (s[0] >= 'a' && s[0] <= 'z'))
  return true if s.length >= 2 && s[0, 2] == '\\\\'
  false
end

def attachment_field(attachment, name)
  return attachment.send(name).to_s if attachment.respond_to?(name)
  return attachment[name].to_s if attachment.respond_to?(:[])
  ''
rescue
  ''
end

def resolve_path(store_dir, uid, uid_lookup)
  return '' if uid.to_s.strip.empty?
  found = uid_lookup[uid.to_s]
  return found if found
  store_dir.empty? ? '' : win_join(store_dir, uid.to_s)
end

def scan_uid_store(root_dir)
  uids = {}
  return uids unless File.directory?(root_dir.to_s)
  stack = [root_dir.to_s]
  until stack.empty?
    dir = stack.pop
    begin
      Dir.entries(dir).each do |entry|
        next if entry == '.' || entry == '..'
        full = File.join(dir, entry)
        if File.directory?(full)
          stack << full
        else
          uids[entry] = full
        end
      end
    rescue
    end
  end
  uids
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

net = WSApplication.current_network
if net.nil?
  WSApplication.message_box(
    "No open network found.\n\nOpen a network (Collection, Distribution, or Asset), then run via Network > Run Ruby Script.",
    'OK', '!', false
  )
  raise 'abort'
end

db = nil
db_guid = ''
file_root = ''
begin
  db = WSApplication.current_database
  db_guid = db.guid.to_s.strip if db && db.respond_to?(:guid)
  db_root = db.file_root.to_s if db && db.respond_to?(:file_root)
  file_root = detect_snumbatdata_root(db_root, db_guid)
rescue => e
  puts "Database lookup: #{e.message}"
end

default_output = begin; WSApplication.local_root.to_s.strip; rescue; 'C:\\Temp'; end

prompt = WSApplication.prompt(
  'HTML Attachment & Video Report',
  [
    ['Process SELECTION only?', 'Boolean', false],
    ['SNumbatData root (parent of Attachments & Videos folders):',
     'String', file_root, nil, 'FOLDER', 'Select SNumbatData folder'],
    ['Output folder:', 'String', default_output, nil, 'FOLDER', 'Select output folder'],
    ['Output filename:', 'String', 'IAM_AttachmentLinks_Report.html'],
  ],
  false
)

if prompt.nil?
  WSApplication.message_box("Dialog closed\nScript cancelled.", 'OK', '!', false)
  raise 'abort'
end

selection_only = prompt_bool(prompt_val(prompt, 0, false))
file_root      = normalise_snumbatdata_root(prompt_val(prompt, 1, file_root))
output_folder  = prompt_val(prompt, 2, default_output).to_s.strip
output_name    = prompt_val(prompt, 3, 'IAM_AttachmentLinks_Report.html').to_s.strip
output_name    = 'IAM_AttachmentLinks_Report.html' if output_name.empty?
output_name   += '.html' unless output_name.downcase.end_with?('.html')
output_html    = win_join(output_folder, output_name)

if output_folder.empty?
  WSApplication.message_box("Output folder is required.\nScript cancelled.", 'OK', '!', false)
  raise 'abort'
end

att_store = file_root.empty? ? '' : win_join(file_root, 'Attachments', db_guid)
vid_store = file_root.empty? ? '' : win_join(file_root, 'Videos', db_guid)

puts "Network      : #{network_display_name(net)}"
puts "Database GUID: #{db_guid.empty? ? '(not detected)' : db_guid}"
puts "Attachments  : #{att_store.empty? ? '(set SNumbatData root in prompt)' : att_store}"
puts "Videos       : #{vid_store.empty? ? '(set SNumbatData root in prompt)' : vid_store}"
puts ''

att_uids = scan_uid_store(att_store)
vid_uids = scan_uid_store(vid_store)
all_uids = vid_uids.merge(att_uids)

export_rows = []
tables_checked = 0
objects_checked = 0

net.tables.each do |table|
  field_names = table.fields.map { |f| f.name }
  has_att = field_names.include?('attachments')
  vid_flds = VIDEO_REF_FIELDS.select { |f| field_names.include?(f) }
  img_flds = IMAGE_REF_FIELDS.select { |f| field_names.include?(f) }
  next unless has_att || !vid_flds.empty? || !img_flds.empty?

  row_set = network_rows(net, table.name, selection_only)
  if row_set.nil?
    puts "Skipped #{table.name} – cannot read row objects on this IAM build"
    next
  end

  tables_checked += 1

  row_set.each do |ro|
    next if ro.nil?
    objects_checked += 1
    obj_id = row_id(ro)

    if has_att && ro.respond_to?(:attachments)
      begin
        attachments = ro.attachments
        if attachments && attachments.respond_to?(:each)
          attachments.each do |attachment|
            next if attachment.nil?
            db_ref = attachment_field(attachment, 'db_ref')
            next if db_ref.strip.empty?

            full_path = resolve_path(att_store, db_ref, att_uids)
            export_rows << {
              'table_name' => table.name,
              'table_label' => table.description.to_s,
              'object_id' => obj_id,
              'file_type' => 'Attachment',
              'purpose' => attachment_field(attachment, 'purpose'),
              'filename' => attachment_field(attachment, 'filename'),
              'description' => attachment_field(attachment, 'description'),
              'db_ref' => db_ref,
              'full_path' => full_path,
              'exists' => !full_path.empty? && File.exist?(full_path)
            }
          end
        end
      rescue => e
        puts "Skipping #{table.name} / #{obj_id} attachments: #{e.message}"
      end
    end

    vid_flds.each do |fld|
      begin
        next unless row_has_field?(ro, fld)
        val = row_field(ro, fld).to_s.strip
        next if val.empty?

        if abs_path?(val)
          full_path = val
        else
          full_path = resolve_path(vid_store, val, all_uids)
        end

        export_rows << {
          'table_name' => table.name,
          'table_label' => table.description.to_s,
          'object_id' => obj_id,
          'file_type' => 'Video',
          'purpose' => fld,
          'filename' => abs_path?(val) ? File.basename(val) : val,
          'description' => '',
          'db_ref' => val,
          'full_path' => full_path,
          'exists' => !full_path.empty? && File.exist?(full_path)
        }
      rescue => e
        puts "Skipping #{table.name} / #{obj_id} #{fld}: #{e.message}"
      end
    end

    img_flds.each do |fld|
      begin
        next unless row_has_field?(ro, fld)
        val = row_field(ro, fld).to_s.strip
        next if val.empty?

        full_path = resolve_path(att_store, val, all_uids)
        export_rows << {
          'table_name' => table.name,
          'table_label' => table.description.to_s,
          'object_id' => obj_id,
          'file_type' => 'Image',
          'purpose' => fld,
          'filename' => val,
          'description' => '',
          'db_ref' => val,
          'full_path' => full_path,
          'exists' => !full_path.empty? && File.exist?(full_path)
        }
      rescue => e
        puts "Skipping #{table.name} / #{obj_id} #{fld}: #{e.message}"
      end
    end
  end
end

# ---------------------------------------------------------------------------
# HTML output (one table, or tabbed sections when multiple tables have data)
# ---------------------------------------------------------------------------

network_name = network_display_name(net)
scope_label  = selection_only ? 'Selection only' : 'All network objects'
missing_count = export_rows.select { |r| !r['exists'] }.size

table_groups = []
group_index = {}
export_rows.each do |row|
  key = row['table_name']
  unless group_index.key?(key)
    group_index[key] = table_groups.size
    table_groups << {
      'table_name' => key,
      'table_label' => row['table_label'],
      'rows' => []
    }
  end
  table_groups[group_index[key]]['rows'] << row
end

meta_lines = [
  "Scope: #{html_escape(scope_label)}",
  "Database GUID: #{html_escape(db_guid.empty? ? 'Not detected' : db_guid)}",
  "File root: #{html_escape(file_root.empty? ? 'Not configured' : file_root)}",
  "Tables scanned: #{tables_checked}",
  "Objects scanned: #{objects_checked}",
  "File references: #{export_rows.size}"
]
meta_lines << "<span class=\"missing\">Missing on disk: #{missing_count}</span>" if missing_count > 0

html = build_attachments_report_html(network_name, meta_lines, table_groups)

FileUtils.mkdir_p(output_folder)
File.open(output_html, 'w') { |f| f.write(html) }

puts "Created HTML report: #{output_html}"
puts "File references    : #{export_rows.size}"
puts "Missing on disk    : #{missing_count}"

summary = "Report created.\n\nFile: #{output_html}\nReferences: #{export_rows.size}"
summary += "\nMissing: #{missing_count}" if missing_count > 0

if WSApplication.message_box("#{summary}\n\nOpen report in your default browser?", 'YesNo', 'Information', false) == 'yes'
  system("start \"\" \"#{output_html.gsub('/', '\\')}\"")
end
