## Count summary table for CCTV Surveys broken down by Task Phase and Completed status.
## Outputs a formatted table to the console showing counts per phase/completion combination.

net = WSApplication.current_network

counts      = Hash.new { |h, k| h[k] = Hash.new(0) }
phase_totals = Hash.new(0)
comp_totals  = Hash.new(0)
grand_total  = 0

net.row_objects('cams_cctv_survey').each do |ro|
  phase     = ro['task_phase'].to_s
  phase     = '(blank)' if phase.empty?
  completed = ro['completed'] == true ? 'Completed' : 'Not Completed'

  counts[phase][completed] += 1
  phase_totals[phase]      += 1
  comp_totals[completed]   += 1
  grand_total              += 1
end

col_labels    = ['Completed', 'Not Completed']
phases        = counts.keys.sort

col_w   = 16
label_w = 20

## Header
separator = '+' + '-' * (label_w + 2) + (col_labels.map { '+' + '-' * (col_w + 2) }.join) + '+' + '-' * (col_w + 2) + '+'
header    = '| ' + 'Task Phase'.ljust(label_w) + ' | ' + col_labels.map { |c| c.center(col_w) }.join(' | ') + ' | ' + 'Total'.center(col_w) + ' |'

puts
puts 'CCTV Survey Count Summary'
puts separator
puts header
puts separator

phases.each do |phase|
  row = '| ' + phase.ljust(label_w) + ' | '
  row += col_labels.map { |c| counts[phase][c].to_s.rjust(col_w) }.join(' | ')
  row += ' | ' + phase_totals[phase].to_s.rjust(col_w) + ' |'
  puts row
end

puts separator

## Totals row
total_row = '| ' + 'Total'.ljust(label_w) + ' | '
total_row += col_labels.map { |c| comp_totals[c].to_s.rjust(col_w) }.join(' | ')
total_row += ' | ' + grand_total.to_s.rjust(col_w) + ' |'
puts total_row
puts separator
puts
