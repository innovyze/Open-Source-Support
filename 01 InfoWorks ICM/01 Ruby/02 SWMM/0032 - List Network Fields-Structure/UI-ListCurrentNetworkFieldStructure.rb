##Lists Object descriptive name & Object table name, followed by Field descriptive name, 
#   Fieldname, & type, followed by blob attributes (where relevant).
on=WSApplication.current_network
	on.tables.each do |i|
		puts "****#{i.description}, #{i.name}"
		i.fields.each do |j|
			puts  "\t#{j.description}, #{j.name}, #{j.data_type}"
			if j.data_type=='WSStructure'
				if j.fields.nil?
					puts "\t\t***badger***"
				else
					j.fields.each do |bf|
						puts "\t\t#{bf.description}, #{bf.name}, #{bf.data_type}"
				end
			end
		end
	end
end
