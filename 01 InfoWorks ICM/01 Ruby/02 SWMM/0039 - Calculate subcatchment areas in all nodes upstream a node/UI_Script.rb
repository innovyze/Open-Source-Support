# variables
$net=WSApplication.current_network
$net.clear_selection
$ro=$net.row_object('hw_node','44628801')
$unprocessed_links=Array.new
$seen_objects=Array.new

# functions
def mark(object)
    object.selected=true
    object._seen=true
    $seen_objects << object
end

def unsee_all
    $seen_objects.each { |object| object._seen=false }
    $seen_objects=Array.new
end

def unprocessed_links(node)
    node.us_links.each do |link|
        if !link._seen
            $unprocessed_links << link
            mark(link)
        end
    end
end

def tot_sub_area(object)
    tot_sub_area=0
    object.navigate('subcatchments').each do |subs|
        tot_sub_area += subs.total_area
        mark(subs)
    end
    tot_sub_area
end

def trace_us(node)
    mark(node)
    total_area=tot_sub_area(node)
    unprocessed_links(node)
    nodes_us=Array.new
    nodes_us << node
    while $unprocessed_links.size>0
        working_link=$unprocessed_links.shift
        working_node=working_link.us_node
        total_area += tot_sub_area(working_link)
        if !working_node.nil? && !working_node._seen
            total_area += tot_sub_area(working_node)
            unprocessed_links(working_node)
            mark(working_node)
            nodes_us << working_node
        end 
    end
    unsee_all
    [nodes_us,total_area]
end

trace_us($ro)[0].each do |node|
    puts "%s: %s" % [node.node_id, trace_us(node)[1]]
end
