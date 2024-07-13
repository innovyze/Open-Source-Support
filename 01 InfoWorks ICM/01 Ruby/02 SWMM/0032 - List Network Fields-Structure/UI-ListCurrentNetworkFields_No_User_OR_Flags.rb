##Lists Object table name, followed by Fieldnames + blob Fieldnames.
on = WSApplication.current_network
puts "Current Network"
on.tables.each do |i|
    puts "****#{i.name}"
    counter = 1
    i.fields.each do |j|
        field_name = j.name.downcase
        next if field_name.include?('note') || field_name.include?('flag') || field_name.include?('user')
        
        puts  "\t#{counter}. #{j.name}"
        counter += 1
        if j.data_type == 'WSStructure'
            if j.fields.nil?
                puts "\t\t***badger***"
            else
                j.fields.each do |bf|
                    sub_field_name = bf.name.downcase
                    next if sub_field_name.include?('note') || sub_field_name.include?('flag') || sub_field_name.include?('user')
                    puts "\t\t #{bf.name}"
                end
            end
        end
    end
end

on = WSApplication.background_network
puts "Background Network"
on.tables.each do |i|
    puts "****#{i.name}"
    counter = 1
    i.fields.each do |j|
        field_name = j.name.downcase
        next if field_name.include?('note') || field_name.include?('flag') || field_name.include?('user')
        
        puts  "\t#{counter}. #{j.name}"
        counter += 1
        if j.data_type == 'WSStructure'
            if j.fields.nil?
                puts "\t\t***badger***"
            else
                j.fields.each do |bf|
                    sub_field_name = bf.name.downcase
                    next if sub_field_name.include?('note') || sub_field_name.include?('flag') || sub_field_name.include?('user')
                    puts "\t\t #{bf.name}"
                end
            end
        end
    end
end