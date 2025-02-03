$on = WSApplication.current_network
$flags_count = Hash.new(0)

$on.tables.each do |table|
  fields = table.fields
  fields.each do |field|
    if field.name.match?(/_flag/)
      $on.row_objects(table.name).each do |ro|
        $flags_count[ro[field.name]] += 1 if !ro[field.name].empty?
      end
    end
  end
end

puts "== Flag Counts in the Current Network =="
$flags_count.each do |flag, count|
  puts "#{flag}: #{count}"
end

$on = WSApplication.background_network

  # Check if there is a background network
  if $on.nil?
    puts "No background network found."
    return
  end

$flags_count = Hash.new(0)

$on.tables.each do |table|
  fields = table.fields
  fields.each do |field|
    if field.name.match?(/_flag/)
      $on.row_objects(table.name).each do |ro|
        $flags_count[ro[field.name]] += 1 if !ro[field.name].empty?
      end
    end
  end
end
puts
puts "== Flag Counts in the Background Network =="
$flags_count.each do |flag, count|
  puts "#{flag}: #{count}"
end