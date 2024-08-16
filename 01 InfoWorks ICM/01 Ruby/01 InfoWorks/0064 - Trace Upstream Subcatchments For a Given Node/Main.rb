#Below function will return an array of nodes, links and subcatchments upstream of a given node
def get_upstream_nodes_links_and_subs(input_node, subs_hash, on)
    unprocessed_links = []
    return_nodes = []
    return_links = []
    return_subs = []

    input_node._seen=true
    return_nodes << input_node
    subs_hash[input_node.node_id].each do |sub|
        return_subs << sub
    end

    input_node.us_links.each do |link|
        if link._seen!=true
            link._seen=true
            unprocessed_links<<link
        end
    end

    while unprocessed_links.size>0
        working=unprocessed_links.shift
        return_links << working
        working_us_node=working.us_node
        if !working_us_node.nil?
            return_nodes << working_us_node

            subs_hash[working_us_node.node_id].each do |sub|
                return_subs << sub
            end
            working_us_node.us_links.each do |l|
                if !l._seen
                    unprocessed_links << l
                    l._seen=true
                end
            end
        end
    end
    return [return_nodes, return_links, return_subs]
end

def get_hashmap_of_nodes_and_Subcatchments(open_net)
    all_subs=open_net.row_objects('_subcatchments')
    return_hashmap={}
    all_nodes=open_net.row_objects('_nodes')
    all_nodes.each do |h|
        return_hashmap[h.node_id]=[]
    end
    all_subs=open_net.row_objects('_subcatchments')
    all_subs.each do |subb|
        return_hashmap[subb.node_id]<<subb
    end
    return return_hashmap
end

#------------------------------------------------------------------------------------------------------------------------------#
#                                                       Main code
#------------------------------------------------------------------------------------------------------------------------------#

#Get the current database and network
db= WSApplication.current_database
on = WSApplication.current_network

#Get the hashmap of nodes and subcatchments
node_sub_hash_map = get_hashmap_of_nodes_and_Subcatchments(on)
selected_nodes = on.row_objects_selection('_nodes')

#If more than one node selected, then show a message and exit
if selected_nodes.size>1
    WSApplication.message_box("Multiple nodes selected! Please select only one node","OK","Information",true)
elsif selected_nodes.size==0
    WSApplication.message_box("No node selected! Please select a node","OK","Information",true)
else #If one node is selected, find the upstream nodes, links and subcatchments
    selected_node = selected_nodes[0]
    upstream_nodes_links_subs = get_upstream_nodes_links_and_subs(selected_node, node_sub_hash_map, on)
    upstream_subs = upstream_nodes_links_subs[2]
    #Select the upstream subcatchments
    on.clear_selection
    upstream_subs.each do |sub|
        sub.selected=true
    end
    #Select Upstream nodes
    upstream_nodes = upstream_nodes_links_subs[0]
    upstream_nodes.each do |node|
        node.selected=true
    end
    #Select Upstream links
    upstream_links = upstream_nodes_links_subs[1]
    upstream_links.each do |link|
        link.selected=true
    end
end
