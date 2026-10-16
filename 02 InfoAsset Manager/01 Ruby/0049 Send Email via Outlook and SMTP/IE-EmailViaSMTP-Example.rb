# ============================================================================
# InfoAsset Manager Exchange Script
# Script: IE-EmailViaSMTP-Example.rb
# Purpose: Example unattended email via InfoAsset Exchange and SMTP.
#          Sample query: cams_pipe_repair where completed is not true.
#          Adapt table, filter, and HTML for your own objects.
#
# Run from: iexchange.exe with database context, e.g. scheduled task + .bat
# ============================================================================

REPAIR_TABLE = 'cams_pipe_repair'.freeze
PROPERTY_TABLE = 'cams_property'.freeze

DEFAULT_EMAIL_SUBJECT = 'Work order summary (example)'.freeze
DEFAULT_SIGNER_NAME = 'Work Order Process Manager'.freeze
DEFAULT_IAO_LOCALE = 'en-gb'.freeze

# --- Exchange configuration (edit for your environment) ---
COLLECTION_NETWORK_ID = 1

RECIPIENT_EMAILS = 'works@example.com'
EMAIL_SUBJECT = DEFAULT_EMAIL_SUBJECT
SIGNER_NAME = DEFAULT_SIGNER_NAME
IAO_SERVER = ''
IAO_WORKSPACE = ''

# :skip = omit records with important gaps; :include = keep them in the email
IMPORTANT_MISSING_POLICY = :skip
# :skip = omit record and continue; :abort = stop the whole job on first critical gap
CRITICAL_MISSING_POLICY = :skip

# true = write HTML only (no SMTP). Recommended for first test run.
DRY_RUN = true
OUTPUT_HTML_PATH = 'C:/Temp/iam_email_smtp_example.html'

# When DRY_RUN is false and SEND_VIA_SMTP is true, send via SMTP (see smtp.env.example.txt).
SEND_VIA_SMTP = true

# false = do not print full HTML to the console (still written to OUTPUT_HTML_PATH when saving).
VERBOSE_HTML_TO_CONSOLE = false

# Optional SMTP host/from/user in script. Password must stay in IAM_SMTP_PASSWORD (smtp.local.env).
SMTP_HOST = ''
SMTP_PORT = 587
SMTP_FROM = ''
SMTP_USER = ''
# --- end configuration ---

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

def build_iao_repair_url(server, workspace_id, network_id, repair_id, locale = DEFAULT_IAO_LOCALE)
  return '' if server.to_s.strip.empty? || workspace_id.to_s.strip.empty?
  return '' if network_id.nil? || repair_id.to_s.strip.empty?

  host = server.to_s.strip.sub(%r{\Ahttps?://}i, '').sub(%r{/.*\z}, '')
  suffix = "/activeObject;uri=mo%252Fcnn%252Fcnn.#{network_id}%252Fro%253Ftable%253D#{REPAIR_TABLE}&id%253D#{double_url_encode_iao(repair_id)}"
  "https://#{host}:30303/InfoAssetOnline/#{locale}/workspaces/webwsp.#{workspace_id.strip}##{suffix.sub(%r{\A/}, '')}"
end

def pipe_link_id(us_node_id, ds_node_id, link_suffix)
  "#{us_node_id}.#{ds_node_id}.#{link_suffix}"
end

def html_escape(text)
  text.to_s
      .gsub('&', '&amp;')
      .gsub('<', '&lt;')
      .gsub('>', '&gt;')
      .gsub('"', '&quot;')
end

def field_missing?(value)
  value.nil? || (value.respond_to?(:empty?) && value.empty?)
end

def format_display_number(value, precision = nil)
  return '(missing)' if field_missing?(value)

  formatted = precision.nil? ? value.round : value.round(precision)
  formatted.to_s
end

def flag_true?(value)
  return true if value == true
  return false if value == false || value.nil?

  value.to_i == 1 || value.to_s.strip.downcase == 'true'
end

def repair_incomplete?(ro)
  return true unless ro.respond_to?(:completed)

  !flag_true?(ro.completed)
end

def collect_incomplete_pipe_repairs(net)
  repairs = []
  net.row_objects(REPAIR_TABLE).each do |ro|
    repairs << ro if repair_incomplete?(ro)
  end
  repairs
end

def network_model_id(net)
  mo = net.model_object
  mo ? mo.id : nil
rescue StandardError
  nil
end

def validate_repair_row(ro, pipe, us_node)
  missing = []
  critical = []

  critical << 'US node X coordinate' if us_node.nil? || field_missing?(us_node.x)
  critical << 'US node Y coordinate' if us_node.nil? || field_missing?(us_node.y)
  critical << 'Pipe size' if pipe.nil? || field_missing?(pipe.width)

  missing << 'Repair type' if field_missing?(ro.repair_type)
  missing << 'Location' if field_missing?(ro.location)
  missing << 'UID' if field_missing?(ro.id)
  missing << 'Pipe depth' if pipe.nil? || field_missing?(pipe.ds_depth_from_cover)
  missing << 'Job number' if field_missing?(ro.job_number)
  missing << 'Contractor' if field_missing?(ro.contractor)
  missing << 'Start length' if field_missing?(ro.start_length)
  missing << 'Repair length' if field_missing?(ro.repair_length)
  missing << 'US manhole' if field_missing?(ro.us_node_id)

  { critical: critical, missing: missing }
end

def append_property_details(paragraph, net, pipe)
  return paragraph if pipe.nil?

  pipe_id = pipe.id.to_s
  net.row_object_collection(PROPERTY_TABLE).each do |prop|
    sanitary_id = pipe_link_id(prop.sanitary_us_node_id, prop.sanitary_ds_node_id, prop.sanitary_link_suffix)
    storm_id = pipe_link_id(prop.storm_us_node_id, prop.storm_ds_node_id, prop.storm_link_suffix)
    next unless sanitary_id == pipe_id || storm_id == pipe_id

    paragraph += '<br/><br/>Customer contact ID: ' + html_escape(prop.id)
    paragraph += '<br/>Street: ' + html_escape(prop.property_address)
    paragraph += '<br/>Town: ' + html_escape(prop.property_town)
    paragraph += '<br/>District: ' + html_escape(prop.property_district)
    paragraph += '<br/>Postcode: ' + html_escape(prop.property_postalcode)
    paragraph += '<br/>'
  end
  paragraph
end

def append_repair_section(paragraph, ro, pipe, us_node, repair_index, repair_total, iao_url)
  repair_end = nil
  unless field_missing?(ro.start_length) || field_missing?(ro.repair_length)
    repair_end = ro.start_length + ro.repair_length
  end
  us_x = field_missing?(us_node.x) ? '(missing)' : us_node.x.floor
  us_y = field_missing?(us_node.y) ? '(missing)' : us_node.y.floor

  paragraph += "Repair #{repair_index} of #{repair_total}<br/>"
  paragraph += 'Repair type: ' + html_escape(field_missing?(ro.repair_type) ? '(missing)' : ro.repair_type) + '<br/>'
  paragraph += 'Location: ' + html_escape(field_missing?(ro.location) ? '(missing)' : ro.location) + " (US X #{us_x}, Y #{us_y})<br/>"
  paragraph += 'UID: ' + html_escape(field_missing?(ro.id) ? '(missing)' : ro.id) + '<br/>'
  paragraph += 'Pipe size: ' + html_escape(format_display_number(pipe.width)) + ', Pipe depth: '
  paragraph += html_escape(format_display_number(pipe.ds_depth_from_cover, 2)) + ' m, Pipe material: '
  paragraph += html_escape(field_missing?(pipe.pipe_material) ? '(missing)' : pipe.pipe_material) + '<br/>'
  paragraph += 'Job code: ' + html_escape(field_missing?(ro.job_number) ? '(missing)' : ro.job_number) + ', Raised by: '
  paragraph += html_escape(field_missing?(ro.team_leader) ? '(missing)' : ro.team_leader) + ', Contractor: '
  paragraph += html_escape(field_missing?(ro.contractor) ? '(missing)' : ro.contractor) + '<br/>'
  if repair_end.nil?
    paragraph += 'Chainage from US manhole: (missing start length or repair length)<br/>'
  else
    paragraph += 'Chainage from US manhole: from ' + html_escape(format_display_number(ro.start_length, 2))
    paragraph += ' to ' + html_escape(format_display_number(repair_end, 2)) + ' m (length '
    paragraph += html_escape(format_display_number(ro.repair_length, 2)) + ' m), downstream from: '
    paragraph += html_escape(field_missing?(ro.us_node_id) ? '(missing)' : ro.us_node_id) + '<br/>'
  end

  unless iao_url.to_s.empty?
    paragraph += 'IAO link: <a href="' + html_escape(iao_url) + '">' + html_escape(iao_url) + '</a><br/>'
  end

  paragraph += '<br/>If job scope changes to a dig, full prints must be obtained before further works commence.<br/>'
  paragraph
end

def build_html_body(intro_html, repair_sections_html, signer_name, email_subject = DEFAULT_EMAIL_SUBJECT)
  <<~HTML
    <!DOCTYPE html>
    <html>
      <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>#{html_escape(email_subject)}</title>
      </head>
      <body>
        #{intro_html}
        #{repair_sections_html}
        <p>Standard TM<br/>
        Complete within 30 days</p>
        <p>Cheers,<br/>
        <strong>#{html_escape(signer_name)}</strong></p>
      </body>
    </html>
  HTML
end

def repair_label_for(ro)
  field_missing?(ro.id) ? '(repair ID unknown)' : ro.id.to_s
end

def build_repair_email_content(net, tasks_selected, network_id:, iao_server:, iao_workspace:,
                               important_policy:, critical_policy:)
  intro_html = '<p>Hi,</p><p>Please raise the following orders:</p>'
  repair_sections_html = ''
  repair_count = 0
  skipped_count = 0
  skipped_no_pipe = 0
  total_repairs = tasks_selected.length
  aborted = false

  tasks_selected.each do |ro|
    pipe = ro.navigate1('pipe')
    if pipe.nil?
      skipped_no_pipe += 1
      puts "Skipped repair #{repair_label_for(ro)}: no related pipe"
      next
    end

    us_node = pipe.navigate1('us_node')
    validation = validate_repair_row(ro, pipe, us_node)
    repair_label = repair_label_for(ro)

    unless validation[:critical].empty?
      msg = "Critical data missing for repair #{repair_label}: #{validation[:critical].join(', ')}"
      if critical_policy == :abort
        puts msg
        aborted = true
        break
      end

      skipped_count += 1
      puts "Skipped repair #{repair_label}: #{validation[:critical].join(', ')}"
      next
    end

    unless validation[:missing].empty?
      if important_policy == :include
        puts "Including repair #{repair_label} despite missing: #{validation[:missing].join(', ')}"
      else
        skipped_count += 1
        puts "Skipped repair #{repair_label}: #{validation[:missing].join(', ')}"
        next
      end
    end

    repair_count += 1
    iao_url = build_iao_repair_url(iao_server, iao_workspace, network_id, ro.id)
    repair_sections_html = append_repair_section(
      repair_sections_html,
      ro,
      pipe,
      us_node,
      repair_count,
      total_repairs,
      iao_url
    )
    repair_sections_html = append_property_details(repair_sections_html, net, pipe)
    repair_sections_html += '<hr/>'
  end

  {
    intro_html: intro_html,
    repair_sections_html: repair_sections_html,
    repair_count: repair_count,
    skipped_count: skipped_count,
    skipped_no_pipe: skipped_no_pipe,
    total_repairs: total_repairs,
    aborted: aborted
  }
end

def smtp_settings_from_env
  host = ENV['IAM_SMTP_HOST'].to_s.strip
  host = SMTP_HOST.to_s.strip if host.empty? && defined?(SMTP_HOST)

  port = (ENV['IAM_SMTP_PORT'] || (defined?(SMTP_PORT) ? SMTP_PORT : nil) || '587').to_i

  from = ENV['IAM_SMTP_FROM'].to_s.strip
  from = SMTP_FROM.to_s.strip if from.empty? && defined?(SMTP_FROM)

  user = ENV['IAM_SMTP_USER'].to_s.strip
  user = SMTP_USER.to_s.strip if user.empty? && defined?(SMTP_USER)

  {
    host: host,
    port: port,
    user: user,
    password: ENV['IAM_SMTP_PASSWORD'].to_s,
    from: from,
    helo: ENV['IAM_SMTP_HELO'].to_s.strip,
    enable_starttls: ENV['IAM_SMTP_STARTTLS'].to_s.strip.downcase != 'false',
    auth: (ENV['IAM_SMTP_AUTH'] || 'login').to_sym
  }
end

def smtp_configuration_errors(settings)
  errors = []
  errors << 'SMTP host (IAM_SMTP_HOST or SMTP_HOST in script)' if settings[:host].to_s.empty?
  errors << 'From address (IAM_SMTP_FROM or SMTP_FROM in script)' if settings[:from].to_s.empty?
  unless settings[:user].to_s.empty?
    if settings[:password].to_s.empty?
      errors << 'IAM_SMTP_PASSWORD (required when SMTP_USER / IAM_SMTP_USER is set; use smtp.local.env — see smtp.env.example.txt)'
    end
  end
  errors
end

def write_html_output(path, html_body)
  File.open(path, 'w:UTF-8') { |f| f.write(html_body) }
  puts "HTML written to #{path}"
end

def deliver_smtp_html_message(settings, recipients, subject, html_body)
  require 'net/smtp'

  to_list = recipients.to_s.split(/[;,]/).map(&:strip).reject(&:empty?)
  raise 'No recipient email addresses configured.' if to_list.empty?
  raise 'IAM_SMTP_HOST is not set.' if settings[:host].to_s.empty?

  from_addr = settings[:from].to_s.strip
  raise 'IAM_SMTP_FROM is not set.' if from_addr.empty?

  message = [
    "From: #{from_addr}",
    "To: #{to_list.join(', ')}",
    "Subject: #{subject}",
    'MIME-Version: 1.0',
    'Content-Type: text/html; charset=UTF-8',
    'Content-Transfer-Encoding: 8bit',
    '',
    html_body
  ].join("\r\n")

  helo = settings[:helo].to_s.empty? ? 'localhost' : settings[:helo]
  user = settings[:user]
  password = settings[:password]

  if user.empty?
    Net::SMTP.start(settings[:host], settings[:port], helo) do |smtp|
      smtp.enable_starttls_auto if settings[:enable_starttls]
      smtp.send_message(message, from_addr, to_list)
    end
  else
    raise 'IAM_SMTP_PASSWORD is not set.' if password.to_s.empty?

    Net::SMTP.start(settings[:host], settings[:port], helo, user, password, settings[:auth]) do |smtp|
      smtp.enable_starttls_auto if settings[:enable_starttls]
      smtp.send_message(message, from_addr, to_list)
    end
  end
end

def open_collection_network(network_id)
  db = WSApplication.open
  mo = db.model_object_from_type_and_id('Collection Network', network_id)
  current_commit_id = mo.current_commit_id
  latest_commit_id = mo.latest_commit_id
  if latest_commit_id > current_commit_id
    puts "Updating network from commit #{current_commit_id} to #{latest_commit_id}"
    mo.update
  else
    puts 'Network is up to date'
  end
  [mo.open, mo]
rescue StandardError => e
  abort "Could not open Collection Network #{network_id}: #{e.message}"
end

def run_incomplete_pipe_repair_email
  net, _network_mo = open_collection_network(COLLECTION_NETWORK_ID)
  network_id = network_model_id(net)

  tasks = collect_incomplete_pipe_repairs(net)
  puts "Incomplete pipe repairs found: #{tasks.length}"

  if tasks.empty?
    puts 'No open pipe repairs (completed is not true). Nothing to do.'
    return
  end

  result = build_repair_email_content(
    net,
    tasks,
    network_id: network_id,
    iao_server: IAO_SERVER,
    iao_workspace: IAO_WORKSPACE,
    important_policy: IMPORTANT_MISSING_POLICY,
    critical_policy: CRITICAL_MISSING_POLICY
  )

  if result[:aborted]
    abort 'Job aborted due to critical data on a repair (CRITICAL_MISSING_POLICY = :abort).'
  end

  if result[:repair_count].zero?
    puts "No repairs included (skipped: #{result[:skipped_count]}, no pipe: #{result[:skipped_no_pipe]})."
    return
  end

  html_body = build_html_body(
    result[:intro_html],
    result[:repair_sections_html],
    SIGNER_NAME,
    EMAIL_SUBJECT
  )

  puts html_body if defined?(VERBOSE_HTML_TO_CONSOLE) && VERBOSE_HTML_TO_CONSOLE
  puts "Repairs included: #{result[:repair_count]} / #{result[:total_repairs]} " \
       "(skipped: #{result[:skipped_count]}, no pipe: #{result[:skipped_no_pipe]})"

  if DRY_RUN
    write_html_output(OUTPUT_HTML_PATH, html_body)
    puts 'DRY_RUN: no email sent.'
    return
  end

  unless SEND_VIA_SMTP
    write_html_output(OUTPUT_HTML_PATH, html_body)
    puts 'SEND_VIA_SMTP is false — HTML saved; no email sent.'
    return
  end

  settings = smtp_settings_from_env
  smtp_errors = smtp_configuration_errors(settings)
  unless smtp_errors.empty?
    write_html_output(OUTPUT_HTML_PATH, html_body)
    puts 'SMTP send skipped — configuration incomplete:'
    smtp_errors.each { |item| puts "  - #{item}" }
    puts 'Set variables from smtp.env.example.txt (and IAM_SMTP_PASSWORD), or use DRY_RUN = true.'
    return
  end

  begin
    deliver_smtp_html_message(settings, RECIPIENT_EMAILS, EMAIL_SUBJECT, html_body)
  rescue StandardError => e
    write_html_output(OUTPUT_HTML_PATH, html_body)
    puts "SMTP send failed: #{e.message}"
    puts e.full_message
    return
  end

  puts "SMTP message sent to #{RECIPIENT_EMAILS}"
end

run_incomplete_pipe_repair_email
puts 'Script finished.'
