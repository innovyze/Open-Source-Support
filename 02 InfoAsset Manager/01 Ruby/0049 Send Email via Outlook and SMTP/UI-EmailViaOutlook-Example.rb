# ============================================================================
# InfoAsset Manager UI Script
# Script: UI-EmailViaOutlook-Example.rb
# Purpose: Example interactive email via Microsoft Outlook (Windows COM).
#          Sample data: GeoPlan selection on cams_pipe_repair. Adapt for your tables.
#
# Run from: Network > Run Ruby Script (Collection Network open; example objects selected)
# Platform: Windows with Outlook installed (uses win32ole)
# ============================================================================

require 'win32ole'

REPAIR_TABLE = 'cams_pipe_repair'.freeze
PROPERTY_TABLE = 'cams_property'.freeze

DEFAULT_EMAIL_SUBJECT = 'Work order summary (example)'.freeze
DEFAULT_SIGNER_NAME = 'Work Order Process Manager'.freeze
DEFAULT_IAO_LOCALE = 'en-gb'.freeze

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

def build_repair_email_content(net, tasks_selected, network_id:, iao_server:, iao_workspace:)
  intro_html = '<p>Hi,</p><p>Please raise the following orders:</p>'
  repair_sections_html = ''
  repair_count = 0
  skipped_count = 0
  total_repairs = tasks_selected.length
  aborted = false

  tasks_selected.each do |ro|
    pipe = ro.navigate1('pipe')
    if pipe.nil?
      puts "Skipped repair #{repair_label_for(ro)}: no related pipe"
      next
    end

    us_node = pipe.navigate1('us_node')
    validation = validate_repair_row(ro, pipe, us_node)
    repair_label = repair_label_for(ro)

    unless validation[:critical].empty?
      msg = "Critical data missing for repair #{repair_label}: #{validation[:critical].join(', ')}"
      WSApplication.message_box(msg, 'OK', 'Stop', nil)
      puts msg
      aborted = true
      break
    end

    unless validation[:missing].empty?
      msg = "Important data missing for repair #{repair_label}: #{validation[:missing].join(', ')}\n\nInclude this repair in the email?\nYes = Include; No = Skip"
      include_repair = WSApplication.message_box(msg, 'YesNo', '!', false).to_s.downcase == 'yes'
      if include_repair
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
    aborted: aborted
  }
end

def deliver_outlook_message(recipients, subject, html_body, send_immediately)
  outlook = WIN32OLE.new('Outlook.Application')
  message = outlook.CreateItem(0)
  message.Subject = subject
  message.HtmlBody = html_body

  recipients.to_s.split(/[;,]/).map(&:strip).reject(&:empty?).each do |address|
    message.Recipients.Add(address)
  end

  message.Save
  message.Send if send_immediately
end

net = WSApplication.current_network
if net.nil?
  WSApplication.message_box('Open a Collection Network before running this script.', 'OK', '!', nil)
  exit
end

tasks_selected = net.row_object_collection_selection(REPAIR_TABLE)
if tasks_selected.length.zero?
  WSApplication.message_box(
    'Select one or more pipe repair records on the GeoPlan, then run this script again.',
    'OK',
    '?',
    nil
  )
  exit
end

prompt_values = WSApplication.prompt(
  'Email and InfoAsset Online options',
  [
    ['Recipient email address(es)', 'String', 'user@example.com'],
    ['Email subject', 'String', DEFAULT_EMAIL_SUBJECT],
    ['Signer name (email signature)', 'String', DEFAULT_SIGNER_NAME],
    ['IAO server host (optional, e.g. localhost)', 'String', ''],
    ['IAO workspace ID (optional)', 'String', ''],
    ['Send immediately? (No = save Outlook draft only)', 'Boolean', false]
  ],
  false
)

recipient_emails = prompt_values[0].to_s.strip
email_subject = prompt_values[1].to_s.strip
email_subject = DEFAULT_EMAIL_SUBJECT if email_subject.empty?
signer_name = prompt_values[2].to_s.strip
signer_name = DEFAULT_SIGNER_NAME if signer_name.empty?
iao_server = prompt_values[3].to_s.strip
iao_workspace = prompt_values[4].to_s.strip
send_immediately = prompt_values[5] ? true : false

if recipient_emails.empty?
  WSApplication.message_box('At least one recipient email address is required.', 'OK', '!', nil)
  exit
end

result = build_repair_email_content(
  net,
  tasks_selected,
  network_id: network_model_id(net),
  iao_server: iao_server,
  iao_workspace: iao_workspace
)

if result[:aborted] || result[:repair_count].zero?
  WSApplication.message_box('Email was not created.', 'OK', '!', nil) if result[:aborted]
  if !result[:aborted] && result[:repair_count].zero?
    detail = result[:skipped_count] > 0 ? " (#{result[:skipped_count]} skipped)" : ''
    WSApplication.message_box("No repair content was generated; email not sent#{detail}.", 'OK', '!', nil)
  end
  exit
end

puts "Repairs included in email: #{result[:repair_count]}; skipped: #{result[:skipped_count]}" if result[:skipped_count] > 0

html_body = build_html_body(
  result[:intro_html],
  result[:repair_sections_html],
  signer_name,
  email_subject
)
puts html_body

begin
  deliver_outlook_message(recipient_emails, email_subject, html_body, send_immediately)
rescue StandardError => e
  WSApplication.message_box("Outlook could not send the message: #{e.message}", 'OK', 'Stop', nil)
  puts e.full_message
  exit
end

if send_immediately
  WSApplication.message_box("Email sent to #{recipient_emails}.", 'OK', 'Information', nil)
else
  WSApplication.message_box('Email saved as an Outlook draft. Review and send from Outlook.', 'OK', 'Information', nil)
end
