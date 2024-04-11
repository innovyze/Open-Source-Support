# John Styles, Krzysztof Tchorzewski, Tony Andrews
# 12/04/2019

# Provided with this script includes:
# 1. Fakenham Network provided as a snapshot file. This Network's coordinate system is British National Grid (EPSG 27700)
# 2. Geoplan IWS file GeoPlanProp_X.iws which can be loaded: 1. Open Network Geoplan > Right Click Properties & Themes > Load > *.iws file

# Pre-requisites for the script to run_SQL
	# 1. A connected network - the script will trace downstream from the injection point.
	# 2. All properties connected to the sewer should be represented as InfoAsset Manager Property objects and associated to a sewer pipe.
	# 2. The new development needs to be represented as an InfoAsset Manager Property Object and must be connected (associated) to an asset using the sanitary pipe and/or stormwater pipe. 
	# 3. Mannings Equation is used to determine capacity - so pipe assets must have valid gradients and pipe sizes. Capacity can be imported from an ICM model if available and the script edited accordingly.
	# 4. The Property Object's Property type (property_type) field must be set to "Development" (this may require editing the choice list for cams_property_type.
	# 5. Create a Flag "CAP"
	# 6. Set Tools>Options>Metric (Native)
	# 7. Before running the script choose an InfoAsset Manager connected Property that has property_type = "Development" (Fakenham network example includes property id = 338F0878-F134-41D2-A50E-93D94BCE3AC1
	

class Capacity
	def initialize
		@net=WSApplication.current_network
		WSApplication.use_user_units=false
		@linked_pipe=''
	end
	def set_up_parameters
		val_array = WSApplication.prompt "Dry Weather Flow Capacity Variables",[['Developer Inflow', 'Number', 0.0], ['Capacity assurance flag', 'String', 'CAP'], ['Average number of people per house', 'Number', 3.5],['Number of litres per day per person', 'Number', 150.0],['DWF multiplier', 'Number', 6.0]], false

		if !val_array.nil?
			@dev_inflow = val_array[0]
			@cap_flag = val_array[1]
			@count_in_house = val_array[2]
			@dwf_person = val_array[3]
			@dwf_multiplier = val_array[4]
		else
			@dev_inflow = 0.0
			@cap_flag = 'CAP'
			@count_in_house = 3.5
			@dwf_person = 150
			@dwf_multiplier = 6.0
		end

		#@cap_flag='CAP'
		#@count_in_house=3.5
		#@dwf_person=150.0
		#@dwf_multiplier=2.3
	end
	def get_development_inflow
		selected_properties=@net.row_objects_selection('cams_property')
		if selected_properties.size==0
			WSApplication.message_box 'No properties selected','OK','!',false
			return false
		else
			found=false
			selected_properties.each do |p|
				if p.property_type.upcase=='DEVELOPMENT'
					if !found
						found=true
						if @dev_inflow.nil?
							WSApplication.message_box "Selected property doesn't have user number 1 populated",'OK',"!", false
							return false
						else
							@development_inflow=@dev_inflow
							pipe=p.navigate1('sanitary_pipe')
							if pipe.nil? 
								WSApplication.message_box "selected property doesn't have linked pipe",'OK',"!", false
								return false
							else
								@linked_pipe=pipe.id
							end
						end
					else
						WSApplication.message_box 'Too many properties of type Development selected','OK',"!", false
						return false
					end
				end
			end
			if !found
				WSApplication.message_box 'No properties selected of type DEVELOPMENT','OK','!',false
				return false
			end
		end
		return true
	end
	def calculate_dwf
		# also zeros user_number_2
		@net.transaction_begin
		@net.row_objects('cams_pipe').each do |pipe|
			properties=pipe.navigate('properties')
			count=0
			properties.each do |p|
				if p.property_type.upcase!='DEVELOPMENT'
					count+=1
				end
			end
			# count is a convenient thing to put here to check that calculate accumulated DWF is doing somethingProcessed
			# sensible
			pipe.user_number_1=count*@count_in_house*@dwf_person*@dwf_multiplier
			pipe.user_number_1_flag=@cap_flag
			pipe.user_number_2 = 0.0
			pipe.user_number_2_flag=@cap_flag
			pipe.write
		end
		@net.transaction_commit
	end
	def add_development_flow_downstream
		@net.transaction_begin
		flow_per_second=@development_inflow /86400/1000 # convert litres per day to m3/s
		@net.row_objects('cams_pipe').each do |p|
			#p.selected=false
			p._seen=false
			p.user_number_4=p.user_number_3
			p.user_number_4_flag=p.user_number_3_flag
			p.write
		end
		@net.row_objects('cams_manhole').each do |m|
			m._seen=false
		end
		unprocessedLinks=Array.new
		endNodes=Array.new
		ro=@net.row_object('cams_pipe',@linked_pipe)
		ro._seen=true
		ro.user_number_4-=flow_per_second
		ro.user_number_4_flag=@cap_flag
		ro.write
		node=ro.ds_node
		node._seen=true
		ds_links=node.ds_links
		ds_links.each do |l|
			if l.table=='cams_pipe' && !l._seen
				if !l._seen
					unprocessedLinks << l
					l._seen=true
					#l.selected=true
					l.user_number_4-=flow_per_second
					l.user_number_4_flag=@cap_flag
					l.write
				end
			end
		end
		while unprocessedLinks.size>0
			working=unprocessedLinks.shift
			#working.selected=true
			workingDSNode=working.ds_node
			if !workingDSNode.nil? && !workingDSNode._seen
				ds_links=workingDSNode.ds_links
				ds_links.each do |l|
					if l.table=='cams_pipe' && !l._seen
						unprocessedLinks << l
						#l.selected=true
						l._seen=true
						l.user_number_4-=flow_per_second
						l.user_number_4_flag=@cap_flag
						l.write
					end
				end
			end
		end
		
		@net.transaction_commit
	end
	def calculate_accumulated_dwf
	# initialise arrays and find all nodes with no upstream pipes
		workingNodes=Array.new
		@net.row_objects('cams_manhole').each do |m|
			m._seen=false
			m._dwf=0.0
			found=0
			m.us_links.each do |l|
				if l.table=='cams_pipe'
					found+=1
				end
			end
			m._unprocessed=found
			if found==0
				workingNodes << m
			end
		end
		@net.row_objects('cams_pipe').each do |p|
			p._seen=false
		end
		# right, this is the sort of thing that really needs a diagram
		# basically the idea is that we start off with all upstream nodes
		# for each node we find all downstream links (there is probably only one and we don't deal with the double
		# counting there would be)
		# the aim here is that with each node we trace downstream, the DWF value for the downstream link is the value
		# accumulated at the node + the value for that pipe. Then we pass that value to the link's downstream node
		# the code basically created an entry in the working nodes array and sets the value to the link's value if it's a new
		# node, if it's note (because we have two or more upstream links for it) we add the accumulated value
		# we keep track of the 'unprocessed links' for each node, the idea here is that we don't try to accumulate things
		# for that node until all the upstream links are available for it (i.e. don't pass things down until it's got its values)
		# (Possibly this is overcomplicating things)
		@net.transaction_begin
		while true
			#puts "WNS #{workingNodes.size}"
			somethingProcessed=false
			(0...workingNodes.size).each do |i|
				m=workingNodes[i]
				#puts "trying #{m.id} #{m._unprocessed}"
				if m._unprocessed==0
					#puts "processing #{m.id} #{workingNodes.size}"
					m.ds_links.each do |dsl|
						if dsl.table=='cams_pipe'
							dsl.user_number_2=m._dwf+dsl.user_number_1
							dsl.user_number_2_flag=@cap_flag
							dsl.write
							newNode=dsl.ds_node
							if newNode 
								if !newNode._seen
									#puts "unseen #{newNode.id}"
									newNode._dwf=dsl.user_number_2
									newNode._seen=true
									workingNodes << newNode
								else
									#puts "seen #{newNode.id}"
									newNode._dwf+=dsl.user_number_2
								end
								newNode._unprocessed-=1
							end
						end
					end
					somethingProcessed=true
					workingNodes.delete_at(i)
					break
				end
			end
			if !somethingProcessed
				break
			end
		end
		@net.transaction_commit
	end
	
	def validate
		@net.clear_selection
		ok=true
		@net.row_objects('cams_pipe').each do |p|
			if p.ds_width.nil? || p.gradient.nil?
				p.selected=true
				ok=false
			end
		end
		if !ok
			WSApplication.message_box 'The selected pipes do not have all the information required to calculate pipe full capacity. The following fields should be populated for each pipe: ds_width and gradient','OK','!',false
		end
		return ok
	end
	
	
	# THIS IS WHERE WE CALCULATE PIPE CAPACITY
	def set_pipe_capacity_and_clear_user_fields
		@net.transaction_begin
		@net.row_objects('cams_pipe').each do |p|
			if p.capacity.nil? #if true #p.capacity.nil? || p.capacity_flag==@cap_flag
				width=p.ds_width/1000.0
				p.capacity=(1.0 / 0.013) * (Math::PI * width**2.0 / 4.0) * ((width/4.0)**(2.0/3.0))* Math.sqrt(p.gradient.abs)
				p.capacity_flag=@cap_flag
			end
			p.user_number_1=nil 
			p.user_number_2=nil 
			p.user_number_3=nil 
			p.user_number_4=nil 								
			p.user_number_5=nil 				
			p.user_number_6=nil 				
			p.write
		end
		@net.transaction_commit
	end
	def calculate_headroom
		@net.transaction_begin
		@net.row_objects('cams_pipe').each do |p|
			p.user_number_3 = p.capacity-(p.user_number_2 / 86400 / 1000) # convert litres per day to m3/s
			#p.user_number_3 = p.user_number_3 * 1000 # convert answer from m3/s to litres/s
			p.user_number_3_flag=@cap_flag
			p.write
		end
		@net.transaction_commit
	end
	def calculate_percentage_remaining_capacity_and_extra_capacity_required
		@net.transaction_begin
		@net.row_objects('cams_pipe').each do |p|
			p.user_number_5=p.user_number_4/p.capacity * 100.0
			p.user_number_5_flag=@cap_flag
			if p.user_number_4 < 0.0
				p.user_number_6=-p.user_number_4
				p.user_number_6_flag=@cap_flag
				p.write				
				p.selected=true
			else
				p.user_number_6 = 0.0
				p.user_number_6_flag=@cap_flag
				p.write				
				p.selected=false
			end

			
		end
		@net.transaction_commit
	end
	def doit
		set_up_parameters
		
		# remember original properties selected
		selected_properties=@net.row_objects_selection('cams_property')
		
		# this has to be done first because validate clears the selection
		if !get_development_inflow
			return
		end
		if !validate
			return
		end
		set_pipe_capacity_and_clear_user_fields
		calculate_dwf
		calculate_accumulated_dwf
		calculate_headroom
		add_development_flow_downstream
		calculate_percentage_remaining_capacity_and_extra_capacity_required
		# finally do unit conversion if required
		# select original property and connection pipe
		selected_properties.each do |p|
			if p.property_type.upcase=='DEVELOPMENT'
				p.selected =  true
				pipe=p.navigate1('sanitary_pipe')
				select_me = @net.row_object('cams_connection_pipe', pipe.id)
				#select_me.selected = true
			end
		end

			@net.run_SQL("Pipe", "SELECT OID AS 'Pipe ID', us_node_id AS 'US Node ID', ds_node_id AS 'DS Node ID', link_suffix AS 'Link Suffix', system_type AS 'System Type', COUNT(properties.*) AS 'Number of Properties Connected', user_number_1 AS 'DWF (l/d)', user_number_2 AS 'Accumulated DWF (l/d)', user_number_3 AS 'Headroom (m3/s)', user_number_4 AS 'Remaining Capacity (m3/s)', user_number_5 AS 'Remaining Capacity (%)', user_number_6 AS 'Extra Capacity Required (m3/s)', length AS 'Length of Sewer', width AS 'Diam (mm)', pipe_material AS 'Pipe Material', YEARPART(NOW())-YEARPART(year_laid) AS 'Age of Sewer' ORDER BY user_number_5")


	end
end

c=Capacity.new
c.doit

