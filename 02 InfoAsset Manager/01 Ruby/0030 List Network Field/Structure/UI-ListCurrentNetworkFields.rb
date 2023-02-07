##Lists Object table name, followed by Fieldnames + blob Fieldnames.
on=WSApplication.current_network
	on.tables.each do |i|
		puts "****#{i.name}"
		i.fields.each do |j|
			puts  "\t#{j.name}"
			if j.data_type=='WSStructure'
				if j.fields.nil?
					puts "\t\t***badger***"
				else
					j.fields.each do |bf|
						puts "\t\t #{bf.name}"
				end
			end
		end
	end
end