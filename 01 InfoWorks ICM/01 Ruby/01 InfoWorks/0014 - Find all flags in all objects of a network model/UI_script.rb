$on=WSApplication.current_network
$valid_arr=["DM","#D"]
$arr=Array.new
$on.tables.each do |table|
  fields=table.fields
  fields.each do |field|
    if field.name.match? (/_flag/)
      $on.row_objects(table.name).each do
        |ro| $arr<<ro[field.name] if !ro[field.name].empty?
      end
    end
  end
end
$validation=$arr-$valid_arr
puts "== Flags not part of the validation list =="
puts $validation