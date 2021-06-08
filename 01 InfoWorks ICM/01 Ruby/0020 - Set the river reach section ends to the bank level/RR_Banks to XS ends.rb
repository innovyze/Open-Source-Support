net = WSApplication.current_network
net.transaction_begin
net.row_objects('hw_river_reach').each do |rr|
    working = Hash.new
    # find left and right bank entries with a section marker and add to working hash
    rr.left_bank.each { |row| working["#{row.section_marker}_f"] = row.Z if !row.section_marker.empty? }
    rr.right_bank.each { |row| working["#{row.section_marker}_l"] = row.Z if !row.section_marker.empty? }
    # populate rr.sections blob table with working hash values: first/last of each section
    # first of first section
    rr.sections[0]['Z'] = working["#{rr.sections[0]['key']}_f"]
    i = 0
    while i < rr.sections.length - 1
        if rr.sections[i + 1]['key'] != rr.sections[i]['key']
            # last of intermediate section
            rr.sections[i]['Z'] = working["#{rr.sections[i]['key']}_l"]
            # first of intermediate section
            rr.sections[i + 1]['Z'] = working["#{rr.sections[i + 1]['key']}_f"]
        end
        i += 1
    end
    # last of last section
    rr.sections[rr.sections.length - 1]['Z'] = working["#{rr.sections[rr.sections.length - 1]['key']}_l"]
    # write to table
    rr.sections.write
    rr.write
end
net.transaction_commit
