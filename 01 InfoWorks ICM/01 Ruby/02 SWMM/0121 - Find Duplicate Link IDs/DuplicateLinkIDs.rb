nw=WSApplication.current_network
arr=nw.row_objects('_links')
links=Hash.new
arr.each do |o|
if links.has_key? o.id
puts "Duplicate ID #{o.id} found in tables #{o.table} and #{links[o.id]}"
else
links[o.id]=o.table
end
end