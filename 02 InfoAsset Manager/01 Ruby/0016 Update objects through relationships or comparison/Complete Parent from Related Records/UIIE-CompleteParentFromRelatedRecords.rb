## Mark parent object records complete when every related work order is completed or resolved.
## Also sets the parent completion date from the latest related completed/resolved date.
##
## Works with both default IAM object tables (for example wams_order, wams_general_maintenance)
## and user-defined custom objects (for example wams__case). Parent and related entries
## can be mixed in the same configuration.
##
## The bundled PARENT_OBJECT_CONFIGS below is an internal testing example only. Replace
## all table, navigate, link_field, and field names for your network.
##
## Add one PARENT_OBJECT_CONFIGS entry per parent table. Each entry has its own
## related_types list.
##
## Run from InfoAsset Manager UI with a Distribution network open:
##   Network > Run Ruby Script...
##
## EXCHANGE CONFIG (used when run via InfoAsset Exchange)
distribution_network_id = 1
commit_message = 'Complete parent from related records'

PARENT_OBJECT_CONFIGS = [
	{
		label: 'Case',
		table: 'wams__case',
		completed_field: 'completed',
		completed_date_field: 'date_completed',
		related_types: [
			{ label: 'Water Station Repair', navigate: 'waterstationrepair', table: 'wams__waterstationrepair', link_field: 'srmcase_', status_field: 'completed', date_field: 'date_completed' },
			{ label: 'Water Meter Repair', navigate: 'watermeterreplace', table: 'wams__watermeterrepair', link_field: 'srmcase_', status_field: 'completed', date_field: 'date_completed' },
			{ label: 'General Maintenance', navigate: 'generalmaintenance', table: 'wams_general_maintenance', link_field: 'work_package', status_field: 'completed', date_field: 'date_completed' }
		]
	}
	# Add another parent table section here, for example:
	# {
	# 	label: 'Works',
	# 	table: 'wams__works',
	# 	completed_field: 'completed',
	# 	completed_date_field: 'date_completed',
	# 	related_types: [
	# 		{ label: 'Hydrant maintenance', navigate: 'hydrant_maintenances', table: 'wams_hydrant_maintenance', link_field: 'work_package', status_field: 'completed', date_field: 'date_completed' },
	# 		{ label: 'General maintenance', navigate: 'general_maintenances', table: 'wams_general_maintenance', link_field: 'work_package', status_field: 'completed', date_field: 'date_completed' }
	# 	]
	# }
]

def flag_true?(value)
	return true if value == true
	return false if value == false || value.nil?

	value.to_i == 1 || value.to_s.strip.downcase == 'true'
end

def read_datetime(value)
	return value if value.is_a?(Time) || value.is_a?(DateTime)
	return value.to_time if value.is_a?(Date)

	text = value.to_s.strip
	return nil if text.empty?

	Time.parse(text)
rescue StandardError
	begin
		Date.parse(text).to_time
	rescue StandardError
		nil
	end
end

def prompt_bool(value)
	value == true || value.to_s.strip.downcase == 'true'
end

def prompt_val(prompt_result, index, default = nil)
	return default if prompt_result.nil?
	return prompt_result[index] if prompt_result.is_a?(Array)

	default
end

def format_flag(value)
	return 'true' if value == true
	return 'false' if value == false
	return '(blank)' if value.nil? || value.to_s.strip.empty?

	value.to_s
end

def format_datetime(value, raw: false)
	parsed = read_datetime(value)
	return '(blank)' if parsed.nil? && (value.nil? || value.to_s.strip.empty?)
	return parsed.strftime('%Y-%m-%d %H:%M:%S') if parsed

	raw ? value.to_s : '(unparseable)'
end

def related_type_label(config)
	label = config[:label].to_s.strip
	return label unless label.empty?

	config[:navigate] || config[:table] || 'Related type'
end

def related_work_orders(parent, related_config, net)
	found = {}

	add = lambda do |row, source|
		id = row.id.to_s.strip
		return if id.empty?

		found[id] = { row: row, sources: [] } unless found.key?(id)
		found[id][:sources] << source unless found[id][:sources].include?(source)
	end

	if related_config[:navigate] && parent.respond_to?(:navigate)
		begin
			children = parent.navigate(related_config[:navigate])
			children.each { |row| add.call(row, 'navigate') } if children && !children.empty?
		rescue StandardError => e
			found[:__navigate_error__] = { error: e.message, sources: ['navigate (failed)'] }
		end
	end

	table = related_config[:table]
	link  = related_config[:link_field]
	if table && link
		begin
			net.row_objects(table).each do |row|
				add.call(row, "link #{link}") if row[link].to_s.strip == parent.id.to_s.strip
			end
		rescue StandardError => e
			found[:__table_error__] = { error: e.message, sources: ["table #{table} (failed)"] }
		end
	end

	found
end

def parent_work_order_summary(parent, parent_config, net)
	total = 0
	complete = 0
	latest_date = nil
	details = []
	type_details = []

	parent_config[:related_types].each do |related_config|
		found = related_work_orders(parent, related_config, net)
		navigate_error = found.delete(:__navigate_error__)
		table_error = found.delete(:__table_error__)

		rows = found.values
		type_total = rows.length
		type_complete = 0
		work_orders = []
		type_label = related_type_label(related_config)

		rows.each do |entry|
			wo = entry[:row]
			status_value = wo[related_config[:status_field]]
			status_done = flag_true?(status_value)
			date_raw = wo[related_config[:date_field]]
			date_parsed = read_datetime(date_raw)

			type_complete += 1 if status_done
			latest_date = date_parsed if status_done && date_parsed && (latest_date.nil? || date_parsed > latest_date)

			work_orders << {
				id: wo.id.to_s,
				sources: entry[:sources],
				status_field: related_config[:status_field],
				status_value: status_value,
				status_done: status_done,
				date_field: related_config[:date_field],
				date_raw: date_raw,
				date_parsed: date_parsed
			}
		end

		total += type_total
		complete += type_complete
		details << "#{type_label}: #{type_complete}/#{type_total}" if type_total > 0

		type_details << {
			label: type_label,
			navigate: related_config[:navigate],
			table: related_config[:table],
			link_field: related_config[:link_field],
			total: type_total,
			complete: type_complete,
			work_orders: work_orders,
			navigate_error: navigate_error ? navigate_error[:error] : nil,
			table_error: table_error ? table_error[:error] : nil
		}
	end

	{
		total: total,
		complete: complete,
		latest_date: latest_date,
		details: details,
		type_details: type_details,
		all_complete: total > 0 && complete == total
	}
end

def log_verbose_parent_header(parent, parent_id, parent_config)
	puts ''
	puts "=== #{parent_config[:label]}: #{parent_id} (#{parent_config[:table]}) ==="
	puts "  Current #{parent_config[:completed_field]}: #{format_flag(parent[parent_config[:completed_field]])}"
	puts "  Current #{parent_config[:completed_date_field]}: #{format_datetime(parent[parent_config[:completed_date_field]], raw: true)}"
end

def log_verbose_type_details(summary, parent_config)
	summary[:type_details].each do |type|
		puts "  [#{type[:label]}] #{type[:complete]}/#{type[:total]}"
		puts "    navigate: #{type[:navigate]}"
		puts "    fallback: #{type[:table]}.#{type[:link_field]} = parent.id"
		puts "    navigate error: #{type[:navigate_error]}" if type[:navigate_error]
		puts "    table scan error: #{type[:table_error]}" if type[:table_error]

		if type[:work_orders].empty?
			puts '    (no related records found)'
		else
			type[:work_orders].each do |wo|
				status_mark = wo[:status_done] ? 'DONE' : 'OPEN'
				date_text = format_datetime(wo[:date_raw], raw: true)
				source_text = wo[:sources].join(', ')
				puts "    - #{wo[:id]} | via #{source_text}"
				puts "      #{wo[:status_field]}=#{format_flag(wo[:status_value])} | #{wo[:date_field]}=#{date_text} | #{status_mark}"
			end
		end
	end

	if summary[:latest_date]
		puts "  Latest related date: #{summary[:latest_date].strftime('%Y-%m-%d %H:%M:%S')}"
	else
		puts '  Latest related date: (none found on completed/resolved records)'
	end
end

def records_to_process(net, parent_config, selection_only)
	table = parent_config[:table]

	if selection_only && net.respond_to?(:row_objects_selection)
		selected = net.row_objects_selection(table)
		return selected if selected && !selected.empty?
	end

	net.row_objects(table)
end

def empty_stats
	{
		scanned: 0,
		already_complete: 0,
		no_related: 0,
		incomplete: 0,
		updated: 0
	}
end

def open_network(distribution_network_id)
	if WSApplication.ui?
		net = WSApplication.current_network
		raise 'No open network. Open a Distribution network and run again.' if net.nil?

		return [net, nil]
	end

	db = WSApplication.open
	dbnet = db.model_object_from_type_and_id('Distribution Network', distribution_network_id)
	current_commit_id = dbnet.current_commit_id
	latest_commit_id = dbnet.latest_commit_id
	if latest_commit_id > current_commit_id
		puts "Updating from Commit ID #{current_commit_id} to Commit ID #{latest_commit_id}"
		dbnet.update
	else
		puts 'Network is up to date'
	end

	[dbnet.open, dbnet]
rescue StandardError => e
	raise "Could not open Distribution Network #{distribution_network_id}: #{e.message}"
end

def run_parent_completion(net, parent_config, selection_only:, dry_run:, verbose:)
	stats = empty_stats
	label = parent_config[:label]
	table = parent_config[:table]

	records = records_to_process(net, parent_config, selection_only)
	if records.nil? || records.count == 0
		puts "No #{label} records found#{selection_only ? ' in the current selection' : ''} (#{table})."
		return stats
	end

	puts ''
	puts "--- #{label} (#{table}) ---"
	puts "#{label} records to scan: #{records.count}"

	records.each do |parent|
		stats[:scanned] += 1
		parent_id = parent.id.to_s

		if flag_true?(parent[parent_config[:completed_field]])
			stats[:already_complete] += 1
			if verbose
				log_verbose_parent_header(parent, parent_id, parent_config)
				puts '  Result: SKIP - already marked complete'
			end
			next
		end

		summary = parent_work_order_summary(parent, parent_config, net)

		if summary[:total] == 0
			stats[:no_related] += 1
			if verbose
				log_verbose_parent_header(parent, parent_id, parent_config)
				log_verbose_type_details(summary, parent_config)
				puts '  Result: SKIP - no related work orders found'
			end
			next
		end

		unless summary[:all_complete]
			stats[:incomplete] += 1
			if verbose
				log_verbose_parent_header(parent, parent_id, parent_config)
				log_verbose_type_details(summary, parent_config)
				puts "  Result: INCOMPLETE (#{summary[:complete]}/#{summary[:total]} related records done)"
			end
			next
		end

		date_text = summary[:latest_date] ? summary[:latest_date].strftime('%Y-%m-%d %H:%M:%S') : 'no date found'

		if verbose
			log_verbose_parent_header(parent, parent_id, parent_config)
			log_verbose_type_details(summary, parent_config)
			puts "  Result: #{dry_run ? 'WOULD COMPLETE' : 'COMPLETE'} -> #{parent_config[:completed_date_field]}=#{date_text}"
		else
			puts "#{dry_run ? 'Would complete' : 'Completing'} #{label}: #{parent_id} -> #{date_text}"
			puts "  #{summary[:details].join('; ')}"
		end

		unless dry_run
			parent[parent_config[:completed_field]] = true
			parent[parent_config[:completed_date_field]] = summary[:latest_date] if summary[:latest_date]
			parent.write
		end

		stats[:updated] += 1
	end

	stats
end

def run_all_completions(net, selection_only:, dry_run:, verbose:)
	if PARENT_OBJECT_CONFIGS.nil? || PARENT_OBJECT_CONFIGS.empty?
		abort 'No parent object configurations defined. Add entries to PARENT_OBJECT_CONFIGS.'
	end

	total_stats = empty_stats
	section_stats = {}

	puts "Mode: #{dry_run ? 'DRY RUN (no writes)' : 'UPDATE'}"
	puts "Parent sections configured: #{PARENT_OBJECT_CONFIGS.length}"

	unless dry_run
		net.transaction_begin
	end

	PARENT_OBJECT_CONFIGS.each do |parent_config|
		stats = run_parent_completion(
			net,
			parent_config,
			selection_only: selection_only,
			dry_run: dry_run,
			verbose: verbose
		)

		section_stats[parent_config[:label]] = stats
		total_stats.each_key do |key|
			total_stats[key] += stats[key]
		end
	end

	unless dry_run
		net.transaction_commit
	end

	[total_stats, section_stats]
end

selection_only = true
dry_run = true
verbose = false

net, net_mo = open_network(distribution_network_id)

if WSApplication.ui?
	val = WSApplication.prompt(
		'Complete parent from related records',
		[
			['Process selection only?', 'Boolean', selection_only],
			['Unchecked = all records in each configured parent table.', 'Readonly', ''],
			['Dry run (report only, no writes)?', 'Boolean', dry_run],
			['Recommended for first test run.', 'Readonly', ''],
			['Verbose output?', 'Boolean', verbose]
		],
		false
	)

	if val.nil?
		abort 'Script cancelled - prompt closed.'
	end

	selection_only = prompt_bool(prompt_val(val, 0, selection_only))
	dry_run = prompt_bool(prompt_val(val, 2, dry_run))
	verbose = prompt_bool(prompt_val(val, 4, verbose))

	section_labels = PARENT_OBJECT_CONFIGS.map { |config| config[:label] }.join(', ')
	if WSApplication.message_box(
		"Scan configured parent objects and #{dry_run ? 'report' : 'update'} completion status?\n\n" \
		"Sections: #{section_labels}\n" \
		"Selection only: #{selection_only ? 'Yes' : 'No'}\n" \
		"Dry run: #{dry_run ? 'Yes' : 'No'}",
		'YesNo',
		'Information',
		false
	).to_s.downcase != 'yes'
		abort 'Script cancelled by user.'
	end
end

start_time = Time.now
stats, section_stats = run_all_completions(
	net,
	selection_only: selection_only,
	dry_run: dry_run,
	verbose: verbose
)
elapsed = Time.now - start_time

puts ''
puts 'Summary (all sections)'
puts "  Scanned:           #{stats[:scanned]}"
puts "  Already complete:  #{stats[:already_complete]}"
puts "  No related WOs:    #{stats[:no_related]}"
puts "  Still incomplete:  #{stats[:incomplete]}"
puts "  #{dry_run ? 'Would update' : 'Updated'}:       #{stats[:updated]}"
puts "  Runtime:           #{elapsed.round(2)} sec"

section_stats.each do |label, section|
	next if section[:scanned] == 0 && section[:updated] == 0

	puts ''
	puts "Summary (#{label})"
	puts "  Scanned:           #{section[:scanned]}"
	puts "  Already complete:  #{section[:already_complete]}"
	puts "  No related WOs:    #{section[:no_related]}"
	puts "  Still incomplete:  #{section[:incomplete]}"
	puts "  #{dry_run ? 'Would update' : 'Updated'}:       #{section[:updated]}"
end

unless WSApplication.ui?
	unless dry_run
		net_mo.commit(commit_message) if net_mo
	end
end
