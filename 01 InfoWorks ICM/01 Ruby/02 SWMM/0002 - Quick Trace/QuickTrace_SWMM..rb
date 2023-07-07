# Original Source https://github.com/ngerdts7/ICM_Tools
# Modified for ICM SWMM Networks

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
		working << n
		workingHash[n.id]=0
        $whole_length = 0
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
								working[index]._val=current._val+l.length
								working[index]._from=current
								working[index]._link=l
                                $whole_length = $whole_length + current._val+l.length
								puts $whole_length 
							end
						end
					end
				end
			end
		end
	end
	def doit
		nodes=@net.row_objects_selection('_nodes')
		if nodes.size!=2
			puts "You need to select two nodes to have a trace"
		else
			@dest=nodes[1].id
			found=process_node(nodes[0])
			while(!found.nil?)
				found.selected=true
				if !found._link.nil?
					found._link.selected=true
				end
				found=found._from
			end
		end
	end
end
d=QuickTrace.new
d.doit
puts "Do you see a red line trace? It's length is %0.2f" % [$whole_length]