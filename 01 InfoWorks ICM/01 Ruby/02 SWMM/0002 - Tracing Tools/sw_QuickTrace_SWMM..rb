# Original Source https://github.com/ngerdts7/ICM_Tools

class QuickTrace
  
	def initialize
		@net=WSApplication.current_network
	end
	def process_node(n)
		working=Array.new
		workingHash=Hash.new
		calculated=Array.new
		calculatedHash=Hash.new
		n._val=0.0
		n._from=nil
		n._link=nil
		@total_length_of_links = 0.0  # Initialize the global variable to store the total length of links
		working << n
		workingHash[n.id]=0
		while working.size>0
			min=nil
			minIndex=-1
			(0...working.size).each do |i|
				if min.nil? || working[i]._val < min
					min=working[i]._val
					minIndex=i
				end
			end
			if minIndex<0
				puts "index error"
				return 
			else
				current=working.delete_at(minIndex)
				if current.id==@dest
					return current
				end
				workingHash.delete current.id
				calculated << current
				calculatedHash[current.id]=0
				(0..1).each do |direction|
					if direction==0
						links=current.ds_links
					else
						links=current.us_links
					end
					links.each do |l|
						if direction==0
							node=l.ds_node
						else
							node=l.us_node
						end
						if !node.nil?
							if !calculatedHash.has_key? node.id
								if workingHash.has_key? node.id
									index=-1
									(0...working.size).each do |i|
										if working[i].id==node.id
											index=i
											break
										end
									end
									if index==-1
										puts "working object #{node.id} in hash but not array"
									end
								else
									working << node
									workingHash[node.id]=0
									index=working.size-1
								end
								if l.length > 0.0
									working[index]._val=current._val+l.length
									@total_length_of_links += l.length  # Update the total length of links									
								else
									working[index]._val=current._val+5
								end
								working[index]._from=current
								working[index]._link=l
							end
						end
					end
				end
				#puts "Updated Total length of links: #{total_length_of_links.round(2)}" # Rounded to two decimal places
			end			
		end	
	end


	def doit
		nodes = @net.row_objects_selection('sw_node')
		if nodes.size != 2
			puts "Please select two nodes for the trace."
			return
		else
			@dest = nodes[1].id
			found = process_node(nodes[0])
			total_nodes_found = 0
			total_links_found = 0

			while !found.nil?
				found.selected = true
				if !found._link.nil?
					found._link.selected = true
					total_links_found += 1
				end
				total_nodes_found += 1
				found = found._from
			end
	
			puts "Trace completed. You should see a red line trace."
			puts "Total nodes found: #{total_nodes_found}"
			puts "Total links found: #{total_links_found}"	
			puts "Total length of links: #{@total_length_of_links.round(2)}" # Rounded to two decimal places		
		end
	end
end
	d = QuickTrace.new
	d.doit


	