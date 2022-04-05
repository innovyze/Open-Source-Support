# Product		InfoWorks WS Pro - UI & EX
# Script Name	Simplify Selected Links
# Description	Removes bends in all selected links.

# Main Function	simplifylinks_main
# Arguments		network (if nil, uses WSApplication.current_network)

# Method(s)
#-------------------------------------------------------------------
def link_simplify (link)
	if link['bends'].size > 4
		oldbends = link['bends']		
		newbends = [oldbends[0], oldbends[1], oldbends[oldbends.size - 2], oldbends[oldbends.size - 1]]
		
		link['bends'] = newbends
		link.write
	end
rescue
	return nil
end

# Main Function
#-------------------------------------------------------------------
def simplifylinks_main (network_in)
	if network_in == nil then network = WSApplication.current_network else network = network_in end

	links = network.row_objects_selection('_links')

	if links.empty?
		puts 'No links selected!'
		exit
	else
		network.transaction_begin
		links.each { |link| link_simplify(link) }
		network.transaction_commit
	end
end

# UI / Exchange Switch
#-------------------------------------------------------------------
if WSApplication.ui? then simplifylinks_main(nil) else end