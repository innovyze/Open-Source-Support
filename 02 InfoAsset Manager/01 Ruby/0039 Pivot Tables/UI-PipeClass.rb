# CONFIG
table       = 'wams_pipe'
row_field   = 'pipe_class'
col_field   = 'user_text_9'
value_field = 'length'
require 'csv'
require 'fileutils'
net = WSApplication.current_network
out_path = File.join(Dir.home, 'Documents', 'IAM_Pivots', 'pivot.csv')
FileUtils.mkdir_p(File.dirname(out_path))
rows = Hash.new { |h,k| h[k] = Hash.new(0.0) }
row_totals = Hash.new(0.0)
col_totals = Hash.new(0.0)
cols = {}
net.row_objects(table).each do |ro|
  r = (ro[row_field] || '(blank)').to_s
  c = (ro[col_field] || '(blank)').to_s
  v = (ro[value_field] || 0).to_f
  rows[r][c] += v
  row_totals[r] += v
  col_totals[c] += v
  cols[c] = true
end
ordered_cols = cols.keys.sort
grand_total = col_totals.values.reduce(0.0, :+)
# Print to console
puts "\nPIVOT TABLE:"
puts "#{row_field}\t" + ordered_cols.join("\t") + "\tGrand Total"
puts "-" * 80
rows.keys.sort.each do |r|
  puts "#{r}\t" + ordered_cols.map { |c| rows[r][c].round(1) }.join("\t") + "\t#{row_totals[r].round(1)}"
end
puts "-" * 80
puts "Column Total\t" + ordered_cols.map { |c| col_totals[c].round(1) }.join("\t") + "\t#{grand_total.round(1)}"
# Save to CSV
CSV.open(out_path, 'wb') do |csv|
  csv << [row_field] + ordered_cols + ['Grand Total']
  rows.keys.sort.each do |r|
    csv << [r] + ordered_cols.map { |c| rows[r][c].round(1) } + [row_totals[r].round(1)]
  end
  csv << ['Column Total'] + ordered_cols.map { |c| col_totals[c].round(1) } + [grand_total.round(1)]
end
puts "\nPivot saved: #{out_path}"