##Lists Object table name, followed by Fieldnames + blob Fieldnames.
on=WSApplication.current_network
on.tables.each do |i|
    puts "****#{i.name}"
    counter = 1
    i.fields.each do |j|
        puts  "\t#{counter}. #{j.name}"
        counter += 1
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

on=WSApplication.background_network
on.tables.each do |i|
    puts "****#{i.name}"
    counter = 1
    i.fields.each do |j|
        puts  "\t#{counter}. #{j.name}"
        counter += 1
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
