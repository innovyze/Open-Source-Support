text = 'Make sure to press ENTER after inputting every number, otherwise the value might not be committed and the script will fail.'
WSApplication.message_box(text,'OK','!','')

title = 'Percentage Change in Runoff for Absolute Area'
dialog = [
    ['Runoff Area 1','NUMBER',0],
    ['Runoff Area 2','NUMBER',0],
    ['Runoff Area 3','NUMBER',0],
    ['Runoff Area 4','NUMBER',0],                                                                                                                                                                                                           
    ['Runoff Area 5','NUMBER',0],
    ['Runoff Area 6','NUMBER',0],
    ['Runoff Area 7','NUMBER',0],
    ['Runoff Area 8','NUMBER',0],
    ['Runoff Area 9','NUMBER',0],
    ['Runoff Area 10','NUMBER',0],
    ['Runoff Area 11','NUMBER',0],
    ['Runoff Area 12','NUMBER',0],
    ['Subcatchment type','String','Foul',nil,'LIST',['Foul','Storm','Sanitary','combined','overland','other']],
]
$user_input = WSApplication.prompt(title,dialog,false)
abort('SCRIPT ABORTED BY USER') if $user_input.nil?

def update_subs(node)
    node.navigate('subcatchments').each do |subs|
        if subs.system_type.downcase == $user_input[3].downcase
            subs.selected = true
            subs.area_absolute_1 = subs.area_absolute_1 * (1 + $user_input[0]/100)
            subs.area_absolute_2 = subs.area_absolute_2 * (1 + $user_input[1]/100)
            subs.area_absolute_3 = subs.area_absolute_3 * (1 + $user_input[2]/100)
            subs.area_absolute_4 = subs.area_absolute_4 * (1 + $user_input[3]/100)
            subs.area_absolute_5 = subs.area_absolute_5 * (1 + $user_input[4]/100)
            subs.area_absolute_6 = subs.area_absolute_6 * (1 + $user_input[5]/100)
            subs.area_absolute_7 = subs.area_absolute_7 * (1 + $user_input[6]/100)
            subs.area_absolute_8 = subs.area_absolute_8 * (1 + $user_input[7]/100)
            subs.area_absolute_9 = subs.area_absolute_9 * (1 + $user_input[8]/100)
            subs.area_absolute_10 = subs.area_absolute_10 * (1 + $user_input[9]/100)
            subs.area_absolute_11 = subs.area_absolute_11 * (1 + $user_input[10]/100)
            subs.area_absolute_12 = subs.area_absolute_12 * (1 + $user_input[11]/100)
            subs.area_absolute_1_flag = "SCRP"
            subs.area_absolute_2_flag = "SCRP"
            subs.area_absolute_3_flag = "SCRP"
            subs.write
        end
    end
end

def scenario
    time = Time.new.strftime('%Y%m%d_%k%M%S').to_s
    $net.add_scenario(time,nil,time)
    $net.current_scenario = time
end

$net = WSApplication.current_network
$roc = $net.row_object_collection_selection('_nodes')
$unprocessedLinks = Array.new

scenario

$net.transaction_begin
$roc.each do |ro|
    update_subs(ro)
    ro.us_links.each do |l|
        if !l._seen
            $unprocessedLinks << l
            l._seen = true
        end
    end
    while $unprocessedLinks.size>0
        working = $unprocessedLinks.shift
        working.selected = true
        workingUSNode = working.us_node
        if !workingUSNode.nil? && !workingUSNode._seen
            workingUSNode.selected = true
            update_subs(workingUSNode)
            workingUSNode.us_links.each do |l|
                if !l._seen
                    $unprocessedLinks << l
                    l.selected = true
                    l._seen = true
                end
            end
        end
    end
end
$net.transaction_commit