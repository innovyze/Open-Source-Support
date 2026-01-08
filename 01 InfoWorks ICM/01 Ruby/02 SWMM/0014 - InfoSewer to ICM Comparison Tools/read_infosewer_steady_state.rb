# ============================================================================
# InfoSewer RPT File BATCH Parser - ALL FILES IN/DNEAR DIRECTORY  (FIXED)
# ============================================================================

require 'csv'

cn = WSApplication.current_network

result = WSApplication.prompt(
  "Batch RPT Analysis - Select ANY RPT file (or any file) in/near the target directory",
  [
    ['Pick an RPT file (or any file in the folder you want to scan)', 'String', nil, nil, 'FILE', true, 'RPT Files|*.rpt|All Files|*.*', 'rpt', false],
    ['=== OPTIONS ===', 'READONLY', ''],
    ['Include subdirectories?', 'Boolean', true],
    ['Export combined CSV?', 'Boolean', true],
    ['Show per-file stats?', 'Boolean', false],
    ['Show aggregate stats?', 'Boolean', true]
  ],
  false
)

unless result
  puts "User cancelled."
  exit
end

selected_path = result[0]

unless selected_path && !selected_path.empty?
  WSApplication.message_box("No file selected.", "OK", "!", false)
  exit
end

unless File.exist?(selected_path)
  WSApplication.message_box("Selected path does not exist:\n#{selected_path}", "OK", "!", false)
  exit
end

# Read prompt options with the correct indexes
include_subdirs = !!result[2]
export_csv      = !!result[3]
show_per_file   = !!result[4]
show_aggregate  = !!result[5]

# If a directory got picked, use it directly; else use the file's folder
start_dir =
  if File.directory?(selected_path)
    selected_path
  else
    File.dirname(selected_path)
  end

puts "\n" + "="*80
puts "BATCH RPT FILE ANALYSIS"
puts "="*80
puts "Selected path: #{selected_path}"
puts "Start directory: #{start_dir}"
puts "Include subdirectories: #{include_subdirs ? 'YES' : 'NO'}"

# ----------------------------------------------------------------------------
# Helper: robust RPT discovery
# ----------------------------------------------------------------------------
def find_rpt_files_from_roots(roots, include_subdirs)
  patterns = []
  roots.uniq.each do |root|
    next unless root && Dir.exist?(root)
    if include_subdirs
      patterns << File.join(root, '**', '*.{rpt,RPT}')
    else
      patterns << File.join(root, '*.{rpt,RPT}')
    end
  end
  # File::FNM_CASEFOLD allows case-insensitive matching on Windows too
  patterns.flat_map { |p| Dir.glob(p, File::FNM_CASEFOLD) }.uniq
end

# Build a smart list of search roots:
#  1) start_dir
#  2) its parents
#  3) the sibling folder to "<name>.OUT" (e.g. YOURTOWN if we are under YOURTOWN.OUT)
#  4) a common "Reports" subfolder under that sibling
roots = []
roots << start_dir
roots << File.expand_path('..', start_dir)
roots << File.expand_path('../..', start_dir)

# detect “…\<ProjectName>.OUT\…” and derive the sibling project folder “\<ProjectName>”
path_parts = start_dir.split(/[\\\/]/)
out_index = path_parts.index { |s| s =~ /\.out\z/i }
if out_index
  project_name = path_parts[out_index].sub(/\.out\z/i, '')
  parent_of_out = File.join(*path_parts[0...out_index]) # may be empty on root drive
  project_sibling =
    if parent_of_out.nil? || parent_of_out.empty?
      project_name
    else
      File.join(parent_of_out, project_name)
    end
  roots << project_sibling
  roots << File.join(project_sibling, 'Reports')
end

puts "\n" + "-"*80
puts "SEARCH ROOTS"
puts "-"*80
roots.uniq.each { |r| puts "  - #{r}" }

# Locate RPTs
rpt_files = find_rpt_files_from_roots(roots, include_subdirs)

if rpt_files.empty?
  msg = "No RPT file found in any of the search roots.\n\nFirst root inspected:\n#{start_dir}\n\n" \
        "If you selected a PF folder under *.OUT\\SCENARIO, the RPTs may be in the project folder " \
        "(e.g., YOURTOWN\\Reports) rather than PF1.\n\n" \
        "Roots searched:\n- " + roots.uniq.join("\n- ")
  WSApplication.message_box(msg, "OK", "!", false)
  exit
end

puts "\nFound #{rpt_files.size} RPT file(s). Showing first 10:"
rpt_files.first(10).each_with_index { |f, i| puts "  #{i+1}. #{f}" }
puts "  ... (#{rpt_files.size - 10} more)" if rpt_files.size > 10

# ----------------------------------------------------------------------------
# Define parsing structure
# ----------------------------------------------------------------------------
section_headers = {
  'Loading Manholes' => ['Base', 'Storm', 'Total'],
  'Pumps'            => ['Pump Count', 'Pump Flow', 'Pump Head'],
  'Force Mains'      => ['Pipe Diam', 'Pipe Flow', 'Pipe Vel.', 'Pipe Loss'],
  'Pipes'            => [
    'Pipe Count', 'Pipe Slope', 'Pipe Diam', 'Pipe Flow', 'Pipe Load',
    'UnPeak Flow', 'Peak Flow', 'Cover Flow', 'I/I Flow', 'Flow Veloc',
    'Pipe d/D', 'Actual Depth', 'Flow Number', 'Froude Crit', 'Depth Full',
    'Flow Cover'
  ]
}

columns_to_skip = {
  'Pipes'       => 2,
  'Force Mains' => 2,
  'Pumps'       => 3
}

# ----------------------------------------------------------------------------
# Stats helpers
# ----------------------------------------------------------------------------
def calculate_stats(vals)
  return [0, 0.0, 0.0, 0.0, 0.0] if vals.empty?
  n = vals.size.to_f
  mean = vals.sum / n
  sum_sq = vals.map { |v| (v - mean) ** 2 }.sum
  std = (n > 1) ? Math.sqrt(sum_sq / (n - 1)) : 0.0
  [vals.size, mean, std, vals.min, vals.max]
end

# Return a stats row array for CSV (count, mean, std, min, p25, median, p75, p95, max)
def stats_row(vals)
  return [0, 0, 0, 0, 0, 0, 0, 0, 0] if vals.empty?
  n, mean, std, min, max = calculate_stats(vals)
  sorted = vals.sort
  p25 = sorted[(sorted.size * 0.25).floor]
  p50 = sorted[(sorted.size * 0.50).floor]
  p75 = sorted[(sorted.size * 0.75).floor]
  p95 = sorted[(sorted.size * 0.95).floor]
  [n, mean.round(3), std.round(3), min.round(3), p25.round(3), p50.round(3), p75.round(3), p95.round(3), max.round(3)]
end

# ----------------------------------------------------------------------------
# Parse all files
# ----------------------------------------------------------------------------
puts "\n" + "="*80
puts "PARSING FILES"
puts "="*80

all_files_data = []

rpt_files.each_with_index do |file_path, idx|
  rel_path = file_path
  puts "\n[#{idx+1}/#{rpt_files.size}] #{rel_path}"

  file_data = { path: file_path, relative_path: rel_path, sections: {} }
  current_section = nil

  begin
    File.foreach(file_path, encoding: 'bom|utf-8') do |line|
      line = line.gsub('Exponential 3-Point', 'Exponential3-Point')
      line = line.strip
      next if line.empty?

      if line.start_with?('[') && line.end_with?(']')
        current_section = line[1..-2]
        file_data[:sections][current_section] ||= {}
        next
      end

      headers = section_headers[current_section]
      next unless current_section && headers

      tokens = line.split
      next if tokens.empty?

      num_expected = headers.size
      skip_cols = columns_to_skip[current_section] || 0
      num_to_grab = num_expected + skip_cols

      next if tokens.size < num_to_grab + 1

      data_tokens = tokens.last(num_to_grab)
      id_tokens = tokens.first(tokens.size - num_to_grab)
      id = id_tokens.join(' ')

      skip_cols.times { data_tokens.shift if !data_tokens.empty? }

      values = data_tokens.map { |t| (Float(t) rescue nil) }

      if !id.empty? && values.size == num_expected && !values.any?(&:nil?)
        file_data[:sections][current_section][id] = values
      end
    end

    all_files_data << file_data
    puts "  Parsed sections: #{file_data[:sections].keys.join(', ')}"
  rescue => e
    puts "  ERROR reading #{file_path}: #{e.class}: #{e.message}"
  end
end

puts "\n#{all_files_data.size} files processed successfully"

# ----------------------------------------------------------------------------
# Per-file stats
# ----------------------------------------------------------------------------
if show_per_file
  puts "\n" + "="*80
  puts "PER-FILE STATISTICS"
  puts "="*80

  all_files_data.each_with_index do |fd, idx|
    puts "\n" + "-"*80
    puts "File #{idx+1}: #{fd[:relative_path]}"
    puts "-"*80

    fd[:sections].each do |section, items|
      next if section == 'Title' || items.empty?
      puts "\n  #{section} (#{items.size} items):"
      headers = section_headers[section]
      next unless headers

      headers.each_with_index do |h, ci|
        vals = items.values.map { |r| r[ci] if r && r[ci] }.compact
        next if vals.empty?
        n, mean, std, min, max = calculate_stats(vals)
        printf "    %-20s | n=%-6d mean=%-10.3f std=%-10.3f min=%-10.3f max=%-10.3f\n",
               h, n, mean, std, min, max
      end
    end
  end
end

# ----------------------------------------------------------------------------
# Aggregate stats
# ----------------------------------------------------------------------------
aggregate = {}
all_files_data.each do |fd|
  fd[:sections].each do |section, items|
    next if section == 'Title'
    aggregate[section] ||= {}
    items.each do |id, values|
      aggregate[section][id] ||= []
      aggregate[section][id] << values
    end
  end
end

if show_aggregate
  puts "\n" + "="*80
  puts "AGGREGATE STATISTICS (ALL FILES)"
  puts "="*80

  aggregate.each do |section, items|
    next if items.empty?
    puts "\n" + "-"*80
    puts "#{section} (#{items.size} unique items)"
    puts "-"*80

    headers = section_headers[section]
    next unless headers

    headers.each_with_index do |h, ci|
      all_vals = []
      items.each_value { |file_arrays| file_arrays.each { |row| all_vals << row[ci] if row && row[ci] } }
      next if all_vals.empty?
      n, mean, std, min, max = calculate_stats(all_vals)
      sorted = all_vals.sort
      p25 = sorted[(sorted.size * 0.25).floor]
      p50 = sorted[(sorted.size * 0.50).floor]
      p75 = sorted[(sorted.size * 0.75).floor]
      p95 = sorted[(sorted.size * 0.95).floor]
      printf "  %-20s | n=%-6d mean=%-8.3f std=%-8.3f min=%-8.3f 25%%=%-8.3f med=%-8.3f 75%%=%-8.3f 95%%=%-8.3f max=%-8.3f\n",
             h, n, mean, std, min, p25, p50, p75, p95, max
    end
  end
end

# ----------------------------------------------------------------------------
# CSV export
# ----------------------------------------------------------------------------
if export_csv
  puts "\n" + "="*80
  puts "EXPORTING CSV FILES"
  puts "="*80

  timestamp = Time.now.strftime("%Y%m%d_%H%M%S")
  output_dir = File.join(start_dir, "RPT_Analysis_#{timestamp}")
  begin
    Dir.mkdir(output_dir)
    puts "Output: #{output_dir}"
  rescue
    output_dir = start_dir
    puts "Output: #{output_dir} (using start directory)"
  end

  # Nodes (manholes)
  begin
    manhole_file = File.join(output_dir, "nodes_manholes_#{timestamp}.csv")
    CSV.open(manhole_file, "wb") do |csv|
      csv << ["Source File", "Manhole ID", "Base Flow", "Storm Load", "Total Flow"]
      all_files_data.each do |fd|
        next unless fd[:sections]['Loading Manholes']
        fd[:sections]['Loading Manholes'].each do |id, vals|
          csv << [fd[:relative_path], id, vals[0] || 0.0, vals[1] || 0.0, vals[2] || 0.0]
        end
      end
    end
    puts "Exported: #{File.basename(manhole_file)}"
  rescue => e
    puts "ERROR exporting nodes: #{e.message}"
  end

  # Links (pipes, force mains, pumps)
  begin
    links_file = File.join(output_dir, "links_all_#{timestamp}.csv")
    CSV.open(links_file, "wb") do |csv|
      csv << ["Source File", "Link ID", "Link Type", "Diameter", "Flow", "Velocity", "Depth Ratio", "Slope", "Peak Flow", "Base Flow", "d/D"]
      all_files_data.each do |fd|
        if fd[:sections]['Pipes']
          fd[:sections]['Pipes'].each do |id, v|
            csv << [fd[:relative_path], id, 'Pipe', v[2] || 0, v[3] || 0, v[9] || 0, v[10] || 0, v[1] || 0, v[6] || 0, v[0] || 0, v[10] || 0]
          end
        end
        if fd[:sections]['Force Mains']
          fd[:sections]['Force Mains'].each do |id, v|
            csv << [fd[:relative_path], id, 'Force Main', v[0] || 0, v[1] || 0, v[2] || 0, 1.0, 0, 0, 0, 1.0]
          end
        end
        if fd[:sections]['Pumps']
          fd[:sections]['Pumps'].each do |id, v|
            csv << [fd[:relative_path], id, 'Pump', 0, v[1] || 0, 0, 0, 0, 0, 0, 0]
          end
        end
      end
    end
    puts "Exported: #{File.basename(links_file)}"
  rescue => e
    puts "ERROR exporting links: #{e.message}"
  end

  # Summary statistics (all sections)
  begin
    stats_file = File.join(output_dir, "summary_statistics_#{timestamp}.csv")
    CSV.open(stats_file, "wb") do |csv|
      csv << ["Section", "Parameter", "Count", "Mean", "Std Dev", "Min", "25th %ile", "Median", "75th %ile", "95th %ile", "Max"]
      aggregate.each do |section, items|
        headers = section_headers[section]
        next unless headers
        headers.each_with_index do |h, ci|
          all_vals = []
          items.each_value { |file_arrays| file_arrays.each { |row| all_vals << row[ci] if row && row[ci] } }
          next if all_vals.empty?
          csv << [section, h] + stats_row(all_vals)
        end
      end
    end
    puts "Exported: #{File.basename(stats_file)}"
  rescue => e
    puts "ERROR exporting summary stats: #{e.message}"
  end

  # Node stats only
  begin
    node_stats_file = File.join(output_dir, "node_statistics_#{timestamp}.csv")
    CSV.open(node_stats_file, "wb") do |csv|
      csv << ["Parameter", "Count", "Mean", "Std Dev", "Min", "25th %ile", "Median", "75th %ile", "95th %ile", "Max"]
      if aggregate['Loading Manholes']
        ['Base', 'Storm', 'Total'].each_with_index do |param, ci|
          all_vals = []
          aggregate['Loading Manholes'].each_value { |file_arrays| file_arrays.each { |row| all_vals << row[ci] if row && row[ci] } }
          next if all_vals.empty?
          csv << [param] + stats_row(all_vals)
        end
      end
    end
    puts "Exported: #{File.basename(node_stats_file)}"
  rescue => e
    puts "ERROR exporting node stats: #{e.message}"
  end

  # Link stats only
  begin
    link_stats_file = File.join(output_dir, "link_statistics_#{timestamp}.csv")
    CSV.open(link_stats_file, "wb") do |csv|
      csv << ["Link Type", "Parameter", "Count", "Mean", "Std Dev", "Min", "25th %ile", "Median", "75th %ile", "95th %ile", "Max"]
      if aggregate['Pipes']
        { 'Pipe Diam' => 2, 'Pipe Flow' => 3, 'Flow Veloc' => 9, 'Pipe d/D' => 10 }.each do |param, col_idx|
          all_vals = []
          aggregate['Pipes'].each_value { |file_arrays| file_arrays.each { |row| all_vals << row[col_idx] if row && row[col_idx] } }
          next if all_vals.empty?
          csv << ['Pipe', param] + stats_row(all_vals)
        end
      end
      if aggregate['Force Mains']
        { 'Pipe Diam' => 0, 'Pipe Flow' => 1, 'Pipe Vel.' => 2 }.each do |param, col_idx|
          all_vals = []
          aggregate['Force Mains'].each_value { |file_arrays| file_arrays.each { |row| all_vals << row[col_idx] if row && row[col_idx] } }
          next if all_vals.empty?
          csv << ['Force Main', param] + stats_row(all_vals)
        end
      end
      if aggregate['Pumps']
        { 'Pump Flow' => 1, 'Pump Head' => 2 }.each do |param, col_idx|
          all_vals = []
          aggregate['Pumps'].each_value { |file_arrays| file_arrays.each { |row| all_vals << row[col_idx] if row && row[col_idx] } }
          next if all_vals.empty?
          csv << ['Pump', param] + stats_row(all_vals)
        end
      end
    end
    puts "Exported: #{File.basename(link_stats_file)}"
  rescue => e
    puts "ERROR exporting link stats: #{e.message}"
  end

  puts "\nAll files saved to: #{output_dir}"
  if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
    system("explorer \"#{output_dir.gsub('/', '\\')}\"") rescue nil
  end
end

puts "\n" + "="*80
puts "BATCH PROCESSING COMPLETE"
puts "="*80

summary =  "Batch RPT Analysis Complete!\n\n"
summary += "Files Processed: #{rpt_files.size}\n"
summary += "Start Directory: #{start_dir}\n\n"
summary += "Search roots:\n"
summary += roots.uniq.map { |r| "  - #{r}" }.join("\n")
WSApplication.message_box(summary, "OK", "Information", false)
puts summary
puts "="*80
