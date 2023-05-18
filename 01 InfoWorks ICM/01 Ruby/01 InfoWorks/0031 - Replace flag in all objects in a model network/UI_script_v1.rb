$net=WSApplication.current_network
$old_flag=WSApplication.input_box('Type the code for the flag that will be replaced','Old flag',nil)
$new_flag=WSApplication.input_box('Type the code for the flag that will replace the old flag','New flag',nil)
$net.transaction_begin
$net.tables.each do |table|
  fields=table.fields
  fields.each do |field|
    if field.name.match? (/_flag/)
      $net.row_objects(table.name).each do |row|
      row[field.name]=$new_flag if row[field.name]==$old_flag
      row.write
      end
    end
  end
end
$net.transaction_commit
puts "Flag \'#{$old_flag}\' replaced by flag \'#{$new_flag}\' in all model object fields"	