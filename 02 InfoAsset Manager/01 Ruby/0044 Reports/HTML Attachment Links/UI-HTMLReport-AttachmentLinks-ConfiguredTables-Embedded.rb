# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-HTMLReport-AttachmentLinks-ConfiguredTables-Embedded.rb
# Purpose: Same configurable table export as UI-HTMLReport-AttachmentLinks-
#          ConfiguredTables.rb, but embeds local image (and optionally other)
#          files into the HTML as data URLs so the report is a single file.
#
# Remote http(s) paths and missing files remain hyperlinks or plain text.
# Edit EXPORT_CONFIG below, then run from Network > Run Ruby Script.
# ============================================================================

require 'cgi'
require 'uri'
require 'fileutils'
require 'base64'

# ---------------------------------------------------------------------------
# EXPORT CONFIGURATION — edit before running
#
# Each hash defines one IAM table to export:
#   'table'   — internal table name (e.g. cams_cctv_survey)
#   'fields'  — column order in the HTML (left to right)
#   'headers' — optional; same length as 'fields' for column titles
#
# Scalar IAM fields: use the field name (e.g. survey_id, when_surveyed).
#
# File UID / path scalars — optional suffix:
#   field:link    Hyperlink to SNumbatData file (video vs attachment store auto-detected)
#   field:exists  Yes / No / blank (path not configured)
#
# attachments BLOB (child records with db_ref, filename, purpose, …):
#   attachments          Same as attachments:links
#   attachments:links    All attachment files as HTML links in one cell
#   attachments:count    Count of attachment records with a db_ref
#   attachments:filenames  Filenames separated by "; "
#   attachments:text     Plain text "purpose — filename (db_ref)" per line
#
# Other nested BLOBs (e.g. cams_cctv_survey.details):
#   details:count              Number of detail records
#   details:links              Links for image/video fields on each detail row
#   details:distance,code,remarks   One cell: each detail row is "distance; code; remarks",
#                                  detail rows separated by line breaks in HTML (<br>)
#   (Replace "details" with your blob field name. Sub-field names are comma-separated.)
#
# Headers for blob sub-field columns (same order as the field list):
#   'details:Distance,Code,Remarks'   or   'Distance, Code, Remarks'
#   Column title shows labels joined with "; ".
#
# Bare blob name without ":…" is not supported — pick a mode above.
#
# Embedded export (this script): at run time you choose whether to inline
# images, other files (PDF etc.), and videos. Large files are linked instead
# when over the max size per file. Same :link / attachments:links tokens apply.
# ---------------------------------------------------------------------------

EXPORT_CONFIG = [
  # --- Collection node (manhole) assets — table cams_manhole ---
  {
    'table' => 'cams_manhole',
    'fields' => %w[
      node_id
      asset_id
      system_type
      location_image:link
      attachments:links
    ],
    'headers' => [
      'Node ID',
      'Asset ID',
      'System type',
      'Location image',
      'Attachments'
    ]
  },
  # --- manhole inspection surveys ---
  {
    'table' => 'cams_manhole_survey',
    'fields' => %w[
      id
      survey_date
      details:distance,structural_score,service_score
      location_image:link
      internal_image:link
      attachments:links
    ],
    'headers' => [
      'Survey ID',
      'Survey date',
      'Details:Distance,Structural,Service',
      'Location image',
      'Internal image',
      'Attachments'
    ]
  },
  # --- CCTV pipe surveys ---
  {
    'table' => 'cams_cctv_survey',
    'fields' => %w[
      id
      when_surveyed
      start_manhole
      finish_manhole
      details:distance,code,remarks
      attachments:links
      video_file_in:link
    ],
    'headers' => [
      'Survey ID',
      'Survey date',
      'Start MH',
      'Finish MH',
      'Details:Distance,Code,Remarks',
      'Attachments',
      'Video in'
    ]
  }
  # Each hash becomes a tab when more than one is listed. Remove or comment out
  # entries you do not need. Field names must exist on your open network schema.
].freeze

IMAGE_REF_FIELDS = %w[
  detail_image ds_image ds_photo external_photo injection_point_image
  internal_image internal_photo location_image location_photo location_sketch
  other_image photo plan_sketch sketch us_image us_photo
].freeze

VIDEO_REF_FIELDS = %w[video_file_in video_file_out video_file].freeze

DETAIL_BLOB_LINK_FIELDS = (IMAGE_REF_FIELDS + VIDEO_REF_FIELDS).uniq.freeze

IMAGE_FILE_EXTENSIONS = %w[.jpg .jpeg .png .gif .webp .bmp .tif .tiff].freeze
VIDEO_FILE_EXTENSIONS = %w[.mp4 .webm .ogg .mov .avi .mkv .m4v].freeze
OTHER_EMBED_EXTENSIONS = %w[.pdf].freeze

IMAGE_DISPLAY_CHOICES = [
  'Inline thumbnail + click opens new tab',
  'Inline thumbnail only',
  'Link only (opens embedded image in new tab)'
].freeze

# Optional fallbacks when db.file_root is empty. Add your UNC workgroup path if needed.
SNUMBATDATA_CANDIDATES = [
  'C:\\ProgramData\\Autodesk\\SNumbatData',
  'C:\\ProgramData\\Innovyze\\SNumbatData'
].freeze

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
  if ro.respond_to?(:[])
    val = ro[field_name]
    return val unless val.nil?
  end
  return ro.send(field_name) if ro.respond_to?(field_name)
  nil
rescue TypeError
  nil
rescue
  nil
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

def parse_field_token(token)
  text = token.to_s.strip
  idx = text.index(':')
  if idx
    { 'base' => text[0, idx], 'mode' => text[idx + 1, text.length - idx - 1] }
  else
    { 'base' => text, 'mode' => 'value' }
  end
end

ATTACHMENTS_MODES = %w[count filenames text links value].freeze
SCALAR_FIELD_MODES = %w[value link exists].freeze

def blob_subfields_from_mode(mode)
  return nil if mode.nil?
  text = mode.to_s.strip
  return nil if text.empty?
  return nil if text == 'count' || text == 'links'
  return nil if SCALAR_FIELD_MODES.include?(text)
  return nil if ATTACHMENTS_MODES.include?(text)
  parts = text.split(',').map(&:strip).reject(&:empty?)
  parts.empty? ? nil : parts
end

def default_column_header(token)
  parsed = parse_field_token(token)
  base = parsed['base']
  mode = parsed['mode']
  subs = blob_subfields_from_mode(mode)
  if base == 'attachments'
    case mode
    when 'count' then 'Attachment count'
    when 'filenames' then 'Attachment filenames'
    when 'text' then 'Attachments (text)'
    when 'links', 'value' then 'Attachment links'
    when nil
      base
    else
      if subs
        subs.join('; ')
      else
        "attachments:#{mode}"
      end
    end
  elsif subs
    subs.join('; ')
  elsif mode == 'link'
    "#{base} (link)"
  elsif mode == 'exists'
    "#{base} (exists)"
  elsif mode == 'count'
    "#{base} count"
  elsif mode == 'links'
    "#{base} links"
  else
    base
  end
end

def resolve_column_header(field_token, header_entry)
  entry = header_entry.to_s.strip
  return default_column_header(field_token) if entry.empty?

  field_parsed = parse_field_token(field_token)
  subs = blob_subfields_from_mode(field_parsed['mode'])
  return entry unless subs

  header_parsed = parse_field_token(entry)
  header_subs = blob_subfields_from_mode(header_parsed['mode'])
  if header_subs && header_parsed['base'] == field_parsed['base']
    return header_subs.join('; ')
  end
  if entry.include?(',')
    return entry.split(',').map(&:strip).join('; ')
  end
  entry
end

def format_scalar_value(value)
  return '' if value.nil?
  return value.strftime('%Y-%m-%d') if value.respond_to?(:strftime)
  if value.is_a?(TrueClass)
    return 'true'
  elsif value.is_a?(FalseClass)
    return 'false'
  end
  value.to_s
end

def external_url?(path)
  lower = path.to_s.strip.downcase
  lower.start_with?('http://') || lower.start_with?('https://')
end

def link_anchor(label, full_path)
  path = full_path.to_s.strip
  href = if external_url?(path)
           path
         else
           file_href(path)
         end
  return html_escape(label) if href.empty?
  safe_label = html_escape(label.to_s.empty? ? File.basename(path) : label)
  "<a href=\"#{html_escape(href)}\" target=\"_blank\" rel=\"noopener noreferrer\">#{safe_label}</a>"
end

def mime_type_for_path(path)
  ext = File.extname(path.to_s).downcase
  case ext
  when '.jpg', '.jpeg' then 'image/jpeg'
  when '.png'  then 'image/png'
  when '.gif'  then 'image/gif'
  when '.webp' then 'image/webp'
  when '.bmp'  then 'image/bmp'
  when '.tif', '.tiff' then 'image/tiff'
  when '.pdf'  then 'application/pdf'
  when '.mp4'  then 'video/mp4'
  when '.webm' then 'video/webm'
  when '.ogg'  then 'video/ogg'
  when '.mov'  then 'video/quicktime'
  when '.avi'  then 'video/x-msvideo'
  when '.mkv'  then 'video/x-matroska'
  when '.m4v'  then 'video/x-m4v'
  else 'application/octet-stream'
  end
end

def video_field_or_file?(field_name, path)
  ext = File.extname(path.to_s).downcase
  VIDEO_REF_FIELDS.include?(field_name) || VIDEO_FILE_EXTENSIONS.include?(ext)
end

def image_field_or_file?(field_name, path)
  ext = File.extname(path.to_s).downcase
  IMAGE_REF_FIELDS.include?(field_name) || IMAGE_FILE_EXTENSIONS.include?(ext)
end

def embed_allowed_for_path?(path, field_name, embed_ctx)
  return false if embed_ctx.nil?
  return false if path.to_s.strip.empty?
  return false if external_url?(path)
  return false unless File.file?(path.to_s)
  if video_field_or_file?(field_name, path)
    return embed_ctx['embed_videos'] == true
  end
  if image_field_or_file?(field_name, path)
    return embed_ctx['embed_images'] == true
  end
  if embed_ctx['embed_other'] == true
    ext = File.extname(path.to_s).downcase
    return OTHER_EMBED_EXTENSIONS.include?(ext)
  end
  false
end

def data_url_for_local_file(path, max_bytes)
  return '' unless File.file?(path.to_s)
  size = File.size(path)
  return '' if size > max_bytes
  bytes = File.binread(path)
  mime = mime_type_for_path(path)
  "data:#{mime};base64,#{Base64.strict_encode64(bytes)}"
rescue => e
  puts "Embed read failed #{path}: #{e.message}"
  ''
end

def image_display_mode_from_choice(choice_text)
  text = choice_text.to_s.strip
  return 'inline' if text == IMAGE_DISPLAY_CHOICES[1]
  return 'link' if text == IMAGE_DISPLAY_CHOICES[2]
  'inline_link'
end

def embedded_image_open_anchor(inner_html, data_url, css_class, title_text)
  safe_url = html_escape(data_url)
  title_attr = title_text.to_s.strip.empty? ? '' : " title=\"#{html_escape(title_text)}\""
  "<a href=\"#{safe_url}\" class=\"#{css_class}\"#{title_attr} " \
         "onclick=\"return openEmbeddedMedia(this);\">#{inner_html}</a>"
end

def render_embedded_markup(data_url, path, field_name, label, embed_ctx)
  safe_url = html_escape(data_url)
  safe_label = html_escape(label.to_s.empty? ? File.basename(path.to_s) : label)
  if video_field_or_file?(field_name, path)
    return "<video class=\"embed-vid\" controls preload=\"metadata\" width=\"320\">" \
           "<source src=\"#{safe_url}\"></video>"
  end
  if image_field_or_file?(field_name, path)
    mode = embed_ctx ? embed_ctx['image_display'] : 'inline_link'
    img_tag = "<img class=\"embed-img\" src=\"#{safe_url}\" alt=\"#{safe_label}\">"
    link_inner = "Open image (#{safe_label})"
    case mode
    when 'inline'
      return img_tag
    when 'link'
      return embedded_image_open_anchor(link_inner, data_url, 'embed-open', '')
    else
      return embedded_image_open_anchor(
        img_tag, data_url, 'embed-img-wrap', 'Open full image in new tab'
      )
    end
  end
  "<a href=\"#{safe_url}\" download=\"#{html_escape(File.basename(path.to_s))}\">#{safe_label}</a>"
end

def media_or_link(label, full_path, field_name, embed_ctx)
  path = full_path.to_s.strip
  return html_escape(label) if path.empty?

  if embed_allowed_for_path?(path, field_name, embed_ctx)
    cache = embed_ctx['cache']
    data_url = cache[path]
    unless data_url
      data_url = data_url_for_local_file(path, embed_ctx['max_bytes'])
      if data_url.empty?
        embed_ctx['stats']['skipped'] += 1
        return link_anchor(label, path)
      end
      cache[path] = data_url
      embed_ctx['stats']['embedded'] += 1
    end
    return render_embedded_markup(data_url, path, field_name, label, embed_ctx)
  end

  embed_ctx['stats']['linked'] += 1 if embed_ctx
  link_anchor(label, path)
end

def read_attachments_blob(ro)
  begin
    if ro.respond_to?(:attachments)
      blob = ro.attachments
      return blob unless blob.nil?
    end
  rescue
  end
  row_field(ro, 'attachments')
rescue
  nil
end

def attachment_storage_ref(attachment)
  db_ref = attachment_field(attachment, 'db_ref').strip
  return db_ref unless db_ref.empty?
  attachment_field(attachment, 'filename').strip
end

def each_attachment_record(ro)
  blob = read_attachments_blob(ro)
  return if blob.nil?

  process = lambda do |attachment|
    next if attachment.nil?
    storage_ref = attachment_storage_ref(attachment)
    next if storage_ref.empty?
    yield attachment, storage_ref
  end

  if blob.respond_to?(:size)
    size = blob.size
    if size.respond_to?(:to_i) && size.to_i > 0 && blob.respond_to?(:[])
      (0...size.to_i).each do |i|
        process.call(blob[i])
      end
      return
    end
  end

  return unless blob.respond_to?(:each)
  blob.each { |attachment| process.call(attachment) }
end

def read_nested_blob(ro, blob_name)
  return row_field(ro, blob_name) if row_field(ro, blob_name)
  return ro.send(blob_name) if ro.respond_to?(blob_name)
  nil
rescue
  nil
end

def nested_blob_size(blob)
  return 0 if blob.nil?
  return blob.size if blob.respond_to?(:size)
  return blob.length if blob.respond_to?(:length)
  0
rescue
  0
end

def nested_child_field(child, field_name)
  return child.send(field_name) if child.respond_to?(field_name)
  return child[field_name] if child.respond_to?(:[])
  nil
rescue
  nil
end

def file_ref_path(uid, field_name, att_store, vid_store, att_uids, all_uids)
  val = uid.to_s.strip
  return '' if val.empty?
  return val if external_url?(val)
  if abs_path?(val)
    val
  elsif VIDEO_REF_FIELDS.include?(field_name)
    resolve_path(vid_store, val, all_uids)
  else
    resolve_path(att_store, val, all_uids)
  end
end

def resolve_field_cell(ro, token, att_store, vid_store, att_uids, all_uids, table_field_names, blob_field_names, embed_ctx)
  parsed = parse_field_token(token)
  base = parsed['base']
  mode = parsed['mode']

  if base == 'attachments'
    subfields = blob_subfields_from_mode(mode)
    if subfields
      return attachment_subfields_cell(ro, subfields)
    end
    mode = 'links' if mode == 'value'
    return attachment_blob_cell(ro, mode, att_store, att_uids, embed_ctx)
  end

  if blob_field_names.include?(base)
    subfields = blob_subfields_from_mode(mode)
    if subfields
      return nested_blob_subfields_cell(ro, base, subfields)
    end
    if mode == 'count' || mode == 'links'
      return nested_blob_cell(ro, base, mode, att_store, vid_store, att_uids, all_uids, embed_ctx)
    end
    if mode == 'value'
      return html_escape("(BLOB field — use #{base}:count, #{base}:links, or #{base}:field1,field2)")
    end
  end

  scalar = row_field(ro, base)
  case mode
  when 'value'
    html_escape(format_scalar_value(scalar))
  when 'exists'
    path = file_ref_path(scalar, base, att_store, vid_store, att_uids, all_uids)
    if scalar.to_s.strip.empty?
      ''
    elsif path.empty?
      html_escape('No')
    else
      File.exist?(path) ? 'Yes' : html_escape('No')
    end
  when 'link'
    val = scalar.to_s.strip
    return '' if val.empty?
    path = file_ref_path(val, base, att_store, vid_store, att_uids, all_uids)
    label = abs_path?(val) ? File.basename(val) : val
    media_or_link(label, path, base, embed_ctx)
  else
    html_escape(format_scalar_value(scalar))
  end
end

def attachment_blob_cell(ro, mode, att_store, att_uids, embed_ctx)
  records = []
  each_attachment_record(ro) { |att, db_ref| records << [att, db_ref] }

  case mode
  when 'count'
    records.size.to_s
  when 'filenames'
    html_escape(records.map { |att, _| attachment_field(att, 'filename') }.reject(&:empty?).join('; '))
  when 'text'
    lines = records.map do |att, db_ref|
      purpose = attachment_field(att, 'purpose')
      filename = attachment_field(att, 'filename')
      label = [purpose, filename].reject(&:empty?).join(' — ')
      label = db_ref if label.empty?
      "#{label} (#{db_ref})"
    end
    html_escape(lines.join("\n")).gsub("\n", '<br>')
  when 'links'
    parts = records.map do |att, storage_ref|
      path = if external_url?(storage_ref) || abs_path?(storage_ref)
               storage_ref
             else
               resolve_path(att_store, storage_ref, att_uids)
             end
      purpose = attachment_field(att, 'purpose')
      filename = attachment_field(att, 'filename')
      label = [purpose, filename].reject(&:empty?).join(': ')
      label = storage_ref if label.empty?
      media_or_link(label, path, 'attachments', embed_ctx)
    end
    parts.join('<br>')
  else
    html_escape("(Unknown attachments mode — use links, count, filenames, or text)")
  end
end

def each_nested_blob_child(blob)
  return if blob.nil?
  if blob.respond_to?(:size) && blob.respond_to?(:[])
    size = blob.size
    if size.respond_to?(:to_i) && size.to_i > 0
      (0...size.to_i).each do |i|
        yield blob[i]
      end
      return
    end
  end
  return unless blob.respond_to?(:each)
  blob.each { |child| yield child }
end

def nested_blob_subfields_cell(ro, blob_name, subfields)
  blob = read_nested_blob(ro, blob_name)
  lines = []
  each_nested_blob_child(blob) do |child|
    next if child.nil?
    parts = subfields.map do |fld|
      html_escape(format_scalar_value(nested_child_field(child, fld)))
    end
    lines << parts.join('; ')
  end
  lines.join('<br>')
end

def attachment_subfields_cell(ro, subfields)
  lines = []
  each_attachment_record(ro) do |att, _storage_ref|
    parts = subfields.map do |fld|
      html_escape(format_scalar_value(attachment_field(att, fld)))
    end
    lines << parts.join('; ')
  end
  lines.join('<br>')
end

def nested_blob_cell(ro, blob_name, mode, att_store, vid_store, att_uids, all_uids, embed_ctx)
  blob = read_nested_blob(ro, blob_name)
  if mode == 'count'
    return nested_blob_size(blob).to_s
  end

  links = []
  each_nested_blob_child(blob) do |child|
    next if child.nil?
    DETAIL_BLOB_LINK_FIELDS.each do |fld|
      val = nested_child_field(child, fld)
      next if val.nil? || val.to_s.strip.empty?
      path = file_ref_path(val, fld, att_store, vid_store, att_uids, all_uids)
      links << media_or_link("#{fld}: #{val}", path, fld, embed_ctx)
    end
  end
  links.join('<br>')
end

def blob_child_field_names(net, table_name, blob_name)
  net.tables.each do |t|
    next unless t.name == table_name
    t.fields.each do |f|
      next unless f.name == blob_name && f.data_type == 'WSStructure'
      return [] if f.fields.nil?
      return f.fields.map { |bf| bf.name }
    end
  end
  []
rescue
  []
end

def table_field_name_list(net, table_name)
  net.tables.each do |t|
    return t.fields.map { |f| f.name } if t.name == table_name
  end
  []
rescue
  []
end

def table_blob_field_names(net, table_name)
  net.tables.each do |t|
    next unless t.name == table_name
    return t.fields.select { |f| f.data_type == 'WSStructure' }.map { |f| f.name }
  end
  []
rescue
  []
end

def table_description(net, table_name)
  net.tables.each do |t|
    return t.description.to_s if t.name == table_name
  end
  table_name
rescue
  table_name
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
    '    .tab-bar { display: flex; flex-wrap: wrap; gap: 4px; margin: 16px 0 0 0; border-bottom: 2px solid #ccc; }',
    '    .tab-bar button { margin: 0; padding: 8px 12px; border: 1px solid #ccc; border-bottom: none; background: #eee; cursor: pointer; font-size: 13px; border-radius: 4px 4px 0 0; max-width: 280px; text-align: left; }',
    '    .tab-bar button.active { background: #fff; font-weight: bold; margin-bottom: -2px; border-bottom: 2px solid #fff; }',
    '    .tab-panel { display: none; padding-top: 8px; }',
    '    .tab-panel.active { display: block; }',
    '    .panel-meta { color: #666; margin: 0 0 8px 0; font-size: 13px; }',
    '    .empty-tab { color: #666; font-style: italic; }',
    '    .embed-img { max-width: 240px; max-height: 180px; height: auto; display: block; margin: 4px 0; }',
    '    a.embed-img-wrap { display: inline-block; cursor: pointer; }',
    '    a.embed-open { display: inline-block; margin: 4px 0; }',
    '    .embed-vid { max-width: 360px; display: block; margin: 4px 0; }'
  ]
end

def build_configured_export_html(network_name, meta_lines, sections)
  html = []
  html << '<!doctype html>'
  html << '<html lang="en">'
  html << '<head>'
  html << '  <meta charset="utf-8">'
  html << '  <meta name="viewport" content="width=device-width, initial-scale=1">'
  html << "  <title>Configured object export - #{html_escape(network_name)}</title>"
  html << '  <style>'
  report_html_style_lines.each { |line| html << line }
  html << '  </style>'
  html << '</head>'
  html << '<body>'
  html << "  <h1>Configured object export - #{html_escape(network_name)}</h1>"
  html << '  <p class="meta">'
  meta_lines.each_with_index do |line, idx|
    html << '<br>' if idx > 0
    html << line
  end
  html << '</p>'

  use_tabs = sections.size > 1
  if use_tabs
    html << '  <div class="tab-bar" role="tablist">'
    sections.each_with_index do |section, idx|
      active = idx.zero? ? ' active' : ''
      label = "#{section['table_label']} (#{section['rows'].size})"
      html << "    <button type=\"button\" class=\"tab-btn#{active}\" role=\"tab\" onclick=\"showReportTab(#{idx}, this)\">#{html_escape(label)}</button>"
    end
    html << '  </div>'
  end

  sections.each_with_index do |section, idx|
    if use_tabs
      active = idx.zero? ? ' active' : ''
      html << "  <div id=\"report-tab-panel-#{idx}\" class=\"tab-panel#{active}\" role=\"tabpanel\">"
      html << "    <h2>#{html_escape(section['table_label'])}</h2>"
      html << "    <p class=\"panel-meta\">Table: <code>#{html_escape(section['table_name'])}</code> &mdash; #{section['rows'].size} object(s)</p>"
    end
    html << '  <table class="data">'
    html << '    <thead><tr>'
    section['headers'].each { |h| html << "      <th>#{html_escape(h)}</th>" }
    html << '    </tr></thead><tbody>'
    if section['rows'].empty?
      col_span = section['headers'].size
      html << "      <tr><td colspan=\"#{col_span}\" class=\"empty-tab\">No objects exported for this table.</td></tr>"
    else
      section['rows'].each do |cells|
        html << '      <tr>'
        cells.each { |cell| html << "        <td>#{cell}</td>" }
        html << '      </tr>'
      end
    end
    html << '    </tbody></table>'
    html << '  </div>' if use_tabs
  end

  html << '  <script>'
  html << '    function openEmbeddedMedia(anchor) {'
  html << '      if (!anchor) return false;'
  html << '      var url = anchor.getAttribute("href");'
  html << '      if (!url || url === "#") {'
  html << '        var img = anchor.querySelector("img");'
  html << '        if (img) { url = img.getAttribute("src"); }'
  html << '      }'
  html << '      if (!url) return false;'
  html << '      var w = window.open("", "_blank");'
  html << '      if (!w) return false;'
  html << '      var doc = w.document;'
  html << '      doc.open();'
  html << '      doc.write("<!doctype html><html><head><meta charset=\\"utf-8\\"><title>Embedded image</title>");'
  html << '      doc.write("<style>body{margin:0;background:#1e1e1e;display:flex;justify-content:center;align-items:center;min-height:100vh;}");'
  html << '      doc.write("img{max-width:100%;max-height:100vh;height:auto;}</style></head><body></body></html>");'
  html << '      doc.close();'
  html << '      var imgEl = doc.createElement("img");'
  html << '      imgEl.src = url;'
  html << '      doc.body.appendChild(imgEl);'
  html << '      return false;'
  html << '    }'
  if use_tabs
    html << '    function showReportTab(index, btn) {'
    html << '      var panels = document.querySelectorAll(".tab-panel");'
    html << '      for (var i = 0; i < panels.length; i++) { panels[i].classList.remove("active"); }'
    html << '      var buttons = document.querySelectorAll(".tab-btn");'
    html << '      for (var j = 0; j < buttons.length; j++) { buttons[j].classList.remove("active"); }'
    html << '      var panel = document.getElementById("report-tab-panel-" + index);'
    html << '      if (panel) { panel.classList.add("active"); }'
    html << '      if (btn) { btn.classList.add("active"); }'
    html << '    }'
  end
  html << '  </script>'

  html << '</body></html>'
  html.join("\n")
end

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if EXPORT_CONFIG.nil? || EXPORT_CONFIG.empty?
  WSApplication.message_box(
    "EXPORT_CONFIG is empty.\n\nEdit the configuration section at the top of the script.",
    'OK', '!', false
  )
  raise 'abort'
end

net = WSApplication.current_network
if net.nil?
  WSApplication.message_box(
    "No open network found.\n\nOpen a network, then run via Network > Run Ruby Script.",
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

prompt1 = WSApplication.prompt(
  'Configured export — single-file HTML (embedded media)',
  [
    ['Process SELECTION only?', 'Boolean', false],
    ['Embed local images in HTML?', 'Boolean', true],
    ['Embedded image display:', 'String', IMAGE_DISPLAY_CHOICES[0], nil, 'LIST', IMAGE_DISPLAY_CHOICES],
    ['Embed other local files (e.g. PDF)?', 'Boolean', false],
    ['Embed local video files in HTML?', 'Boolean', false],
    ['Max embed size per file (MB, 0 = no limit):', 'String', '8'],
    ['SNumbatData root (parent of Attachments & Videos folders):',
     'String', file_root, nil, 'FOLDER', 'Select SNumbatData folder'],
    ['Output folder:', 'String', default_output, nil, 'FOLDER', 'Select output folder'],
    ['Output filename:', 'String', 'IAM_AttachmentLinks_ConfiguredTables_Embedded.html'],
  ],
  false
)

if prompt1.nil?
  WSApplication.message_box("Dialog closed\nScript cancelled.", 'OK', '!', false)
  raise 'abort'
end

selection_only = prompt_bool(prompt_val(prompt1, 0, false))
embed_images   = prompt_bool(prompt_val(prompt1, 1, true))
image_display  = image_display_mode_from_choice(prompt_val(prompt1, 2, IMAGE_DISPLAY_CHOICES[0]))
embed_other    = prompt_bool(prompt_val(prompt1, 3, false))
embed_videos   = prompt_bool(prompt_val(prompt1, 4, false))
max_mb_text    = prompt_val(prompt1, 5, '8').to_s.strip
max_mb         = max_mb_text.empty? ? 8 : max_mb_text.to_i
max_mb         = 8 if max_mb < 0
max_bytes      = max_mb.zero? ? 2_147_483_647 : max_mb * 1024 * 1024
file_root      = normalise_snumbatdata_root(prompt_val(prompt1, 6, file_root))
output_folder  = prompt_val(prompt1, 7, default_output).to_s.strip
output_name    = prompt_val(prompt1, 8, 'IAM_AttachmentLinks_ConfiguredTables_Embedded.html').to_s.strip
output_name    = 'IAM_AttachmentLinks_ConfiguredTables_Embedded.html' if output_name.empty?
output_name   += '.html' unless output_name.downcase.end_with?('.html')
output_html    = win_join(output_folder, output_name)

if output_folder.empty?
  WSApplication.message_box("Output folder is required.\nScript cancelled.", 'OK', '!', false)
  raise 'abort'
end

att_store = file_root.empty? ? '' : win_join(file_root, 'Attachments', db_guid)
vid_store = file_root.empty? ? '' : win_join(file_root, 'Videos', db_guid)
att_uids = scan_uid_store(att_store)
vid_uids = scan_uid_store(vid_store)
all_uids = vid_uids.merge(att_uids)

embed_ctx = {
  'embed_images' => embed_images,
  'image_display' => image_display,
  'embed_other' => embed_other,
  'embed_videos' => embed_videos,
  'max_bytes' => max_bytes,
  'cache' => {},
  'stats' => { 'embedded' => 0, 'linked' => 0, 'skipped' => 0 }
}

known_tables = {}
net.tables.each { |t| known_tables[t.name] = true }

sections = []
EXPORT_CONFIG.each do |entry|
  table_name = entry['table'].to_s.strip
  fields = entry['fields']
  if table_name.empty? || fields.nil? || fields.empty?
    puts 'Skipping config entry with no table or fields'
    next
  end
  unless known_tables[table_name]
    puts "Warning: table '#{table_name}' not found in open network — skipped"
    next
  end

  raw_headers = entry['headers']
  if raw_headers.nil? || raw_headers.size != fields.size
    headers = fields.map { |f| default_column_header(f) }
  else
    headers = fields.each_with_index.map { |f, i| resolve_column_header(f, raw_headers[i]) }
  end

  field_names = table_field_name_list(net, table_name)
  blob_field_names = table_blob_field_names(net, table_name)
  fields.each do |token|
    parsed = parse_field_token(token)
    base = parsed['base']
    subs = blob_subfields_from_mode(parsed['mode'])
    if subs
      if base == 'attachments' || blob_field_names.include?(base)
        child_names = blob_child_field_names(net, table_name, base)
        unless child_names.empty?
          subs.each do |sf|
            puts "Warning: #{table_name}.#{base} — sub-field '#{sf}' not in blob schema" unless child_names.include?(sf)
          end
        end
      end
      next
    end
    next if base == 'attachments'
    next if parsed['mode'] == 'count' || parsed['mode'] == 'links'
    next if field_names.include?(base)
    puts "Warning: #{table_name} — field '#{parsed['base']}' not in table schema"
  end

  row_set = network_rows(net, table_name, selection_only)
  if row_set.nil?
    puts "Skipped #{table_name} — cannot read row objects on this IAM build"
    next
  end

  data_rows = []
  row_set.each do |ro|
    next if ro.nil?
    cells = fields.map do |token|
      resolve_field_cell(ro, token, att_store, vid_store, att_uids, all_uids, field_names, blob_field_names, embed_ctx)
    end
    data_rows << cells
  end

  sections << {
    'table_name' => table_name,
    'table_label' => table_description(net, table_name),
    'headers' => headers,
    'rows' => data_rows
  }
  puts "Exported #{table_name}: #{data_rows.size} object row(s)"
end

if sections.empty?
  WSApplication.message_box(
    "No data exported.\n\nCheck EXPORT_CONFIG table names match the open network.",
    'OK', '!', false
  )
  raise 'abort'
end

network_name = network_display_name(net)
scope_label  = selection_only ? 'Selection only' : 'All network objects'
object_count = sections.inject(0) { |sum, s| sum + s['rows'].size }

stats = embed_ctx['stats']
meta_lines = [
  "Scope: #{html_escape(scope_label)}",
  "Database GUID: #{html_escape(db_guid.empty? ? 'Not detected' : db_guid)}",
  "File root: #{html_escape(file_root.empty? ? 'Not configured' : file_root)}",
  "Configured tables: #{sections.size}",
  "Object rows: #{object_count}",
  "Embedded files: #{stats['embedded']} unique | Linked (not embedded): #{stats['linked']} | Skipped (missing/too large): #{stats['skipped']}"
]

html = build_configured_export_html(network_name, meta_lines, sections)
FileUtils.mkdir_p(output_folder)
File.open(output_html, 'w') { |f| f.write(html) }

puts "Created: #{output_html}"

summary = "Report created (single-file HTML).\n\nFile: #{output_html}\nTables: #{sections.size}\nObject rows: #{object_count}\nEmbedded: #{stats['embedded']} unique file(s)"
if WSApplication.message_box("#{summary}\n\nOpen report in your default browser?", 'YesNo', 'Information', false) == 'yes'
  system("start \"\" \"#{output_html.gsub('/', '\\')}\"")
end
