# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0001 - Pipe Length Statistics\expand.rb" 
# Find the smallest 1 percent of link lengths

net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('sw_conduit').each do |ro|
  link_lengths << ro.length if ro.length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.01

# Calculate the median length (50th percentile)
sorted_lengths = link_lengths.sort
median_length = sorted_lengths[sorted_lengths.length / 2]

# Select the links whose length is below the threshold or median length
selected_links = []
ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length && (ro.length < threshold_length || ro.length < median_length)
    ro.selected = true
    selected_links << ro
  end
end

total_links = link_lengths.length

if selected_links.any?
  puts("| ------------------------------------ | ------ |")
  puts("| Description                          | Value  |")
  puts("| ------------------------------------ | ------ |")
  puts("| Minimum link length                  | #{'%.2f' % link_lengths.min} |")
  puts("| Maximum link length                  | #{'%.2f' % link_lengths.max} |")
  puts("| Threshold length for lowest 1%       | #{'%.2f' % threshold_length} |")
  puts("| Median link length (50th percentile) | #{'%.2f' % median_length} |")
  puts("| Number of links below threshold      | #{selected_links.length} |")
  puts("| Total number of links                | #{total_links} |")
  puts("| ------------------------------------ | ------ |")
else
puts "No links were selected."
end


 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0001 - Pipe Length Statistics\hw_UI_Script.rb" 
# Find the smallest 10 percent of link lengths
net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('hw_conduit').each do |ro|
  link_lengths << ro.conduit_length if ro.conduit_length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.1

# Calculate the median length (50th percentile)
sorted_lengths = link_lengths.sort
median_length = sorted_lengths[sorted_lengths.length / 2]

# Select the links whose length is below the threshold or median length
selected_links = []
ro = net.row_objects('hw_conduit').each do |ro|
  if ro.conduit_length && (ro.conduit_length < threshold_length || ro.conduit_length < median_length)
    ro.selected = true
    selected_links << ro
  end
end

total_links = link_lengths.length

if selected_links.any?
    puts("| ------------------------------------ | ------ |")
    puts("| Description                          | Value  |")
    puts("| ------------------------------------ | ------ |")
    puts("| Minimum link length                  | #{'%.2f' % link_lengths.min} |")
    puts("| Maximum link length                  | #{'%.2f' % link_lengths.max} |")
    puts("| Threshold length for lowest 10%      | #{'%.2f' % threshold_length} |")
    puts("| Median link length (50th percentile) | #{'%.2f' % median_length} |")
    puts("| Number of links below threshold      | #{selected_links.length} |")
    puts("| Total number of links                | #{total_links} |")
    puts("| ------------------------------------ | ------ |")
else
  puts "No links were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0001 - Pipe Length Statistics\sw_UI_Script.rb" 
# Find the smallest 10 percent of link lengths

net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('sw_conduit').each do |ro|
  link_lengths << ro.length if ro.length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.1

# Calculate the median length (50th percentile)
sorted_lengths = link_lengths.sort
median_length = sorted_lengths[sorted_lengths.length / 2]

# Select the links whose length is below the threshold or median length
selected_links = []
ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length && (ro.length < threshold_length || ro.length < median_length)
    ro.selected = true
    selected_links << ro
  end
end

total_links = link_lengths.length

if selected_links.any?
  puts("| ------------------------------------ | ------ |")
  puts("| Description                          | Value  |")
  puts("| ------------------------------------ | ------ |")
  puts("| Minimum link length                  | #{'%.2f' % link_lengths.min} |")
  puts("| Maximum link length                  | #{'%.2f' % link_lengths.max} |")
  puts("| Threshold length for lowest 10%      | #{'%.2f' % threshold_length} |")
  puts("| Median link length (50th percentile) | #{'%.2f' % median_length} |")
  puts("| Number of links below threshold      | #{selected_links.length} |")
  puts("| Total number of links                | #{total_links} |")
  puts("| ------------------------------------ | ------ |")
else
puts "No links were selected."
end

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0002 - Quick Trace\hw_QuickTrace.rb" 
# Original Source https://github.com/ngerdts7/ICM_Tools
# For ICM InfoWorks Networks

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
								if l.link_type == 'Cond'
									working[index]._val=current._val+l.conduit_length
									@total_length_of_links += l.conduit_length  # Update the total length of links									
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
		nodes = @net.row_objects_selection('_nodes')
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


	 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0002 - Quick Trace\sw_QuickTrace.rb" 
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


	 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0003 - Scenario Maker\Scenario_Generator.rb" 
# Original Source https://github.com/ngerdts7/ICM_Tools
# Modified for ICM SWMM Networks

net=WSApplication.current_network

# Define which parameters will be varied by the script. 
# Key   = name of ICM variable to be modified
# name  = abreviation of parameter to be used in scenario name
# table = name of table to be edited that contains the parameter
# id    = model ID in specified table where parameter changes are made (e.g. subcatchment ID, pipe ID, etc.)
# Range = [min, max, # of steps] -> define the range to be tested and how many steps you want the script to try.
#       Example: [0,1,5] -> will create 5 scenarios where the parameter ranges from 0 to 1 -> [0, 0.25, 0.5, 0.75, 1.0]

# Remove/add param rows as needed to account for different variables. The loop below supports up to 8 variables, but it can be expanded.
param=Hash.new
param['p_area_1'] =               {'name'=>'p1', 'table'=>'hw_land_use',            'id'=>'12430', 'Range'=>[0.3,1,2]}
param['p_area_2'] =               {'name'=>'p2', 'table'=>'hw_land_use',            'id'=>'12430', 'Range'=>[10,20,2]}
param['runoff_routing_value'] =   {'name'=>'rv', 'table'=>'hw_runoff_surface',      'id'=>'2',     'Range'=>[10,30,2]}
param['percolation_coefficient'] ={'name'=>'pc', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[2,10,3]}
param['percolation_threshold'] =  {'name'=>'pt', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[40,80,3]}
param['percolation_percentage'] = {'name'=>'pp', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[15,25,2]}
param['baseflow_coefficient'] =   {'name'=>'bc', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[30,50,2]}
param['infiltration_coefficient']={'name'=>'ic', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[10,20,2]}
var = param.keys

# =======================================================================================
# Prepare methods used later in the iteration loop:
#
def list_values(range_array)
# Method to convert range array into array of values to be used:
	dx = (range_array[1]-range_array[0])/(range_array[2]-1.00)
	return Array.new(range_array[2]) {|i| i*dx+range_array[0]}
end

def create_scenario(param,var,vars,net)
# Method to generate a new scenario and apply parameter changes based on input set
	scenario = ''
	for i in 0..var.length-1
		# assemble unique scenario name based on parameter composition
		scenario << param[var[i]]['name'] + "=" + vars[i].to_s + "_"
	end
	net.add_scenario(scenario,nil,'') 
	net.current_scenario=scenario
	net.clear_selection
	net.transaction_begin
	for i in 0..var.length-1
		# Apply parameter changes in scenario as defined by vars array
		puts param[var[i]]['table']
		puts param[var[i]]['id']
		row_obj = net.row_object(param[var[i]]['table'],param[var[i]]['id'])
		row_obj[var[i]] = vars[i]
		row_obj.write
	end
	net.transaction_commit
	v=net.validate(scenario)
	return scenario
end

# Generate scenarios for every possible parameter combination:
scenarios = []
variations = var.map { |v| list_values(param[v]['Range']) }
variations.first.product(*variations[1..-1]) do |vars|
  scenario = create_scenario(param, var, vars, net)
  puts "Configured scenario #{scenario} with #{vars.length} variables"
  scenarios << scenario
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0004 - New ICM Scenarios\hw_sw_new ICM Scenarios.RB" 
# Original Source: https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits

# Access the current network from the WSApplication
current_network = WSApplication.current_network

# Define a constant message to be displayed at the end
THANK_YOU_MESSAGE = 'Thank you for using Ruby in ICM InfoWorks'

# Create an array to hold the scenarios
scenarios = Array.new

# Define the scenarios - these represent different modeling scenarios to be added to the network
scenarios = ['SF484_IA_10mm', 'S456__IA_10mm', 'SF284_IA_10mm', 'SF484_IA_10mm_100ImPerv', 'S456__IA_10mm_100ImPerv', 'SF284__IA_10mm_100ImPerv']

# Iterate through each scenario in the scenarios array
scenarios.each do |scenario|
  # Add the scenario to the current network
  # The parameters are (name, description, folder) - description and folder are left empty in this case
  current_network.add_scenario(scenario, nil, '')

  # Optional: You could add a message here to confirm that the scenario was added successfully
  puts "Scenario #{scenario} has been added successfully."
end

# Print the thank you message after all scenarios have been added
puts THANK_YOU_MESSAGE 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0005 - Change All Subcatchment, Node and Link IDs\Change All Node and Link IDs.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
  # Accessing current network
  net = WSApplication.current_network
  raise "Error: current network not found" if net.nil?

  net.transaction_begin
  
  # Get all the nodes, links, and subcatchments as arrays
  nodes_ro = net.row_objects('_nodes')
  raise "Error: nodes not found" if nodes_ro.nil?
  links_ro = net.row_objects('_links')
  raise "Error: links not found" if links_ro.nil?
  subcatchments_ro = net.row_objects('_subcatchments')
  raise "Error: subcatchments not found" if subcatchments_ro.nil?
  
  node_number = 1
  nodes_ro.each do |node|
    begin
      node.node_id = "N#{node_number}"
      node.write
      node_number += 1
    rescue => e
      puts "Error changing node ID: #{e.message}"
    end
  end

  link_number = 1
  links_ro.each do |link|
    begin
      link.id = "L#{link_number}"
      link.write
      link_number += 1
    rescue => e
      puts "Error changing link ID: #{e.message}"
    end
  end  

  subcatchment_number = 1
  subcatchments_ro.each do |subcatchment|
    begin
      subcatchment.id = "S#{subcatchment_number}"
      subcatchment.write
      subcatchment_number += 1
    rescue => e
      puts "Error changing subcatchment ID: #{e.message}"
    end
  end
  
  puts "Node IDs Changed", node_number
  puts "Link IDs Changed", link_number
  puts "Subcatchment IDs Changed", subcatchment_number
  net.transaction_commit    

rescue => e
  puts "Error: #{e.message}"
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0006  - Add Total Area for Subs\hw_Sum_Selected_Total_Area.rb" 
def calculate_total_area
  net = WSApplication.current_network
  total_area = 0
  count = 0

  net.row_object_collection('hw_subcatchment').each do |s|
    if s.selected?
      total_area += s.total_area
      count += 1
    end
  end

  puts "Total Area: #{'%.3f' % total_area}"
  puts "Number of selected subcatchments: #{count}"
  if total_area == 0
    puts "Either you selected no subcatchments or you have no subcatchments with a non-zero area."
  end
end

# Call the method to calculate and print the total area
calculate_total_area
puts 'Thank you for using Ruby in ICM InfoWorks' 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0006  - Add Total Area for Subs\sw_Sum_Selected_Total_Area.rb" 
def calculate_total_area
  net = WSApplication.current_network
  total_area = 0
  count = 0

  net.row_object_collection('sw_subcatchment').each do |s|
    if s.selected?
      total_area += s.area
      count += 1
    end
  end

  puts "Total Area: #{'%.3f' % total_area}"
  puts "Number of selected subcatchments: #{count}"
  if total_area == 0
    puts "Either you selected no subcatchments or you have no subcatchments with a non-zero area."
  end
end

# Call the method to calculate and print the total area
calculate_total_area
puts 'Thank you for using Ruby in ICM SWMM' 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0007 - Count Objects In the Database\count_objects_in_db.rb" 
DEPTH_LIMIT = 9999

# Get the current user
user = ENV['USER'] || ENV['USERNAME']
print "0007 - Count Objects In the Database...", user
puts ' '

# Recursive method to count the number of objects
#
# @param mo [WSModelObject]
# @param counts [Hash<Integer>]
# @param depth [Integer]

def get_child_objects(mo, counts, depth)
  depth += 1

  # Exit if we hit the depth limit - this shouldn't happen, but it's good practice for any recursion
  if depth >= DEPTH_LIMIT
    puts format("Depth limit of %i reached - either this database is very large, or something went wrong!", DEPTH_LIMIT)
    return
  end

  counts[mo.type] += 1
  mo.children.each { |cmo| get_child_objects(cmo, counts, depth) }
  return
end

counts = Hash.new { |h, k| h[k] = 0 } # Default constructor so when we add a new key, it gets set to 0
depth = 0 # Not technically depth, but this is used to avoid an (unlikely) infinite loop

# Iterate through the database objects (except recyled ones)
database = WSApplication.current_database
database.root_model_objects.each do |rmo|
  get_child_objects(rmo, counts, depth)
end

# Print the result
counts.each { |table, count| puts format("%s: %i object(s)", table, count)}




 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0008 - Select Upstream Subcatchments from a Node with Multilinks\hw_UI_Script.rb" 
# net variable is assigned the current network of the WSApplication
# the hash code is from https://github.com/chaitanyalakeshri/ruby_scripts and 
# the tree walking code is from Unit 5 from https://github.com/innovyze/Open-Source-Support/tree/main/01%20InfoWorks%20ICM/01%20Ruby
net = WSApplication.current_network

# Get all subcatchments from the network and assign them to the variable all_subs
all_subs=net.row_object_collection('hw_subcatchment')

# Create an empty hash variable named node_sub_hash_map
node_sub_hash_map={}

# Get all nodes from the network and assign them to the variable all_nodes
all_nodes=net.row_object_collection('hw_node')

# Assign node ID's as hash keys in the node_sub_hash_map
all_nodes.each do |h|
	node_sub_hash_map[h.node_id]=[]
end

# Get all subcatchments again and assign them to the variable all_subs
all_subs=net.row_object_collection('hw_subcatchment')


# Pair subcatchments to appropriate hash keys (i.e. node id's) in the node_sub_hash_map
all_subs.each do |subb|
	if subb.node_id != ''
		node_sub_hash_map[subb.node_id] << subb
	else
		links = Array.new
		links = subb.lateral_links
		links.each do |link|
			node_sub_hash_map[link.node_id] << subb
		end
	end
end

# Get all the selected rows in the _nodes collection and assign them to the variable roc
roc = net.row_object_collection_selection('_nodes')

# Create an empty array named unprocessedLinks
unprocessedLinks = Array.new

roc.each do |ro|
	# Iterate through all the upstream links of the current row object
	ro.us_links.each do |l|
		# if the link has not been seen before, add it to the unprocessedLinks array
		if !l._seen
			unprocessedLinks << l
			l._seen=true
		end
	end
	# While there are still unprocessed links in the array
	while unprocessedLinks.size>0
		# take the first link in the array and assign it to the variable working
		working = unprocessedLinks.shift
		working.selected=true
		# get the upstream node of the current link
		workingUSNode = working.us_node
		# if the upstream node is not nil and has not been seen before
		if !workingUSNode.nil? && !workingUSNode._seen
			workingUSNode.selected=true
			# Now that hash is ready with node id's as key and upstream subcatchments as paired values, keys can be used to get an array containing upstream subcathments
			# In the below code id's of subcatchments upstream of node 'node_1' are printed. The below code can be reused multiple times for different nodes within the script without being computationally expensive
			node_sub_hash_map[workingUSNode.id].each do |sub|
				puts "Found Upstream Subcatchment #{sub.id} connected to Node #{workingUSNode.id}"
				sub.selected=true
			end
			# Iterate through all the upstream links of the current node and add them to the unprocessedLinks array
			workingUSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					l.selected=true
					l._seen=true
				end
			end
		end
	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0009 - ICM Binary Results Export\EX_script.rb" 
require 'date'

class ICMBinaryObject
	attr_reader :offset, :name
	def initialize(name,offset,float_blob_attributes,double_blob_attributes)
		@name=name
		@offset=offset
		@float_blob_attributes=float_blob_attributes
		@float_blob_offsets=Array.new
		@double_blob_attributes=double_blob_attributes
		@double_blob_offsets=Array.new
		blob_offset=0 # NB, this is a count for both sorts of blobs i.e. if there are float blobs and double blobs, the double blob offsets include the float blobs
		if !float_blob_attributes.nil?
			(0...float_blob_attributes.size).each do |i|
				@float_blob_offsets << blob_offset
				blob_offset+=float_blob_attributes[i]
			end
		end
		if !double_blob_attributes.nil?
			(0...double_blob_attributes.size).each do |i|
				@double_blob_offsets << blob_offset
				blob_offset+=(double_blob_attributes[i]*2)
			end
		end
	end
	def get_float_blob_size(n)
		return @float_blob_attributes[n]
	end
	def get_float_blob_offset(n)
		return @float_blob_offsets[n]
	end
	def get_double_blob_size(n)
		return @double_blob_attributes[n]
	end
	def get_double_blob_offset(n)
		return @double_blob_offsets[n]
	end	
	def dump
		out=@name + ' ' + @offset.to_s
		if !@float_blob_attributes.nil?
			@float_blob_attributes.each do |a|
				out+=' '
				out+=a.to_s
			end
		end
		if !@double_blob_attributes.nil?
			@double_blob_attributes.each do |a|
				out+=' '
				out+=a.to_s
			end
		end		
		puts out
	end
end

class SimTime
	def initialize(val)
		@val=val
	end
	def to_s
		if @val>0
			return DateTime.jd(@val + DateTime.new(1899,12,30,0).jd.to_f).to_s
		else
			@val=-@val.to_i
			seconds=@val%60
			mins=(@val/60)%60
			hours=(@val/3600)%24
			days=@val/86400
			return sprintf("0000-00-%2.3dT%2.2d:%2.2d:%2.2d+00:00",days,hours,mins,seconds)
		end
	end
end

class ICMBinaryUtil
	def ICMBinaryUtil.readlong(f)
		blah=f.read(4)
		return blah.unpack('l')[0]
	end
	def ICMBinaryUtil.readdouble(f)
		blah=f.read(8)
		return blah.unpack('d')[0]
	end
	def ICMBinaryUtil.readdate(f)
		blah=f.read(8)
		simtime=blah.unpack('d')[0]	
		return SimTime.new(simtime)
	end
	def ICMBinaryUtil.readstring(f)
		blah=f.read(1)
		bytes=blah.unpack('C')[0]
		if bytes>0
			ret=f.read(bytes)
		else
			ret=''
		end
		if (bytes+1)%4!=0
			padding=4-((bytes+1)%4)
			f.read(padding)
		end
		return ret
	end
	def ICMBinaryUtil.words(s)
		len=s.length
		len+=1
		if(len%4!=0)
			len+=(4-len%4)
		end
		return len/4
	end
end

class ICMBinaryAttributes
	attr_reader :name, :desc, :unit, :precision
	def init(f)
		@name=ICMBinaryUtil.readstring(f)
		@desc=ICMBinaryUtil.readstring(f)
		@unit=ICMBinaryUtil.readstring(f)
		@precision=ICMBinaryUtil.readlong(f)
		return ICMBinaryUtil.words(@name)+ICMBinaryUtil.words(@desc)+ICMBinaryUtil.words(@unit)+1
	end
	def dump
		puts "#{name} '#{desc}' #{unit} #{precision}"
	end
end
class ICMBinaryTable
	attr_reader :name,:desc
	def init(f,b_max,object_offset)
		@b_max=b_max
		@objectHash=Hash.new
		header_size=0
		object_count=ICMBinaryUtil.readlong(f)
		non_blob_attribute_count=ICMBinaryUtil.readlong(f)
		float_blob_attributes_count=ICMBinaryUtil.readlong(f)	
		if @b_max
			double_blob_attributes_count=ICMBinaryUtil.readlong(f)
		else
			double_blob_attributes_count=0
		end
		header_size+=3
		if @b_max
			header_size+=1
		end
		@name=ICMBinaryUtil.readstring(f)
		@desc=ICMBinaryUtil.readstring(f)
		header_size+=ICMBinaryUtil.words(@name)
		header_size+=ICMBinaryUtil.words(@desc)
		@non_blob_attributes=Array.new
		(0...non_blob_attribute_count).each do |i|
			temp=ICMBinaryAttributes.new
			header_size+=temp.init(f)
			@non_blob_attributes << temp
		end
		@float_blob_attributes=Array.new
		(0...float_blob_attributes_count).each do |i|
			temp=ICMBinaryAttributes.new
			header_size+=temp.init(f)
			@float_blob_attributes << temp			
		end
		@double_blob_attributes=Array.new
		(0...double_blob_attributes_count).each do |i|
			temp=ICMBinaryAttributes.new
			header_size+=temp.init(f)
			@double_blob_attributes << temp			
		end		
		@objects=Array.new
		(0...object_count).each do |i|
			name=ICMBinaryUtil.readstring(f)
			header_size+=ICMBinaryUtil.words(name)
			float_blob_attributes_for_object=nil
			double_blob_attributes_for_object=nil
			size_of_results_for_object=non_blob_attribute_count
			if(float_blob_attributes_count>0)
				float_blob_attributes_for_object=Array.new
				(0...float_blob_attributes_count).each do |j|
					temp2=ICMBinaryUtil.readlong(f)
					float_blob_attributes_for_object << temp2
					header_size+=1
					size_of_results_for_object+=temp2
				end
			end
			if(double_blob_attributes_count>0)
				double_blob_attributes_for_object=Array.new
				(0...double_blob_attributes_count).each do |j|
					temp2=ICMBinaryUtil.readlong(f)
					double_blob_attributes_for_object << temp2
					header_size+=1
					size_of_results_for_object+=(temp2*2)
				end
			end			
			obj=ICMBinaryObject.new(name,object_offset,float_blob_attributes_for_object,double_blob_attributes_for_object)
			object_offset+=size_of_results_for_object
			@objects << obj
			@objectHash[name]=obj
		end
		temp=Array.new
		temp << header_size
		temp << object_offset
		return temp
	end
	def get_object(name)
		return @objectHash[name]
	end
	def get_attribute_info(name)
		(0...@non_blob_attributes.size).each do |i|
			if @non_blob_attributes[i].name==name
				ret = Array.new
				ret << i
				ret << 0
				return ret
			end
		end
		(0...@float_blob_attributes.size).each do |i|
			if @float_blob_attributes[i].name==name
				ret=Array.new
				ret << i 
				ret << 1
				return ret
			end
		end
		(0...@double_blob_attributes.size).each do |i|
			if @double_lob_attributes[i].name==name
				ret=Array.new
				ret << i 
				ret << 2
				return ret
			end
		end		
		return nil
	end
	def get_non_blob_attribute_count
		return @non_blob_attributes.size
	end
	def get_non_blob_attribute_name(n)
		return @non_blob_attributes[n].name
	end
	def get_non_blob_attribute_desc(n)
		return @non_blob_attributes[n].desc
	end
	def get_float_blob_attribute_count
		return @float_blob_attributes.size
	end
	def get_float_blob_attribute_name(n)
		return @float_blob_attributes[n].name
	end
	def get_float_blob_attribute_desc(n)
		return @float_blob_attributes[n].desc
	end
	def get_double_blob_attribute_count
		return @double_blob_attributes.size
	end
	def get_double_blob_attribute_name(n)
		return @double_blob_attributes[n].name
	end
	def get_double_blob_attribute_desc(n)
		return @double_blob_attributes[n].desc
	end	
	def list_attributes
		@non_blob_attributes.each do |a|
			puts "#{a.name} '#{a.desc}'"
		end
		@float_blob_attributes.each do |a|
			puts "#{a.name} '#{a.desc}' (blob)"
		end
		@double_blob_attributes.each do |a|
			puts "#{a.name} '#{a.desc}' (double blob)"
		end		
	end
	def list_objects
		@objects.each do |o|
			puts o.name
		end
	end
	def get_blob_sizes(name)
		obj=@objectHash[name]
		if obj.nil?
			raise "invalid object"
		end
		(0...@float_blob_attributes.size).each do |i|
			puts "#{@float_blob_attributes[i].name} '#{@float_blob_attributes[i].desc}' #{obj.get_float_blob_size(i)}"
		end
		(0...@double_blob_attributes.size).each do |i|
			puts "#{@double_blob_attributes[i].name} '#{@double_blob_attributes[i].desc}' #{obj.get_double_blob_size(i)}"
		end		
	end
	def dump
		puts '----'
		puts @name
		puts @non_blob_attributes.size
		@non_blob_attributes.each do |a|
			a.dump
		end
		puts @float_blob_attributes.size
		@float_blob_attributes.each do |a|
			a.dump
		end
		puts @double_blob_attributes.size		
		@double_blob_attributes.each do |a|
			a.dump
		end		
		puts @objects.size
		@objects.each do |o|
			o.dump
		end
	end
end

class ICMBinaryReader
	def init(binary_file,risk)
		@f=File.open binary_file, 'rb'
		version=ICMBinaryUtil.readlong(@f)
		if version==20151009
			@max=true
		elsif version==20110922
			@max=false
		else
			puts 'invalid file type'
			return false
		end
		if @max
			@timestep_count=1
		else
			@timestep_count=ICMBinaryUtil.readlong(@f)
			#puts @timestep_count
			@timesteps=Array.new
			(0...@timestep_count).each do |i|
				if risk
					timestep=ICMBinaryUtil.readdouble(@f)
				else
					timestep=ICMBinaryUtil.readdate(@f)
				end
				@timesteps << timestep
			end
		end
		table_count=ICMBinaryUtil.readlong(@f)
		#puts table_count
		skipped_words=ICMBinaryUtil.readlong(@f)
		#puts "expected #{skipped_words}"
		found_words=0
		tables=Array.new
		@tables_hash=Hash.new
		object_offset=0
		(0...table_count).each do |i|
			table=ICMBinaryTable.new
			temp=table.init(@f,@max,object_offset)
			found_words+=temp[0]
			object_offset=temp[1]
			tables << table
			@tables_hash[table.name]=table
			#table.dump
		end
		@timestep_size = object_offset
		@data_offset= found_words + 3
		if !@max
			@data_offset+= 1 + (2 * @timestep_count)
		end
		if skipped_words != found_words
			puts "expected #{skipped_words} found #{found_words}"
			return false
		end
		#puts "data size per timestep #{@timestep_size}"
		expected_file_size=((@timestep_size * @timestep_count)+@data_offset)*4;
		actual_file_size=@f.size;
		if(expected_file_size!=actual_file_size)
			puts "expected file size = #{expected_file_size} found file size = #{actual_file_size}"
			return false
		end
		return true

		#@f.close
	end
	def timesteps
		return @timesteps.size
	end
	def timestep(i)
		return @timesteps[i]
	end
	def get_table(name)
		return @tables_hash[name]
	end
	def get_value(timestep,table_name,object_id,attribute,index)
		#puts "getting #{timestep} #{table_name} #{object_id} #{attribute} #{index}"
		if timestep<0 || timestep>= @timestep_count
			raise "invalid timestep"
		end
		table=get_table(table_name)
		if table.nil?
			raise "invalid table"
		end
		object=table.get_object(object_id)
		if object.nil?
			raise 'invalid object'
		end
		attribute_info=table.get_attribute_info(attribute)
		if attribute_info.nil?
			raise 'invalid attribute'
		end
		#puts "data offset = #{@data_offset}"
		#puts "object offset = #{object.offset}"
		if attribute_info[1]==1
			blob_size = object.get_float_blob_size(attribute_info[0])
			if index < 0 || index >= blob_size
				return "XXXXX"
				#raise 'index out of range for blob attribute'
			else
				#puts "blob offset = #{object.get_float_blob_offset(attribute_info[0])}"
				offset=@data_offset + (@timestep_size * timestep) + object.offset + object.get_float_blob_offset(attribute_info[0])+index+ table.get_non_blob_attribute_count
			end
		elsif attribute_info[1]==2
			blob_size = object.get_double_blob_size(attribute_info[0])
			if index < 0 || index >= blob_size
				return "XXXXX"
				#raise 'index out of range for blob attribute'
			else
				#puts "blob offset = #{object.get_double_blob_offset(attribute_info[0])}"
				offset=@data_offset + (@timestep_size * timestep) + object.offset + object.get_double_blob_offset(attribute_info[0])+(index*2)+ table.get_non_blob_attribute_count
			end			
		else
			if index!=0
				raise 'non zero index for non blob attribute'
			else
				#puts "non blob offset = #{attribute_info[0]}"
				offset=@data_offset + (@timestep_size * timestep) + (object.offset + attribute_info[0]) 
			end
		end
		#puts "offset #{offset}"
		@f.seek(offset * 4,IO::SEEK_SET)		
		if(attribute_info[1]==2)
			blah=@f.read(8)
			return blah.unpack('d')[0]		
		else
			blah=@f.read(4)
			return blah.unpack('f')[0]	
		end
	end
	def get_results(obj_type,id,attribute)
		(0...@timesteps.size).each do |i|
			puts "#{@timesteps[i]},#{get_value(i,obj_type,id,attribute,0)}"
		end
	end
	def get_all_results(obj_type,id)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end	
		l=''
		l2=''
		(0...table.get_non_blob_attribute_count).each do |i|
			l+=','
			l2+=','
			l+=table.get_non_blob_attribute_name(i)
			l2+=table.get_non_blob_attribute_desc(i)
		end
		puts l
		puts l2
		if @timesteps.nil?
			l=''
			(0...table.get_non_blob_attribute_count).each do |j|
				l+=','
				l+="#{get_value(0,obj_type,id,table.get_non_blob_attribute_name(j),0)}"
			end
			puts l
		else
			(0...@timesteps.size).each do |i|
				l="#{@timesteps[i]}"
				(0...table.get_non_blob_attribute_count).each do |j|
					l+=','
					l+="#{get_value(i,obj_type,id,table.get_non_blob_attribute_name(j),0)}"
				end
				puts l
			end
		end
	end
	def get_blob_sizes(obj_type,id)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end
		table.get_blob_sizes(id)
	end	
	def get_all_blob_results(obj_type,id,index)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end	
		l=''
		l2=''
		(0...table.get_float_blob_attribute_count).each do |i|
			l+=','
			l2+=','
			l+=table.get_float_blob_attribute_name(i)
			l2+=table.get_float_blob_attribute_desc(i)
		end
		(0...table.get_double_blob_attribute_count).each do |i|
			l+=','
			l2+=','
			l+=table.get_double_blob_attribute_name(i)
			l2+=table.get_double_blob_attribute_desc(i)
		end		
		puts l
		puts l2
		if @timesteps.nil?
			l=''
			(0...table.get_float_blob_attribute_count).each do |j|
				l+=','
				l+="#{get_value(0,obj_type,id,table.get_float_blob_attribute_name(j),index)}"
			end
			(0...table.get_double_blob_attribute_count).each do |j|
				l+=','
				l+="#{get_value(0,obj_type,id,table.get_double_blob_attribute_name(j),index)}"
			end			
			puts l		
		else
			(0...@timesteps.size).each do |i|
				l="#{@timesteps[i]}"
				(0...table.get_float_blob_attribute_count).each do |j|
					l+=','
					l+="#{get_value(i,obj_type,id,table.get_float_blob_attribute_name(j),index)}"
				end
				(0...table.get_double_blob_attribute_count).each do |j|
					l+=','
					l+="#{get_value(i,obj_type,id,table.get_double_blob_attribute_name(j),index)}"
				end				
				puts l
			end
		end
	end	
	def list_tables
		@tables_hash.keys.sort.each do |k|
			puts k
		end
	end
	def list_attributes(obj_type)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end
		table.list_attributes
	end
	def list_objects(obj_type)
		table=get_table(obj_type)
		if table.nil?
			raise "invalid table"
		end
		table.list_objects
	end
end
	
	
usage=false
if ARGV.count<2 
	usage=true
else
	icmbr=ICMBinaryReader.new
	if !icmbr.init ARGV[0],(ARGV[1]=='RR')
		puts "failed to initialise"
	else
		if ARGV.count==2 && ARGV[1]=='T'
			icmbr.list_tables
		elsif ARGV.count==3 && ARGV[1]=='A'
			icmbr.list_attributes(ARGV[2])
		elsif ARGV.count==3 && ARGV[1]=='O'
			icmbr.list_objects(ARGV[2])
		elsif ARGV.count==4 && (ARGV[1]=='R' || ARGV[1]=='RR')
			icmbr.get_all_results ARGV[2],ARGV[3]			
		elsif ARGV.count==4 && ARGV[1]=='S'
			icmbr.get_blob_sizes ARGV[2],ARGV[3]
		elsif ARGV.count==5 && ARGV[1]=='BR'
			icmbr.get_all_blob_results ARGV[2],ARGV[3],ARGV[4].to_i
		else
			usage=true
		end
	end
end
if usage
	puts "usage - <filename> T = lists tables"
	puts "        <filename> A <table> = lists attributes for table"
	puts "	      <filename> O <table> = lists objects in table"
	puts "        <filename> R <table> <object> =  all (non blob) results for object"
	puts "        <filename> RR <table> <object> =  all (non blob) results for object (for risk results)"
	puts "        <filename> S <table> <object> = sizes of blobs for that object"
	puts "        <filename> BR <table> <object> <index> = blob results for that index into the blob array for that object"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0010 - List all results fields in a simulation (SWMM or ICM)\UI_script.rb" 
def print_table_results(net)
  # Iterate over each table in the network
  net.tables.each do |table|
    # Initialize an array to store the names of result fields
    results_array = []
    found_results = false

    # Check each row object in the current table
    net.row_object_collection(table.name).each do |row_object|
      # Check if the row object has a 'results_fields' property and results have not been found yet
      if row_object.table_info.results_fields && !found_results
        # If yes, add the field names to the results_array
        row_object.table_info.results_fields.each do |field|
          results_array << field.name
        end
        found_results = true  # Set flag to true after finding the first set of results
        break  # Exit the loop after processing the first row with results
      end
    end

    # Print the table name and its result fields only if there are result fields
    unless results_array.empty?
      puts "Table: #{table.name.upcase}"
      puts "Results fields: #{results_array.join(', ')}"
      puts
    end
  end
end

# Usage example
net = WSApplication.current_network
print_table_results(net)
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0011 - Pipe Length Histogram\hw_UI_Script.rb" 
# Find the smallest 10 percent of pipes
net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('hw_conduit').each do |ro|
  link_lengths << ro.conduit_length if ro.conduit_length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.1

# Calculate the median length (50th percentile)
sorted_lengths = link_lengths.sort
median_length = sorted_lengths[sorted_lengths.length / 2]

# Select the links whose length is below the threshold or median length
selected_links = []
ro = net.row_objects('hw_conduit').each do |ro|
  if ro.conduit_length && (ro.conduit_length < threshold_length || ro.conduit_length < median_length)
    ro.selected = true
    selected_links << ro
  end
end

total_links = link_lengths.length

if selected_links.any?
  printf("%-440s %-0.2f\n", "Minimum link length", link_lengths.min)
  printf("%-440s %-0.2f\n", "Maximum link length", link_lengths.max)
  printf("%-44s %-0.2f\n", "Threshold length for lowest 10%", threshold_length)
  printf("%-44s %-0.2f\n", "Median link length (50th percentile)", median_length)
  printf("%-44s %-d\n", "Number of links below threshold", selected_links.length)
  printf("%-44s %-d\n", "Total number of links", total_links)  
else
  puts "No links were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0011 - Pipe Length Histogram\sw_UI_Script.rb" 
net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length
    link_lengths << ro.length
  end
end

link_lengths.sort!

percentiles = [10, 20, 30, 40, 50, 60, 70, 80, 90]
threshold_lengths = percentiles.map do |p|
  index = (p / 100.0 * (link_lengths.size - 1)).round
  link_lengths[index]
end

selected_links_length = Array.new(9) { [] }

ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length
    threshold_lengths.each_with_index do |threshold, i|
      if ro.length < threshold
        ro.selected = true
        selected_links_length[i] << ro
      end
    end
  end
end

total_length = link_lengths.sum
total_links = net.row_objects('sw_conduit').size

if selected_links_length.any? { |links| links.any? }
  printf("%-50s %12.2f\n", "Minimum link length", link_lengths.min)
  printf("%-50s %12.2f\n", "Maximum link length", link_lengths.max)
  percentiles.each_with_index do |p, i|
    printf("%-50s %12.2f\n", "Threshold length for lowest #{p}%", threshold_lengths[i])
    printf("%-50s %12d\n", "Number of links below #{p}% threshold", selected_links_length[i].length)
  end
  printf("%-50s %12.2f\n", "Total length of links", total_length)
  printf("%-50s %12d\n", "Total number of links", total_links)
else
  puts "No links were selected."
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0012 - ODEC Export Node and Conduit tables to CSV and MIF\UI_script.rb" 
require 'date'

# Sets the current directory to a user defined location
Dir.chdir 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\ICM SWMM Ruby\0012 - ODEC Export Node and Conduit tables to CSV and MIF'
cfg_file = './ICMFieldMapping.cfg'
export_date = DateTime.now.strftime("%Y%d%m%H%S")

# Network variables and WSOpenNetwork conversion to WSModelObject
net = WSApplication.current_network
mo = net.model_object

# ODEC method options
options=Hash.new
options['Error File'] = '.\ICMExportErrors.txt'
# options['Export Selection'] = true

# Export (with timer)
outputs = Array.new
outputs << 'CSV'
outputs << 'MIF'

tables = Array.new
tables << 'Node'
tables << 'Conduit'

outputs.each do |output|
    tables.each do |table|
        puts "#{table} - #{output} export commenced: #{DateTime.now.to_time}"
        file_name = "#{export_date} #{mo.name} - #{table}"
        net.odec_export_ex(output, cfg_file, options, table, file_name + ('.csv' if output == 'CSV').to_s)
        puts "=> Exported file: \"#{Dir.getwd}/#{file_name}\""
        puts "#{table} - #{output} export complete: #{DateTime.now.to_time}"
        puts ''
    end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0013 - Depression Storage  Statistics\hw_UI_Script.rb" 
# Find the smallest 10 percent of pipes
net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('hw_conduit').each do |ro|
  link_lengths << ro.conduit_length if ro.conduit_length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.1

# Calculate the median length (50th percentile)
sorted_lengths = link_lengths.sort
median_length = sorted_lengths[sorted_lengths.length / 2]

# Select the links whose length is below the threshold or median length
selected_links = []
ro = net.row_objects('hw_conduit').each do |ro|
  if ro.conduit_length && (ro.conduit_length < threshold_length || ro.conduit_length < median_length)
    ro.selected = true
    selected_links << ro
  end
end

total_links = link_lengths.length

if selected_links.any?
  printf("%-440s %-0.2f\n", "Minimum link length", link_lengths.min)
  printf("%-440s %-0.2f\n", "Maximum link length", link_lengths.max)
  printf("%-44s %-0.2f\n", "Threshold length for lowest 10%", threshold_length)
  printf("%-44s %-0.2f\n", "Median link length (50th percentile)", median_length)
  printf("%-44s %-d\n", "Number of links below threshold", selected_links.length)
  printf("%-44s %-d\n", "Total number of links", total_links)  
else
  puts "No links were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0013 - Depression Storage  Statistics\sw_UI_Script.rb" 
# Find the smallet 10 percent of pipes

net = WSApplication.current_network
net.clear_selection

link_lengths = []
ro = net.row_objects('sw_conduit').each do |ro|
  link_lengths << ro.length if ro.length
end

# Calculate the threshold length for the lowest ten percent
threshold_length = link_lengths.min + (link_lengths.max - link_lengths.min) * 0.1

# Select the links whose length is below the threshold
selected_links = []
ro = net.row_objects('sw_conduit').each do |ro|
  if ro.length && ro.length < threshold_length
    ro.selected = true
    selected_links << ro
  end
end
total_links = link_lengths.length

if selected_links.any?
  printf("%-40s %-0.2f\n", "Minimum link length", link_lengths.min)
  printf("%-40s %-0.2f\n", "Maximum link length", link_lengths.max)
  printf("%-40s %-0.2f\n", "Threshold length for lowest 10%", threshold_length)
  printf("%-40s %-d\n", "Number of links below threshold", selected_links.length)
  printf("%-40s %-d\n", "Total number of links", total_links)  
else
  puts "No links were selected."
end


 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0014 - Find all flags in all objects of a network model\All_Input_Variables.rb" 
# Initialize a hash to store numeric fields. The hash is structured as {table_name: {field_name: [values]}}
numeric_fields = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }

# Initialize a hash to store non-numeric fields. The hash is structured as {value: count}
non_numeric_fields = Hash.new(0)

# Iterate through each table in the current network
WSApplication.current_network.tables.each do |table|
  # For each table, iterate through each field
  table.fields.each do |field|
    # For each field, iterate through each row object
    WSApplication.current_network.row_objects(table.name).each do |row_object|
      # Get the value of the field for the current row object
      value = row_object[field.name]

      # Check if the value is numeric
      if value.is_a?(Numeric)
        # If the value is numeric, add it to the numeric_fields hash
        numeric_fields[table.name][field.name] << value
      else
        # If the value is not numeric, increment its count in the non_numeric_fields hash
        non_numeric_fields[value] += 1
      end
    end
  end
end

# Print a summary of the numeric fields
puts "Summary of numeric fields:"
numeric_fields.each do |table_name, fields|
  fields.each do |field_name, values|
    # Calculate statistics for the current field
    count = values.size
    sum = values.sum
    max_value = values.max
    min_value = values.min
    mean = sum / count if count > 0

    # Print the statistics for the current field
    puts sprintf("Table: %-35s Field: %-30s Count: %-15d Mean: %-15.4f Max: %-15.4f Min: %-15.4f", table_name, field_name, count, mean, max_value, min_value)
  end
end

# Print a summary of the non-numeric fields
puts "Summary of non-numeric fields:"
non_numeric_fields.each do |value, count|
  # Print the count for the current value
  puts "#{value}: #{count}"
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0014 - Find all flags in all objects of a network model\All_Results.rb" 

# Initialize variables
numeric_fields = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = [] } }
non_numeric_fields = Hash.new(0)

# Iterate through each table in the current network
WSApplication.current_network.tables.each do |table|
  puts "Processing table: #{table.name}"
  # For each table, iterate through each row object
  WSApplication.current_network.row_objects(table.name).each do |row_object|
    # Check if the row object has results fields
    if row_object.table_info.results_fields
      # For each results field, iterate
      row_object.table_info.results_fields.each do |field|
        puts "Table: #{table.name} Field: #{field.name}"
        # Check if the field exists in the row object
        if row_object.has_field?(field.name)
          value = row_object[field.name]

          if value.is_a?(Numeric)
            numeric_fields[table.name][field.name] << value
          else
            non_numeric_fields[value] += 1
          end
        else
          puts "Field #{field.name} does not exist in table: #{table.name}"
        end
      end
    else
      puts "No results fields for table: #{table.name}"
    end
  end
end

# Print summary of numeric fields
puts "Summary of numeric fields:"
numeric_fields.each do |table_name, fields|
  fields.each do |field_name, values|
    count = values.size
    sum = values.sum
    max_value = values.max
    min_value = values.min
    mean = sum / count if count > 0

    puts sprintf("Table: %-35s Field: %-30s Count: %-15d Mean: %-15.4f Max: %-15.4f Min: %-15.4f", table_name, field_name, count, mean, max_value, min_value)
  end
end

# Print summary of non-numeric fields
puts "Summary of non-numeric fields:"
non_numeric_fields.each do |value, count|
  puts "#{value}: #{count}"
end

# Print summary of numeric fields
puts "Summary of numeric fields:"
numeric_fields.each do |table_name, fields|
  fields.each do |field_name, values|
    count = values.size
    sum = values.sum
    max_value = values.max
    min_value = values.min
    mean = sum / count if count > 0

    puts sprintf("Table: %-35s Field: %-30s Count: %-15d Mean: %-15.4f Max: %-15.4f Min: %-15.4f", table_name, field_name, count, mean, max_value, min_value)
  end
end

# Print summary of non-numeric fields
puts "Summary of non-numeric fields:"
non_numeric_fields.each do |value, count|
  puts "#{value}: #{count}"
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0014 - Find all flags in all objects of a network model\UI_script.rb" 
$on = WSApplication.current_network
$flags_count = Hash.new(0)

$on.tables.each do |table|
  fields = table.fields
  fields.each do |field|
    if field.name.match?(/_flag/)
      $on.row_objects(table.name).each do |ro|
        $flags_count[ro[field.name]] += 1 if !ro[field.name].empty?
      end
    end
  end
end

puts "== Flag Counts in the Current Network =="
$flags_count.each do |flag, count|
  puts "#{flag}: #{count}"
end

$on = WSApplication.background_network

  # Check if there is a background network
  if $on.nil?
    puts "No background network found."
    return
  end

$flags_count = Hash.new(0)

$on.tables.each do |table|
  fields = table.fields
  fields.each do |field|
    if field.name.match?(/_flag/)
      $on.row_objects(table.name).each do |ro|
        $flags_count[ro[field.name]] += 1 if !ro[field.name].empty?
      end
    end
  end
end
puts
puts "== Flag Counts in the Background Network =="
$flags_count.each do |flag, count|
  puts "#{flag}: #{count}"
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0015 - Pipe Diameter Statistics\hw_UI_Script.rb" 
# Find the smallest 10 percent of conduit heights and widths
net = WSApplication.current_network
net.clear_selection

conduit_heights = []
conduit_widths = []
ro = net.row_objects('hw_conduit').each do |ro|
  conduit_heights << ro.conduit_height if ro.conduit_height
  conduit_widths << ro.conduit_width if ro.conduit_width
end

# Calculate the threshold height and width for the lowest ten percent
threshold_height = conduit_heights.min + (conduit_heights.max - conduit_heights.min) * 0.1
threshold_width = conduit_widths.min + (conduit_widths.max - conduit_widths.min) * 0.1

# Calculate the median height and width (50th percentile)
sorted_heights = conduit_heights.sort
median_height = sorted_heights[sorted_heights.length / 2]
sorted_widths = conduit_widths.sort
median_width = sorted_widths[sorted_widths.length / 2]

# Select the conduits whose height or width is below the threshold or median
selected_conduits = []
ro = net.row_objects('hw_conduit').each do |ro|
  if (ro.conduit_height && (ro.conduit_height < threshold_height || ro.conduit_height < median_height)) ||
     (ro.conduit_width && (ro.conduit_width < threshold_width || ro.conduit_width < median_width))
    ro.selected = true
    selected_conduits << ro
  end
end

total_conduits = [conduit_heights.length, conduit_widths.length].max

if selected_conduits.any?
  printf("%-44s %-0.2f\n", "Minimum conduit height", conduit_heights.min)
  printf("%-44s %-0.2f\n", "Maximum conduit height", conduit_heights.max)
  printf("%-44s %-0.2f\n", "Threshold height for lowest 10%", threshold_height)
  printf("%-44s %-0.2f\n", "Median conduit height (50th percentile)", median_height)
  printf("%-44s %-0.2f\n", "Minimum conduit width", conduit_widths.min)
  printf("%-44s %-0.2f\n", "Maximum conduit width", conduit_widths.max)
  printf("%-44s %-0.2f\n", "Threshold width for lowest 10%", threshold_width)
  printf("%-44s %-0.2f\n", "Median conduit width (50th percentile)", median_width)
  printf("%-44s %-d\n", "Number of conduits below threshold", selected_conduits.length)
  printf("%-44s %-d\n", "Total number of conduits", total_conduits)  
else
  puts "No conduits were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0015 - Pipe Diameter Statistics\sw_UI_Script.rb" 
# Find the smallest 10 percent of conduit heights and widths
net = WSApplication.current_network
net.clear_selection

conduit_heights = []
conduit_widths = []
ro = net.row_objects('sw_conduit').each do |ro|
  conduit_heights << ro.conduit_height if ro.conduit_height
  conduit_widths << ro.conduit_width if ro.conduit_width
end

# Calculate the threshold height and width for the lowest ten percent
threshold_height = conduit_heights.min + (conduit_heights.max - conduit_heights.min) * 0.1
threshold_width = conduit_widths.min + (conduit_widths.max - conduit_widths.min) * 0.1

# Calculate the median height and width (50th percentile)
sorted_heights = conduit_heights.sort
median_height = sorted_heights[sorted_heights.length / 2]
sorted_widths = conduit_widths.sort
median_width = sorted_widths[sorted_widths.length / 2]

# Select the conduits whose height or width is below the threshold or median
selected_conduits = []
ro = net.row_objects('sw_conduit').each do |ro|
  if (ro.conduit_height && (ro.conduit_height < threshold_height || ro.conduit_height < median_height)) ||
     (ro.conduit_width && (ro.conduit_width < threshold_width || ro.conduit_width < median_width))
    ro.selected = true
    selected_conduits << ro
  end
end

total_conduits = [conduit_heights.length, conduit_widths.length].max

if selected_conduits.any?
  printf("%-44s %-0.2f\n", "Minimum conduit height", conduit_heights.min)
  printf("%-44s %-0.2f\n", "Maximum conduit height", conduit_heights.max)
  printf("%-44s %-0.2f\n", "Threshold height for lowest 10%", threshold_height)
  printf("%-44s %-0.2f\n", "Median conduit height (50th percentile)", median_height)
  printf("%-44s %-0.2f\n", "Minimum conduit width", conduit_widths.min)
  printf("%-44s %-0.2f\n", "Maximum conduit width", conduit_widths.max)
  printf("%-44s %-0.2f\n", "Threshold width for lowest 10%", threshold_width)
  printf("%-44s %-0.2f\n", "Median conduit width (50th percentile)", median_width)
  printf("%-44s %-d\n", "Number of conduits below threshold", selected_conduits.length)
  printf("%-44s %-d\n", "Total number of conduits", total_conduits)  
else
  puts "No conduits were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0016 - All Link Parameter  Statistics\hw_UI_Script.rb" 
# Find the smallest 10 percent of conduit heights and widths
net = WSApplication.current_network
net.clear_selection

conduit_heights = []
conduit_widths = []
ro = net.row_objects('hw_conduit').each do |ro|
  conduit_heights << ro.conduit_height if ro.conduit_height
  conduit_widths << ro.conduit_width if ro.conduit_width
end

# Calculate the threshold height and width for the lowest ten percent
threshold_height = conduit_heights.min + (conduit_heights.max - conduit_heights.min) * 0.1
threshold_width = conduit_widths.min + (conduit_widths.max - conduit_widths.min) * 0.1

# Calculate the median height and width (50th percentile)
sorted_heights = conduit_heights.sort
median_height = sorted_heights[sorted_heights.length / 2]
sorted_widths = conduit_widths.sort
median_width = sorted_widths[sorted_widths.length / 2]

# Select the conduits whose height or width is below the threshold or median
selected_conduits = []
ro = net.row_objects('hw_conduit').each do |ro|
  if (ro.conduit_height && (ro.conduit_height < threshold_height || ro.conduit_height < median_height)) ||
     (ro.conduit_width && (ro.conduit_width < threshold_width || ro.conduit_width < median_width))
    ro.selected = true
    selected_conduits << ro
  end
end

total_conduits = [conduit_heights.length, conduit_widths.length].max

if selected_conduits.any?
  printf("%-44s %-0.2f\n", "Minimum conduit height", conduit_heights.min)
  printf("%-44s %-0.2f\n", "Maximum conduit height", conduit_heights.max)
  printf("%-44s %-0.2f\n", "Threshold height for lowest 10%", threshold_height)
  printf("%-44s %-0.2f\n", "Median conduit height (50th percentile)", median_height)
  printf("%-44s %-0.2f\n", "Minimum conduit width", conduit_widths.min)
  printf("%-44s %-0.2f\n", "Maximum conduit width", conduit_widths.max)
  printf("%-44s %-0.2f\n", "Threshold width for lowest 10%", threshold_width)
  printf("%-44s %-0.2f\n", "Median conduit width (50th percentile)", median_width)
  printf("%-44s %-d\n", "Number of conduits below threshold", selected_conduits.length)
  printf("%-44s %-d\n", "Total number of conduits", total_conduits)  
else
  puts "No conduits were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0016 - All Link Parameter  Statistics\sw_UI_Script.rb" 
# Find the smallest 10 percent of conduit heights and widths
net = WSApplication.current_network
net.clear_selection

conduit_heights = []
conduit_widths = []
ro = net.row_objects('sw_conduit').each do |ro|
  conduit_heights << ro.conduit_height if ro.conduit_height
  conduit_widths << ro.conduit_width if ro.conduit_width
end

# Calculate the threshold height and width for the lowest ten percent
threshold_height = conduit_heights.min + (conduit_heights.max - conduit_heights.min) * 0.1
threshold_width = conduit_widths.min + (conduit_widths.max - conduit_widths.min) * 0.1

# Calculate the median height and width (50th percentile)
sorted_heights = conduit_heights.sort
median_height = sorted_heights[sorted_heights.length / 2]
sorted_widths = conduit_widths.sort
median_width = sorted_widths[sorted_widths.length / 2]

# Select the conduits whose height or width is below the threshold or median
selected_conduits = []
ro = net.row_objects('sw_conduit').each do |ro|
  if (ro.conduit_height && (ro.conduit_height < threshold_height || ro.conduit_height < median_height)) ||
     (ro.conduit_width && (ro.conduit_width < threshold_width || ro.conduit_width < median_width))
    ro.selected = true
    selected_conduits << ro
  end
end

total_conduits = [conduit_heights.length, conduit_widths.length].max

if selected_conduits.any?
  printf("%-44s %-0.2f\n", "Minimum conduit height", conduit_heights.min)
  printf("%-44s %-0.2f\n", "Maximum conduit height", conduit_heights.max)
  printf("%-44s %-0.2f\n", "Threshold height for lowest 10%", threshold_height)
  printf("%-44s %-0.2f\n", "Median conduit height (50th percentile)", median_height)
  printf("%-44s %-0.2f\n", "Minimum conduit width", conduit_widths.min)
  printf("%-44s %-0.2f\n", "Maximum conduit width", conduit_widths.max)
  printf("%-44s %-0.2f\n", "Threshold width for lowest 10%", threshold_width)
  printf("%-44s %-0.2f\n", "Median conduit width (50th percentile)", median_width)
  printf("%-44s %-d\n", "Number of conduits below threshold", selected_conduits.length)
  printf("%-44s %-d\n", "Total number of conduits", total_conduits)  
else
  puts "No conduits were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0017 - All Node Parameter  Statistics\hw_UI_Script.rb" 
# Access the current database and network, and then obtain the current model object
db = WSApplication.current_database
my_network = WSApplication.current_network
my_object = my_network.model_object

# Get the parent ID and type of the current object
p_id = my_object.parent_id
p_type = my_object.parent_type

# Retrieve the parent object from the database
parent_object = db.model_object_from_type_and_id(p_type, p_id)

# Loop through the hierarchy of parent objects
(0..999).each do
  # Print the name of the current parent object
  puts "Parent Object: #{parent_object.name}"

  # Get the parent ID and type of the current parent object
  temp_p_id = parent_object.parent_id
  temp_p_type = parent_object.parent_type

  # Break the loop if the parent ID is 0, indicating the top of the hierarchy
  break if temp_p_id == 0

  # Retrieve the next parent object in the hierarchy
  parent_object = db.model_object_from_type_and_id(temp_p_type, temp_p_id)
end
#################################################################################################

# Define database fields for an ICM network Subcatchment object
database_fields = [
  "population",
  "base_flow",
  "trade_flow",
  "additional_foul_flow",
  "user_number_1",
  "user_number_2",
  "user_number_3",
  "user_number_4",
  "user_number_5",
  "user_number_6",
  "user_number_7",
  "user_number_8",
  "user_number_9",
  "user_number_10"
]

begin
  net = WSApplication.current_network
  net.clear_selection

 # Loop through each scenario
  net.scenarios do |s|
    
  current_scenario=net.current_scenario=s

  # Output the current scenario
  puts "Scenario     : #{net.current_scenario}"

  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }

  # Initialize the count of processed rows
  row_count = 0

  # Collect data for each field
  net.row_objects('hw_subcatchment').each do |ro|
    row_count += 1
    database_fields.each do |field|
      error_field = field # Update error_field with the current field
      value = ro[field] || 0 # Replace nil with 0 or handle it as needed
      fields_data[field] << value
    end
  end

  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    
    if data.empty?
      puts "#{field} has no data!"
      next
    end
    
    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum

    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, row_count, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end # End of scenario loop

rescue => e
  # Include the field name and number of processed rows in the error message
  puts "An error occurred with the field '#{field}' after processing #{row_count} rows: #{e.message}"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0017 - All Node Parameter  Statistics\sw_UI_Script.rb" 
# Access the current database and network, and then obtain the current model object
db = WSApplication.current_database
my_network = WSApplication.current_network
my_object = my_network.model_object

# Get the parent ID and type of the current object
p_id = my_object.parent_id
p_type = my_object.parent_type

# Retrieve the parent object from the database
parent_object = db.model_object_from_type_and_id(p_type, p_id)

# Loop through the hierarchy of parent objects
(0..999).each do
  # Print the name of the current parent object
  puts "Parent Object: #{parent_object.name}"

  # Get the parent ID and type of the current parent object
  temp_p_id = parent_object.parent_id
  temp_p_type = parent_object.parent_type

  # Break the loop if the parent ID is 0, indicating the top of the hierarchy
  break if temp_p_id == 0

  # Retrieve the next parent object in the hierarchy
  parent_object = db.model_object_from_type_and_id(temp_p_type, temp_p_id)
end
#################################################################################################

# Define database fields for SWMM network nodes
database_fields = [
  "X",
  "Y",
  "invert_elevation",
  "ground_level",
  "maximum_depth",
  "initial_depth",
  "surcharge_depth",
  "ponded_area",
  "inflow_baseline", 
  "inflow_scaling",
  "base_flow"
]

begin
  net = WSApplication.current_network
  net.clear_selection
  puts "Scenario     : #{net.current_scenario}"

  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }

  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0

  # Collect data for each field from sw_node
  net.row_objects('sw_node').each do |ro|
    row_count += 1
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end

  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    
    if data.empty?
      puts "#{field} has no data!"
      next
    end
    
    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum

    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, row_count, min_value, max_value, mean_value, standard_deviation, total_value)
    if field == "inflow_baseline" || field == "base_flow" then total_expected = total_expected + total_value*694.44  end
    if field == "inflow_scaling" then total_expected = total_expected + total_value  end
    # Assuming 'field' is a variable that holds the current field name
    if field == "inflow_baseline" || field == "base_flow"
      printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
            field, row_count, min_value*694.44, max_value*694.44, mean_value*694.44, standard_deviation*694.44, total_value*694.44)
end
  end
  printf("Total Expected GPM: %-10.2f\n", total_expected)

  #####################################################################################################

  # Initialize the count of processed rows and prepare storage for baseline data
  row_count = 0
  baseline_data = []

  # Collect baseline data from sw_node_additional_dwf
  net.row_objects('sw_node').each do |ro|
      ro.additional_dwf.each do |additional_dwf|
          row_count += 1
          baseline_data << additional_dwf.baseline
    end
  end

  # Check if there is any data in baseline
  if baseline_data.empty?
    puts "baseline has no data!"
  else
    # Calculate statistics for baseline data
    min_value = baseline_data.min
    max_value = baseline_data.max
    sum = baseline_data.inject(0.0) { |accum, val| accum + val }
    mean_value = sum / baseline_data.size
    # Calculate the standard deviation
    sum_of_squares = baseline_data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / baseline_data.size)
    total_value = sum

    # Print statistics for baseline
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           "baseline, MGD", row_count, min_value, max_value, mean_value, standard_deviation, total_value)
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           "baseline, GPM", row_count, min_value*694.44, max_value*694.44, mean_value*694.44, standard_deviation*694.44, total_value*694.44)
  end

rescue => e
  # Error message for general script errors
  puts "An error occurred after processing #{row_count} rows: #{e.message}"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0018 - All Subcatcatchemt Parameter  Statistics\hw_UI_Script.rb" 
# Find the smallest 10 percent of conduit heights and widths
net = WSApplication.current_network
net.clear_selection

conduit_heights = []
conduit_widths = []
ro = net.row_objects('hw_conduit').each do |ro|
  conduit_heights << ro.conduit_height if ro.conduit_height
  conduit_widths << ro.conduit_width if ro.conduit_width
end

# Calculate the threshold height and width for the lowest ten percent
threshold_height = conduit_heights.min + (conduit_heights.max - conduit_heights.min) * 0.1
threshold_width = conduit_widths.min + (conduit_widths.max - conduit_widths.min) * 0.1

# Calculate the median height and width (50th percentile)
sorted_heights = conduit_heights.sort
median_height = sorted_heights[sorted_heights.length / 2]
sorted_widths = conduit_widths.sort
median_width = sorted_widths[sorted_widths.length / 2]

# Select the conduits whose height or width is below the threshold or median
selected_conduits = []
ro = net.row_objects('hw_conduit').each do |ro|
  if (ro.conduit_height && (ro.conduit_height < threshold_height || ro.conduit_height < median_height)) ||
     (ro.conduit_width && (ro.conduit_width < threshold_width || ro.conduit_width < median_width))
    ro.selected = true
    selected_conduits << ro
  end
end

total_conduits = [conduit_heights.length, conduit_widths.length].max

if selected_conduits.any?
  printf("%-44s %-0.2f\n", "Minimum conduit height", conduit_heights.min)
  printf("%-44s %-0.2f\n", "Maximum conduit height", conduit_heights.max)
  printf("%-44s %-0.2f\n", "Threshold height for lowest 10%", threshold_height)
  printf("%-44s %-0.2f\n", "Median conduit height (50th percentile)", median_height)
  printf("%-44s %-0.2f\n", "Minimum conduit width", conduit_widths.min)
  printf("%-44s %-0.2f\n", "Maximum conduit width", conduit_widths.max)
  printf("%-44s %-0.2f\n", "Threshold width for lowest 10%", threshold_width)
  printf("%-44s %-0.2f\n", "Median conduit width (50th percentile)", median_width)
  printf("%-44s %-d\n", "Number of conduits below threshold", selected_conduits.length)
  printf("%-44s %-d\n", "Total number of conduits", total_conduits)  
else
  puts "No conduits were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0018 - All Subcatcatchemt Parameter  Statistics\sw_UI_Script.rb" 
# Find the smallest 10 percent of conduit heights and widths
net = WSApplication.current_network
net.clear_selection

conduit_heights = []
conduit_widths = []
ro = net.row_objects('sw_conduit').each do |ro|
  conduit_heights << ro.conduit_height if ro.conduit_height
  conduit_widths << ro.conduit_width if ro.conduit_width
end

# Calculate the threshold height and width for the lowest ten percent
threshold_height = conduit_heights.min + (conduit_heights.max - conduit_heights.min) * 0.1
threshold_width = conduit_widths.min + (conduit_widths.max - conduit_widths.min) * 0.1

# Calculate the median height and width (50th percentile)
sorted_heights = conduit_heights.sort
median_height = sorted_heights[sorted_heights.length / 2]
sorted_widths = conduit_widths.sort
median_width = sorted_widths[sorted_widths.length / 2]

# Select the conduits whose height or width is below the threshold or median
selected_conduits = []
ro = net.row_objects('sw_conduit').each do |ro|
  if (ro.conduit_height && (ro.conduit_height < threshold_height || ro.conduit_height < median_height)) ||
     (ro.conduit_width && (ro.conduit_width < threshold_width || ro.conduit_width < median_width))
    ro.selected = true
    selected_conduits << ro
  end
end

total_conduits = [conduit_heights.length, conduit_widths.length].max

if selected_conduits.any?
  printf("%-44s %-0.2f\n", "Minimum conduit height", conduit_heights.min)
  printf("%-44s %-0.2f\n", "Maximum conduit height", conduit_heights.max)
  printf("%-44s %-0.2f\n", "Threshold height for lowest 10%", threshold_height)
  printf("%-44s %-0.2f\n", "Median conduit height (50th percentile)", median_height)
  printf("%-44s %-0.2f\n", "Minimum conduit width", conduit_widths.min)
  printf("%-44s %-0.2f\n", "Maximum conduit width", conduit_widths.max)
  printf("%-44s %-0.2f\n", "Threshold width for lowest 10%", threshold_width)
  printf("%-44s %-0.2f\n", "Median conduit width (50th percentile)", median_width)
  printf("%-44s %-d\n", "Number of conduits below threshold", selected_conduits.length)
  printf("%-44s %-d\n", "Total number of conduits", total_conduits)  
else
  puts "No conduits were selected."
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0019 - Distribute attachment details by a shared value\UI-PDFDistribute_Selection.rb" 
class Attachments
	def initialize
		@net=WSApplication.current_network
	end
	def doit
		map=Hash.new
		@net.row_objects_selection('cams_cctv_survey').each do |ro|
			attachments=ro.attachments
			attachments.each do |a|
				if a.db_ref.downcase[-4..-1]=='.pdf'
					if map[ro.contract_no].nil?
						pdf=Array.new
						pdf << a.purpose
						pdf << a.filename
						pdf << a.description
						pdf << a.db_ref
						map[ro.contract_no]=pdf
					else
						puts "Duplicate PDF for contract no #{ro.contract_no} in survey #{ro.id}"
					end
				end
			end
		end
		@net.transaction_begin
		@net.row_objects_selection('cams_cctv_survey').each do |ro|
			if !map.has_key? ro.contract_no
				puts "Survey #{ro.id} - contract no not matched or can't find PDF"
			else
				found=false
				
				attachments=ro.attachments				
				attachments.each do |a|
					if a.db_ref.downcase[-4..-1]=='.pdf'
						found=true
						break
					end
				end
				if !found
					n=attachments.length
					attachments.length=n+1
					attachments[n].purpose=map[ro.contract_no][0]
					attachments[n].filename=map[ro.contract_no][1]
					attachments[n].description=map[ro.contract_no][2]
					attachments[n].db_ref=map[ro.contract_no][3]
					attachments.write
					ro.write
				end
					
			end
		end
		@net.transaction_commit
	end
end
fred=Attachments.new
fred.doit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0019 - Distribute attachment details by a shared value\UIIE-PDFDistribute.rb" 
class Attachments
	def initialize
		if WSApplication.ui?
			@net=WSApplication.current_network		## Uses current open network when run in UI
		else
			db=WSApplication.open('//localhost:40000/db', false)
			@dbnet=db.model_object_from_type_and_id 'Collection Network',1		## Run on Collection Network #1 in IE
			current_commit_id = @dbnet.current_commit_id
			latest_commit_id = @dbnet.latest_commit_id
			if(latest_commit_id > current_commit_id) then
				puts "Updating from Commit ID #{current_commit_id} to Commit ID #{latest_commit_id}"
				@dbnet.update
			else
				puts 'Network is up to date'
			end
			@net=@dbnet.open
		end
	end
	def doit
		map=Hash.new
		@net.row_objects('cams_cctv_survey').each do |ro|
			attachments=ro.attachments
			attachments.each do |a|
				if a.db_ref.downcase[-4..-1]=='.pdf'
					if map[ro.contract_no].nil?
						pdf=Array.new
						pdf << a.purpose
						pdf << a.filename
						pdf << a.description
						pdf << a.db_ref
						map[ro.contract_no]=pdf
					else
						puts "Duplicate PDF for contract no #{ro.contract_no} in survey #{ro.id}"
					end
				end
			end
		end
		@net.transaction_begin
		@net.row_objects('cams_cctv_survey').each do |ro|
			if !map.has_key? ro.contract_no
				puts "Survey #{ro.id} - contract no not matched or can't find PDF"
			else
				found=false
				
				attachments=ro.attachments				
				attachments.each do |a|
					if a.db_ref.downcase[-4..-1]=='.pdf'
						found=true
						break
					end
				end
				if !found
					n=attachments.length
					attachments.length=n+1
					attachments[n].purpose=map[ro.contract_no][0]
					attachments[n].filename=map[ro.contract_no][1]
					attachments[n].description=map[ro.contract_no][2]
					attachments[n].db_ref=map[ro.contract_no][3]
					attachments.write
					ro.write
				end
					
			end
		end
		@net.transaction_commit
		if !WSApplication.ui?
			@dbnet.commit('PDF Distribute script run.')		##Commits the changes when the script is run via Exchange
			puts 'Committed'
		end
	end
end
fred=Attachments.new
fred.doit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0020  - Generate Individual Reports for a Selection of Objects\UI-Reports-CreateIndividualForSelection.rb" 

## Available Reprots:
##[['cams_manhole',nil],['cams_manhole_survey',nil],['cams_cctv_survey','MSCC'],['cams_cctv_survey','PACP'],['cams_cctv_survey',nil],['cams_pipe_clean',nil],['cams_pipe_repair',nil],['cams_manhole_repair',nil],['cams_fog_inspection',nil]]

net=WSApplication.current_network
tables=[['cams_manhole_survey',nil]]

objs=Array.new
tables.each do |t|
	objs << net.row_objects_selection(t[0])
end
(0...tables.size).each do |i|	
	t=tables[i]
	o=objs[i]
	n=0
	o.each do |ro|
		net.clear_selection
		ro.selected=true
		suffix=''
		if !t[1].nil?
			suffix=t[1]+'_'
		end
		prefix="c:\\temp\\Report_#{t[0]}_#{suffix}_#{ro.id}"	## Export folder location and report name pre-fix
		net.generate_report(t[0],t[1],ro.id,prefix+'.doc')		## Generate a Word report
		#net.generate_report(t[0],t[1],ro.id,prefix+'.html')		## Generate a HTML report
		n+=1
	end
end
WSApplication.message_box "Reports Exported","OK","Information", false
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0020  - Generate Individual Reports for a Selection of Objects\UI-Reports-CreateIndividualForSelection_folder.rb" 

## Available Reprots:
##[['cams_manhole',nil],['cams_manhole_survey',nil],['cams_cctv_survey','MSCC'],['cams_cctv_survey','PACP'],['cams_cctv_survey',nil],['cams_pipe_clean',nil],['cams_pipe_repair',nil],['cams_manhole_repair',nil],['cams_fog_inspection',nil]]

net=WSApplication.current_network
tables=[['cams_cctv_survey','MSCC']]

folder=WSApplication.folder_dialog('Select an Export Location',true)

objs=Array.new
tables.each do |t|
	objs << net.row_objects_selection(t[0])
end
(0...tables.size).each do |i|	
	t=tables[i]
	o=objs[i]
	n=0
	o.each do |ro|
		net.clear_selection
		ro.selected=true
		suffix=''
		if !t[1].nil?
			suffix=t[1]+'_'
		end
		prefix="#{folder}\\#{t[0]}_#{suffix}#{ro.id}"
		net.generate_report(t[0],t[1],ro.id,prefix+'.doc')		## Generate a Word report
		#net.generate_report(t[0],t[1],ro.id,prefix+'.html')		## Generate a HTML report
		n+=1
	end
end
WSApplication.message_box "Reports exported to #{folder}","OK","Information", false
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0021 - Create nodes from polygon,subcatchment boundary\UI_script.rb" 
# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_polygon').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Calculate the centroid of the polygon
        centroid_x = boundary_array.each_slice(2).map(&:first).sum / (boundary_array.size / 2)
        centroid_y = boundary_array.each_slice(2).map(&:last).sum / (boundary_array.size / 2)

        # Create a new node at the centroid for a SWMM model use sw_node
        centroid_node = net.new_row_object('hw_node')
        centroid_node['node_id'] = polygon.id + '_centroid'
        centroid_node['x'] = centroid_x
        centroid_node['y'] = centroid_y
        centroid_node.write

        # Create a new node at each vertex
        boundary_array.each_slice(2).with_index do |(x, y), index|
            vertex_node = net.new_row_object('hw_node')
            vertex_node['node_id'] = "#{polygon.id}_vertex_#{index}"
            vertex_node['x'] = x
            vertex_node['y'] = y
            vertex_node.write
        end
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0022 - Output CSV of calcs based on Subcatchment Data\UI_script.rb" 
require 'CSV'
net=WSApplication.current_network

CSVsaveloc=WSApplication.file_dialog(false, "csv", "Comma Separated Variable File", "Drainage Capacity Factor Assessment",false,true)
f = File.new(CSVsaveloc, "w")

#CSV save location & open csv file
 
arr=Array.new
arr << "ID"
arr << "Total Subcatchment Area (ha)"
arr << "Contributing Subcatchment Area (ha)"
arr << "Total Pavement Area (ha)"
arr << "Total Roof Area (ha)"
arr << "Total Permeable Area (ha)"
arr << "Population"
arr << "Non Domentic Flow (l/s)"
arr << "Infiltration (l/s)"

#build array

f.puts arr.to_csv 

#array to csv

##net.each_selected do |an|

	arr=Array.new
	
	arr << "Total"
	curlen = 0
	sccount = 0
	
	totscareaf = 0
	conscareaf = 0
	populf = 0
	paveareaf = 0
	roofareaf = 0
	permareaf = 0
	totscareac = 0
	conscareac = 0
	populc = 0
	paveareac = 0
	roofareac = 0
	permareac = 0
	totscareao = 0
	conscareao = 0
	populo = 0
	paveareao = 0
	roofareao = 0
	permareao = 0
	tradeflow = 0
	baseflow = 0
	addfoulflow = 0
	pavearea = 0
	roofarea = 0
	permarea = 0
	totscarea = 0
	conscarea = 0
	popul = 0

	#New array for individual IDs
	
	net.row_objects('_subcatchments').each do |sc|
		if sc.selected
			sccount = sccount + 1
			if sc.system_type.downcase == "foul"
				if !sc.total_area.nil?
					totscareaf = totscareaf + sc.total_area
				end
				if !sc.contributing_area.nil?
					conscareaf = conscareaf + sc.contributing_area
				end
				if !sc.population.nil?
					populf = populf + sc.population
				end
				if !sc.additional_foul_flow.nil?
					addfoulflow = addfoulflow + sc.additional_foul_flow
				end
				if !sc.area_absolute_1.nil?
					paveareaf = paveareaf + sc.area_absolute_1
				end
				if !sc.area_absolute_2.nil?
					roofareaf = roofareaf + sc.area_absolute_2
				end
				if !sc.area_absolute_3.nil?
					permareaf = permareaf + sc.area_absolute_3
				end
			elsif sc.system_type.downcase == "combined"
				if !sc.total_area.nil?
					totscareac = totscareac + sc.total_area
				end
				if !sc.contributing_area.nil?
					conscareac = conscareac + sc.contributing_area
				end
				if !sc.population.nil?
					populc = populc + sc.population
				end
				if !sc.additional_foul_flow.nil?
					addfoulflow = addfoulflow + sc.additional_foul_flow
				end
				if !sc.area_absolute_1.nil?
					paveareac = paveareac + sc.area_absolute_1
				end
				if !sc.area_absolute_2.nil?
					roofareac = roofareac + sc.area_absolute_2
				end
				if !sc.area_absolute_3.nil?
					permareac = permareac + sc.area_absolute_3
				end
			else
				if !sc.total_area.nil?
					totscareao = totscareao + sc.total_area
				end
				if !sc.contributing_area.nil?
					conscareao = conscareao + sc.contributing_area
				end
				if !sc.population.nil?
					populo = populo + sc.population
				end
				if !sc.additional_foul_flow.nil?
					addfoulflow = addfoulflow + sc.additional_foul_flow
				end
				if !sc.area_absolute_1.nil?
					paveareao = paveareao + sc.area_absolute_1
				end
				if !sc.area_absolute_2.nil?
					roofareao = roofareao + sc.area_absolute_2
				end
				if !sc.area_absolute_3.nil?
					permareao = permareao + sc.area_absolute_3
				end
			end
			
			if !sc.trade_flow.nil?
				tradeflow = tradeflow + sc.trade_flow
			end

			if !sc.base_flow.nil?
				baseflow = baseflow + sc.base_flow
			end
		end
	end

	#Subcatchment analysis

	tradeflow = tradeflow*1000
	baseflow = baseflow*1000
	addfoulflow = addfoulflow*1000
	totscarea = totscareaf + totscareac + totscareao
	conscarea = conscareaf + conscareac + conscareao
	popul = populf + populc + populo
	pavearea = paveareaf + paveareac + paveareao
	roofarea = roofareaf + roofareac + roofareao
	permarea = permareaf + permareac + permareao

	#Rationalise values

	arr << '%.2f' % totscarea
	arr << '%.2f' % conscarea
	arr << '%.2f' % pavearea
	arr << '%.2f' % roofarea
	arr << '%.2f' % permarea
	arr << '%.1f' % popul
	arr << '%.2f' % tradeflow
	arr << '%.2f' % baseflow
	
	f.puts arr.to_csv

##end

	#array to csv

f.close
text = "Routine completed successfully."
oicon = "Information"
WSApplication.message_box(text,'OK',oicon,nil) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0023 - Rename Nodes & Links using Name Generation pattern\UI-RenameNodeLinks.rb" 
net=WSApplication.current_network
net.transaction_begin

net.row_objects_selection('_nodes').each do |ro|
	ro.autoname
	ro.write
end

net.row_objects_selection('_links').each do |ro|
	ro.autoname
	ro.write
end

net.transaction_commit
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0024 - Change Subcatchment Boundaries\UI_Generic_Sides.rb" 
# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Function to generate the boundary for a polygon with a given number of sides
def generate_polygon_boundary(boundary_array, sides)
    # Calculate the minimum and maximum x and y coordinates
    min_x = boundary_array.each_slice(2).map(&:first).min
    max_x = boundary_array.each_slice(2).map(&:first).max
    min_y = boundary_array.each_slice(2).map(&:last).min
    max_y = boundary_array.each_slice(2).map(&:last).max

    # Calculate the width and height
    width = max_x - min_x
    height = max_y - min_y

    # Calculate the points of the polygon
    polygon_boundary = []
    sides.times do |i|
        angle = 2 * Math::PI / sides * i
        x = min_x + width * 0.5 + width * 0.5 * Math.cos(angle)
        y = min_y + height * 0.5 + height * 0.5 * Math.sin(angle)
        polygon_boundary << x << y
    end
    polygon_boundary << polygon_boundary[0] << polygon_boundary[1]  # Close the shapet
    polygon_boundary
end

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Set the new boundary array
        sides = 5 
        polygon.boundary_array = generate_polygon_boundary(boundary_array, sides)  # Change the number of sides here
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0024 - Change Subcatchment Boundaries\UI_script.rb" 
# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Calculate the minimum and maximum x and y coordinates
        min_x = boundary_array.each_slice(2).map(&:first).min
        max_x = boundary_array.each_slice(2).map(&:first).max
        min_y = boundary_array.each_slice(2).map(&:last).min
        max_y = boundary_array.each_slice(2).map(&:last).max
        puts "Subcatchment ID: #{polygon.id} | Min X: #{min_x} | Max X: #{max_x} | Min Y: #{min_y} | Max Y: #{max_y}"

        # Create a new boundary array for the square
        square_boundary = [min_x, min_y, max_x, min_y, max_x, max_y, min_x, max_y, min_x, min_y]

        # Set the new boundary array
        polygon.boundary_array = square_boundary
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit

# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Calculate the minimum and maximum x and y coordinates
        min_x = boundary_array.each_slice(2).map(&:first).min
        max_x = boundary_array.each_slice(2).map(&:first).max
        min_y = boundary_array.each_slice(2).map(&:last).min
        max_y = boundary_array.each_slice(2).map(&:last).max

        # Calculate the width and height
        width = max_x - min_x
        height = max_y - min_y

        # Calculate the points of the hexagon
        hexagon_boundary = [
            min_x + width * 0.25, min_y,
            min_x + width * 0.75, min_y,
            max_x, min_y + height * 0.5,
            min_x + width * 0.75, max_y,
            min_x + width * 0.25, max_y,
            min_x, min_y + height * 0.5,
            min_x + width * 0.25, min_y
        ]

        # Set the new boundary array
        polygon.boundary_array = hexagon_boundary
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit

# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Calculate the minimum and maximum x and y coordinates
        min_x = boundary_array.each_slice(2).map(&:first).min
        max_x = boundary_array.each_slice(2).map(&:first).max
        min_y = boundary_array.each_slice(2).map(&:last).min
        max_y = boundary_array.each_slice(2).map(&:last).max

        # Calculate the width and height
        width = max_x - min_x
        height = max_y - min_y

        # Calculate the points of the pentagon
        pentagon_boundary = [
            min_x + width * 0.5, min_y,
            max_x, min_y + height * 0.4,
            min_x + width * 0.8, max_y,
            min_x + width * 0.2, max_y,
            min_x, min_y + height * 0.4,
            min_x + width * 0.5, min_y
        ]

        # Set the new boundary array
        polygon.boundary_array = pentagon_boundary
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit

# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Calculate the minimum and maximum x and y coordinates
        min_x = boundary_array.each_slice(2).map(&:first).min
        max_x = boundary_array.each_slice(2).map(&:first).max
        min_y = boundary_array.each_slice(2).map(&:last).min
        max_y = boundary_array.each_slice(2).map(&:last).max

        # Calculate the width and height
        width = max_x - min_x
        height = max_y - min_y

        # Calculate the points of the nonagon
        nonagon_boundary = []
        9.times do |i|
            angle = 2 * Math::PI / 9 * i
            x = min_x + width * 0.5 + width * 0.5 * Math.cos(angle)
            y = min_y + height * 0.5 + height * 0.5 * Math.sin(angle)
            nonagon_boundary << x << y
        end
        nonagon_boundary << nonagon_boundary[0] << nonagon_boundary[1]  # Close the shape

        # Set the new boundary array
        polygon.boundary_array = nonagon_boundary
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit

# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Function to generate the boundary for a polygon with a given number of sides
def generate_polygon_boundary(boundary_array, sides)
    # Calculate the minimum and maximum x and y coordinates
    min_x = boundary_array.each_slice(2).map(&:first).min
    max_x = boundary_array.each_slice(2).map(&:first).max
    min_y = boundary_array.each_slice(2).map(&:last).min
    max_y = boundary_array.each_slice(2).map(&:last).max

    # Calculate the width and height
    width = max_x - min_x
    height = max_y - min_y

    # Calculate the points of the polygon
    polygon_boundary = []
    sides.times do |i|
        angle = 2 * Math::PI / sides * i
        x = min_x + width * 0.5 + width * 0.5 * Math.cos(angle)
        y = min_y + height * 0.5 + height * 0.5 * Math.sin(angle)
        polygon_boundary << x << y
    end
    polygon_boundary << polygon_boundary[0] << polygon_boundary[1]  # Close the shape

    polygon_boundary
end

# Iterate over all polygon objects in the network or subatchments for hw_subcatchment
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
        # Get the boundary array of the polygon
        boundary_array = polygon.boundary_array

        # Set the new boundary array
        sides = 7 
        polygon.boundary_array = generate_polygon_boundary(boundary_array, sides)  # Change the number of sides here
        polygon.write
    end
end

# Commit the transaction, making all changes permanent
net.transaction_commit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0025 - Get Minimum X, Y for All Nodes\Get Minimum X for All Nodes.rb" 
# Modified from Innovyze Ruby Documentation

net = WSApplication.current_network

# Initialize the minimum and maximum x and y values to nil
min_x = nil
min_y = nil
max_x = nil
max_y = nil

# Iterate through the nodes in the network
net.row_objects('_nodes').each do |node|
  # Check if the x value of the current node is less than the current minimum x value
  if min_x.nil? || node.x < min_x
    # If so, update the minimum x value
    min_x = node.x
  end
  
  # Check if the x value of the current node is greater than the current maximum x value
  if max_x.nil? || node.x > max_x
    # If so, update the maximum x value
    max_x = node.x
  end

  # Check if the y value of the current node is less than the current minimum y value
  if min_y.nil? || node.y < min_y
    # If so, update the minimum y value
    min_y = node.y
  end
  
  # Check if the y value of the current node is greater than the current maximum y value
  if max_y.nil? || node.y > max_y
    # If so, update the maximum y value
    max_y = node.y
  end
end

# Output the minimum and maximum x and y values
puts "Minimum x, y: #{'%.3f' % min_x},   #{'%.3f' % min_y}"
puts "Maximum x, y: #{'%.3f' % max_x},   #{'%.3f' % max_y}"
puts 'Welcome to InfoWorks ICM Version ' + WSApplication.version
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0026 - Make_Subcatchments_From_Imported_InfoSewer_Manholes\hw_UI_Script.rb" 
# Source: https://github.com/chaitanyalakeshri/ruby_scripts 

begin
  # Accessing the current network from InfoWorks
  net = WSApplication.current_network
  # Raise an error if the current network is not found
  raise "Error: current network not found" if net.nil?
  
  # Accessing Row objects or collection of row objects
  # These can include nodes, links, subcatchments, and others

  # Get all the nodes as a row object collection for the InfoWorks Network
  nodes_roc = net.row_object_collection('hw_node')
  # Raise an error if nodes are not found
  raise "Error: nodes not found" if nodes_roc.nil?

  # Get all the nodes and subcatchments as arrays in an InfoWorks Network
  nodes_hash_map = {}
  subcatchments_hash_map = {}
  nodes_ro = net.row_objects('_nodes')
  subcatchments_ro = net.row_objects('hw_subcatchment')
  # Raise an error if nodes or subcatchments are not found
  raise "Error: nodes or subcatchments not found" if nodes_ro.nil? || subcatchments_ro.nil?

  # Build a hash map of nodes using x, y coordinates as keys
  nodes_ro.each do |node|
    nodes_hash_map[[node.x, node.y]] ||= []
    nodes_hash_map[[node.x, node.y]] << node
  end

  # Begin a transaction to create new subcatchments
  net.transaction_begin
  nodes_hash_map.each do |coordinates, nodes|
    subcatchment = net.new_row_object('hw_subcatchment')
    subcatchment.subcatchment_id = nodes.first.id
    subcatchment.x = nodes.first.x
    subcatchment.y = nodes.first.y
    subcatchment.total_area = 0.10 # Set a default total area for the subcatchment
    subcatchment.write # Write the new subcatchment to the network
  end
  net.transaction_commit # Commit the transaction to finalize the creation of new subcatchments

  # Print the number of nodes, existing subcatchments, and new subcatchments created
  printf "%-30s %-d\n", "Number of HW Nodes...", nodes_ro.count
  printf "%-30s %-d\n", "Number of HW Subcatchments...", subcatchments_ro.count
  printf "%-30s %-d\n", "Number of New Subcatchments...", nodes_hash_map.size

rescue => e
  # Print an error message if an exception is raised
  puts "Error: #{e.message}"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0026 - Make_Subcatchments_From_Imported_InfoSewer_Manholes\sw_UI_Script.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
    
    # Accessing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
    
    # Get all the nodes or subcatchments as row object collection for InfoWorks Network
    nodes_roc = net.row_object_collection('sw_node')
    raise "Error: nodes not found" if nodes_roc.nil?

    # Get all the nodes and subcatchments as array in an InfoWorks Network
    nodes_hash_map = {}
    subcatchments_hash_map = {}
    nodes_ro = net.row_objects('sw_node')
    subcatchments_ro = net.row_objects('sw_subcatchment')
    raise "Error: nodes or subcatchments not found" if nodes_ro.nil? || subcatchments_ro.nil?

    # Build a hash map of nodes using x, y coordinates as keys
    nodes_ro.each do |node|
    nodes_hash_map[[node.x, node.y]] ||= []
    nodes_hash_map[[node.x, node.y]] << node
    end

    # Create new subcatchments for each unique x, y coordinate pair in the nodes hash map
    net.transaction_begin
    nodes_hash_map.each do |coordinates, nodes|
    subcatchment = net.new_row_object('sw_subcatchment')
    subcatchment.subcatchment_id = nodes.first.id
    subcatchment.x = nodes.first.x
    subcatchment.y = nodes.first.y
    subcatchment.area = 0.10
    subcatchment.write
    end
    net.transaction_commit

    # Print number of nodes and new subcatchments created
    printf "%-30s %-d\n", "Number of SW Nodes...", nodes_ro.count
    printf "%-30s %-d\n", "Number of SW Subcatchments...", subcatchments_ro.count
    printf "%-30s %-d\n", "Number of New Subcatchments...", nodes_hash_map.size

  
  rescue => e
    puts "Error: #{e.message}"
  end
   
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0027 - Copy selected subcatchments five times\hw_UI_script.rb" 
net = WSApplication.current_network

# Ask the user for the number of copies they want to create
number_of_copies = 5

# Loops through all subcatchment objects
net.row_objects('hw_subcatchment').each do |subcatchment|
    
    # Check if the catchment is selected
    if subcatchment.selected?
        
        # Loop as per the number of copies
        (1..number_of_copies).each do |copy_number|
            
            # Start a 'transaction'
            net.transaction_begin
            
            # Create a new subcatchment object
            new_object = net.new_row_object('hw_subcatchment')
            
            # Name it with '_copy_<number>' suffix
            new_object['subcatchment_id'] = "#{subcatchment['subcatchment_id']}_c_#{copy_number}"
            
            # Loop through each column
            new_object.table_info.fields.each do |field|
                
                # Copy across the field value if it's not the subcatchment name
                if field.name != 'subcatchment_id'
                    new_object[field.name] = subcatchment[field.name]
                end
            end
                       
            # Write changes
            new_object.write
            
            # End the 'transaction'
            net.transaction_commit
        end
    end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0027 - Copy selected subcatchments five times\Move_Copy_Impored_Pumps.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection
    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?
  
    subcatchments_roc = net.row_object_collection('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_roc = net.row_object_collection('hw_pump')
    raise "Error: pump not found" if pump_roc.nil?
  
    # Get all the nodes or links or subcatchments as array
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
    puts "Total number of nodes: #{nodes_ro.count}"
    
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
    puts "Total number of subcatchments: #{subcatchments_ro.count}"

    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    puts "Total number of links: #{links_ro.count}"
    # Existing code
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    
    pump_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pump_ro.nil?
    puts "Total number of pumps: #{pump_ro.count}"

    # Filter links with the label 'Pump'
    pump_links = links_ro.select { |link| link.user_text_10 == 'Pump' }

    # Check if any pump links are found
    if pump_links.any?
    # Display the total number of pump links
    puts "-" * 20  # Separator
    puts "Total number of pump links: #{pump_links.count}"

    # Iterate over each pump link and display its details
    net.transaction_begin
    pump_links.each_with_index do |pump_link, index|
        puts "Pump Link #{index + 1} Details:"
        puts "Link ID: #{pump_link.id}"
        puts "Upstream Node ID: #{pump_link.us_node_id}"
        puts "Downstream Node ID: #{pump_link.ds_node_id}"
        puts "-" * 20  # Separator
        # Assuming pump_ro is a pre-defined object for storing/linking pump data
        pump_ro = new_pump_ro()
        pump_ro.us_node_id = pump_link.us_node_id.to_s
        pump_ro.ds_node_id = pump_link.ds_node_id
        pump_ro.id = pump_link.id  
        pump_ro.write
    end
    net.transaction_commit
    else
    puts "No pump links found."
    end
  
  rescue => e
    puts "Error: #{e.message}"
  end
   
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0027 - Copy selected subcatchments five times\Step1a_Create_Subcatchments.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
    
    # Accessing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
    
    # Get all the nodes or subcatchments as row object collection for InfoWorks Network
    nodes_roc = net.row_object_collection('hw_node')
    raise "Error: nodes not found" if nodes_roc.nil?

    # Get all the nodes and subcatchments as array in an InfoWorks Network
    nodes_hash_map = {}
    subcatchments_hash_map = {}
    nodes_ro = net.row_objects('_nodes')
    subcatchments_ro = net.row_objects('hw_subcatchment')
    raise "Error: nodes or subcatchments not found" if nodes_ro.nil? || subcatchments_ro.nil?

    # Build a hash map of nodes using x, y coordinates as keys
    nodes_ro.each do |node|
    nodes_hash_map[[node.x, node.y]] ||= []
    nodes_hash_map[[node.x, node.y]] << node
    end

    # Create new subcatchments for each unique x, y coordinate pair in the nodes hash map
    net.transaction_begin
    nodes_hash_map.each do |coordinates, nodes|
    subcatchment = net.new_row_object('hw_subcatchment')
    subcatchment.subcatchment_id = nodes.first.id
    subcatchment.x = nodes.first.x
    subcatchment.y = nodes.first.y
    subcatchment.total_area = 0.10
    subcatchment.write
    end
    net.transaction_commit

    # Print number of nodes and new subcatchments created
    printf "%-30s %-d\n", "Number of HW Nodes...", nodes_ro.count
    printf "%-30s %-d\n", "Number of HW Subcatchments...", subcatchments_ro.count
    printf "%-30s %-d\n", "Number of New Subcatchments...", nodes_hash_map.size

  
  rescue => e
    puts "Error: #{e.message}"
  end
   
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0027 - Copy selected subcatchments five times\Step7a_InfoSewer_subcatchment_copy_for_ten_loads.rb" 
net=WSApplication.current_network 													# selects current active network
net.row_objects('hw_subcatchment').each do |subcatchment|							# loops through all subcatchment objects
    if subcatchment.selected?														# 'if' the catchment is selected
		net.transaction_begin														# start a 'transaction'
    	new_object = net.new_row_object('hw_subcatchment')							# create a new subcatchment object
    	new_object['subcatchment_id'] = subcatchment['subcatchment_id'] + "_copy" 	# name it with '_copy' suffix
    	new_object.table_info.fields.each do |field|								# for each column
    		if field.name != 'subcatchment_id'										# 'if' it's not the subcatchment name
    			new_object[field.name] = subcatchment[field.name]					# copy across the field value
    		end																		# end of 'if' condition 
    	end																			# end of column loop
    	new_object.write															# write changes
		net.transaction_commit												    	# end the 'transaction'
    end																				# end of 'if' condition
end																					# end of loop 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0027 - Copy selected subcatchments five times\sw_UI_script.rb" 
net = WSApplication.current_network

# Ask the user for the number of copies they want to create
number_of_copies = 5

# Loops through all subcatchment objects
net.row_objects('sw_subcatchment').each do |subcatchment|
    
    # Check if the catchment is selected
    if subcatchment.selected?
        
        # Loop as per the number of copies
        (1..number_of_copies).each do |copy_number|
            
            # Start a 'transaction'
            net.transaction_begin
            
            # Create a new subcatchment object
            new_object = net.new_row_object('sw_subcatchment')
            
            # Name it with '_copy_<number>' suffix
            new_object['subcatchment_id'] = "#{subcatchment['subcatchment_id']}_c_#{copy_number}"
            
            # Loop through each column
            new_object.table_info.fields.each do |field|
                
                # Copy across the field value if it's not the subcatchment name
                if field.name != 'subcatchment_id'
                    new_object[field.name] = subcatchment[field.name]
                end
            end
                       
            # Write changes
            new_object.write
            
            # End the 'transaction'
            net.transaction_commit
        end
    end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0028 - Percentage change in runoff surfaces upstream node into new scenario\UI_script.rb" 
text = 'Make sure to press ENTER after inputting every number, otherwise the value might not be committed and the script will fail.'
WSApplication.message_box(text,'OK','!','')

title = 'Percentage change in runoff'
dialog = [
    ['Runoff Area 1','NUMBER',0],
    ['Runoff Area 2','NUMBER',0],
    ['Runoff Area 3','NUMBER',0],
    ['Subcatchment type','String','Foul',nil,'LIST',['Foul','Storm']],
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
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0029 - Runoff surfaces from selected subcatchments\UI_script.rb" 
# Get the current network object
net = WSApplication.current_network

# Initialize an empty hash to store IDs of selected runoff surfaces
selected_runoff_surfaces = {}

# Iterate through the selected rows in the hw_runoff_surface table
net.row_objects_selection('hw_runoff_surface').each do |rs|
  # Add the ID of the current row to the hash with a value of 0
  selected_runoff_surfaces[rs.id] = 0
end

# Initialize an empty hash to store IDs of selected land uses
selected_land_uses = {}

# Iterate through all the rows in the hw_land_use table
net.row_objects('hw_land_use').each do |lu|
  # Iterate through the fields runoff_index_1 to runoff_index_10
  (1..10).each do |i|
    # Get the value of the current field
    runoff_surface = lu["runoff_index_#{i}"]
    # If the field has a value
    if !runoff_surface.nil?
      # Check if the value is a key in the selected_runoff_surfaces hash
      if selected_runoff_surfaces.key?(runoff_surface)
        # If it is, add the ID of the current row to the selected_land_uses hash
        # with a value of 0 and set the selected field of the row to true
        selected_land_uses[lu.id] = 0
        lu.selected = true
      end
    end
  end
end

# Iterate through all the rows in the hw_subcatchment table
net.row_objects('hw_subcatchment').each do |s|
  # If the land_use_id field of the current row is a key in the selected_land_uses hash
  if selected_land_uses.key?(s.land_use_id)
    # Set the selected field of the row to true
    s.selected = true
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0030 - Connect subcatchment to nearest node\SW_UI_script.rb" 
net=WSApplication.current_network
puts 'Running ruby for SWMM Networks'
nodes=Array.new
net.row_object_collection('sw_node').each do |n|
        if n.selected?
                temp=Array.new
                temp << n.id
                temp << n.x
                temp << n.y
                nodes << temp
        end
end
net.transaction_begin
net.row_object_collection('sw_subcatchment').each do |s|
        if s.selected?
                sx = s.x
                sy = s.y
                nearest_distance = 999999999.9
                (0...nodes.size).each do |i|
                        nx = nodes[i][1]
                        ny = nodes[i][2]
                        n_id = nodes[i][0]
                        distance=((sx-nx)*(sx-nx))+((sy-ny)*(sy-ny))
                        if distance < nearest_distance
                                nearest_distance=distance
                                s.outlet_id = n_id
                        end
                end
        else
        puts 'You forgot to select anything'
        end
        s.write
end
puts 'Ending ruby'
net.transaction_commit

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0030 - Connect subcatchment to nearest node\UI_script.rb" 
net=WSApplication.current_network
puts 'running ruby for InfoWorks Networks'
nodes=Array.new
net.row_object_collection('hw_node').each do |n|
        if n.selected?
                temp=Array.new
                temp << n.id
                temp << n.x
                temp << n.y
                nodes << temp
        end
end
net.transaction_begin
net.row_object_collection('hw_subcatchment').each do |s|
        if s.selected?
                sx = s.x
                sy = s.y
                nearest_distance = 999999999.9
                nearest_storm_distance = 999999999.9
                nearest_foul_distance = 999999999.9
                nearest_sanitary_distance = 999999999.9
                nearest_combined_distance = 999999999.9
                nearest_overland_distance = 999999999.9
                nearest_other_distance = 999999999.9
                (0...nodes.size).each do |i|
                        nx = nodes[i][1]
                        ny = nodes[i][2]
                        n_id = nodes[i][0]
                        distance=((sx-nx)*(sx-nx))+((sy-ny)*(sy-ny))
                        if distance < nearest_distance
                                nearest_distance=distance
                                s.node_id = n_id
                        end
                end
        else
        puts 'You forgot to select anything'
        end
        s.write
end
puts 'ending ruby'
net.transaction_commit

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0031 - List all results fields in a Simulation\Are-Methods-UIOnly-Working.rb" 
# This method of obtaining objects is WIP

$instances = {}
$instances[:WSOpenNetwork]           = WSApplication.current_network
$instances[:WSDatabase]              = WSApplication.current_database
$instances[:WSModelObjectCollection] = $instances[:WSDatabase].model_object.collection("Model Group")
$instances[:WSModelObject]           = $instances[:WSModelObjectCollection][0]
$instances[:WSNumbatNetworkObject]   = $instances[:WSDatabase].model_object.collection("Model Network")[0]
$instances[:WSSimObject]             = $instances[:WSDatabase].model_object.collection("Sim")[0]

$instances[:WSOpenNetwork].transaction_begin
$instances[:WSRowObject]             = $instances[:WSOpenNetwork].new_row_object("hw_prefs")
$instances[:WSNode]                  = $instances[:WSOpenNetwork].new_row_object("hw_nodes")
$instances[:WSLink]                  = $instances[:WSOpenNetwork].new_row_object("hw_conduit")
$instances[:WSOpenNetwork].transaction_rollback

#... etc.


def try(object,method,args)
	begin
		object.method(method).call(*args)
	rescue Exception => e
                message = e.to_s  #In general if you get a parameter type error, the method is likely runnable in the UI.
                if (message =="The method cannot be run from the user interface")
                    message = "ICMExchange Only"
                elsif message=="The method is for Innovyze internal use only, please check your licence."
                    message = "Innovyze Private method"
                elsif message == "The method cannot be run from InfoWorks ICM"
                    message = "The method cannot be run from InfoWorks ICM"
                end
		puts (object.to_s + "." +  method.to_s).ljust(80) + ":\t" + message
	end
end

Module.constants.each do |const|
    if const.to_s[/MS.+/]
        cls = Module.const_get(const) #class
        methods = cls.singleton_methods - Object.methods
        instance_methods = cls.instance_methods - Object.methods
        
        #Test singleton methods
        if methods.length > 0
            methods.each do |method|
                args = getTestArgs(cls,method)
                try(cls,method,args)
            end
        end
        
        #Test instance methods
        icls = $instances[const]
        if instance_methods.length > 0
            instance_methods.each do |method|
                args = getTestArgs(cls,method)
                try(icls,method,args)
            end
        end
    end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0031 - List all results fields in a Simulation\UI_script.rb" 
require 'set'

def print_table_results(net,bn)
  
  net.tables.each do |table|
    results_set = Set.new
    puts "Table: #{table.name.upcase}"
    net.row_object_collection(table.name).each do |row_object|
      next unless row_object.table_info.results_fields

      row_object.table_info.fields.each do |field|
        results_set << field.name
      end
    end
    puts "DB fields: #{results_set.to_a}"
    puts "Total number of unique fields: #{results_set.size}"
    puts
  end
  
  bn.tables.each do |table|
    results_set = Set.new
    puts "Table: #{table.name.upcase}"
    bn.row_object_collection(table.name).each do |row_object|
      next unless row_object.table_info.results_fields

      row_object.table_info.fields.each do |field|
        results_set << field.name
      end
    end
    puts "DB fields: #{results_set.to_a}"
    puts "Total number of unique fields: #{results_set.size}"
    puts
  end

end

# usage example
net = WSApplication.current_network
bn = WSApplication.background_network

# Print the table results
print_table_results(net,bn) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0032 - List Network Fields-Structure\hash_sw_hw_tables.rb" 
def get_tables_hash(network)
    tables_hash = {}
  
    network.tables.each do |table|
      tables_hash[table.name] = table
    end
  
    tables_hash
  end


def print_fields(network)
    fields_hash = {}
  
    network.tables.each do |table|
      table.fields.each do |field|
        next unless field.name.start_with?('sw', 'hw')
  
        prefix, suffix = field.name.split('_', 2)
        fields_hash[suffix] ||= { 'sw' => [], 'hw' => [] }
        fields_hash[suffix][prefix] << field.name
      end
    end
  
    fields_hash.each do |suffix, prefixes|
      puts "Suffix: #{suffix}"
      puts "SW Fields: #{prefixes['sw'].join(', ')}"
      puts "HW Fields: #{prefixes['hw'].join(', ')}"
      puts
    end
  end

  on = WSApplication.current_network
  on_tables = get_tables_hash(on)
  
  bn = WSApplication.background_network
  bn_tables = get_tables_hash(bn)
  
  on = WSApplication.current_network
  print_fields(on)
  
  on = WSApplication.background_network
  print_fields(on) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0032 - List Network Fields-Structure\UI-ListCurrentNetworkFields.rb" 
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
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0032 - List Network Fields-Structure\UI-ListCurrentNetworkFieldStructure.rb" 
# Get the current network
on=WSApplication.current_network

# Iterate over each table in the network
on.tables.each do |i|
  # Print the table description and name
  puts "****#{i.description}, #{i.name}"
  field_counter = 1
  # Iterate over each field in the table
  i.fields.each do |j|
    # Skip if the field's name or description contains the word "flag", "user", "nodes", or "hyperlinks"
    next if j.name.include?('flag') || j.description.include?('flag') || j.name.include?('user') || j.description.include?('user') || j.name.include?('notes') || j.description.include?('notes') || j.name.include?('hyperlinks') || j.description.include?('hyperlinks')

    # Print the field description, name, and data type
    puts  "\t#{field_counter}. #{j.description}, #{j.name}, #{j.data_type}"
    field_counter += 1
    # Check if the field's data type is 'WSStructure'
    if j.data_type=='WSStructure'
      if j.fields.nil?
        puts "\t\t***badger***"
      else
        # Iterate over each field in the 'WSStructure' data type
        j.fields.each do |bf|
          # Skip if the blob field's name or description contains the word "flag", "user", "notes", or "hyperlinks"
          next if bf.name.include?('flag') || bf.description.include?('flag') || bf.name.include?('user') || bf.description.include?('user') || bf.name.include?('notes') || bf.description.include?('notes') || bf.name.include?('hyperlinks') || bf.description.include?('hyperlinks')

          # Print the blob field description, name, and data type
          puts "\t\t#{bf.description}, #{bf.name}, #{bf.data_type}"
        end
      end
    end
  end
end

# Get the current network again
on=WSApplication.current_network

# Iterate over each table in the network
on.tables.each do |i|
  # Skip if the table name does not contain "sw_" or "hw_"
  next unless i.name.include?('sw_') || i.name.include?('hw_')
  # Print the table description and name
  puts "#{i.description}, #{i.name}"
end

# Initialize an array to hold table names
table_names = []
puts
# Iterate over each table in the network
on.tables.each do |i|
  # Add to the array if the table name contains "sw_" or "hw_"
  table_names << i.name if i.name.include?('sw_') || i.name.include?('hw_')
end

# Print the table names on one line separated by a comma
puts table_names.join(', ')
puts 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0033 - Make an Inflows File from User Fields\sw_UI_script.rb" 
def save_csv_inflows_file(net)

	data_7day = [
		['0','11','22','33','44','55','66','77','8','88','888','8888','88888','888888','8888888'],
		['1.0','0.620006','0.780006','0.8','0.099994','0.8','0.737004','0.119989','0','0','0','0.8','0','0','0'],
		['1.0','0.519989','0.759989','0.739994','0.199989','0.729997','0.54101','0.179994','0','0','0','0.8','0','0','0'],
		['1.0','0.48','0.739994','0.700006','0.249997','0.679989','0.343989','0.130009','0','0','0','0.8','0','0.499994','0'],
		['1.0','0.489997','0.749991','0.679989','0.300006','0.620006','0.363001','0.119989','0','0','0','0.8','0','0.700006','0'],
		['1.0','0.569997','0.759989','0.729997','0.4','0.759989','0.375007','0.130009','0','0','0','0.8','0','0.899994','0'],
		['1.0','0.780006','0.749991','0.88','0.499994','0.860006','0.573991','0.390003','0','0','0','0.8','0','1.399989','0'],
		['1.0','1.049997','0.829991','1.159989','0.599989','1.12','1.031989','0.519989','0','0','0','1.500006','0','1.799989','0'],
		['1.0','1.219994','0.860006','1.2','0.8','1.309991','1.593997','0.839989','0','0','0','2.999989','0','1.900006','0'],
		['1.0','1.190003','0.919989','1.110003','0.999989','1.330009','1.524999','1.059994','0','0','0','4','0','2','0'],
		['1.0','1.110003','0.930009','0.999989','1.100006','1.369997','1.223007','1.44','0','0','0','4.499994','0','1.900006','0'],
		['1.0','1.129997','1.04','1.010009','1.250009','1.190003','1.18699','3.270003','0','0','0','4','0','1.500006','0'],
		['1.0','1.090009','1.139994','1.010009','1.6','1.149991','1.115001','2.729997','0','0','0','2.999989','0','0.999989','0'],
		['1.0','1.12','1.190003','0.999989','1.650009','1.190003','1.058009','2.489997','0','0','0','2','0','0.300006','0'],
		['1.0','1.149991','1.209997','1.020006','1.6','1.289997','1.030003','2.759989','0','0','0','1.500006','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','1.6','1.139994','0.871007','2.439989','0','0','0','1.250009','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','1.6','0.909991','0.871007','1.529997','0','0','0','0.999989','0','0.199989','0'],
		['1.0','1.139994','1.229991','1.090009','1.350003','0.899994','0.862996','0.969997','0','0','0','0.999989','0','0.199989','0'],
		['1.0','1.209997','1.239989','1.110003','1.2','1.079989','1.00501','0.710003','0','0','0','0.700006','0','0.8','0'],
		['1.0','1.260006','1.209997','1.149991','1.049997','0.889997','1.207989','0.659994','0','0','0','0.700006','0','0.999989','0'],
		['1.0','1.299994','1.219994','1.180006','0.999989','1.100006','1.244006','0.470003','0','0','0','0.499994','0','1.2','0'],
		['1.0','1.239989','1.159989','1.229991','0.999989','0.969997','1.491994','0.269991','0','0','0','0.499994','0','0.899994','0'],
		['1.0','1.2','1.079989','1.190003','0.899994','0.88','1.430003','0.300006','0','0','0','0.499994','0','0.499994','0'],
		['1.0','1.020006','0.88','1.069991','0.850009','0.979994','1.28','0.269991','0','0','0','0.499994','0','0','0'],
		['1.0','0.809997','0.829991','0.930009','0.700006','0.749991','1.036006','0.199989','0','0','0','0.499994','0','0','0'],
		['1.0','0.620006','0.780006','0.8','0.390003','0.8','0.737004','0.119989','0','0','0','0.700006','0','0','0'],
		['1.0','0.519989','0.759989','0.739994','0.4','0.729997','0.54101','0.179994','0','0','0','0.700006','0','0','0'],
		['1.0','0.48','0.739994','0.700006','0.390003','0.679989','0.343989','0.130009','0','0','0','0.700006','0','0.499994','0'],
		['1.0','0.489997','0.749991','0.679989','0.4','0.620006','0.363001','0.119989','0','0','0','0.749991','0','0.700006','0'],
		['1.0','0.569997','0.759989','0.729997','0.419994','0.759989','0.375007','0.130009','0','0','0','0.749991','0','0.899994','0'],
		['1.0','0.780006','0.749991','0.88','0.599989','0.860006','0.573991','0.390003','0','0','0','0.8','0','1.399989','0'],
		['1.0','1.049997','0.829991','1.159989','1.020006','1.12','1.031989','0.519989','0','0','0','1.500006','0','1.799989','0'],
		['1.0','1.219994','0.860006','1.2','1.539994','1.309991','1.593997','0.839989','0','0','0','2.8','0','1.900006','0'],
		['1.0','1.190003','0.919989','1.110003','1.479989','1.330009','1.524999','1.059994','0','0','0','3.799989','0','2','0'],
		['1.0','1.110003','0.930009','0.999989','1.209997','1.369997','1.223007','1.44','0','0','0','4.199989','0','1.900006','0'],
		['1.0','1.129997','1.04','1.010009','1.180006','1.190003','1.18699','3.270003','0','0','0','3.699994','0','1.500006','0'],
		['1.0','1.090009','1.139994','1.010009','1.12','1.149991','1.115001','2.729997','0','0','0','3.500006','0','0.999989','0'],
		['1.0','1.12','1.190003','0.999989','1.069991','1.190003','1.058009','2.489997','0','0','0.300006','2','0','0.300006','0'],
		['1.0','1.149991','1.209997','1.020006','1.049997','1.289997','1.030003','2.759989','0','0','0.700006','1.500006','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','1.100006','1.139994','0.871007','2.439989','0','0','0.999989','1.250009','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','1.149991','0.909991','0.871007','1.529997','0','0','1.100006','0.999989','0','0.199989','0'],
		['1.0','1.139994','1.229991','1.090009','1.2','0.899994','0.862996','0.969997','0','0','0.899994','0.999989','0','0.199989','0'],
		['1.0','1.209997','1.239989','1.110003','1.399989','1.079989','1.00501','0.710003','0','0','0.300006','0.700006','0','0.8','0'],
		['1.0','1.260006','1.209997','1.149991','1.699994','0.889997','1.207989','0.659994','0','0','0','0.700006','0','0.999989','0'],
		['1.0','1.299994','1.219994','1.180006','1.799989','1.100006','1.244006','0.470003','0','0','0','0.499994','0','1.2','0'],
		['1.0','1.239989','1.159989','1.229991','1.900006','0.969997','1.491994','0.269991','0','0','0','0.499994','0','0.899994','0'],
		['1.0','1.2','1.079989','1.190003','1.750003','0.88','1.430003','0.300006','0','0','0','0.499994','0','0.499994','0'],
		['1.0','1.020006','0.88','1.069991','1.399989','0.979994','1.28','0.269991','0','0','0','0.499994','0','0','0'],
		['1.0','0.809997','0.829991','0.930009','0.8','0.749991','1.036006','0.199989','0','0','0','0.499994','0','0','0'],
		['1.0','0.620006','0.780006','0.8','0.749991','0.8','0.737004','0.119989','0','0','0','0.700006','0','0','0'],
		['1.0','0.519989','0.759989','0.739994','0.569997','0.729997','0.54101','0.179994','0','0','0','0.700006','0','0','0'],
		['1.0','0.48','0.739994','0.700006','0.390003','0.679989','0.343989','0.130009','0','0','0','0.700006','0','0.499994','0'],
		['1.0','0.489997','0.749991','0.679989','0.4','0.620006','0.363001','0.119989','0','0','0','0.749991','0','0.700006','0'],
		['1.0','0.569997','0.759989','0.729997','0.419994','0.759989','0.375007','0.130009','0','0','0','0.749991','0','0.899994','0'],
		['1.0','0.780006','0.749991','0.88','0.599989','0.860006','0.573991','0.390003','0','0','0','0.8','0','1.399989','0'],
		['1.0','1.049997','0.829991','1.159989','1.020006','1.12','1.031989','0.519989','0','0','0','1.500006','0','1.799989','0'],
		['1.0','1.219994','0.860006','1.2','1.539994','1.309991','1.593997','0.839989','0','0','0','2.8','0','1.900006','0'],
		['1.0','1.190003','0.919989','1.110003','1.479989','1.330009','1.524999','1.059994','0','0','0','3.799989','0','2','0'],
		['1.0','1.110003','0.930009','0.999989','1.209997','1.369997','1.223007','1.44','0','0','0','4.199989','0','1.900006','0'],
		['1.0','1.129997','1.04','1.010009','1.180006','1.190003','1.18699','3.270003','0','0','0','3.699994','0','1.500006','0'],
		['1.0','1.090009','1.139994','1.010009','1.12','1.149991','1.115001','2.729997','0','0','0','3.500006','0','0.999989','0'],
		['1.0','1.12','1.190003','0.999989','1.069991','1.190003','1.058009','2.489997','0','0','0','2','0','0.300006','0'],
		['1.0','1.149991','1.209997','1.020006','1.049997','1.289997','1.030003','2.759989','0','0','0','1.500006','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','0.899994','1.139994','0.871007','2.439989','0','0','0','1.250009','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','0.889997','0.909991','0.871007','1.529997','0','0','0','0.999989','0','0.199989','0'],
		['1.0','1.139994','1.229991','1.090009','0.88','0.899994','0.862996','0.969997','0','0','0','0.999989','0','0.199989','0'],
		['1.0','1.209997','1.239989','1.110003','1.010009','1.079989','1.00501','0.710003','0','0','0','0.700006','0','0.8','0'],
		['1.0','1.260006','1.209997','1.149991','1.190003','0.889997','1.207989','0.659994','0','0','0','0.700006','0','0.999989','0'],
		['1.0','1.299994','1.219994','1.180006','1.229991','1.100006','1.244006','0.470003','0.999989','0','0','0.499994','0','1.2','0'],
		['1.0','1.239989','1.159989','1.229991','1.449997','0.969997','1.491994','0.269991','0','0','0','0.499994','0','0.899994','0'],
		['1.0','1.2','1.079989','1.190003','1.389991','0.88','1.430003','0.300006','0','0','0','0.499994','0','0.499994','0'],
		['1.0','1.020006','0.88','1.069991','1.250009','0.979994','1.28','0.269991','0','0','0','0.499994','0','0','0'],
		['1.0','0.809997','0.829991','0.930009','1.020006','0.749991','1.036006','0.199989','0','0','0','0.499994','0','0','0'],
		['1.0','0.620006','0.780006','0.8','0.749991','0.8','0.737004','0.119989','0','0','0','0.700006','0','0','0'],
		['1.0','0.519989','0.759989','0.739994','0.569997','0.729997','0.54101','0.179994','0','0','0','0.700006','0','0','0'],
		['1.0','0.48','0.739994','0.700006','0.390003','0.679989','0.343989','0.130009','0','0','0','0.700006','0','0.499994','0'],
		['1.0','0.489997','0.749991','0.679989','0.4','0.620006','0.363001','0.119989','0','0','0','0.749991','0','0.700006','0'],
		['1.0','0.569997','0.759989','0.729997','0.419994','0.759989','0.375007','0.130009','0','0','0','0.749991','0','0.899994','0'],
		['1.0','0.780006','0.749991','0.88','0.599989','0.860006','0.573991','0.390003','0','0','0','0.8','0','1.399989','0'],
		['1.0','1.049997','0.829991','1.159989','1.020006','1.12','1.031989','0.519989','0','0','0','1.500006','0','1.799989','0'],
		['1.0','1.219994','0.860006','1.2','1.539994','1.309991','1.593997','0.839989','0','0','0','2.8','0','1.900006','0'],
		['1.0','1.190003','0.919989','1.110003','1.479989','1.330009','1.524999','1.059994','0','0','0','3.799989','0','2','0'],
		['1.0','1.110003','0.930009','0.999989','1.209997','1.369997','1.223007','1.44','0','0','0','4.199989','0','1.900006','0'],
		['1.0','1.129997','1.04','1.010009','1.180006','1.190003','1.18699','3.270003','0','0','0','3.699994','0','1.500006','0'],
		['1.0','1.090009','1.139994','1.010009','1.12','1.149991','1.115001','2.729997','0','0','0','3.500006','0','0.999989','0'],
		['1.0','1.12','1.190003','0.999989','1.069991','1.190003','1.058009','2.489997','0','0','0','2','0','0.300006','0'],
		['1.0','1.149991','1.209997','1.020006','1.049997','1.289997','1.030003','2.759989','0','0','0.700006','1.500006','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','0.899994','1.139994','0.871007','2.439989','0','0','0.8','1.250009','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','0.889997','0.909991','0.871007','1.529997','0','0','1.12','0.999989','0','0.199989','0'],
		['1.0','1.139994','1.229991','1.090009','0.88','0.899994','0.862996','0.969997','0','0','0.899994','0.999989','0','0.199989','0'],
		['1.0','1.209997','1.239989','1.110003','1.010009','1.079989','1.00501','0.710003','0','0','0','0.700006','0','0.8','0'],
		['1.0','1.260006','1.209997','1.149991','1.190003','0.889997','1.207989','0.659994','0','0','0','0.700006','0','0.999989','0'],
		['1.0','1.299994','1.219994','1.180006','1.229991','1.100006','1.244006','0.470003','0','0','0','0.499994','0','1.2','0'],
		['1.0','1.239989','1.159989','1.229991','1.449997','0.969997','1.491994','0.269991','0','0','0','0.499994','0','0.899994','0'],
		['1.0','1.2','1.079989','1.190003','1.389991','0.88','1.430003','0.300006','0','0','0','0.499994','0','0.499994','0'],
		['1.0','1.020006','0.88','1.069991','1.250009','0.979994','1.28','0.269991','0','0','0','0.499994','0','0','0'],
		['1.0','0.809997','0.829991','0.930009','1.020006','0.749991','1.036006','0.199989','0','0','0','0.499994','0','0','0'],
		['1.0','0.620006','0.780006','0.8','0.749991','0.8','0.737004','0.119989','0','0','0','0.700006','0','0','0'],
		['1.0','0.519989','0.759989','0.739994','0.569997','0.729997','0.54101','0.179994','0','0','0','0.700006','0','0','0'],
		['1.0','0.48','0.739994','0.700006','0.390003','0.679989','0.343989','0.130009','0','0','0','0.700006','0','0.499994','0'],
		['1.0','0.489997','0.749991','0.679989','0.4','0.620006','0.363001','0.119989','0','0','0','0.749991','0','0.700006','0'],
		['1.0','0.569997','0.759989','0.729997','0.419994','0.759989','0.375007','0.130009','0','0','0','0.749991','0','0.899994','0'],
		['1.0','0.780006','0.749991','0.88','0.599989','0.860006','0.573991','0.390003','0','0','0','0.8','0','1.399989','0'],
		['1.0','1.049997','0.829991','1.159989','1.020006','1.12','1.031989','0.519989','0','0','0','1.500006','0','1.799989','0'],
		['1.0','1.219994','0.860006','1.2','1.539994','1.309991','1.593997','0.839989','0','0','0','2.8','0','1.900006','0'],
		['1.0','1.190003','0.919989','1.110003','1.479989','1.330009','1.524999','1.059994','0','0','0','3.799989','0','2','0'],
		['1.0','1.110003','0.930009','0.999989','1.209997','1.369997','1.223007','1.44','0','0','0','4.199989','0','1.900006','0'],
		['1.0','1.129997','1.04','1.010009','1.180006','1.190003','1.18699','3.270003','0','0','0','3.699994','0','1.500006','0'],
		['1.0','1.090009','1.139994','1.010009','1.12','1.149991','1.115001','2.729997','0','0','0','3.500006','0','0.999989','0'],
		['1.0','1.12','1.190003','0.999989','1.069991','1.190003','1.058009','2.489997','0','0','0','2','0','0.300006','0'],
		['1.0','1.149991','1.209997','1.020006','1.049997','1.289997','1.030003','2.759989','0','0','0','1.500006','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','0.899994','1.139994','0.871007','2.439989','0','0','0','1.250009','0','0.199989','0'],
		['1.0','1.159989','1.250009','0.999989','0.889997','0.909991','0.871007','1.529997','0','0','0','0.999989','0','0.199989','0'],
		['1.0','1.139994','1.229991','1.090009','0.88','0.899994','0.862996','0.969997','0','0','0','0.999989','0','0.199989','0'],
		['1.0','1.209997','1.239989','1.110003','1.010009','1.079989','1.00501','0.710003','0','0','0','0.700006','0','0.099994','0'],
		['1.0','1.260006','1.209997','1.149991','1.190003','0.889997','1.207989','0.659994','0','0','0','0.700006','0','0.099994','0'],
		['1.0','1.299994','1.219994','1.180006','1.229991','1.100006','1.244006','0.470003','0','0','0.499994','0.499994','0','0.099994','0'],
		['1.0','1.239989','1.159989','1.229991','1.449997','0.969997','1.491994','0.269991','0','0','0.599989','0.499994','0','0.099994','0'],
		['1.0','1.2','1.079989','1.190003','1.389991','0.88','1.430003','0.300006','0','0','0.599989','0.499994','0','0.099994','0'],
		['1.0','1.020006','0.88','1.069991','1.250009','0.979994','1.28','0.269991','0','0','0.700006','0.499994','0','0','0'],
		['1.0','0.809997','0.829991','0.930009','1.020006','0.749991','1.036006','0.199989','0','0','0.649997','0.499994','0','0','0'],
		['1.0','0.759989','1.030003','0.950003','1.069991','1.100006','1.079989','0','0','0','0.649997','0.700006','0','0','0'],
		['1.0','0.700006','0.999989','0.96','0.999989','0.989991','0.999989','0','0','0','0','0.700006','0','0.499994','0'],
		['1.0','0.669991','1.030003','0.969997','1.190003','1.139994','1.2','0','0','0','0','0.749991','0','0.700006','0'],
		['1.0','0.579994','1.04','0.899994','0.999989','0.899994','0.999989','0','0','0','0','0.749991','0','0.899994','0'],
		['1.0','0.599989','1.030003','0.850009','0.899994','0.969997','0.950003','0','0','0','0','0.749991','0','1.6','0'],
		['1.0','0.64','1.010009','0.749991','0.700006','0.8','0.679989','0','0','0','0','0.999989','0','1.900006','0'],
		['1.0','0.710003','0.999989','0.630003','0.4','0.649997','0.370009','0','0','0','0','1.190003','0','2.099994','0'],
		['1.0','0.909991','0.999989','0.759989','0.4','0.999989','0.359989','0','0','0','0','1.289997','0','2.499994','1.6'],
		['1.0','1.020006','1.010009','0.909991','0.599989','1.12','0.599989','0','0','0','0','1.299994','0','2.4','1.900006'],
		['1.0','1.209997','1.049997','1.2','1.100006','1.100006','1.190003','0','0','0.099994','0','1.469991','0','2.099994','2.099994'],
		['1.0','1.28','1.010009','1.239989','1.2','1.180006','1.289997','0','0','0.179994','0','1.479989','0','1.900006','2.4'],
		['1.0','1.260006','1.030003','1.239989','1.299994','1.149991','1.299994','0','0','0.189991','0','1.399989','0','0.899994','2.300006'],
		['1.0','1.219994','1.020006','1.219994','1.399989','0.940006','1.469991','0','0','0.179994','0','1.500006','0','0.499994','2'],
		['1.0','1.170009','1.079989','1.2','1.399989','0.860006','1.479989','0','0','0.130009','0','1.399989','0','0.199989','1.799989'],
		['1.0','1.250009','1.049997','1.250009','1.389991','1.059994','1.399989','0','0','0','0','1.2','0','0.199989','0.999989'],
		['1.0','1.229991','1.069991','1.250009','1.399989','1.020006','1.500006','0','0','0','0','1.010009','0','0.199989','0.099994'],
		['1.0','1.2','1.04','1.100006','1.350003','1.2','1.399989','0','0','0','0','0.899994','0','0.099994','0'],
		['1.0','1.2','1.030003','1.100006','1.100006','0.909991','1.2','0','0','0','0','0.8','0','0.099994','0'],
		['1.0','1.190003','1.020006','0.999989','0.999989','1.049997','1.010009','0','0','0','0','0.8','0','0.099994','0'],
		['1.0','1.219994','0.889997','0.999989','0.899994','0.690009','0.899994','0','0','0','0.889997','0.700006','0','0.099994','0'],
		['1.0','1.139994','0.839989','0.899994','0.8','1.069991','0.8','0','0','0','0.950003','0.899994','0','0.099994','0'],
		['1.0','1.049997','0.889997','0.899994','0.8','1.020006','0.8','0','0','0','0.999989','0.700006','0','0','0'],
		['1.0','0.940006','0.930009','0.860006','0.700006','0.739994','0.700006','0','0','0','0.950003','0.700006','0','0','0'],
		['1.0','0.819994','0.930009','0.870003','0.899994','1.330009','0.899994','0','0','0','0.930009','0.700006','0','0','0'],
		['1.0','0.759989','1.030003','0.950003','1.069991','1.100006','1.079989','0','0','0','0.8','0.700006','0','0','0'],
		['1.0','0.700006','0.999989','0.96','0.999989','0.989991','0.999989','0','0','0','0','0.700006','0','0','0'],
		['1.0','0.669991','1.030003','0.969997','1.190003','1.139994','1.2','0','0','0','0','0.749991','0','0.499994','0'],
		['1.0','0.579994','1.04','0.899994','0.999989','0.899994','0.999989','0','0','0','0','0.749991','0','0.700006','0'],
		['1.0','0.599989','1.030003','0.850009','0.899994','0.969997','0.950003','0','0','0','0','0.749991','0','0.899994','0'],
		['1.0','0.64','1.010009','0.749991','0.700006','0.8','0.679989','0','0','0','0','0.999989','0','1.6','0'],
		['1.0','0.710003','0.999989','0.630003','0.4','0.649997','0.370009','0','0','0','0','1.190003','0','1.900006','0'],
		['1.0','0.909991','0.999989','0.759989','0.4','0.999989','0.359989','0','0','0','0','1.289997','0.899994','2.099994','1.6'],
		['1.0','1.020006','1.010009','0.909991','0.599989','1.12','0.599989','0','0','0','0','1.299994','1.100006','2.499994','1.900006'],
		['1.0','1.209997','1.049997','1.2','1.100006','1.100006','1.190003','0','0','0.099994','0','1.469991','1.250009','2.4','2.099994'],
		['1.0','1.28','1.010009','1.239989','1.2','1.180006','1.289997','0','0','0.099994','0','1.479989','1.299994','2.099994','2.4'],
		['1.0','1.260006','1.030003','1.239989','1.299994','1.149991','1.299994','0','0','0.249997','0','1.399989','1.2','1.900006','2.300006'],
		['1.0','1.219994','1.020006','1.219994','1.399989','0.940006','1.469991','0','0','0.4','0','1.500006','1.100006','0.899994','2'],
		['1.0','1.170009','1.079989','1.2','1.399989','0.860006','1.479989','0','0','1.250009','0','1.399989','0.999989','0.499994','1.799989'],
		['1.0','1.250009','1.049997','1.250009','1.389991','1.059994','1.399989','0','0','0','0','1.2','0','0.199989','0.999989'],
		['1.0','1.229991','1.069991','1.250009','1.399989','1.020006','1.500006','0','0','0','0','1.010009','0','0.199989','0.099994'],
		['1.0','1.2','1.04','1.100006','1.350003','1.2','1.399989','0','0','0','0','0.899994','0','0.199989','0'],
		['1.0','1.2','1.030003','1.100006','1.100006','0.909991','1.2','0','0','0','0.700006','0.8','0','0.099994','0'],
		['1.0','1.190003','1.020006','0.999989','0.999989','1.049997','1.010009','0','0','0','0.8','0.8','0','0.099994','0'],
		['1.0','1.219994','0.889997','0.999989','0.899994','0.690009','0.899994','0','0','0','0.979994','0.700006','0','0.099994','0'],
		['1.0','1.139994','0.839989','0.899994','0.8','1.069991','0.8','0','0','0','0.979994','0.899994','0','0.099994','0'],
		['1.0','1.049997','0.889997','0.899994','0.8','1.020006','0.8','0','0','0','0.950003','0.700006','0','0.099994','0'],
		['1.0','0.940006','0.930009','0.860006','0.700006','0.739994','0.700006','0','0','0','0.700006','0.700006','0','0','0'],
		['1.0','0.819994','0.930009','0.870003','0.899994','1.330009','0.899994','0','0','0','0.4','0.700006','0','0','0']
	  ]

	  def print_table(data_7day, row, column)
		if row < data_7day.length && column < data_7day[row].length
		  return data_7day[row][column]
		else
		  return 1.0
		end
	  end

	  def find_column(data_7day, target)
		# Get the first row
		first_row = data_7day[0]
	  
		# Find the index of the target in the first row
		index = first_row.index(target)
	  
		# If the target is not found, index will be nil
		if index.nil?
		  return nil
		else
		  # Return the index
		  return index
		end
	  end
	    	
	# Define database fields for SWMM network nodes
	database_fields = [
	  "node_id",
	  "inflow_scaling",
	  'user_number_1',
	  'user_number_2',
	  'user_number_3',
	  'user_number_4',
	  'user_number_5',
	  'user_number_6',
	  'user_number_7',
	  'user_number_8',
	  'user_number_9',
	  'user_number_10',
	  'user_text_1',
	  'user_text_2',
	  'user_text_3',
	  'user_text_4',
	  'user_text_5',
	  'user_text_6',
	  'user_text_7',
	  'user_text_8',
	  'user_text_9',
	  'user_text_10'
	]

	net.clear_selection
	puts "Scenario : #{net.current_scenario}"

	# Prepare hash for storing data of each field for database_fields
	fields_data = {}
	database_fields.each { |field| fields_data[field] = [] }

	# Initialize the count of processed rows
	row_count = 0
	total_expected = 0.0

	# Collect data for each field from sw_node
	net.row_objects('sw_node').each do |ro|
	row_count += 1
	database_fields.each do |field|
		fields_data[field] << ro[field] if ro[field]
		end
	end  

	table_index = 0

	# Initialize an array to store the node IDs
	node_ids = []

	data_7day[1..-1].each_with_index do |csv_index|
	# Skip the first row since it's the header
	next if csv_index == 0
	table_index += 1

	# Iterate over each row object
	net.row_objects('sw_node').each do |ro|
		# Calculate the sum of all user numbers
		user_number_sum = (1..10).sum { |i| ro["user_number_#{i}"].to_f }
		# Add the node ID to the array
		if user_number_sum > 0.0 then
			#puts table_index,user_number_sum
			if table_index == 1 then node_ids << ro['node_id'] end
			end

		indexes = {}
		flows = {}
		(1..10).each do |i|
		key = "user_text_#{i}"
		flow = "user_number_#{i}"
		index = find_column(data_7day, ro[key])
		indexes[key] = index.nil? ? 0 : index
		flows[flow] = index.nil? ? 0 : index
		user_number_key = "user_number_#{i}"
		end
		combined_indexes = flows.merge(indexes)

		# Only process rows where the total of all the user numbers is greater than 0.0
		if user_number_sum > 0.0
		begin
			#print "#{user_number_sum},"
			#print "#{ro['node_id']},"
			# Use indexes
			new_user_number_sum = 0.0
			indexes.each do |key, value|
			if value > 0 then 
				user_number = ro["user_number_#{value}"]
				new_user_number_sum += user_number.to_f * print_table(data_7day, table_index, value).to_f * (1440.0/1000000.0)
				end
			end
			# Print a newline character to separate each row
			print "#{new_user_number_sum},"
				rescue => e
					#puts "An error occurred: #{e.message}"
				end
			end	
	end
	puts	
	end
	# Print all of the node IDs in one row separated by commas
	puts node_ids.join(',')
	node_ids.each_with_index do |node_id, index|
		print "#{index + 1},"
		end
	# Print all of the node IDs in one column
	puts node_ids.join("\n")
	puts ''  
	end

	# Usage example
	begin
	net = WSApplication.current_network
	save_csv_inflows_file(net)
	rescue StandardError => e
		#puts "An error occurred: #{e.message}"
		end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0034 -  Display Export geometries\UI-ExportPipeArrayCSV.rb" 
## Display and Export to CSV the point_array of selected Pipes to to the file on line 5.

net=WSApplication.current_network
require 'csv'
CSV.open("c:\\temp\\pipes.csv", "wb") do |csv|
	pipes=net.row_objects_selection('cams_pipe')		## Remove "_selection" to run on whole network
	pipes.each do |s|
		unless s.point_array.nil?
			puts "#{s.us_node_id}.#{s.ds_node_id}.#{s.link_suffix} #{s.point_array}"
			csv << ["#{s.us_node_id}", "#{s.ds_node_id}", "#{s.link_suffix}", "#{s.point_array}"]
		else
			puts "#{s.us_node_id}.#{s.ds_node_id}.#{s.link_suffix}"
			csv << ["#{s.us_node_id}", "#{s.ds_node_id}", "#{s.link_suffix}",]	
		end
	end
end

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0035 -  List Master Database Objects Contents\UIIE-DatabaseContents.rb" 
# IExchange Configuration (ignore if using UI)
database = '//localhost:40000/IA_NEW'
logFilename = 'Output.txt'

# General Configuration
object_types = ['Collection Network', 'Distribution Network', 'Asset Network', 'Theme', 'Stored Query', 'Selection List', 'Web workspace']

# End of Configuration

if WSApplication.ui?
	db = WSApplication.current_database

	def log(str = '')
		puts str
	end
else
	db = WSApplication.open(database)

	$logFile = File.open(logFilename, 'w')
	def log(str = '')
		puts str
		$logFile.puts str
	end
end

log object_types
log

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

log "Database Guid: #{db.guid}"
log

object_types.each { |network_type|
	networks = db.model_object_collection(network_type)
	network_ids = Array.new
	
	log "#{network_type}(s)"
	
	networks.each { |network|
		log "#{network.id}	#{network.name}"
		#log "#{network.id}	#{network.name}		#{network.path}"
		network_ids.push network.id
	}

	log "Identified #{network_ids.size} #{network_type}"
	log
}

endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

log
log "Done.  Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
log

puts log

if !WSApplication.ui?
	$logFile.close()
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0035 -  List Master Database Objects Contents\UIIE-DatabaseSummary.rb" 
# IExchange Configuration (ignore if using UI)
database = '//localhost:40000/IA_NEW'
logFilename = 'Output.txt'

# General Configuration
object_types = ['Collection Network', 'Distribution Network', 'Asset Network', 'Theme', 'Stored Query', 'Selection List', 'Web workspace']

# End of Configuration

if WSApplication.ui?
	db = WSApplication.current_database

	def log(str = '')
		puts str
	end
else
	db = WSApplication.open(database)

	$logFile = File.open(logFilename, 'w')
	def log(str = '')
		puts str
		$logFile.puts str
	end
end

startingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)

log "Database Guid: #{db.guid}"
log

object_types.each { |network_type|
	networks = db.model_object_collection(network_type)
	network_ids = Array.new

	networks.each { |network|
		network_ids.push network.id
	}

	log "#{network_ids.size}	#{network_type}"

}

endingTime = Process.clock_gettime(Process::CLOCK_MONOTONIC)
elapsed = endingTime - startingTime

log
log "Done.  Time taken #{Time.at(elapsed).utc.strftime("%H:%M:%S")}"
log

puts log

if !WSApplication.ui?
	$logFile.close()
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0036 -  Create Selection List\UI-CreateSelectionList.rb" 
db=WSApplication.current_database
net=WSApplication.current_network

group=db.model_object_from_type_and_id('yarra',1)	## Where to create the Selection List object on the db
sl=group.new_model_object('Selection List','Anode')	## Create new Selection List called 'New_Selection'
sl=group.new_model_object('Selection List','Alink')	## Create new Selection List called 'New_Selection'
net.save_selection(sl)									## Save current selection into the sl as above 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0037 -  Select Isolated Nodes\UI-SelectIsolatedNodes.rb" 
net=WSApplication.current_network
net.clear_selection
ro=net.row_objects('_nodes').each do |ro|
	if ro.us_links.length==0 && ro.ds_links.length==0 && ro.navigate('lateral_pipe').size==0
		ro.selected=true
	end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0038 - Remove rows from a blob field\UI-DeleteRowsFromAttachmentsBlob.rb" 
## Remove certain data rows from the Attachments blob of Manhole Survey objects.

net=WSApplication.current_network
net.transaction_begin
fields=Array.new
fieldsHash=Hash.new
net.table('cams_manhole_survey').fields.each do |f|
	if f.name=='attachments'
		n=0
		f.fields.each do |bf|
			fields << bf.name
			fieldsHash[bf.name]=n
			n+=1
		end
		break
	end
end
net.row_objects_selection('cams_manhole_survey').each do |s|
	attachments=s.attachments
	$allValues=Array.new
	if attachments.size>0
		(0...attachments.size).each do |i|
			values=Array.new
			#IF Attahcments.Description is not = '123' write into the array
			if attachments[i].description!='123'
			fields.each do |f|
				values << attachments[i][f]
				end
			$allValues << values
			end
		end
		#Alter the Attachments blob size 
		attachments.length = $allValues.length
		(0...$allValues.size).each do |i|
			j=0
			fields.each do |f|
				attachments[i][f]=$allValues[i][j]
				j+=1
			end
		end
		attachments.write
		s.write
	end	
end
net.transaction_commit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0039 - Calculate subcatchment areas in all nodes upstream a node\UI_Script.rb" 
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
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0040 - Create a new selection list using a SQL query\UI_Script.rb" 
db=WSApplication.current_database
net=WSApplication.current_network
net.clear_selection
group=db.find_root_model_object 'Model Group','InfoSewer_ICM_Erie_Models_Feb'
net.run_SQL "_links","flags.value='ISAC''"
net.run_SQL "_nodes","flags.value='ISAC''"
net.run_SQL "_subcatchments","flags.value='ISAC''"
sl=group.new_model_object 'Selection List','Conduits'
puts s1=sl.name
net.save_selection sl
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0041 - Get results from all timesteps for Links, US Flow, DS Flow\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define a hash to store the mean us_flow for each link
mean_us_flows = {}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs
# Print the time interval in seconds and minutes
puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60.0]

# Define the result field names
res_field_names = [ "us_depth", "us_flow",  "us_froude",  "us_totalhead", "us_vel","ds_depth", "ds_flow", 
"ds_depth", "ds_flow", "ds_froude", "ds_totalhead", "ds_vel",  "volume", "HYDGRAD"]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?
    res_field_names.each do |res_field_name|
      # Get the results for the specified field
      results = ro.results(res_field_name)
  
      # Ensure we have results for all timesteps
      if results.size == ts.size
        # Initialize variables for statistics
        total = 0.0
        count = 0
        total_integrated_over_time = 0.0
        min_value = results.first.to_f
        max_value = results.first.to_f

        # Iterate through the results and update statistics
        results.each do |result|
          val = result.to_f

          total += val
          total_integrated_over_time += val * time_interval
          min_value = [min_value, val].min
          max_value = [max_value, val].max
          count += 1
        end

        # Calculate the mean value
        mean_value = total / count

        # Store the mean us_flow for the current link
        mean_us_flows[sel.id] = mean_value if res_field_name == 'us_flow'

        # Print the statistics
        puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Mean: #{'%15.5f' % mean_value} | Max: #{'%15.5f' % max_value} | Min: #{'%15.5f' % min_value} | Steps: #{'%10d' % count} | Sum: #{'%12.5e' % total_integrated_over_time}"
      else
        puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
      end
    end
  rescue => e
    # Output error message if any error occurred during processing this object
     #puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end

# Sort the mean_us_flows hash by value in descending order and select the top ten links
top_ten_links = mean_us_flows.sort_by { |_, v| -v }.first(10).map { |k, _| k }

# Print the top ten links with the largest mean us_flow
puts
puts "Top ten links with the largest mean us_flow:"
top_ten_links.each { |link| puts link }

# Select the top ten links on the geoplan
net.clear_selection
top_ten_links.each { |link| net.row_object('_links', link).selected = true }
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0042 - Get results from all timesteps for Subcatchments, All Params\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected Subcatchments
field_names = [
  'qfoul', 'qtrade', 'rainfall', 'evaprate', 'grndstor', 'soilstor', 'qsoil',
  'qinfsoil', 'qrdii', 'qinfilt', 'qinfgrnd', 'qground', 'plowfw', 'plowsnow',
  'impfw', 'pervfw', 'impmelt', 'pervmelt', 'impsnow', 'pervsnow', 'losttogw',
  'napi', 'qcatch', 'q_lid_in', 'q_lid_out', 'q_lid_drain', 'q_exceedance',
  'rainprof', 'effrain', 'qbase', 'v_exceedance', 'runoff', 'qsurf01',
  'qsurf02', 'qsurf03', 'qsurf04', 'qsurf05', 'qsurf06', 'qsurf07', 'qsurf08',
  'qsurf09', 'qsurf10', 'qsurf11', 'qsurf12'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current subcatchment
    ro = net.row_object('_subcatchments', sel.id)
    
    # If ro is nil, then the object with the given id is not a subcatchment
    raise "Object with ID #{sel.id} is not a subcatchment." if ro.nil?

    # Iterate over each field name
    field_names.each do |res_field_name|
      begin
        # Get the count of results for the current field
        rs_size = ro.results(res_field_name).count

     # If the count of results matches the count of timesteps, proceed with calculations
     if rs_size == ts_size
      # Initialize variables to keep track of statistics
      total = 0.0
      total_integrated_over_time = 0.0
      min_value = Float::INFINITY
      max_value = -Float::INFINITY
      count = 0
      
      # Assuming the time steps are evenly spaced, calculate the time interval in seconds
      time_int      = (ts[1] - ts[0]).abs
      time_interval =  time_int
      
      # Iterate through the results and update statistics
      ro.results(res_field_name).each_with_index do |result, time_step_index|
        total += result.to_f
        total_integrated_over_time += result.to_f * time_interval 
        min_value = [min_value, result.to_f].min
        max_value = [max_value, result.to_f].max
        count += 1
      end

      # Calculate the mean value if the count is greater than 0
      mean_value = count > 0 ? total / count : 0

       # If the field name is 'rainfall', adjust the total_integrated_over_time value
       total_integrated_over_time /= 3600.0  if res_field_name == 'rainfall' 
       total_integrated_over_time * sel.total_area * 10000.0  if res_field_name != 'rainfall' 
      
      # Print the total, total integrated over time, mean, max, and min values
      puts "Sub: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    end

      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for subcatchment with ID #{sel.id}."
        next
      end
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    #puts "Error processing subcatchment with ID #{sel.id}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0042 - Get results from all timesteps for Subcatchments, All Params\sw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected Subcatchments
field_names = [
   'RAINFALL', 'SNOW_DEPTH', 'EVAPORATION_LOSS', 'INFILTRATION_LOSS', 'RUNOFF',
  'GROUNDWATER_FLOW', 'GROUNDWATER_ELEVATION', 'IMPERV_RUNOFF', 'PERV_RUNOFF'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current subcatchment
    ro = net.row_object('_subcatchments', sel.id)
    
    # If ro is nil, then the object with the given id is not a subcatchment
    raise "Object with ID #{sel.id} is not a subcatchment." if ro.nil?

    # Iterate over each field name
    field_names.each do |res_field_name|
      begin
        # Get the count of results for the current field
        rs_size = ro.results(res_field_name).count

     # If the count of results matches the count of timesteps, proceed with calculations
     if rs_size == ts_size
      # Initialize variables to keep track of statistics
      total = 0.0
      total_integrated_over_time = 0.0
      min_value = Float::INFINITY
      max_value = -Float::INFINITY
      count = 0
      
      # Assuming the time steps are evenly spaced, calculate the time interval in seconds
      time_int      = (ts[1] - ts[0]).abs
      time_interval =  time_int * 86400.0
      
      # Iterate through the results and update statistics
      ro.results(res_field_name).each_with_index do |result, time_step_index|
        total += result.to_f
        total_integrated_over_time += result.to_f * time_interval
        min_value = [min_value, result.to_f].min
        max_value = [max_value, result.to_f].max
        count += 1
      end

      # Calculate the mean value if the count is greater than 0
      mean_value = count > 0 ? total / count : 0

      total_integrated_over_time /= 3600.0 if res_field_name != 'RUNOFF'
      #total_integrated_over_time *= sel.area * 10000.0 if res_field_name == 'RUNOFF'

      puts "Sub: #{'%-12s' % sel.id} | Field: #{'%-18s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    end

      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for subcatchment with ID #{sel.id}."
        next
      end
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    #puts "Error processing subcatchment with ID #{sel.id}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0043 - Get results from all timesteps for Manholes, Qnode\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps and gauge timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps timesteps
ts = net.list_timesteps

# Define the result field name to fetch the results (in this case, 'qnode')
res_field_name = 'QNODE'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current node 
    ro = net.row_object('hw_node', sel.node_id) 
    rs_size=ro.results(res_field_name).count

 # Check if the count of results matches the count of timesteps
 if rs_size == ts_size

  # Initialize variables to keep track of statistics
  total = 0.0 # Added this line for the total sum
  total_integrated_over_time = 0.0
  min_value = Float::INFINITY
  max_value = -Float::INFINITY
  count = 0
  
  # Assuming the time steps are evenly spaced, calculate the time interval in seconds
  time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1
  
  # Iterate through the results and print each one
  ro.results(res_field_name).each_with_index do |result, time_step_index|
    # Update the total, total integrated over time, min, and max based on the current result
    total += result.to_f # Added this line to calculate the total sum
    total_integrated_over_time += result.to_f * time_interval
    min_value = [min_value, result.to_f].min
    max_value = [max_value, result.to_f].max
    count += 1 # Increment the count for calculating the mean
    end
  end 
  
  # Calculate the mean value if the count is greater than 0
  mean_value = count > 0 ? total / count : 0
  
  # Print the total, total integrated over time, mean, max, and min values
  puts "Node: #{'%-12s' % sel.node_id} | Sum: #{'%12.4f' % total_integrated_over_time} | Mean: #{'%12.4f' % mean_value} | Max: #{'%12.4f' % max_value} | Min: #{'%12.4f' % min_value} | Field: #{res_field_name}"
end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0044 - Get results from all timesteps for Manholes, All Params\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps and gauge timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs
# Print the time interval in seconds and minutes
puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60.0]

# Define the result field names to fetch the results for all selected nodes
result_field_names = [
  'depnod', 'dmaxd', 'volume', 'flooddepth', 'floodvolume', 'flvol',
  'qinfnod', 'qnode', 'qrain', 'flooddepth', 'floodvolume', 'flvol',
  'gllyflow', 'gttrsprd', 'inleteff', 'ovdepnod', 'ovqnode', 'ovvolume',
  'twoddepnod', 'twodflow', 'twodfloodflow', 'ctwodflow', 'q_limited',
  'q_limited_volume', 'q_limited_volume_rate'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current node
    ro = net.row_object('hw_node', sel.node_id) 
    
    # If ro is nil, then the object with the given id is not a node
    raise "Object with ID #{sel.node_id} is not a node." if ro.nil?

    # Iterate through each result field name
    result_field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        # Check if the count of results matches the count of timesteps
        if rs_size == ts_size

          # Initialize variables to keep track of statistics
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0

          # Iterate through the results and calculate statistics
          ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            
            if ['qnode', 'qinfnod', 'qrain'].include?(res_field_name)
              total_integrated_over_time += result.to_f * time_interval
            else
              total_integrated_over_time = result.to_f
            end

            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          # Calculate the mean value if the count is greater than 0
          mean_value = count > 0 ? total / count : 0
          
          # Print the total, total integrated over time, mean, max, min values, and count
          if ['qnode', 'qinfnod', 'qrain'].include?(res_field_name)
          puts "Node: #{'%-12s' % sel.node_id} | #{'%-16s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
          else
          puts "Node: #{'%-12s' % sel.node_id} | #{'%-16s' % res_field_name} | End: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
          end 
        end

      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for node with ID #{sel.node_id}."
        next
      end
    end

      rescue => e
        # Output error message if any error occurred during processing this object
        #puts "Error processing node with ID #{sel.node_id}. Error: #{e.message}"
      end
    end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0044 - Get results from all timesteps for Manholes, All Params\sw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps and gauge timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected nodes
result_field_names = [
    'DEPTH', 'HEAD', 'VOLUME', 'LATERAL_INFLOW',' TOTAL_INFLOW', 'FLOODING', 'PRESSURE', 'INVERT_ELEVATION',
    'HEAD_CLASS'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current node
    ro = net.row_object('sw_node', sel.node_id) 
    
    # If ro is nil, then the object with the given id is not a node
    raise "Object with ID #{sel.node_id} is not a node." if ro.nil?

    # Iterate through each result field name
    result_field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        # Check if the count of results matches the count of timesteps
        if rs_size == ts_size

          # Initialize variables to keep track of statistics
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0
          
          # Assuming the time steps are evenly spaced, calculate the time interval in seconds
          time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1
          
          # Iterate through the results and calculate statistics
          ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            
            if ['LATERAL_INFLOW', 'TOTAL_INFLOW'].include?(res_field_name)
              total_integrated_over_time += result.to_f * time_interval
            else
              total_integrated_over_time = result.to_f
            end

            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          # Calculate the mean value if the count is greater than 0
          mean_value = count > 0 ? total / count : 0
          
          # Print the total, total integrated over time, mean, max, min values, and count
          if ['LATERAL_INFLOW', 'TOTAL_INFLOW'].include?(res_field_name)
          puts "Node: #{'%-16s' % sel.node_id} | #{'%-16s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
          else
          puts "Node: #{'%-16s' % sel.node_id} | #{'%-16s' % res_field_name} | End: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
          end 
        end

      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for node with ID #{sel.node_id}."
        next
      end
    end

      rescue => e
        # Output error message if any error occurred during processing this object
        #puts "Error processing node with ID #{sel.node_id}. Error: #{e.message}"
      end
    end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0045 - Get results from all timesteps for Links, All Params\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected links
field_names = [
  'us_depth', 'ds_depth',  'us_flow', 'ds_flow', 
  'us_froude', 'ds_froude',  'us_vel', 'ds_vel', 'us_totalhead',
  'ds_totalhead','hydgrad',
  'surcharge', 'volume', 'qlink', 'qinflnk', 
  'surcharge', 
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link
    ro = net.row_object('_links', sel.id)

    # Iterate over each field name
    field_names.each do |res_field_name|
      # Get the count of results for the current field
      rs_size = ro.results(res_field_name).count

      # If the count of results matches the count of timesteps, proceed with calculations
      if rs_size == ts_size
        # Initialize variables to keep track of statistics
        total = 0.0
        total_integrated_over_time = 0.0
        min_value = Float::INFINITY
        max_value = -Float::INFINITY
        count = 0
        
        # Assuming the time steps are evenly spaced, calculate the time interval in seconds
        time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1
        
        # Iterate through the results and update statistics
        ro.results(res_field_name).each_with_index do |result, time_step_index|
          total += result.to_f
          total_integrated_over_time += result.to_f * time_interval
          min_value = [min_value, result.to_f].min
          max_value = [max_value, result.to_f].max
          count += 1
        end

        # Calculate the mean value if the count is greater than 0
        mean_value = count > 0 ? total / count : 0
        
        # Print the total, total integrated over time, mean, max, and min values
        puts "Link: #{'%-12s' % sel.id} | #{'%-16s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
      end
    end

  rescue
    # This will handle the error when the field does not exist
    #puts "Error: Field '#{res_field_name}' does not exist for node with ID #{sel.node_id}."
    next
  end
end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end


 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0045 - Get results from all timesteps for Links, All Params\sw_UI_script.rb" 
# Import the 'date' library
require 'date'
 
# Get the current network object from ICM SWMM
net = WSApplication.current_network
 
# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count
 
# Get the list of timesteps
ts = net.list_timesteps
 
# Define the result field names to fetch the results for all selected links
field_names = [
    'FLOW',  'MAX_FLOW',   'DEPTH',     'VELOCITY',   'MAX_VELOCITY',  'HGL',     'FLOW_VOLUME',     'FLOW_CLASS',
    'CAPACITY',  'MAX_CAPACITY',   'SURCHARGED',     'ENTRY_LOSS',     'EXIT_LOSS'
]
  # Initialize an empty array to store the results
  results = []
 
# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link
    ro = net.row_object('_links', sel.id)
    next if ro.nil?
    diameter = ro.conduit_height / 1000.0
    full_flow = 3.14159 * (diameter/2.0) * (diameter/2.0)

    # Iterate over each field name
    field_names.each do |res_field_name|
      begin  # Nested begin for inner operations
        # Get the count of results for the current field
        rs_size = ro.results(res_field_name).count
 
        # If the count of results matches the count of timesteps, proceed with calculations
        if rs_size == ts_size
        # Initialize variables to keep track of statistics
        total = 0.0
        total_integrated_over_time = 0.0
        min_value = Float::INFINITY
        max_value = -Float::INFINITY
        count = 0
       
        # Assuming the time steps are evenly spaced, calculate the time interval in seconds
        time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1
       
        # Iterate through the results and update statistics
        ro.results(res_field_name).each_with_index do |result, time_step_index|

          total += result.to_f
            if ['FLOW'].include?(res_field_name)
                total_integrated_over_time += result.to_f * time_interval
            else
                total_integrated_over_time = result.to_f
            end
          min_value = [min_value, result.to_f].min
          max_value = [max_value, result.to_f].max
          count += 1
          end
 
        # Calculate the mean value if the count is greater than 0
        mean_value = count > 0 ? total / count : 0
 
        puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.5f' % max_value} | Min: #{'%15.5f' % min_value} | Steps: #{'%15d' % count}"
        if ['DEPTH'].include?(res_field_name)
          puts "Link: #{'%-12s' % sel.id} | Field: d/D          | Sum: #{'%15.4f' % (total_integrated_over_time/diameter)} | Mean: #{'%15.4f' % (mean_value/diameter)} | Max: #{'%15.5f' % (max_value/diameter)} | Min: #{'%15.5f' % (min_value/diameter)} | Diameter: #{'%12.3f' % diameter}"
          end
          if ['FLOW'].include?(res_field_name)
            puts "Link: #{'%-12s' % sel.id} | Field: q/Q          | Sum: #{'%15.4f' % (total_integrated_over_time/full_flow)} | Mean: #{'%15.4f' % (mean_value/full_flow)} | Max: #{'%15.5f' % (max_value/full_flow)} | Min: #{'%15.5f' % (min_value/full_flow)} | Full Flow: #{'%11.3f' % full_flow}"
          end         
      end
 
      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for link with ID #{sel.id}."
        next
      end
    end
 
  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0046 - Output SUDS control as CSV\UI_Script.rb" 
#Below ICM UI script can be used to export SUDS control data from each subcatchment to a csv

require 'csv'

open_net = WSApplication.current_network

# Prompt user for an output folder
result = WSApplication.prompt "Export Subcatchment SUDS control as CSV",
[
  ['Output folder', 'String', nil, nil, 'FILE', true, 'csv', 'CSV', false]
], false
output_folder = result[0]

# Set up the CSV header
header = [
  "Subcatchment ID",
  "SUDS structure ID",
  "SUDS control ID",
  "Control type",
  "Area",
  "Number of units",
  "Area of subcatchment (%)",
  "Unit surface width",
  "Initial saturation (%)",
  "Impervious area treated (%)",
  "Pervious area treated (%)",
  "Outflow to",
  "Drain to subcatchment",
  "Drain to node",
  "Surface"
]

# Initialize an array to store the CSV data
suds_data = [header]

# Iterate over each subcatchment and its SUDS controls
open_net.row_objects('_subcatchments').each do |sub|
  sub.SUDS_controls.each do |control|
    # Add a row to the CSV data for each SUDS control
    puts sub.subcatchment_id
    puts control.id
    puts control.suds_structure
    puts control.control_type
    puts control.area
    puts control.num_units
    puts control.area_subcatchment_pct
    puts control.unit_surface_width
    puts control.initial_saturation_pct
    puts control.impervious_area_treated_pct
    puts control.pervious_area_treated_pct
    puts control.outflow_to
    puts control.drain_to_subcatchment
    puts control.drain_to_node
    puts control.surface

    suds_data.push([
     sub.subcatchment_id,
      control.id,
      control.suds_structure,
      control.control_type,
      control.area,
      control.num_units,
      control.area_subcatchment_pct,
      control.unit_surface_width,
      control.initial_saturation_pct,
      control.impervious_area_treated_pct,
      control.pervious_area_treated_pct,
      control.outflow_to,
      control.drain_to_subcatchment,
      control.drain_to_node,
      control.surface
    ])

    
      # Print all attributes of the control object
      control.instance_variables.each do |var|
        puts "#{var}: #{control.instance_variable_get(var)}"
      end

  end
end

# Write the CSV data to a file in the specified output folder
CSV.open(output_folder, "w") do |csv|
  suds_data.each do |row|
    csv << row
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0047 - Select links sharing the same us and ds node ids\UI_Script.rb" 
net = WSApplication.current_network
net.clear_selection
links_list_all = []

# Creates an array of arrays containing the unique link id and the upstream and downstream nodes of each link.
net.row_objects('_links').each do |link|
  usds = "#{link.us_node_id}-#{link.ds_node_id}"
  links_list_all << [usds, link.id]
end

# Groups all links by their respective us/ds node ids
group_by_usds = links_list_all.group_by { |usds, id| usds }.transform_values { |values| values.map { |usds, id| id } }

# Filters groups with us/ds showing more than once and converts hash to a flattened array of links
link_list_sel = group_by_usds.select { |usds, ids| ids.length > 1 }.values.flatten

# Selects only links from the list above on the active network
net.row_objects('_links').each do |link|
  link.selected = true if link_list_sel.include?(link.id)
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0048 - Delete all scenarios except Base\UI_Script.rb" 
net=WSApplication.current_network
net.scenarios do |s|
    if s != 'Base'
        net.delete_scenario(s)
    end
end
puts 'All scenarios deleted' 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0049 - Clear SUDS from subcatchments\hw_UI_Script.rb" 
#Below UI script clears SUDS control data (blob structure) from all the subcatchments
require 'CSV'
require 'date'

on=WSApplication.current_network
start_time=Time.now

on.transaction_begin
on.row_objects('_subcatchments').each do |ro|
	ro.suds_controls.size=0
	ro.suds_controls.write
	ro.write
	arr.ti.fields.each do |field|
		puts field+' '+ro.results(field).to_s
	end
end
on.transaction_commit

end_time=Time.now

net_time= end_time - start_time

puts
puts 'Script Runtime :'+ net_time.to_s + ' sec'

=begin
suds_controls.area
suds_controls.area_subcatchment_pct
suds_controls.control_type
suds_controls.drain_to_node
suds_controls.id
suds_controls.impervious_area_treated_pct
suds_controls.initial_saturation_pct
suds_controls.num_units
suds_controls.outflow_to
suds_controls.pervious_area_treated_pct
suds_controls.suds_structure
suds_controls.unit_surface_width
suds_controls.surface
=end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0050 - Assign Subcatchment to nearest 'Storage' type Node\Nearest Storage Node.rb" 
net=WSApplication.current_network
net.transaction_begin

puts 'Connecting subcatchments to the closest storage node to centroid:'

#loop through each subcatchment object extracting the X,Y and setting a default distance of 999999999
subcatchment=net.row_objects('hw_subcatchment').each do |subcatchment| 
	if subcatchment.node_id == "" #where field is blank
	x=subcatchment.x
	y=subcatchment.y
	di=9999999999
	dischargeNode=''
	
node=net.row_objects('hw_node').each do |node| 
	if node.node_type.downcase == "storage" #only calculate against note_type = storage
	#.downcase makes the match case insensitive
	tdi=((x-node.x)**2+(y-node.y)**2)**0.5 #calculate distance to node
		if (tdi<di)
		dischargeNode=node['node_id'] #updates node id for smallest distance
		di=tdi
		end
	end
end 

puts subcatchment['subcatchment_id']+':'+ dischargeNode
subcatchment['node_id'] = dischargeNode
subcatchment.write 

	end
end

net.transaction_commit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0051 - Additional DWF Node IDs\sw_UI_Script.rb" 
# Access the current database and network, and then obtain the current model object
net = WSApplication.current_network

# Initialize the count of processed rows and prepare storage for baseline data
row_count = 0
baseline_data = []

# Collect baseline data from sw_node_additional_dwf
net.row_objects('sw_node').each do |ro|
  #ro.additional_dwf.size=0
    ro.additional_dwf.each do |additional_dwf|
        row_count += 1
          puts "#{ro.id}, #{ro.bf_pattern_1}"
        baseline_data << additional_dwf.baseline
  end
end

# Check if there is any data in baseline
if baseline_data.empty?
  puts "baseline has no data!"
else
  # Calculate statistics for baseline data
  min_value = baseline_data.min
  max_value = baseline_data.max
  sum = baseline_data.inject(0.0) { |accum, val| accum + val }
  mean_value = sum / baseline_data.size
  # Calculate the standard deviation
  sum_of_squares = baseline_data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
  standard_deviation = Math.sqrt(sum_of_squares / baseline_data.size)
  total_value = sum

  # Print statistics for baseline
  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
         "baseline, MGD", row_count, min_value, max_value, mean_value, standard_deviation, total_value)
  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
         "baseline, GPM", row_count, min_value*694.44, max_value*694.44, mean_value*694.44, standard_deviation*694.44, total_value*694.44)
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0052 - Stats for ICM Network Tables\hw_UI_Script.rb" 
# Accessing current network
net = WSApplication.WSApplication.current_network 
raise "Error: current network not found" if net.nil?

tables = [
  "hw_node",
  "hw_conduit",
  "hw_subcatchment"
]

begin
  nodes_hash_map = Hash.new { |h, k| h[k] = [] }
  
  tables.each do |table|
    nodes_ro = net.row_objects(table)
    raise "Error: #{table} not found" if nodes_ro.nil?
    number_nodes = nodes_ro.size
    printf "%-50s %-d\n", "Number of #{table.upcase}", number_nodes

    # Initialize totals for parameters
    total_length = 0.0
    total_area = 0.0
    total_volume = 0.0

    # Iterate over each row object and sum up the parameters
    nodes_ro.each do |node|
      node.
      total_length += node.length.to_f if node.respond_to?(:length)
      total_area += node.area.to_f if node.respond_to?(:area)
      total_volume += node.volume.to_f if node.respond_to?(:volume)
    end

    # Print totals for parameters
    puts "Total length for #{table.upcase}: #{total_length}"
    puts "Total area for #{table.upcase}: #{total_area}"
    puts "Total volume for #{table.upcase}: #{total_volume}"
  end

rescue => e
  puts "Error: #{e.message}"
end


 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0053 - Scenario Counter\Scenario_Generator.rb" 
# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits 

current_network = WSApplication.current_network

THANK_YOU_MESSAGE = 'Thank you for using Ruby in ICM InfoWorks'

scenarios=Array.new
scenarios = [ 
"FUTURE_II",
"FUTURE_II_2023",
"FUT_II_I25",
"FU_II_ALT1_I25_LS",
"U_II_ALT1_I25_LS"
]

current_network.scenarios do |scenario|
    if scenario != 'Base'
        current_network.delete_scenario(scenario)
    end
end
puts 'All scenarios deleted'

scenarios.each do |scenario|
	current_network.add_scenario(scenario,nil,'')
  end

puts THANK_YOU_MESSAGE

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0054 - Flow Survey\Flow Survey.rb" 

net=WSApplication.current_network


def ustrace(link)
	link._seen=true
	unprocessedLinks=Array.new
	unprocessedLinks<<link
	uslinks=Array.new
	uslinks<<link
	usnodes=Array.new
	
	
	while unprocessedLinks.size>0
		working=unprocessedLinks.shift
		workingUSNode=working.us_node
		if !workingUSNode.nil? && !workingUSNode._seen
			usnodes<<workingUSNode
			workingUSNode._seen=true
			workingUSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					uslinks<<l
					l._seen=true
				end
			end
		end
	end
	return [usnodes,uslinks]
end
val=WSApplication.prompt "Flow Monitor Input Dialog Box",
[
['ID of Master Group or Model Group where selection list will be saved','String'],
['Above ID is of Master Group/ Model Group?','String','Model group',nil,'LIST',['Model group','Master group']]
],true
db=WSApplication.current_database
mo=db.model_object_from_type_and_id(val[1],val[0].to_i)
flow_monitors_links=net.row_objects_selection('_links')
flow_monitors_links.each do |z|
	z._seen=true
end
flow_monitors_links.each do |n|
	net.clear_selection
	us_array=ustrace(n)
	
	nodes_roc=us_array[0]
	nodes_roc.each do |a|
		a.selected=true
	end
	
	links_roc=us_array[1]
	links_roc.each do |b|
		b.selected=true
	end
	
	#Slecting U/S subcatchments 
	subs_all=net.row_objects('_subcatchments')
	net.row_objects_selection('_nodes').each do |d| 
		subs_all.each do |c|
			if c.drains_to=="Node" && c.node_id==d.node_id
				c.selected=true
			end
		end
	end
	child=mo.new_model_object('Selection list',n.us_node_id+"."+n.link_suffix)
	net.save_selection child
	net.clear_selection
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0055 - Scenario Maker - Specific\hw_sw_Scenario_Generator.rb" 
# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits 

current_network = WSApplication.current_network

THANK_YOU_MESSAGE = 'Thank you for using Ruby in ICM InfoWorks'

scenarios=Array.new
scenarios = [ 
  "PHASE0",
  "PHASE1",
 "PHASE2",
 "PHASE3",
 "PHASE4",
  "PHASE5",
  "AVG_BASE",
  "PHASE5_ASSUMEDMHS",
  "PHASE1_ASSUMEDMHS",
  "PHASE0_ASSUMEDMHS",
  "PHASE2_ASSUMEDMHS",
  "PHASE3_ASSUMEDMHS",
  "PHASE4_ASSUMEDMHS",
  "PHASE5_FIXED"  
]

current_network.scenarios do |scenario|
    if scenario != 'Base'
        current_network.delete_scenario(scenario)
    end
end
puts 'All scenarios deleted'

scenarios.each do |scenario|
	current_network.add_scenario(scenario,nil,'')
  end

puts THANK_YOU_MESSAGE

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0056 - Listview of the currently selected network objects\UI_Script.rb" 
# Source https://gist.github.com/sancarn/00e44231eba3ac20123e10601f236175

require_relative('Powershell.rb')
require 'json'

net = WSApplication.current_network
data = {}
data["head"] =["Table name", "Object ID"]
data["body"] = []
selectedItems = []

#Get all selected items
net.table_names.each do |table|
	selection = net.row_object_collection_selection(table)
	selection.each do |o|
		data["body"].push([table,o.id])
		selectedItems.push(o)
	end
end

#Build GUI
gui=<<END_GUI
#Get data from ruby as JSON string
$data = #{data.to_json.to_json.gsub(/\\"/,"\"\"")}
$data = ConvertFrom-Json $data


Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

#region begin GUI{

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '500,400'
$Form.text                       = "Form"
$Form.TopMost                    = $false
$form.Resize                     = $false
$form.FormBorderStyle            = 'FixedToolWindow'

$okButton                        = New-Object System.Windows.Forms.Button
$okButton.text                   = "OK"
$okButton.width                  = 150
$okButton.height                 = 50
$okButton.location               = New-Object System.Drawing.Point(96,330)
$okButton.Add_Click({
    ForEach($item in $ListView1.SelectedIndices){
        Write-Host $item
    }
    $Form.close()
})

$cancelButton                    = New-Object System.Windows.Forms.Button
$cancelButton.text               = "Cancel"
$cancelButton.width              = 150
$cancelButton.height             = 50
$cancelButton.location           = New-Object System.Drawing.Point(256,330)
$cancelButton.add_click({
	Write-Host "Cancel"
    $Form.close()
})

$ListView1                       = New-Object System.Windows.Forms.ListView
$ListView1.text                  = "listView"
$ListView1.width                 = 490
$ListView1.height                = 300
$ListView1.location              = New-Object System.Drawing.Point(5,5)
$ListView1.MultiSelect = 1
$ListView1.View = 'Details'
$ListView1.FullRowSelect = 1
$ListView1.Font = 'Microsoft Sans Serif,20'

#Generate headers
ForEach($d in $data.head){
    $col = $ListView1.columns.add($d)
    $col.width = -2
}

#Generate items
ForEach($item in $data.body){
    $lvi = New-Object System.Windows.Forms.ListViewItem($item)
    For($i=1;$i -lt $item.length; $i++){
        [void]$lvi.SubItems.Add($item[$i])
    }
   [void]$ListView1.items.add($lvi)
}

$Form.controls.AddRange(@($okButton, $cancelButton ,$ListView1))

[void]$Form.ShowDialog()
END_GUI

#Execute Powershell script, display GUI and retrieve user selection.
guiData = Powershell.exec(gui)

#If cancel button was not clicked then...
if guiData[:STDOUT] != "Cancel\n"
	#Get refined selection from STDOUT
	refinedSelection = guiData[:STDOUT].split("\n").map {|i| i.to_i}

	#If object NOT within selected range, unselect it.
	selectedItems.each_with_index do |o,ind|
		if !(refinedSelection.include? ind)
			o.selected = false;
		end
	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0056 - Listview of the currently selected network objects\0053 - Scenario Maker\Scenario_Generator.rb" 
# Original Source https://github.com/ngerdts7/ICM_Tools
# Modified for ICM SWMM Networks

net=WSApplication.current_network

# Define which parameters will be varied by the script. 
# Key   = name of ICM variable to be modified
# name  = abreviation of parameter to be used in scenario name
# table = name of table to be edited that contains the parameter
# id    = model ID in specified table where parameter changes are made (e.g. subcatchment ID, pipe ID, etc.)
# Range = [min, max, # of steps] -> define the range to be tested and how many steps you want the script to try.
#       Example: [0,1,5] -> will create 5 scenarios where the parameter ranges from 0 to 1 -> [0, 0.25, 0.5, 0.75, 1.0]

# Remove/add param rows as needed to account for different variables. The loop below supports up to 8 variables, but it can be expanded.
param=Hash.new
param['p_area_1'] =               {'name'=>'p1', 'table'=>'hw_land_use',            'id'=>'12430', 'Range'=>[0.3,1,2]}
param['p_area_2'] =               {'name'=>'p2', 'table'=>'hw_land_use',            'id'=>'12430', 'Range'=>[10,20,2]}
param['runoff_routing_value'] =   {'name'=>'rv', 'table'=>'hw_runoff_surface',      'id'=>'2',     'Range'=>[10,30,2]}
param['percolation_coefficient'] ={'name'=>'pc', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[2,10,3]}
param['percolation_threshold'] =  {'name'=>'pt', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[40,80,3]}
param['percolation_percentage'] = {'name'=>'pp', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[15,25,2]}
param['baseflow_coefficient'] =   {'name'=>'bc', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[30,50,2]}
param['infiltration_coefficient']={'name'=>'ic', 'table'=>'hw_ground_infiltration', 'id'=>'12430', 'Range'=>[10,20,2]}
var = param.keys

# =======================================================================================
# Prepare methods used later in the iteration loop:
#
def list_values(range_array)
# Method to convert range array into array of values to be used:
	dx = (range_array[1]-range_array[0])/(range_array[2]-1.00)
	return Array.new(range_array[2]) {|i| i*dx+range_array[0]}
end

def create_scenario(param,var,vars,net)
# Method to generate a new scenario and apply parameter changes based on input set
	scenario = ''
	for i in 0..var.length-1
		# assemble unique scenario name based on parameter composition
		scenario << param[var[i]]['name'] + "=" + vars[i].to_s + "_"
	end
	net.add_scenario(scenario,nil,'') 
	net.current_scenario=scenario
	net.clear_selection
	net.transaction_begin
	for i in 0..var.length-1
		# Apply parameter changes in scenario as defined by vars array
		puts param[var[i]]['table']
		puts param[var[i]]['id']
		row_obj = net.row_object(param[var[i]]['table'],param[var[i]]['id'])
		row_obj[var[i]] = vars[i]
		row_obj.write
	end
	net.transaction_commit
	v=net.validate(scenario)
	return scenario
end

# =======================================================================================
# Generate scenarios for every possible parameter combination:
scenarios=Array.new
var1 = list_values(param[var[0]]['Range'])
var1.each do | v1 |
	if var.length >= 2
		var2 = list_values(param[var[1]]['Range'])
		var2.each do | v2 |
			if var.length >= 3
				var3 = list_values(param[var[2]]['Range'])
				var3.each do | v3 |
					if var.length >= 4
						var4 = list_values(param[var[3]]['Range'])
						var4.each do | v4 |
							if var.length >= 5
								var5 = list_values(param[var[4]]['Range'])
								var5.each do | v5 |
									if var.length >= 6
										var6 = list_values(param[var[5]]['Range'])
										var6.each do | v6 |
											if var.length >= 7
												var7 = list_values(param[var[6]]['Range'])
												var7.each do | v7 |
													if var.length >= 8
														var8 = list_values(param[var[7]]['Range'])
														var8.each do | v8 |
															scenario = create_scenario(param,var,[v1,v2,v3,v4,v5,v6,v7,v8],net)
															puts "Configured scenario #{scenario} with 8 variables"
															scenarios << scenario
														end
													else
														puts "Configuring scenarios for 7 variables"
														scenario = create_scenario(param,var,[v1,v2,v3,v4,v5,v6,v7],net)
														scenarios << scenario
													end
												end
											else
												puts "Configuring scenarios for 6 variables"
												scenario = create_scenario(param,var,[v1,v2,v3,v4,v5,v6],net)
												scenarios << scenario
											end
										end
									else
										puts "Configuring scenarios for 5 variables"
										scenario = create_scenario(param,var,[v1,v2,v3,v4,v5],net)
										scenarios << scenario
									end
								end
							else
								puts "Configuring scenarios for 4 variables"
								scenario = create_scenario(param,var,[v1,v2,v3,v4],net)
								scenarios << scenario
							end
						end
					else
						puts "Configuring scenarios for 3 variables"
						scenario = create_scenario(param,var,[v1,v2,v3],net)
						scenarios << scenario
					end
				end
			else
				puts "Configuring scenarios for 2 variables"
				scenario = create_scenario(param,var,[v1,v2],net)
				scenarios << scenario
			end
		end
	else
		puts "Configuring scenarios for 1 variable"
		scenario = create_scenario(param,var,[v1],net)
		scenarios << scenario
	end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0057- Bifurcation Nodes\hw_sw_Bifurcation Nodes.rb" 
# Below script selects all bifurcation nodes in a ICM model network
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

=begin
WSApplication.current_network
net.clear_selection

#Creating an array to store u/s node ID
us_node_arry= Array.new

#stores u/s node id into array called 'us_node_arry' from link object collection
links_oc=net.row_objects('_links')
links_oc.each do |a|
	us_node_arry << a.us_node_id
	end


#If a node is counted two or more number of times its identified as bifurcation node and its added to current selection
us_node_arry.each do |b|
	if us_node_arry.count(b)>1
		net.row_object('_nodes',b).selected=true
	end
end
=end

net = WSApplication.current_network
net.clear_selection

# Initialize a hash to store the count of occurrences for each u/s node ID
us_node_count = Hash.new(0)

# Count the occurrences of each u/s node ID in the links object collection
net.row_objects('_links').each do |link|
  us_node_count[link.us_node_id] += 1
end

# Select any nodes that have a count greater than 1 (bifurcation nodes)
us_node_count.each do |node_id, count|
  if count > 1
    net.row_object('_nodes', node_id).selected = true
	puts "Node #{node_id} has #{count} occurrences in links."
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0058 - Header Nodes\hw_sw_Header Nodes.rb" 
# the code is from https://github.com/chaitanyalakeshri/ruby_scripts
# modifed by CHATGPT

# Check if there is a network open in the WSApplication
if WSApplication.current_network.nil?
    puts "Error: There is no open network in the WSApplication."
    return
  end
  
  # Get the current network
  net = WSApplication.current_network
  net.clear_selection
  
  # Create an array to store node IDs
  node_ids = []
  
  # Validate if the nodes_oc is not empty
  nodes_oc = net.row_objects('_nodes')
  if nodes_oc.empty?
    puts "Error: _nodes object collection is empty."
    return
  end
  
  # Store node IDs into the array 'node_ids' from the nodes object collection
  nodes_oc.each do |node|
    node_ids << node.node_id
  end
  
  # Create an array to store downstream node IDs
  downstream_node_ids = []
  
  # Validate if the links_oc is not empty
  links_oc = net.row_objects('_links')
  if links_oc.empty?
    puts "Error: _links object collection is empty."
    return
  end
  
  # Store downstream node IDs into the array 'downstream_node_ids' from the links object collection
  links_oc.each do |link|
    downstream_node_ids << link.ds_node_id
  end
  
  # Loop through each node ID
  node_ids.each do |node_id|
    # If the node ID is not in the downstream node IDs array, select it
    if !downstream_node_ids.include?(node_id)
      net.row_object('_nodes', node_id).selected = true
      puts "Selected Node: #{node_id}"
    end
  end

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0059 - Dry Pipes\hw_dry pipes.rb" 
#Below script selects all dry pipes in a ICM model network
# the code is from https://github.com/chaitanyalakeshri/ruby_scripts
# modifed by CHATGPT and RED

net=WSApplication.current_network
net.clear_selection

#creating an array to store drainage node id of subcatchments
node_id=Array.new

subs_all=net.row_object_collection('_subcatchments')
subs_all.each do |a|
	node_id<<a.node_id
end
unprocessed_links=Array.new
node_id.each do |x|
	a=net.row_object('hw_node',x)
	a.ds_links.each do |l|
		unprocessed_links<<l	
	end
	while unprocessed_links.size>0
		working=unprocessed_links.shift
		working._seen=true
		working_ds_node=working.ds_node
		if !working_ds_node._seen && !working_ds_node.nil?
			working_ds_node._seen=true
			working_ds_node.ds_links.each do |b|
				unprocessed_links<<b
			end
		end
	end
end

all_links = net.row_object_collection('_links')
all_links.each do |d|
  if !d._seen
    d.selected = true
    d.us_node.selected = true
    puts "Selected Node: #{d.us_node.id}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0059 - Dry Pipes\sw_dry pipes.rb" 
#Below script selects all dry pipes in a ICM model network
# the code is from https://github.com/chaitanyalakeshri/ruby_scripts
# modifed by CHATGPT and RED

net=WSApplication.current_network
net.clear_selection

#creating an array to store drainage node id of subcatchments
node_id=Array.new

subs_all=net.row_object_collection('_subcatchments')
subs_all.each do |a|
	node_id<<a.outlet_id
end
unprocessed_links=Array.new
node_id.each do |x|
	a=net.row_object('sw_node',x)
	a.ds_links.each do |l|
		unprocessed_links<<l	
	end
	while unprocessed_links.size>0
		working=unprocessed_links.shift
		working._seen=true
		working_ds_node=working.ds_node
		if !working_ds_node._seen && !working_ds_node.nil?
			working_ds_node._seen=true
			working_ds_node.ds_links.each do |b|
				unprocessed_links<<b
			end
		end
	end
end

all_links = net.row_object_collection('_links')
all_links.each do |d|
  if !d._seen
    d.selected = true
    d.us_node.selected = true
    puts "Selected Node: #{d.us_node.id}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0060 - Compare ICM Headloss in Ruby Script\hw_UI_script.rb" 
require 'date'

NodeResultsDataFields = [
  'DEPNOD',
  'FloodDepth',
  'GLLYFLOW',
  'GTTRSPRD',
  'INLETEFF',
  'OVDEPNOD'
]

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Output the headers for the HEC22 comparison
header_fields = NodeResultsDataFields.map { |field| field.ljust(9) }.join(' ')
puts ";#{'Node_ID'.ljust(11)} #{'Time'.ljust(8)} #{header_fields} inlet_eff_value hec22_spread hec22_eff hec22_eff_diff ICM_NEW_T	ICM_OLD_T"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Get the row object for the current node using node id
    ro = net.row_object('_nodes', sel.id)
    
    # Skip the iteration if the row object is nil (not a node)
    next if ro.nil?

    # Initialize the counter for the timesteps
    count = 0

    # This loop should iterate through each timestep
    ts.each_with_index do |timestep, index|
      # Collect results for all specified fields
      all_field_results = NodeResultsDataFields.map do |field|
        field_results = ro.results(field)
        if field_results.empty?
          puts "Field '#{field}' does not exist for node ID #{sel.id}. Exiting script."
          exit
        elsif field_results.size == ts.size
          val = field_results[index].to_f # Get the value for the current timestep
          '%.4f' % val
        else
          'N/A' # Not available or mismatch in timestep count
        end
      end

      
      # Calculate the exact time for this result
      current_time = count * time_interval
       # Extract the DEPNOD value for the current index if it is one of the fields
       depnod_value = all_field_results[NodeResultsDataFields.index('FloodDepth')].nil? ? 0.0 : all_field_results[NodeResultsDataFields.index('DEPNOD')].to_f rescue 0.0
       depnode_value = depnod_value - 16.190
       inlet_eff_value = all_field_results[NodeResultsDataFields.index('INLETEFF')].nil? ? 0.0 : all_field_results[NodeResultsDataFields.index('INLETEFF')].to_f rescue 0.0
       inlet_flow_value = all_field_results[NodeResultsDataFields.index('GLLYFLOW')].nil? ? 0.0 : all_field_results[NodeResultsDataFields.index('GLLYFLOW')].to_f rescue 0.0      
   
      hec22_spread = 0.87*(inlet_flow_value**0.42)*0.0003802**0.3*(1.0/(0.013*0.02)**0.6)      #  =$P$10*(GLLYFLOW^0.42)*($P$8^0.3)*(1/(($P$9*$P$6)^0.6))    
      icm_spread = all_field_results[NodeResultsDataFields.index('GTTRSPRD')].to_f rescue 0.0

        # Check if depnod_value is greater than or equal to 0.0
        if depnod_value >= 0.0
          if depnod_value == 0.0
              # Handle the case where depnod_value is 0 to avoid division by zero
              # You can assign a default value or handle it as needed
              icm_spreadsheet = 0 # or some other appropriate handling
          else
              # Calculate icm_spreadsheet using the given formula
              icm_spreadsheet = 1.469 * ((inlet_flow_value ** 1.02) / (depnod_value ** 1.6))               # =$P$4*((B2^1.02)/(D2^1.6))
              icm_spread_old  = 1.469 * ((inlet_flow_value ** 1.02) / (depnod_value ** 1.6))*0.2 ** 0.6   # =$P$4*((B2^1.02)/(D2^1.6))*$P$6^0.6
          end
        else
          # Handle the case where depnod_value is negative if needed
          # For example, set icm_spreadsheet to nil or a specific error value
          icm_spreadsheet = nil # or some error handling
        end

        if hec22_spread > ro.opening_length
          hec22_eff = 1.0 - ( 1 - (ro.opening_length/hec22_spread)**1.8)    #   =IF(G2>$P$7,1-(1-($P$7/G2))^1.8,1)
        else
          hec22_eff = 1.0 # or appropriate handling for the case when hec22_spread is 0
          inlet_eff_value = 1.0
        end
      
      hec22_eff_diff = hec22_eff -  inlet_eff_value

      # Assuming current_time is in seconds
      days = current_time / (24 * 60 * 60) # Number of days
      remaining_seconds = current_time % (24 * 60 * 60)
      hours = remaining_seconds / (60 * 60) # Number of hours
      remaining_seconds %= (60 * 60) # Remaining seconds after hours
      minutes = remaining_seconds / 60 # Number of minutes
      seconds = remaining_seconds % 60 # Remaining seconds after minutes

      # Output the results for all fields on the same line
      puts "#{sel.id.ljust(10)} #{hours.to_i.to_s.rjust(2, '0')}:#{format('%02d', minutes)}:#{format('%02d', seconds)} " +
           "#{all_field_results.map { |result| result.ljust(10) }.join(' ')} #{'%10.4f' % inlet_eff_value} #{'%10.4f' % hec22_spread} #{'%10.4f' % hec22_eff} #{'%10.4f' % hec22_eff_diff} #{'%10.4f' % icm_spread_old} #{'%10.4f' % icm_spreadsheet}"
      count += 1 # Increment the counter after each iteration
    end
  rescue => e
    # Output error message if any error occurred during processing this node
    puts "Error processing node with ID #{sel.id}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0060 - Find All Network Elements\hw_UI_Script.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Define a method to process row objects
    def process_row_objects(net, type)
        hash_map = Hash.new { |h, k| h[k] = [] }
        row_objects = net.row_objects(type)
        raise "Error: #{type} not found" if row_objects.nil?
        row_objects.each do |obj|
            hash_map[obj.id] << obj.id
        end   
        printf "%-20s \n", "Name"
        hash_map.each do |name, id|
            printf "#{type.capitalize} %-20s \n", name
        end
    end

    # Process nodes, links, subcatchments, and pumps
    process_row_objects(net, '_nodes')
    process_row_objects(net, '_links')
    process_row_objects(net, '_subcatchments')
    process_row_objects(net, 'hw_weirs')
    process_row_objects(net, 'hw_orifices')
    process_row_objects(net, 'hw_pump')

rescue => e
    puts "Error: #{e.message}"
end

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0060 - Find All Network Elements\sw_UI_Script.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Define a method to process row objects
    def process_row_objects(net, type)
        hash_map = Hash.new { |h, k| h[k] = [] }
        row_objects = net.row_objects(type)
        raise "Error: #{type} not found" if row_objects.nil?
        row_objects.each do |obj|
            hash_map[obj.id] << obj.id
        end   
        printf "%-20s \n", "Name"
        hash_map.each do |name, id|
            printf "#{type.capitalize} %-20s \n", name
        end
    end

    # Process nodes, links, subcatchments, and pumps
    process_row_objects(net, '_nodes')
    process_row_objects(net, '_links')
    process_row_objects(net, '_subcatchments')
    process_row_objects(net, 'sw_pump')

rescue => e
    puts "Error: #{e.message}"
end

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0063 - ICM SWMM All Tables\ICM SWMM All Tables.rb" 
# Counts all of the tables in an ICM SWMM Network

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?

    table_names = [
        "sw_conduit",
        "sw_node",
        "sw_uh",
        "sw_uh_group",
        "sw_weir",
        "sw_pump",
        "sw_orifice",
        "sw_outlet",
        "sw_subcatchment",
        "sw_suds_control",
        "sw_aquifer",
        "sw_snow_pack",
        "sw_raingage",
        "sw_curve_control",
        # "sw_curve_diversion",  Ruby says "Error: no such table"
        "sw_curve_pump",
        "sw_curve_rating",
        "sw_curve_shape",
        "sw_curve_storage",
        "sw_curve_tidal",
        "sw_curve_weir",
        "sw_curve_underdrain",
        "sw_land_use",  
        "sw_pollutant",
        "sw_polygon",
        "sw_General_line",    
        "sw_spatial_rain_source",
        "sw_spatial_rain_zone",
        "sw_transect",
        "sw_tvd_connector",
        "sw_soil",
        "sw_2d_zone",
        "sw_mesh_zone",
        "sw_porous_polygon",
        "sw_porous_wall",
        "sw_roughness_zone",
        "sw_mesh_level_zone",
        "sw_roughness_definition",
        "sw_2d_boundary_line",
        "sw_head_unit_discharge"
      ]
      
      table_names.each do |table_name|
        hash_map = Hash.new { |h, k| h[k] = [] }
        table_rows = net.row_objects(table_name)
        raise "Error: #{table_name} not found" if table_rows.nil?
        number_of_rows = 0
        table_rows.each do |row|
          number_of_rows += 1
        end
        printf "%-50s %-d\n", "ICM SWMM Elements #{table_name}", number_of_rows
      end
        
rescue => e
    puts "Error: #{e.message}"
  end
   
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0064 - ICM SWMM Network Overview\ICM SWMM Network Overview.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 
begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?

    # Get all the nodes or links or subcatchments as row object collection

    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?
  
    subcatchments_roc = net.row_object_collection('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?

        # Get all the nodes or links or subcatchments as array in an ICM SwMM Network
        nodes_hash_map={}
        nodes_hash_map = Hash.new { |h, k| h[k] = [] }
        nodes_ro = net.row_objects('sw_node')
        raise "Error: nodes not found" if nodes_ro.nil?
        number_nodes = 0
        number_outfalls = 0
        number_storage = 0
        number_junction = 0
        number_inflow_baseline = 0
        number_inflow_scaling = 0
        number_base_flow = 0
        number_additional_dwf = 0
        total_invert = 0.0
        total_ground = 0.0
        total_depth = 0.0
        total_initial_depth = 0.0
        total_surcharge_depth = 0.0
        total_ponded_area = 0.0
        total_unit_hydrograph_area = 0.0
        total_flooding_discharge_coeff = 0.0
        
        nodes_ro.each do |node|

            # Check if the node has additional_dwf and it is not nil
              node.additional_dwf.each do |additional_dwf|
                # Increment the counter if baseline is greater than 0
                number_additional_dwf += 1 if additional_dwf.baseline && additional_dwf.baseline > 0
              end
          
            number_inflow_scaling += 1 if node.inflow_scaling > 0
            number_base_flow      += 1 if node.base_flow  > 0     
            number_inflow_baseline += 1 if node.inflow_baseline > 0
            number_nodes += 1
            if node.node_type == 'Outfall'
                number_outfalls += 1
            elsif node.node_type == 'Storage'
                number_storage += 1
            elsif node.node_type == 'Junction'
                number_junction += 1
            end
            total_invert += node.invert_elevation
            total_ground += node.ground_level
            total_depth += node.maximum_depth
            total_initial_depth += node.initial_depth unless node.initial_depth.nil?
            total_surcharge_depth += node.surcharge_depth unless node.surcharge_depth.nil?
            total_ponded_area += node.ponded_area unless node.ponded_area.nil?
            total_unit_hydrograph_area += node.unit_hydrograph_area unless node.unit_hydrograph_area.nil?
            total_flooding_discharge_coeff += node.flooding_discharge_coeff unless node.flooding_discharge_coeff.nil?
        end
        
        average_invert = total_invert / number_nodes
        average_ground = total_ground / number_nodes
        average_depth = total_depth / number_nodes
        average_initial_depth = total_initial_depth / number_nodes
        average_surcharge_depth = total_surcharge_depth / number_nodes
        average_ponded_area = total_ponded_area / number_nodes
        average_unit_hydrograph_area = total_unit_hydrograph_area / number_nodes
        average_flooding_discharge_coeff = total_flooding_discharge_coeff / number_nodes
        
        printf "%-40s %-d\n", "Number of SW Nodes", number_nodes
        printf "%-40s %-d\n", "Number of SW Junctions", number_junction
        printf "%-40s %-d\n", "Number of SW Storage", number_storage
        printf "%-40s %-d\n", "Number of SW Outfalls", number_outfalls
        printf "%-40s %-d\n", "Number of SW Inflow Baseline", number_inflow_baseline
        printf "%-40s %-d\n", "Number of SW Inflow Scaling", number_inflow_scaling
        printf "%-40s %-d\n", "Number of SW Base Flow", number_base_flow
        printf "%-40s %-d\n", "Number of SW Additional DWF", number_additional_dwf
        printf "%-40s %-.3f\n", "Average Invert Elevation", average_invert
        printf "%-40s %-.3f\n", "Average Ground Elevation", average_ground
        printf "%-40s %-.3f\n", "Average Full Depth", average_depth
        printf "%-40s %-.3f\n", "Average Initial Depth", average_initial_depth
        printf "%-40s %-.3f\n", "Average Surcharge Depth", average_surcharge_depth
        printf "%-40s %-.3f\n", "Average Ponded Area", average_ponded_area
        printf "%-40s %-.3f\n", "Average Unit Hydrograph Area", average_unit_hydrograph_area
        printf "%-40s %-.3f\n", "Average Flooding Discharge Coeff", average_flooding_discharge_coeff
        

        links_hash_map = {}
        links_hash_map = Hash.new { |h, k| h[k] = [] }
        links_ro = net.row_objects('sw_conduit')
        raise "Error: links not found" if links_ro.nil?
        number_links = 0
        number_length = 0.0
        total_conduit_height = 0.0
        total_conduit_width = 0.0
        total_manning_n = 0.0
        total_downstream_invert = 0.0
        total_upstream_invert = 0.0
        total_number_of_barrels = 0
        total_us_invert = 0.0
        total_ds_invert = 0.0
        total_us_headloss_coeff = 0.0
        total_ds_headloss_coeff = 0.0
        total_bottom_mannings_N = 0.0
        total_roughness_depth_threshold = 0.0
        total_initial_flow = 0.0
        total_max_flow = 0.0
        total_av_headloss_coeff = 0.0
        total_seepage_rate = 0.0
        total_flap_gate = 0
        total_culvert_code = 0
        
        links_ro.each do |link|
            number_links += 1
            number_length += link.length
            total_conduit_height += link.Conduit_height unless link.Conduit_height.nil?
            total_conduit_width += link.Conduit_width unless link.Conduit_width.nil?
            total_manning_n += link.Mannings_N unless link.Mannings_N.nil?
            total_downstream_invert += link.ds_invert unless link.ds_invert.nil?
            total_upstream_invert += link.us_invert unless link.us_invert.nil?
            total_number_of_barrels += link.number_of_barrels unless link.number_of_barrels.nil?
            total_us_invert += link.us_invert unless link.us_invert.nil?
            total_ds_invert += link.ds_invert unless link.ds_invert.nil?
            total_us_headloss_coeff += link.us_headloss_coeff unless link.us_headloss_coeff.nil?
            total_ds_headloss_coeff += link.ds_headloss_coeff unless link.ds_headloss_coeff.nil?
            total_bottom_mannings_N += link.bottom_mannings_N unless link.bottom_mannings_N.nil?
            total_roughness_depth_threshold += link.roughness_depth_threshold unless link.roughness_depth_threshold.nil?
            total_initial_flow += link.initial_flow unless link.initial_flow.nil?
            total_max_flow += link.max_flow unless link.max_flow.nil?
            total_av_headloss_coeff += link.av_headloss_coeff unless link.av_headloss_coeff.nil?
            total_seepage_rate += link.seepage_rate unless link.seepage_rate.nil?
            total_flap_gate ||= link.flap_gate
            total_culvert_code ||= link.culvert_code
        end
          
        average_conduit_height = total_conduit_height / number_links unless number_links == 0
        average_conduit_width = total_conduit_width / number_links unless number_links == 0
        average_manning_n = total_manning_n / number_links unless number_links == 0
        average_downstream_invert = total_downstream_invert / number_links unless number_links == 0
        average_upstream_invert = total_upstream_invert / number_links unless number_links == 0
        average_us_invert = total_us_invert / number_links unless number_links == 0
        average_ds_invert = total_ds_invert / number_links unless number_links == 0
        average_number_of_barrels = total_number_of_barrels / number_links unless number_links == 0
        average_us_headloss_coeff = total_us_headloss_coeff / number_links unless number_links == 0
        average_ds_headloss_coeff = total_ds_headloss_coeff / number_links unless number_links == 0
        average_bottom_mannings_N = total_bottom_mannings_N / number_links unless number_links == 0
        average_roughness_depth_threshold = total_roughness_depth_threshold / number_links unless number_links == 0
        average_initial_flow = total_initial_flow / number_links unless number_links == 0
        average_max_flow = total_max_flow / number_links unless number_links == 0
        average_av_headloss_coeff = total_av_headloss_coeff / number_links unless number_links == 0
        average_seepage_rate = total_seepage_rate / number_links unless number_links == 0
        average_flap_gate = total_flap_gate / number_links unless number_links == 0
        average_culvert_code = total_culvert_code / number_links unless number_links == 0

        
        printf "%-40s %-d\n", "Number of SW Links", number_links
        if number_links != 0
        printf "%-40s %-.3f\n", "Total SW Length", number_length
        printf "%-40s %-.3f\n", "Average Conduit Height", average_conduit_height
        printf "%-40s %-.3f\n", "Average Conduit Width", average_conduit_width
        printf "%-40s %-.3f\n", "Average Manning n", average_manning_n
        printf "%-40s %-.3f\n", "Average Downstream Invert", average_downstream_invert
        printf "%-40s %-.3f\n", "Average Upstream Invert", average_upstream_invert
        printf "%-40s %-.3f\n", "Average Number of Barrels", average_number_of_barrels
        printf "%-40s %-.3f\n", "Average US Invert", average_us_invert
        printf "%-40s %-.3f\n", "Average DS Invert", average_ds_invert
        printf "%-40s %-.3f\n", "Average US Headloss Coefficient", average_us_headloss_coeff
        printf "%-40s %-.3f\n", "Average DS Headloss Coefficient", average_ds_headloss_coeff
        printf "%-40s %-.3f\n", "Average Bottom Mannings N", average_bottom_mannings_N
        printf "%-40s %-.3f\n", "Average Roughness Depth Threshold", average_roughness_depth_threshold
        printf "%-40s %-.3f\n", "Average Initial Flow", average_initial_flow
        printf "%-40s %-.3f\n", "Average Max Flow", average_max_flow
        printf "%-40s %-.3f\n", "Average Average Headloss Coefficient", average_av_headloss_coeff
        printf "%-40s %-.3f\n", "Average Seepage Rate", average_seepage_rate
        printf "%-40s %-.3f\n", "Average Flap Gate", average_flap_gate
        printf "%-40s %-.3f\n", "Average Culvert Code", average_culvert_code
        end        
        
        subcatchments_hash_map = {}
        subcatchments_hash_map = Hash.new { |h, k| h[k] = [] }
        subcatchments_ro = net.row_objects('sw_subcatchment')
        raise "Error: subcatchments not found" if subcatchments_ro.nil?

        number_subcatchments = 0
        total_area = 0.0
        total_imperviousness = 0.0
        total_slope = 0.0
        total_width = 0.0
        total_initial_infiltration = 0.0
        total_limiting_infiltration = 0.0
        total_decay_factor = 0.0
        total_max_infiltration_volume = 0.0
        total_average_capillary_suction = 0.0
        total_saturated_hydraulic_conductivity = 0.0
        total_initial_moisture_deficit = 0.0
        total_curve_number = 0.0
        total_drying_time = 0.0
        total_time_of_concentration = 0.0
        total_hydraulic_length = 0.0
        total_shape_factor = 0.0
        total_initial_abstraction = 0.0
        
        subcatchments_ro.each do |subcatchment|
          number_subcatchments += 1
          total_area += subcatchment.area.to_f if subcatchment.area
          total_imperviousness += subcatchment.percent_impervious.to_f if subcatchment.percent_impervious
          total_slope += subcatchment.catchment_slope.to_f if subcatchment.catchment_slope
          total_width += subcatchment.width.to_f if subcatchment.width
          total_initial_infiltration += subcatchment.initial_infiltration.to_f if subcatchment.initial_infiltration
          total_limiting_infiltration += subcatchment.limiting_infiltration.to_f if subcatchment.limiting_infiltration
          total_decay_factor += subcatchment.decay_factor.to_f if subcatchment.decay_factor
          total_max_infiltration_volume += subcatchment.max_infiltration_volume.to_f if subcatchment.max_infiltration_volume
          total_average_capillary_suction += subcatchment.average_capillary_suction.to_f if subcatchment.average_capillary_suction
          total_saturated_hydraulic_conductivity += subcatchment.saturated_hydraulic_conductivity.to_f if subcatchment.saturated_hydraulic_conductivity
          total_initial_moisture_deficit += subcatchment.initial_moisture_deficit.to_f if subcatchment.initial_moisture_deficit
          total_curve_number += subcatchment.curve_number.to_f if subcatchment.curve_number
          total_drying_time += subcatchment.drying_time.to_f if subcatchment.drying_time
          total_time_of_concentration += subcatchment.time_of_concentration.to_f if subcatchment.time_of_concentration
          total_hydraulic_length += subcatchment.hydraulic_length.to_f if subcatchment.hydraulic_length
          total_shape_factor += subcatchment.shape_factor.to_f if subcatchment.shape_factor
          total_initial_abstraction += subcatchment.initial_abstraction.to_f if subcatchment.initial_abstraction
        end
        
        if number_subcatchments != 0
          average_imperviousness = total_imperviousness / number_subcatchments
          average_slope = total_slope / number_subcatchments
          average_width = total_width / number_subcatchments
          average_initial_infiltration = total_initial_infiltration / number_subcatchments
          average_limiting_infiltration = total_limiting_infiltration / number_subcatchments
          average_decay_factor = total_decay_factor / number_subcatchments
          average_max_infiltration_volume = total_max_infiltration_volume / number_subcatchments
          average_average_capillary_suction = total_average_capillary_suction / number_subcatchments
          average_saturated_hydraulic_conductivity = total_saturated_hydraulic_conductivity / number_subcatchments
          average_initial_moisture_deficit = total_initial_moisture_deficit / number_subcatchments
          average_curve_number = total_curve_number / number_subcatchments
          average_drying_time = total_drying_time / number_subcatchments
          average_time_of_concentration = total_time_of_concentration / number_subcatchments
          average_hydraulic_length = total_hydraulic_length / number_subcatchments
          average_shape_factor = total_shape_factor / number_subcatchments
          average_initial_abstraction = total_initial_abstraction / number_subcatchments
        else
          # handle the divide by zero error here
        end          
        
        printf "%-40s %-d\n", "Number of SW Subcatchments", number_subcatchments   
        if number_subcatchments != 0
            printf "%-40s %-.3f\n", "Total SW Subcatchment Area", total_area
            printf "%-40s %-.3f\n", "Average Imperviousness", average_imperviousness
            printf "%-40s %-.3f\n", "Average Subcatchment Slope", average_slope
            printf "%-40s %-.3f\n", "Average Subcatchment Width", average_width
            printf "%-40s %-.3f\n", "Average Capillary Suction", average_average_capillary_suction
            printf "%-40s %-.3f\n", "Saturated Hydraulic Conductivity", average_saturated_hydraulic_conductivity
            printf "%-40s %-.3f\n", "Initial Infiltration", average_initial_infiltration
            printf "%-40s %-.3f\n", "Limiting Infiltration", average_limiting_infiltration
            printf "%-40s %-.3f\n", "Decay Factor", average_decay_factor
            printf "%-40s %-.3f\n", "Max Infiltration Volume", average_max_infiltration_volume
            printf "%-40s %-.3f\n", "Initial Moisture Deficit", average_initial_moisture_deficit
            printf "%-40s %-.3f\n", "Curve Number", average_curve_number
            printf "%-40s %-.3f\n", "Drying Time", average_drying_time
            printf "%-40s %-.3f\n", "Average Time of Concentration", average_time_of_concentration
            printf "%-40s %-.3f\n", "Average Hydraulic Length", average_hydraulic_length
            printf "%-40s %-.3f\n", "Average Shape Factor", average_shape_factor
            printf "%-40s %-.3f\n", "Average Initial Abstraction", average_initial_abstraction      
        end
        
        pumps_hash_map = {}
        pumps_hash_map = Hash.new { |h, k| h[k] = [] }
        pumps_ro = net.row_objects('sw_pump')
        raise "Error: pump not found" if pumps_ro.nil?
        number_pumps = 0
        pumps_ro.each do |pump|
            number_pumps += 1
        end
        printf "%-40s %-d\n", "Number of Pumps", number_pumps
    
    weirs_hash_map = {}
    weirs_hash_map = Hash.new { |h, k| h[k] = [] }
    weirs_ro = net.row_objects('sw_weir')
    raise "Error: weirs not found" if weirs_ro.nil?
    number_weirs = 0
    weirs_ro.each do |weir|
        number_weirs += 1
    end
    printf "%-40s %-d\n", "Number of Weirs", number_weirs
    
    orifices_hash_map = {}
    orifices_hash_map = Hash.new { |h, k| h[k] = [] }
    orifices_ro = net.row_objects('sw_orifice')
    raise "Error: orifices not found" if orifices_ro.nil?
    number_orifices = 0
    orifices_ro.each do |orifice|
        number_orifices += 1
    end
    printf "%-40s %-d\n", "Number of Orifices", number_orifices
    
    channels_hash_map = {}
    channels_hash_map = Hash.new { |h, k| h[k] = [] }
    channels_ro = net.row_objects('sw_outlet')
    raise "Error: outletds not found" if channels_ro.nil?
    number_channels = 0
    channels_ro.each do |channel|
        number_channels += 1
    end
    printf "%-40s %-d\n", "Number of Outlets", number_channels

    printf "%-40s\n", "This was an overview of the elements in an ICM SWMM Network"

    rescue => e
        puts "Error: #{e.message}"
      end
      
    
     
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0065 - Get and Put Run Dialog Parameters\EX Run Parameters.rb" 
def retrieve_run_parameters(run_id)
    # Retrieve all the parameters in the specified run as a Hash
    database = WSApplication.open
    simulation = database.model_object_from_type_and_id('Run', run_id)
    parameters = {}
    database.list_read_write_run_fields.each do |field|
        parameters[field] = simulation[field]    
    end
    return parameters
end

run_id = # specify the run ID here
puts retrieve_run_parameters(run_id)
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0066 - ICM results against measured data within the UI\Sensor_Comparison.rb" 
# This is a simple script for reviewing ICM results against measured data within the UI.
# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits 

# Example script to compare model vs measured data
require 'date'

# Locate path with sensor data files
sensor_dir = WSApplication.folder_dialog 'Select a folder for sensor data files',  true 

# Define Sensor to Model Mapping for all desired locations:
locations=Hash.new
locations['50135.1'] = {"sensor_file"=>'sensor_1.txt',"output"=>'us_flow',"symbol"=>'Cross', "Color"=>WSApplication.colour(0,0,255)}
locations['50009.1'] = {"sensor_file"=>'sensor_2.txt',"output"=>'us_flow',"symbol"=>'Circle',"Color"=>WSApplication.colour(0,255,0)}
locations['72332.1'] = {"sensor_file"=>'sensor_3.txt',"output"=>'us_flow',"symbol"=>'Square',"Color"=>WSApplication.colour(255,0,0)}
locations['72346.1'] = {"sensor_file"=>'sensor_4.txt',"output"=>'us_flow',"symbol"=>'Star',  "Color"=>WSApplication.colour(0,0,0)}

# Prep common graph settings
graph_window=Hash.new
graph_window['YAxisLabel']='Flow rate (ft3/s)'
graph_window['IsTime']=true
icm_color=WSApplication.colour(0,0,255)
sensor_color=WSApplication.colour(255,0,0)

# Initialize ICM Network and results
net=WSApplication.current_network
n = net.timestep_count

# Loop through each defined location
scatter_trace=Array.new
locations.each do | location, options |
# Fetch Sensor Data from file	
	sensor_data = IO.readlines(sensor_dir+'\\'+options['sensor_file'])
	sensor = sensor_data.slice(0,n) # ensure arrays are the same size

# Read ICM results data and compare against measured values
	pipe=net.row_object('hw_conduit',location)
	results=pipe.results('us_flow')
	squared_difference = 0.0
	results.each_index {|t| squared_difference += (results[t]-sensor[t].to_f)**2}
	#puts "Location #{} has Variance of: #{squared_difference/n}"

# Build Graph Arrays	
	traces=Array.new
	traces << {'Title'=>location,'TraceColour'=>icm_color,'LineType'=>'Solid','Marker'=>"None", "XArray"=>net.list_timesteps,"YArray"=>results}
	traces << {'Title'=>options['sensor_file'],'TraceColour'=>sensor_color,'LineType'=>'Solid','Marker'=>"None", "XArray"=>net.list_timesteps,"YArray"=>sensor}
	scatter_trace << {'Title'=>location,'LineType'=>'None','Marker'=>options['symbol'],'SymbolColour'=>options['Color'],"XArray"=>sensor,"YArray"=>results}

# Generate Line Graph of Sensor vs ICM results
	graph_window['WindowTitle']=location
	graph_window['GraphTitle']=location+' Variance = '+(squared_difference/n).to_s
	graph_window['Traces']=traces
	WSApplication.graph graph_window
end

# Generate Scatter graph with all locations
graph_window['WindowTitle']='Scatter Comparison of all locations'
graph_window['GraphTitle']=''
graph_window['Traces']=scatter_trace
graph_window['IsTime']=false
graph_window['YAxisLabel']='Flow rate (ft3/s)'
graph_window['XAxisLabel']='Flow rate (ft3/s)'
WSApplication.graph graph_window 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0067 - ICM Ruby Tutorials\ICM Ruby Tutorials.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection
    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?
  
    subcatchments_roc = net.row_object_collection('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_roc = net.row_object_collection('hw_pump')
    raise "Error: pump not found" if pump_roc.nil?
  
    # Get all the nodes or links or subcatchments as array
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
  
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
  
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pump_ro.nil?
  
    # accessing an individual row object
    ro = net.row_object('hw_conduit', '1234567.1')
    raise "Error: row object not found" if ro.nil?
  
    # Getting value of particular field from a specific row object
    ro = net.row_object('hw_conduit', '1234567.1').length
    raise "Error: length not found" if ro.nil?
  
    # selecting a particular object
    ro = net.row_object('hw_conduit', '1234567.1').selected = true
  
    # clear selection
    net.clear_selection
  
  rescue => e
    puts "Error: #{e.message}"
  end
   
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0068 - ICM InfoWorks All Table Names\ICM InfoWorks All Table Names.rb" 
# Counts all of the tables in an ICM InfoWorks Network

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?

    tables = [
        "hw_node",
        "hw_conduit",
        "hw_subcatchment",
        "hw_orifice",
        "hw_channel",
        "hw_river_reach",
        "hw_pump",
        "hw_screen",
        "hw_siphon",
        "hw_sluice",
        "hw_irregular_weir",
        "hw_user_control",
        "hw_weir",
        "hw_culvert_inlet",
        "hw_culvert_outlet",
        "hw_flap_valve",
        "hw_bridge",
        "hw_bridge_opening",
        "hw_bridge_blockage",
        "hw_bridge_inlet",
        "hw_bridge_outlet",
        "hw_flume",
        "hw_blockage",
        "hw_mesh_zone",
        "hw_mesh_level_zone",
        "hw_inline_bank",  
        "hw_roughness_zone",
        "hw_storage_area",    
        "hw_building",
        "hw_2d_boundary_line",
        "hw_2d_ic_polygon",
        "hw_2d_wq_ic_polygon",
        "hw_2d_inf_ic_polygon",
        "hw_2d_sed_ic_polygon",
        "hw_2d_infiltration_zone",
        "hw_2d_infil_surface",
        "hw_2d_turbulence_zone",
        "hw_2d_turbulence_model",
        "hw_2d_permeable_zone",
        "hw_2d_point_source",
        "hw_2d_zone",
        "hw_damage_receptor",
        "hw_General_line",
        "hw_General_point",
        "hw_polygon",
        "hw_risk_impact_zone",   
        "hw_porous_polygon",
        "hw_porous_wall",
        "hw_2d_linear_structure",
        "hw_2d_sluice",
        "hw_2d_bridge",
        "hw_2d_line_source",
        "hw_tvd_connector",
        "hw_spatial_rain_source",
        "hw_spatial_rain_zone",
        "hw_ground_infiltration",
        "hw_headloss",
        "hw_suds_control",
        "hw_head_discharge",
        "hw_pdm_descriptor",
        "hw_head_unit_discharge",
        "hw_flow_efficiency",
        "hw_land_use",
        "hw_swmm_land_use",
        "hw_channel_shape",
        "hw_runoff_surface",
        "hw_shape",
        "hw_sediment_grading",
        "hw_sim_parameters",
        "hw_snow_pack",
        "hw_unit_hydrograph",
        "hw_unit_hydrograph_month",
        "hw_wq_params",
        "hw_conduit_defaults",
        "hw_manhole_defaults",
        "hw_channel_defaults",
        "hw_river_reach_defaults",
        "hw_subcatchment_defaults",
        "hw_large_catchment_parameters",
        "hw_2d_zone_defaults",
        "hw_snow_parameters",
        "hw_cross_section_survey",
        "hw_bank_survey",
        "hw_prunes",
        "hw_arma",
        "hw_roughness_definition"
  ]
  
  nodes_hash_map = Hash.new { |h, k| h[k] = [] }
  
  tables.each do |table|
    nodes_ro = net.row_objects(table)
    raise "Error: #{table} not found" if nodes_ro.nil?
    number_nodes = 0
    nodes_ro.each do |node|
      number_nodes += 1
    end
    printf "%-50s %-d\n", "Number of #{table.upcase}", number_nodes
  end
  
rescue => e
    puts "Error: #{e.message}"
  end
   
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0069 - Make an Overview of All Network Elements\Make an Overview of All Network Elements.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 
begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection for InfoWorks Network

    nodes_roc = net.row_object_collection('hw_node')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('hw_conduit')
    raise "Error: links not found" if links_roc.nil?
  
    subcatchments_roc = net.row_object_collection('hw_subcatchment')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_roc = net.row_object_collection('hw_pump')
    raise "Error: pump not found" if pump_roc.nil?
  
    # Get all the nodes or links or subcatchments as array in an InfoWorks Network
    nodes_hash_map={}
    nodes_hash_map = Hash.new { |h, k| h[k] = [] }
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
    number_nodes = 0
    nodes_ro.each do |node|
        number_nodes += 1
    end       
    printf "%-30s %-d\n", "Number of HW Nodes...", number_nodes

    links_hash_map = {}
    links_hash_map = Hash.new { |h, k| h[k] = [] }
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    number_links = 0
    links_ro.each do |link|
        number_links += 1
    end          
    printf "%-30s %-d\n", "Number of HW Links...", number_links

    subcatchments_hash_map = {}
    subcatchments_hash_map = Hash.new { |h, k| h[k] = [] }
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
    number_subcatchments = 0
    subcatchments_ro.each do |subcatchment|
        number_subcatchments += 1
    end
    printf "%-30s %-d\n", "Number of HW Subcatchments.", number_subcatchments
   
    pumps_hash_map = {}
    pumps_hash_map = Hash.new { |h, k| h[k] = [] }
    pumps_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pumps_ro.nil?
    number_pumps = 0
    pumps_ro.each do |pump|
        number_pumps += 1
    end
    printf "%-30s %-d\n", "Number of Pumps...", number_pumps

weirs_hash_map = {}
weirs_hash_map = Hash.new { |h, k| h[k] = [] }
weirs_ro = net.row_objects('hw_weir')
raise "Error: weirs not found" if weirs_ro.nil?
number_weirs = 0
weirs_ro.each do |weir|
    number_weirs += 1
end
printf "%-30s %-d\n", "Number of Weirs...", number_weirs

orifices_hash_map = {}
orifices_hash_map = Hash.new { |h, k| h[k] = [] }
orifices_ro = net.row_objects('hw_orifice')
raise "Error: orifices not found" if orifices_ro.nil?
number_orifices = 0
orifices_ro.each do |orifice|
    number_orifices += 1
end
printf "%-30s %-d\n", "Number of Orifices...", number_orifices

channels_hash_map = {}
channels_hash_map = Hash.new { |h, k| h[k] = [] }
channels_ro = net.row_objects('hw_channel')
raise "Error: channels not found" if channels_ro.nil?
number_channels = 0
channels_ro.each do |channel|
    number_channels += 1
end
printf "%-30s %-d\n", "Number of Channels...", number_channels

river_reaches_hash_map = {}
river_reaches_hash_map = Hash.new { |h, k| h[k] = [] }
river_reaches_ro = net.row_objects('hw_river_reach')
raise "Error: river reaches not found" if river_reaches_ro.nil?
number_river_reaches = 0
river_reaches_ro.each do |river_reach|
    number_river_reaches += 1
end
printf "%-30s %-d\n", "Number of River Reaches...", number_river_reaches

hw_storage_areas_hash_map = {}
hw_storage_areas_hash_map = Hash.new { |h, k| h[k] = [] }
hw_storage_areas_ro = net.row_objects('hw_storage_area')
raise "Error: hw storage areas not found" if hw_storage_areas_ro.nil?
number_hw_storage_areas = 0
hw_storage_areas_ro.each do |hw_storage_area|
    number_hw_storage_areas += 1
end
printf "%-30s %-d\n", "Number of HW Storage Areas...", number_hw_storage_areas

hw_culvert_inlets_hash_map = {}
hw_culvert_inlets_hash_map = Hash.new { |h, k| h[k] = [] }
hw_culvert_inlets_ro = net.row_objects('hw_culvert_inlet')
raise "Error: hw culvert inlets not found" if hw_culvert_inlets_ro.nil?
number_hw_culvert_inlets = 0
hw_culvert_inlets_ro.each do |hw_culvert_inlet|
    number_hw_culvert_inlets += 1
end
printf "%-30s %-d\n", "Number of HW Culvert Inlets...", number_hw_culvert_inlets

hw_culvert_outlets_hash_map = {}
hw_culvert_outlets_hash_map = Hash.new { |h, k| h[k] = [] }
hw_culvert_outlets_ro = net.row_objects('hw_culvert_outlet')
raise "Error: hw culvert outlets not found" if hw_culvert_outlets_ro.nil?
number_hw_culvert_outlets = 0
hw_culvert_outlets_ro.each do |hw_culvert_outlet|
number_hw_culvert_outlets += 1
end
printf "%-30s %-d\n", "Number of HW Culvert Outlets..", number_hw_culvert_outlets

hw_flap_valves_hash_map = {}
hw_flap_valves_hash_map = Hash.new { |h, k| h[k] = [] }
hw_flap_valves_ro = net.row_objects('hw_flap_valve')
raise "Error: hw flap valves not found" if hw_flap_valves_ro.nil?
number_hw_flap_valves = 0
hw_flap_valves_ro.each do |hw_flap_valve|
number_hw_flap_valves += 1
end
printf "%-30s %-d\n", "Number of HW Flap Valves...", number_hw_flap_valves

hw_bridges_hash_map = {}
hw_bridges_hash_map = Hash.new { |h, k| h[k] = [] }
hw_bridges_ro = net.row_objects('hw_bridge')
raise "Error: hw bridges not found" if hw_bridges_ro.nil?
number_hw_bridges = 0
hw_bridges_ro.each do |hw_bridge|
number_hw_bridges += 1
end
printf "%-30s %-d\n", "Number of HW Bridges...", number_hw_bridges

hw_flumes_hash_map = {}
hw_flumes_hash_map = Hash.new { |h, k| h[k] = [] }
hw_flumes_ro = net.row_objects('hw_flume')
raise "Error: hw flumes not found" if hw_flumes_ro.nil?
number_hw_flumes = 0
hw_flumes_ro.each do |hw_flume|
number_hw_flumes += 1
end
printf "%-30s %-d\n", "Number of HW Flumes...", number_hw_flumes

hw_polygons_hash_map = {}
hw_polygons_hash_map = Hash.new { |h, k| h[k] = [] }
hw_polygons_ro = net.row_objects('hw_polygon')
raise "Error: hw polygons not found" if hw_polygons_ro.nil?
number_hw_polygons = 0
hw_polygons_ro.each do |hw_polygon|
number_hw_polygons += 1
end
printf "%-30s %-d\n","Number of Polygons...  ", number_hw_polygons

rescue => e
    puts "Error: #{e.message}"
  end
  

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0070 - Upstream Subcatchments from an Outfall\hw_Upstream Subcatchments from an Outfall.rb" 
# Select Upstream Subcatchments from a Node with Multilinks
# net variable is assigned the current network of the WSApplication
# the hash code is from https://github.com/chaitanyalakeshri/ruby_scripts and 
# the tree walking code is from Unit 5 from https://github.com/innovyze/Open-Source-Support/tree/main/01%20InfoWorks%20ICM/01%20Ruby
net = WSApplication.current_network

# Get all subcatchments from the network and assign them to the variable all_subs
all_subs=net.row_objects('_subcatchments')

# Create an empty hash variable named node_sub_hash_map
node_sub_hash_map={}

# Get all nodes from the network and assign them to the variable all_nodes
all_nodes=net.row_objects('_nodes')

# Assign node ID's as hash keys in the node_sub_hash_map
all_nodes.each do |h|
	node_sub_hash_map[h.node_id]=[]
end

# Get all subcatchments again and assign them to the variable all_subs
all_subs=net.row_objects('_subcatchments')

# Pair subcatchments to appropriate hash keys (i.e. node id's) in the node_sub_hash_map
node_sub_hash_map = Hash.new { |h, k| h[k] = [] }
all_subs.each do |subb|
  node_sub_hash_map[subb.node_id] << subb
end

# Get all the selected rows in the _nodes collection and assign them to the variable roc
roc = net.row_object_collection_selection('_nodes')

# Create an empty array named unprocessedLinks
unprocessedLinks = Array.new

# Initialize a counter variable for the total number of subcatchments and a variable for the total are
total_subcatchments = 0
total_area = 0.0

roc.each do |ro|
	# Iterate through all the upstream links of the current row object
	ro.us_links.each do |l|
		# if the link has not been seen before, add it to the unprocessedLinks array
		if !l._seen
			unprocessedLinks << l
			l._seen=true
		end
	end
	# While there are still unprocessed links in the array
	while unprocessedLinks.size>0
		# take the first link in the array and assign it to the variable working
		working = unprocessedLinks.shift
		working.selected=true
		# get the upstream node of the current link
		workingUSNode = working.us_node
		# if the upstream node is not nil and has not been seen before
		if !workingUSNode.nil? && !workingUSNode._seen
			workingUSNode.selected=true
			# Now that hash is ready with node id's as key and upstream subcatchments as paired values, keys can be used to get an array containing upstream subcathments
			# In the below code id's of subcatchments upstream of node 'node_1' are printed. The below code can be reused multiple times for different nodes within the script without being computationally expensive
			node_sub_hash_map[workingUSNode.id].each  do |sub|
				# puts "Found Upstream Subcatchment #{sub.id} connected to Node #{workingUSNode.id}"
				total_area += sub.total_area
				total_subcatchments += 1
				sub.selected=true
			end
			# Iterate through all the upstream links of the current node and add them to the unprocessedLinks array
			workingUSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					l.selected=true
					l._seen=true
				end
			end
		end
	end
end

# Print the total number of subcatchments and the total area
puts "Total number of found Subcatchments: #{total_subcatchments}"
puts "Total area of found Subcatchments:   #{total_area.round(4)}"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0070 - Upstream Subcatchments from an Outfall\sw_Upstream Subcatchments from an Outfall.rb" 
# Select Upstream Subcatchments from a Node with Multilinks
# net variable is assigned the current network of the WSApplication
# the hash code is from https://github.com/chaitanyalakeshri/ruby_scripts and 
# the tree walking code is from Unit 5 from https://github.com/innovyze/Open-Source-Support/tree/main/01%20InfoWorks%20ICM/01%20Ruby
net = WSApplication.current_network

# Get all subcatchments from the network and assign them to the variable all_subs
all_subs=net.row_objects('_subcatchments')

# Create an empty hash variable named node_sub_hash_map
node_sub_hash_map={}

# Get all nodes from the network and assign them to the variable all_nodes
all_nodes=net.row_objects('_nodes')

# Assign node ID's as hash keys in the node_sub_hash_map
all_nodes.each do |h|
	node_sub_hash_map[h.node_id]=[]
end

# Get all subcatchments again and assign them to the variable all_subs
all_subs=net.row_objects('_subcatchments')

# Pair subcatchments to appropriate hash keys (i.e. node id's) in the node_sub_hash_map
node_sub_hash_map = Hash.new { |h, k| h[k] = [] }
all_subs.each do |subb|
  node_sub_hash_map[subb.outlet_id] << subb
end

# Get all the selected rows in the _nodes collection and assign them to the variable roc
roc = net.row_object_collection_selection('_nodes')

# Create an empty array named unprocessedLinks
unprocessedLinks = Array.new

# Initialize a counter variable for the total number of subcatchments and a variable for the total are
total_subcatchments = 0
total_area = 0.0

roc.each do |ro|
	# Iterate through all the upstream links of the current row object
	ro.us_links.each do |l|
		# if the link has not been seen before, add it to the unprocessedLinks array
		if !l._seen
			unprocessedLinks << l
			l._seen=true
		end
	end
	# While there are still unprocessed links in the array
	while unprocessedLinks.size>0
		# take the first link in the array and assign it to the variable working
		working = unprocessedLinks.shift
		working.selected=true
		# get the upstream node of the current link
		workingUSNode = working.us_node
		# if the upstream node is not nil and has not been seen before
		if !workingUSNode.nil? && !workingUSNode._seen
			workingUSNode.selected=true
			# Now that hash is ready with node id's as key and upstream subcatchments as paired values, keys can be used to get an array containing upstream subcathments
			# In the below code id's of subcatchments upstream of node 'node_1' are printed. The below code can be reused multiple times for different nodes within the script without being computationally expensive
			node_sub_hash_map[workingUSNode.id].each  do |sub|
				# puts "Found Upstream Subcatchment #{sub.id} connected to Node #{workingUSNode.id}"
				total_area += sub.area
				total_subcatchments += 1
				sub.selected=true
			end
			# Iterate through all the upstream links of the current node and add them to the unprocessedLinks array
			workingUSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					l.selected=true
					l._seen=true
				end
			end
		end
	end
end

# Print the total number of subcatchments and the total area
puts "Total number of found Subcatchments: #{total_subcatchments}"
puts "Total area of found Subcatchments:   #{total_area.round(4)}"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0071 - Raingages, All Output Parameters\sw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps and gauge timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected rain gages
result_field_names = [ 'RAINDPTH', 'RAINFALL' ]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current gage
    ro = net.row_object('sw_raingage', sel.raingage_id) 
    
    # If ro is nil, then the object with the given id is not a gage
    raise "Object with ID #{sel.raingage_id} is not a gage" if ro.nil?

    # Iterate through each result field name
    result_field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        # Check if the count of results matches the count of timesteps
        if rs_size == ts_size

          # Initialize variables to keep track of statistics
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0
          
          # Assuming the time steps are evenly spaced, calculate the time interval in seconds
          time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1
          
          # Iterate through the results and calculate statistics
          ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            
            total_integrated_over_time += result.to_f * time_interval
        
            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          # Calculate the mean value if the count is greater than 0
          mean_value = count > 0 ? total / count : 0

          # Adjust total_integrated_over_time calculation
          # Assuming total_integrated_over_time is calculated earlier in the script
          total_integrated_over_time /= 3600.0

          # Modify total_integrated_over_time if result_field_name is 'RAINDPTH'
          if res_field_name == 'RAINDPTH'
            total_integrated_over_time = max_value * 1000.0
          end                   
          
          # Print the total, total integrated over time, mean, max, min values, and count
          puts "Gage: #{'%-16s' % sel.raingage_id} | Field: #{'%-12s' % res_field_name} | Sum: #{'%15.4f' % total_integrated_over_time} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
        end

      rescue
        # This will handle the error when the field does not exist
        #puts "Error: Field '#{res_field_name}' does not exist for node with ID #{sel.node_id}."
        next
      end
    end

      rescue => e
        # Output error message if any error occurred during processing this object
        #puts "Error processing node with ID #{sel.node_id}. Error: #{e.message}"
      end
    end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0072 - Find Root Model Group\UI_script.rb" 
# Access the current database and network, and then obtain the current model object
db = WSApplication.current_database
my_network = WSApplication.current_network
my_object = my_network.model_object

# Get the parent ID and type of the current object
p_id = my_object.parent_id
p_type = my_object.parent_type

# Retrieve the parent object from the database
parent_object = db.model_object_from_type_and_id(p_type, p_id)

# Loop through the hierarchy of parent objects
(0..999).each do
  # Print the name of the current parent object
  puts "Parent Object: #{parent_object.name}"

  # Get the parent ID and type of the current parent object
  temp_p_id = parent_object.parent_id
  temp_p_type = parent_object.parent_type

  # Break the loop if the parent ID is 0, indicating the top of the hierarchy
  break if temp_p_id == 0

  # Retrieve the next parent object in the hierarchy
  parent_object = db.model_object_from_type_and_id(temp_p_type, temp_p_id)
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0073 - Rename Exported Image & Attachment Files\Callback.rb" 
class Exporter
	def Exporter.Filename(obj)
		if !obj['attachments.filename'].nil?
			name=obj['id']+'_'+obj['attachments.filename']
			return name.gsub(/[^0-9A-Za-z _-]/, '')
		elsif !obj['attachments.purpose'].nil?
			name=obj['id']+'_'+obj['attachments.purpose']
			return name.gsub(/[^0-9A-Za-z _-]/, '')
		else
			name2=obj['id']
			return name2.gsub(/[^0-9A-Za-z _-]/, '')
		end
	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0073 - Rename Exported Image & Attachment Files\UI-FileRename_v4.rb" 
require 'csv'

val=WSApplication.prompt "Rename Files",
[
['FOLDER containing files to be renamed:','String',nil,nil,'FOLDER','Files folder'],
['CSV filename mapping file:','String',nil,nil,'FILE',true,'csv','CSV mapping file',false],
['CURRENT filename column header:','String'],
['NEW filename column header:','String'],
],false
if val==nil
	WSApplication.message_box("Parameters dialog closed\nScript cancelled",'OK','!',nil)
else
puts "[Files Folder, CSV Mappings file, CURRENT filename column, NEW filename column]\n"+val.to_s

exportloc=val[0].to_s
exportfile=val[1].to_s
image=val[2].downcase.to_s
name=val[3].downcase.to_s

if val[0]==nil
	WSApplication.message_box("Files folder required\nScript cancelled",'OK','!',nil)
elsif val[1]==nil
	WSApplication.message_box("Mapping file required\nScript cancelled",'OK','!',nil)
elsif val[2]==nil || val[3]==nil
	WSApplication.message_box("Column mappings incomplete\nScript cancelled",'OK','!',nil)
else


files = Dir.foreach(exportloc).select { |x| File.file?("#{exportloc}/#{x}") }
found=[]
files.each do |a|
	b=File.basename(a, ".*")
	found << b
end


converter = lambda { |header| header.downcase }
CSV.foreach(exportfile, :headers=>true, header_converters: converter) do |row|
rn=$.
    if (row[image].length)
        fileFrom = File.join(exportloc, row[image])
        fileTo = File.join(exportloc, row[name] + File.extname(fileFrom))
		fileTo2 = File.join(exportloc, row[name] + '_' + rn.to_s + File.extname(fileFrom))
        
		filenew = row[name]
		filenew2 = row[name] + '_' + rn.to_s
		
		if !found.include? filenew
			File.rename(fileFrom, fileTo)
			found << filenew
			puts 'File "'+row[image]+'" renamed "'+filenew+'"'
			
		elsif !found.include? filenew2
			File.rename(fileFrom, fileTo2)
			found << filenew2
			puts 'File "'+row[image]+'" renamed "'+filenew2+'"'
		
		else
		puts 'File "'+row[image]+'" not renamed, possible duplicate of "'+row[name]+'"'
		end
    end
end

end

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0074 - Capacity Assurance White Paper\UI-CapacityAssuranceCalculation.rb" 
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

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0075 - Sandbox Instance Evaluation and Class Scope\Sandbox.rb" 
# Source of this code is https://github.com/sancarn/Innovyze-ICM-Libraries/blob/master/libraries/InfoWorks-ICM/Ruby/Randoms/SandboxingExample.rb

class Monk
  # Monk class (currently empty)
end

class Sandbox
  # Sandbox class (currently empty)
end

# Creating a new instance of Sandbox
box = Sandbox.new

# Adding methods to the instance 'box' using instance_eval
box.instance_eval do
  # Define a method 'amazing'
  def amazing
    "amazing"
  end

  # Output combining 'amazing' method and string
  p amazing + " stuff"

  # Define another method 'number'
  def number
    42
  end

  # Output combining 'amazing' method and 'number' method
  p amazing + " " + number.to_s
end

# Trying to access the 'amazing' method outside of its context
begin
  p amazing
rescue
  p "We couldn't evaluate 'amazing' from outside the instance context!"
end

# Accessing 'amazing' method from within its instance context
p "Accessing 'amazing' from inside the instance: " + box.instance_eval('amazing')

# Creating a new Sandbox instance
new_box = Sandbox.new

# Trying to access the 'amazing' method in a new instance where it's not defined
begin
  p new_box.instance_eval('Sandox says amazing')
rescue
  p "We couldn't evaluate 'amazing' in a new Sandbox instance!"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0076 - InfoWorks vs SWMM CSV Comparison\compare_icm_swmm_icm_files.rb" 
# ICM SWMM vs ICM files 
#  This function reads CSV files from ICM SWMM and ICM and compares them.
#  The CSV files are generated from the ICM SWMM and ICM models using the
#  "Export Results to CSV" function in the ICM SWMM and ICM models.
#  The CSV files are compared by comparing the values in the "Value" column.
#  The CSV files are assumed to have the same number of rows and the same
#  column headers.

require 'csv'

def compare_icm_swmm_icm_files(icm_swmm_csv_file, icm_csv_file)
  # The CSV files are assumed to have the same number of rows and the same
  # column headers.
  icm_swmm_csv = CSV.read(icm_swmm_csv_file)
  icm_csv = CSV.read(icm_csv_file)
  # The CSV files are assumed to have the same number of rows and the same
  # column headers.
  icm_swmm_csv.each_with_index do |icm_swmm_row, index|
    icm_row = icm_csv[index]
    # Compare the values in the "Value" column.
    if icm_swmm_row[1] != icm_row[1]
      return false
    end
  end
  return true
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0077 - ICM InfoWorks UX Tables\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in minutes assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs 
puts time_interval  

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name for downstream depth
res_field_name = 'ds_depth'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Find the maximum value and its index
      max_value = results.first.to_f
      max_index = 0

      results.each_with_index do |result, index|
        val = result.to_f
        if val > max_value
          max_value = val
          max_index = index
        end
      end

      # Get the time of maximum depth
      max_time = ts[max_index]

        # Calculate total seconds from the given time
        total_seconds = max_index * time_interval

        # Assuming total_seconds is calculated correctly as an integer value
        days = total_seconds / (24 * 3600)           # Calculates the number of days
        remaining_seconds = total_seconds % (24 * 3600)  # Remaining seconds after extracting days
        hours = remaining_seconds / 3600             # Calculates the number of hours
        remaining_seconds %= 3600                    # Remaining seconds after extracting hours
        minutes = remaining_seconds / 60             # Calculates the number of minutes
        seconds = remaining_seconds % 60             # Remaining seconds after extracting minutes

        # Format the time into a readable string with integer values
        formatted_time = "#{days}d #{hours}h #{minutes}m #{seconds}s"

        # Print the information with formatted maximum time
        puts "Link ID: #{sel.id}             Max DS Depth: #{'%9.3f' % max_value} at Time: #{formatted_time}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0078 - ICM SWMM UX Tables\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in minutes assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs 
puts time_interval  

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name for downstream depth
res_field_name = 'ds_depth'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Find the maximum value and its index
      max_value = results.first.to_f
      max_index = 0

      results.each_with_index do |result, index|
        val = result.to_f
        if val > max_value
          max_value = val
          max_index = index
        end
      end

      # Get the time of maximum depth
      max_time = ts[max_index]

        # Calculate total seconds from the given time
        total_seconds = max_index * time_interval

        # Assuming total_seconds is calculated correctly as an integer value
        days = total_seconds / (24 * 3600)           # Calculates the number of days
        remaining_seconds = total_seconds % (24 * 3600)  # Remaining seconds after extracting days
        hours = remaining_seconds / 3600             # Calculates the number of hours
        remaining_seconds %= 3600                    # Remaining seconds after extracting hours
        minutes = remaining_seconds / 60             # Calculates the number of minutes
        seconds = remaining_seconds % 60             # Remaining seconds after extracting minutes

        # Format the time into a readable string with integer values
        formatted_time = "#{days}d #{hours}h #{minutes}m #{seconds}s"

        # Print the information with formatted maximum time
        puts "Link ID: #{sel.id}             Max DS Depth: #{'%9.3f' % max_value} at Time: #{formatted_time}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0079 - ICM SWMM IWR Tables\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in minutes assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs 
puts time_interval  

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name for downstream depth
res_field_name = 'ds_depth'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Find the maximum value and its index
      max_value = results.first.to_f
      max_index = 0

      results.each_with_index do |result, index|
        val = result.to_f
        if val > max_value
          max_value = val
          max_index = index
        end
      end

      # Get the time of maximum depth
      max_time = ts[max_index]

        # Calculate total seconds from the given time
        total_seconds = max_index * time_interval

        # Assuming total_seconds is calculated correctly as an integer value
        days = total_seconds / (24 * 3600)           # Calculates the number of days
        remaining_seconds = total_seconds % (24 * 3600)  # Remaining seconds after extracting days
        hours = remaining_seconds / 3600             # Calculates the number of hours
        remaining_seconds %= 3600                    # Remaining seconds after extracting hours
        minutes = remaining_seconds / 60             # Calculates the number of minutes
        seconds = remaining_seconds % 60             # Remaining seconds after extracting minutes

        # Format the time into a readable string with integer values
        formatted_time = "#{days}d #{hours}h #{minutes}m #{seconds}s"

        # Print the information with formatted maximum time
        puts "Link ID: #{sel.id}             Max DS Depth: #{'%9.3f' % max_value} at Time: #{formatted_time}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0080 - ICM InfoWorks IWR Tables\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in minutes assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs 
puts time_interval  

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name for downstream depth
res_field_name = 'ds_depth'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Find the maximum value and its index
      max_value = results.first.to_f
      max_index = 0

      results.each_with_index do |result, index|
        val = result.to_f
        if val > max_value
          max_value = val
          max_index = index
        end
      end

      # Get the time of maximum depth
      max_time = ts[max_index]

        # Calculate total seconds from the given time
        total_seconds = max_index * time_interval

        # Assuming total_seconds is calculated correctly as an integer value
        days = total_seconds / (24 * 3600)           # Calculates the number of days
        remaining_seconds = total_seconds % (24 * 3600)  # Remaining seconds after extracting days
        hours = remaining_seconds / 3600             # Calculates the number of hours
        remaining_seconds %= 3600                    # Remaining seconds after extracting hours
        minutes = remaining_seconds / 60             # Calculates the number of minutes
        seconds = remaining_seconds % 60             # Remaining seconds after extracting minutes

        # Format the time into a readable string with integer values
        formatted_time = "#{days}d #{hours}h #{minutes}m #{seconds}s"

        # Print the information with formatted maximum time
        puts "Link ID: #{sel.id}             Max DS Depth: #{'%9.3f' % max_value} at Time: #{formatted_time}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0081 - Export Compare Network Versions to CSV\IE-csv_changes.rb" 
db=WSApplication.open('localhost:40000/database')       ## Open databaswe
net=db.model_object_from_type_and_id('Collection Network',20)       ## Network to use

net.csv_changes(100,120,'C:\\temp\\changes.csv')        ## nno.csv_changes(commit_id1, commit_id2, filename) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0082 - Create SuDS for All Subcatchments\UI_Script.rb" 
# ICM UI script can be used to create SUDS control data for each subcatchment

open_net = WSApplication.current_network

# Set up the CSV header
header = [
  "Subcatchment ID",
  "SUDS structure ID",
  "SUDS control ID",
  "Control type",
  "Area",
  "Number of units",
  "Area of subcatchment (%)",
  "Unit surface width",
  "Initial saturation (%)",
  "Impervious area treated (%)",
  "Pervious area treated (%)",
  "Outflow to",
  "Drain to subcatchment",
  "Drain to node",
  "Surface"
]

open_net.transaction_begin

# Iterate over each subcatchment and its SUDS controls
open_net.row_objects('hw_subcatchment').each do |sub|

  sub.suds_controls.each do |control|
    # Set properties of the control
    control.id = sub.subcatchment_id + "_SUDS"
    puts control.ID
  end
  sub.suds_controls.write
end

puts "Finished creating SUDS control data for each subcatchment"
open_net.transaction_commit

=begin
suds_controls.area
suds_controls.area_subcatchment_pct
suds_controls.control_type
suds_controls.drain_to_node
suds_controls.id
suds_controls.impervious_area_treated_pct
suds_controls.initial_saturation_pct
suds_controls.num_units
suds_controls.outflow_to
suds_controls.pervious_area_treated_pct
suds_controls.suds_structure
suds_controls.unit_surface_width
suds_controls.surface
=end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0083 - Find Time of Max DS Depth\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in minutes assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs 
puts time_interval  

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name for downstream depth
res_field_name = 'ds_depth'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Find the maximum value and its index
      max_value = results.first.to_f
      max_index = 0

      results.each_with_index do |result, index|
        val = result.to_f
        if val > max_value
          max_value = val
          max_index = index
        end
      end

      # Get the time of maximum depth
      max_time = ts[max_index]

        # Calculate total seconds from the given time
        total_seconds = max_index * time_interval

        # Assuming total_seconds is calculated correctly as an integer value
        days = total_seconds / (24 * 3600)           # Calculates the number of days
        remaining_seconds = total_seconds % (24 * 3600)  # Remaining seconds after extracting days
        hours = remaining_seconds / 3600             # Calculates the number of hours
        remaining_seconds %= 3600                    # Remaining seconds after extracting hours
        minutes = remaining_seconds / 60             # Calculates the number of minutes
        seconds = remaining_seconds % 60             # Remaining seconds after extracting minutes

        # Format the time into a readable string with integer values
        formatted_time = "#{days}d #{hours}h #{minutes}m #{seconds}s"

        # Print the information with formatted maximum time
        puts "Link ID: #{sel.id}             Max DS Depth: #{'%9.3f' % max_value} at Time: #{formatted_time}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0084 - Change All Node, Subs and Link IDs\hw_change All Node, Subs and Link ID.rb" 
  # Source: https://github.com/chaitanyalakeshri/ruby_scripts 
begin
  # Accessing the current network (ICM InfoWorks Only) 
  net = WSApplication.current_network
  raise "Error: current network not found" if net.nil?

  net.transaction_begin

  # Define function to update IDs for a given set of row objects
  def update_ids(row_objects, prefix)
    number = 1
    row_objects.each do |obj|
      obj.id = "#{prefix}#{number}"
      number += 1
      obj.write
    end
    number
  end

  # Get all nodes, links, and subcatchments as arrays and update their IDs
  nodes_ro = net.row_objects('_nodes')
  links_ro = net.row_objects('_links')
  subs_ro = net.row_objects('_subcatchments')
  raise "Error: objects not found" if nodes_ro.nil? || links_ro.nil? || subs_ro.nil?
  
  # Update IDs for nodes, links, and subcatchments
  puts "Node IDs Changed", update_ids(nodes_ro, "N_")
  #puts "Link IDs Changed", update_ids(links_ro, "L_")
  puts "Sub  IDs Changed", update_ids(subs_ro, "S_")

  net.transaction_commit    

rescue => e
  puts "Error: #{e.message}"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0084 - Change All Node, Subs and Link IDs\sw_change All Node, Subs and Link ID.rb" 
  # Source: https://github.com/chaitanyalakeshri/ruby_scripts 
begin
  # Accessing the current network (ICM SWMM Only) 
  net = WSApplication.current_network
  raise "Error: current network not found" if net.nil?

  net.transaction_begin

  # Define function to update IDs for a given set of row objects
  def update_ids(row_objects, prefix)
    number = 1
    row_objects.each do |obj|
      obj.id = "#{prefix}#{number}"
      number += 1
      obj.write
    end
    number
  end

  # Get all nodes, links, and subcatchments as arrays and update their IDs
  nodes_ro = net.row_objects('_nodes')
  links_ro = net.row_objects('_links')
  subs_ro = net.row_objects('_subcatchments')
  raise "Error: objects not found" if nodes_ro.nil? || links_ro.nil? || subs_ro.nil?
  
  # Update IDs for nodes, links, and subcatchments
  puts "Node IDs Changed", update_ids(nodes_ro, "N_")
  puts "Link IDs Changed", update_ids(links_ro, "L_")
  puts "Sub  IDs Changed", update_ids(subs_ro, "S_")

  net.transaction_commit    

rescue => e
  puts "Error: #{e.message}"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0085 - Export SWMM5 Calibration Files - Node Flooding\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'FloodDepth'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Nodes for Node Flood Depth"
puts ";         Day      Time  FloodDepth"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_nodes', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0086 - Export SWMM5 Calibration Files - Groundwater Elev\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'RUNOFF'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Subsfor Subcatchmemnt Runoff"
puts ";         Day      Time  Runoff"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('hw_subcatchment', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0087 - Export SWMM5 Calibration Files - Groundwater Flow\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'RUNOFF'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Subsfor Subcatchmemnt Runoff"
puts ";         Day      Time  Runoff"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('hw_subcatchment', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0088 - Export SWMM5 Calibration Files - Runoff\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'RUNOFF'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Subsfor Subcatchmemnt Runoff"
puts ";         Day      Time  Runoff"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('hw_subcatchment', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0089 - Export SWMM5 Calibration Files - Node Flood Depth\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'FloodDepth'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Nodes for Node Flood Depth"
puts ";         Day      Time  FloodDepth"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_nodes', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0090 - Export SWMM5 Calibration Files - Node Level\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'DEPNOD'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Nodes for Node Level"
puts ";         Day      Time  DEPNOD"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_nodes', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0091 - Export SWMM5 Calibration Files - Node Lateral Inflow\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'QNODE'

# Output the headers for the SWMM5 Calibration File
puts ";Selected Nodes for Node Inflow"
puts ";         Day      Time  QNODE"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_nodes', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  sel.id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0092 - Export SWMM5 Calibration Files - Downstream Velocity\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'ds_vel'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Downstream Velocity"
puts ";Conduit  Day      Time  Velocity"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0093 - Export SWMM5 Calibration Files - Upstream Velocity\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'us_vel'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Velocity"
puts ";Conduit  Day      Time  Velocity"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0094 - Export SWMM5 Calibration Files - Upstream  Depth\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]) * 24 * 60 * 60

# Define the result field name
res_field_name = 'us_depth'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Depth"
puts ";Conduit  Day      Time  Depth"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0095 - Export SWMM5 Calibration Files - Downstream Depth\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]) * 24 * 60 * 60

# Define the result field name
res_field_name = 'ds_depth'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Downstream Depth"
puts ";Conduit  Day      Time  Depth"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0096 - Export SWMM5 Calibration Files - Downstream Flow\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'ds_flow'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Downstream Flow"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0097 - Export SWMM5 Calibration Files - Upstream Flow\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'us_flow'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Flow"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\InfoSewer_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Subcatchment', 'Step1b_InfoSewer_Subcatchment_Manhole_csv.cfg', 'Node.csv'],
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv'],
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'wwellhyd.csv'],
    ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv'],
    # MH DWF and Pipe Hydraulics 
    ['Subcatchment','Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario.cfg', 'mhhyd.csv'],
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Move_Copy_Imported_Pumps.rb" 
# Source https://github.com/chaitanyalakeshri/ruby_scripts 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection
    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?
  
    subcatchments_roc = net.row_object_collection('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_roc.nil?
  
    # one can also access exclusive tables like pump table ,conduit table or orifice table
    pump_roc = net.row_object_collection('hw_pump')
    raise "Error: pump not found" if pump_roc.nil?
  
    # Get all the nodes or links or subcatchments as array
    nodes_ro = net.row_objects('_nodes')
    raise "Error: nodes not found" if nodes_ro.nil?
    puts "Total number of nodes: #{nodes_ro.count}"
    
    subcatchments_ro = net.row_objects('_subcatchments')
    raise "Error: subcatchments not found" if subcatchments_ro.nil?
    puts "Total number of subcatchments: #{subcatchments_ro.count}"

    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    puts "Total number of links: #{links_ro.count}"
    # Existing code
    links_ro = net.row_objects('_links')
    raise "Error: links not found" if links_ro.nil?
    
    pump_ro = net.row_objects('hw_pump')
    raise "Error: pump not found" if pump_ro.nil?
    puts "Total number of pumps: #{pump_ro.count}"

    # Filter links with the label 'Pump'
    pump_links = links_ro.select { |link| link.user_text_10 == 'Pump' }

    # Check if any pump links are found
    if pump_links.any?
    # Display the total number of pump links
    puts "-" * 20  # Separator
    puts "Total number of pump links: #{pump_links.count}"

    # Iterate over each pump link and display its details
    net.transaction_begin
    pump_links.each_with_index do |pump_link, index|
        puts "Pump Link #{index + 1} Details:"
        puts "Link ID: #{pump_link.id}"
        puts "Upstream Node ID: #{pump_link.us_node_id}"
        puts "Downstream Node ID: #{pump_link.ds_node_id}"
        puts "-" * 20  # Separator
        # Assuming pump_ro is a pre-defined object for storing/linking pump data
        net.row_objects('hw_pump')
        pump_ro.us_node_id = pump_link.us_node_id.to_s
        pump_ro.ds_node_id = pump_link.ds_node_id
        pump_ro.id = pump_link.id  
        pump_ro.write
    end
    net.transaction_commit
    else
    puts "No pump links found."
    end
  
  rescue => e
    puts "Error: #{e.message}"
  end
   
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario_ODIC.rb" 
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step11_InfoSewer_pipehyd_scenario_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\dickinre\Desktop\Erie_InfoSewer\OneDrive_2023-11-14\To be Converted for Quote\Fraser_20231114\Fraser\FRASERMAP_FOR MODEL2.IEDB\Pipe\ULTIMATE'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step12_Point_Scenario_csv.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Subcatchment', 'Step1b_InfoSewer_Manhole_csv.cfg', 'Node.csv'],
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv'],
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'Node.csv'],
    ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv'],
    # MH DWF and Pipe Hydraulics 
    ['Subcatchment','Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario.cfg', 'mhhyd.csv'],
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step13_Point_Runopt_csv.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Subcatchment', 'Step1b_InfoSewer_Manhole_csv.cfg', 'Node.csv'],
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv'],
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'Node.csv'],
    ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv'],
    # MH DWF and Pipe Hydraulics 
    ['Subcatchment','Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario.cfg', 'mhhyd.csv'],
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step14_Point_Patterns_csv.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Subcatchment', 'Step1b_InfoSewer_Manhole_csv.cfg', 'Node.csv'],
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv'],
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'Node.csv'],
    ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv'],
    # MH DWF and Pipe Hydraulics 
    ['Subcatchment','Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario.cfg', 'mhhyd.csv'],
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step15_Point_Patndata_csv.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Subcatchment', 'Step1b_InfoSewer_Manhole_csv.cfg', 'Node.csv'],
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv'],
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'Node.csv'],
    ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv'],
    # MH DWF and Pipe Hydraulics 
    ['Subcatchment','Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario.cfg', 'mhhyd.csv'],
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step16_Additional_DWF_ICM_SWMM_XLOAD_csv.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv'],
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv'],
    ['Subcatchment', 'Step1b_InfoSewer_Manhole_csv.cfg', 'Node.csv'],
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv'],
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv'],
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv'],
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv'],
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv'],
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'Node.csv'],
    ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv'],
    # MH DWF and Pipe Hydraulics 
    ['Subcatchment','Step10_InfoSewer_subcatchment_dwf_mhhyd_scenario.cfg', 'mhhyd.csv'],
    ['Conduit','Step11_InfoSewer_pipehyd_scenario.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step17_User_10_ICM_SWMM_XLOAD_csv.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\dickinre\Desktop\NLV_Model_2021_09_16_final\NLV_Model_2021_09_16_final\MPU_MODEL_UPDATE_20210916.IEDB\XLoad\base'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step17_User_10_ICM_SWMM_XLOAD_csv.cfg', 'xload.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step18_User_123_ICM_SWMM_mhhyd_csv.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\dickinre\Desktop\NLV_Model_2021_09_16_final\NLV_Model_2021_09_16_final\MPU_MODEL_UPDATE_20210916.IEDB\Manhole\MH2020-2'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step18_User_123_ICM_SWMM_mhhyd_csv.cfg', 'mhhyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step1a_InfoSewer_Manhole_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1a_InfoSewer_Manhole_csv.cfg', 'manhole.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step1b_InfoSewer_Subcatchment_Manhole_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Subcatchment', 'Step1b_InfoSewer_Subcachment_Manhole_csv.cfg', 'Node.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step1_InfoSewer_Node_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step1_InfoSewer_Node_csv.cfg', 'Node.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step21_User_123_ICM_SWMM_pipehyd_csv .rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for SWMM network nodes
  database_fields = [
    'us_invert',
		'ds_invert',
    'length',
    'conduit_height',
    'conduit_width',
    'number_of_barrels',
    'user_number_1',
    'user_number_2',
    'user_number_3',
    'user_number_4',
    'user_number_5',
    'user_number_6',
    'user_number_7',
    'user_number_8',
    'user_number_9',
    'user_number_10'
  ]

  open_net.clear_selection
  puts "Scenario     : #{open_net.current_scenario}"
  puts "Version      : #{WSApplication.version}"
  puts "Units        : #{WSApplication.use_user_units}"
  puts "Database     : #{WSApplication.current_database}"
  puts "Network      : #{WSApplication.current_network}" 
  
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('Sw_conduit').each do |ro|
    row_count += 1
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end
  
  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    if data.empty?
      #puts "#{field} has no data!"
      next
    end

    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum
  
    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end

# Call the print_csv_inflows_file method
print_csv_inflows_file(open_net)

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\dickinre\Desktop\NLV_Model_2021_09_16_final\NLV_Model_2021_09_16_final\MPU_MODEL_UPDATE_20210916.IEDB\Pipe\PIPE2050-2'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Conduit', 'Step21_User_123_ICM_SWMM_pipehyd_csv.cfg', 'pipehyd.csv']
] 

import_steps.each do |layer, cfg_file, csv_file|
  begin
    open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
    puts "Imported #{layer} layer from #{cfg_file}"
  rescue StandardError => e
    puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
  end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM SWMM"

# Call the print_csv_inflows_file method again
print_csv_inflows_file(open_net)

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step22a_User_123_ICM_mhhyd_csv_One_Read.rb" 
require 'csv'

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for SWMM network nodes
  database_fields = [
    'ground_level',
		'flood_level',
    'chamber_area',
    'shaft_area',
    'user_number_1',
    'user_number_2',
    'user_number_3',
    'user_number_4',
    'user_number_5',
    'user_number_6',
    'user_number_7',
    'user_number_8',
    'user_number_9',
    'user_number_10'
  ]

  open_net.clear_selection
  puts "Scenario     : #{open_net.current_scenario}"
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('hw_node').each do |ro|
    row_count += 1
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end
  
  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    if data.empty?
      #puts "#{field} has no data!"
      next
    end

    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum
  
    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end

def import_node_loads(open_net,folder_path,mh_set)

  # Define the configuration and CSV file paths
  val=WSApplication.prompt "Manhole Loads for an InfoSewer Scenario",
  [
  ['Pick the Scenario Name that Matches the InfoSewer Dataset ','String',nil,nil,'FOLDER','Manhole Folder']
  ],false
    # Exit the program if the user cancelled the prompt
    return  if val.nil?
  csv  = val[0] + "\\mhhyd.csv"
  puts csv

  # Initialize an empty array to hold the hashes
  rows = []

  # Open and read the CSV file
  CSV.foreach(csv, headers: true).with_index do |row, index|
    # Add the row to the array as a hash
    rows << {
      "ID" => row[0], 
      "DIAMETER" => row[1],
      "RIM_ELEV" => row[2],
      "LOAD1" => row[4],
      "PATTERN1" => row[6],
      "LOAD2" => row[8],
      "PATTERN2" => row[10],
      "LOAD3" => row[12],
      "PATTERN3" => row[14],
      "LOAD4" => row[16],
      "PATTERN4" => row[18],
      "LOAD5" => row[20],
      "PATTERN5" => row[22],
      "LOAD6" => row[24],
      "PATTERN6" => row[26],
      "LOAD7" => row[28],
      "PATTERN7" => row[30],
      "LOAD8" => row[32],
      "PATTERN8" => row[34],
      "LOAD9" => row[36],
      "PATTERN9" => row[38],
      "LOAD10" => row[40],
      "PATTERN10" => row[42]
    }
  end

  # save the rows
  rows.each do |row|
    open_net.row_objects('hw_node').each do |ro|
      if ro.node_id.strip.downcase == row["ID"].strip.downcase then
        ro.user_number_1 = row["DIAMETER"]
        ro.user_number_2 = row["RIM_ELEV"]
        ro.user_number_3 = row["LOAD1"]
        ro.user_number_4 = row["LOAD2"]
        ro.user_number_5 = row["LOAD3"]
        ro.user_number_6 = row["LOAD4"]
        ro.user_number_7 = row["LOAD5"]
        ro.user_number_8 = row["LOAD6"]
        ro.user_number_9 = row["LOAD7"]
        ro.user_number_10 = row["LOAD8"]
        ro.write
        break
      end
    end
  end

    rows.each do |row|
      open_net.row_objects('hw_subcatchment').each do |ro|
        if ro.subcatchment_id == row["ID"] then
          ro.user_number_1 = row["LOAD1"]
          ro.user_number_2 = row["LOAD2"]
          ro.user_number_3 = row["LOAD3"]
          ro.user_number_4 = row["LOAD4"]
          ro.user_number_5 = row["LOAD5"]
          ro.user_number_6 = row["LOAD6"]
          ro.user_number_7 = row["LOAD7"]
          ro.user_number_8 = row["LOAD8"]
          ro.user_number_9 = row["LOAD9"]
          ro.user_number_10 = row["LOAD10"]          
          ro.user_text_1 = row["PATTERN1"]
          ro.user_text_2 = row["PATTERN2"]
          ro.user_text_3 = row["PATTERN3"]
          ro.user_text_4 = row["PATTERN4"]
          ro.user_text_5 = row["PATTERN5"]
          ro.user_text_6 = row["PATTERN6"]
          ro.user_text_7 = row["PATTERN7"]
          ro.user_text_8 = row["PATTERN8"]
          ro.user_text_9 = row["PATTERN9"]
          ro.user_text_10 = row["PATTERN10"]
          ro.write
          break
        end
      end
    end
end
#========================================================================
# Access the current open network in the application
open_net = WSApplication.current_network

    # Define the configuration and CSV file paths
    csv=WSApplication.prompt "Manhole Hydraulics and loads for an InfoSewer Scenario",
    [
    ['Pick the Scenario Name for the InfoSewer Dataset ','String',nil,nil,'FOLDER','Manhole Folder']
    ],false
    puts csv
#========================================================================
      # Initialize an empty array to hold the hashes
      rows = []

      csv_file_path  = File.join(csv, "scenario.csv")
      puts csv_file_path

      # Headers to exclude
      exclude_headers = ["USE_TIME", "TIME_SET", "USE_REPORT", "REPORT_SET", "USE_OPTION", "OPTION_SET","PISLT_SET"]

      # Read the CSV file
      CSV.open(csv_file_path, 'r', headers: true) do |csv|

      # Process the rows
      csv.each do |row|
        row_string = ""
        row.headers.each do |header|
          unless row[header].nil? || exclude_headers.include?(header)
            row_string += sprintf("%-15s: %s, ", header, row[header])
          end
        end
        puts row_string
          # Add the row to the array as a hash
          rows << row.to_h
        end
      end
#========================================================================

open_net.scenarios do |scenario|
  open_net.current_scenario = scenario
  text = WSApplication.message_box("Scenario #{open_net.current_scenario} to Import", 'OK', 'Information', nil)
    puts "Importing for Scenario #{open_net.current_scenario}"
      # Initialize 'mh_set' variable
      mh_set = nil
        rows.each do |row|  
          if row['ID'] == open_net.current_scenario
            puts "Row: #{row['ID']}, Current Scenario: #{open_net.current_scenario}, MH_SET: #{row['MH_SET']}"
            if row['MH_SET'].nil?
              puts "MH_SET is nil"
            elsif !row['MH_SET'].is_a?(String)
              puts "MH_SET is not a string: #{row['MH_SET']}"
            else
              mh_set = row['MH_SET'].upcase
            end
            break # Exit the loop once the matching row is found
          end
        end      
        # Set pipe_set to 'BASE' if the current scenario is 'BASE'
        if open_net.current_scenario.upcase == 'BASE' || mh_set.nil?
          mh_set = 'BASE'
        end
    
        text = WSApplication.message_box("MH_Set is #{mh_set} to Import", 'OK', 'Information', nil)

    open_net.transaction_begin
    import_node_loads(open_net,csv,mh_set)
    open_net.transaction_commit
    # Call the print_csv_inflows_file method
    print_csv_inflows_file(open_net)
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks" 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step22_User_123_ICM_mhhyd_csv_File_Reader.rb" 
require 'csv'

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for SWMM network nodes
  database_fields = [
    'ground_level',
		'flood_level',
    'chamber_area',
    'shaft_area',
    'user_number_1',
    'user_number_2',
    'user_number_3',
    'user_number_4',
    'user_number_5',
    'user_number_6',
    'user_number_7',
    'user_number_8',
    'user_number_9',
    'user_number_10'
  ]

  open_net.clear_selection
  puts "Scenario     : #{open_net.current_scenario}"
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('hw_node').each do |ro|
    row_count += 1
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end
  
  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    if data.empty?
      #puts "#{field} has no data!"
      next
    end

    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum
  
    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end

def import_node_loads(open_net)

  # Define the configuration and CSV file paths
  val=WSApplication.prompt "Manhole Loads for an InfoSewer Scenario",
  [
  ['Pick the Scenario Name that Matches the InfoSewer Dataset ','String',nil,nil,'FOLDER','Manhole Folder']
  ],false
    # Exit the program if the user cancelled the prompt
    return  if val.nil?
  csv  = val[0] + "\\mhhyd.csv"
  puts csv

  # Initialize an empty array to hold the hashes
  rows = []

  # Open and read the CSV file
  CSV.foreach(csv, headers: true).with_index do |row, index|
    # Add the row to the array as a hash
    rows << {
      "ID" => row[0], 
      "DIAMETER" => row[1],
      "RIM_ELEV" => row[2],
      "LOAD1" => row[4],
      "PATTERN1" => row[6],
      "LOAD2" => row[8],
      "PATTERN2" => row[10],
      "LOAD3" => row[12],
      "PATTERN3" => row[14],
      "LOAD4" => row[16],
      "PATTERN4" => row[18],
      "LOAD5" => row[20],
      "PATTERN5" => row[22],
      "LOAD6" => row[24],
      "PATTERN6" => row[26],
      "LOAD7" => row[28],
      "PATTERN7" => row[30],
      "LOAD8" => row[32],
      "PATTERN8" => row[34],
      "LOAD9" => row[36],
      "PATTERN9" => row[38],
      "LOAD10" => row[40],
      "PATTERN10" => row[42]
    }
  end

  # save the rows
  rows.each do |row|
    open_net.row_objects('hw_node').each do |ro|
      if ro.node_id.strip.downcase == row["ID"].strip.downcase then
        ro.user_number_1 = row["DIAMETER"]
        ro.user_number_2 = row["RIM_ELEV"]
        ro.user_number_3 = row["LOAD1"]
        ro.user_number_4 = row["LOAD2"]
        ro.user_number_5 = row["LOAD3"]
        ro.user_number_6 = row["LOAD4"]
        ro.user_number_7 = row["LOAD5"]
        ro.user_number_8 = row["LOAD6"]
        ro.user_number_9 = row["LOAD7"]
        ro.user_number_10 = row["LOAD8"]
        ro.write
        break
      end
    end
  end

    rows.each do |row|
      open_net.row_objects('hw_subcatchment').each do |ro|
        if ro.subcatchment_id == row["ID"] then
          ro.user_number_1 = row["LOAD1"]
          ro.user_number_2 = row["LOAD2"]
          ro.user_number_3 = row["LOAD3"]
          ro.user_number_4 = row["LOAD4"]
          ro.user_number_5 = row["LOAD5"]
          ro.user_number_6 = row["LOAD6"]
          ro.user_number_7 = row["LOAD7"]
          ro.user_number_8 = row["LOAD8"]
          ro.user_number_9 = row["LOAD9"]
          ro.user_number_10 = row["LOAD10"]          
          ro.user_text_1 = row["PATTERN1"]
          ro.user_text_2 = row["PATTERN2"]
          ro.user_text_3 = row["PATTERN3"]
          ro.user_text_4 = row["PATTERN4"]
          ro.user_text_5 = row["PATTERN5"]
          ro.user_text_6 = row["PATTERN6"]
          ro.user_text_7 = row["PATTERN7"]
          ro.user_text_8 = row["PATTERN8"]
          ro.user_text_9 = row["PATTERN9"]
          ro.user_text_10 = row["PATTERN10"]
          ro.write
          break
        end
      end
    end
end
#========================================================================
# Access the current open network in the application
open_net = WSApplication.current_network

    open_net.transaction_begin
    import_node_loads(open_net)
    open_net.transaction_commit
    # Call the print_csv_inflows_file method
    print_csv_inflows_file(open_net)

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks" 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step23a_User_123_ICM_pipehyd_csv_One_Read.rb" 
require 'csv'

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for SWMM network nodes
  database_fields = [
    'us_invert',
		'ds_invert',
    'conduit_length',
    'conduit_height',
    'conduit_width',
    'number_of_barrels',
    'bottom_roughness_N',
    'top_roughness_N',
    'user_number_1',
    'user_number_2',
    'user_number_3',
    'user_number_4',
    'user_number_5',
    'user_number_6',
    'user_number_7',
    'user_number_8',
    'user_number_9',
    'user_number_10'
  ]
  
  # Define the data fields
  data_fields = ["ID", "FROM_INV", "TO_INV", "LENGTH", "DIAMETER", "COEFF", "PARALLEL"]

  open_net.clear_selection
  puts "Reading Scenario : #{open_net.current_scenario}"
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('hw_conduit').each do |ro|
    row_count += 1
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end
  
  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    if data.empty?
      #puts "#{field} has no data!"
      next
    end

    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum
  
    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end

#========================================================================
def import_pipe_hydraulics(open_net, folder_path,pipe_set)    

  csv_file_path  = File.join(folder_path, "/pipe/#{pipe_set}/", "pipehyd.csv")
  puts csv_file_path

  # Initialize an empty array to hold the hashes
  rows = []

  # Open and read the CSV file
  CSV.foreach(csv_file_path, headers: true).with_index do |row, index|
    
    # Add the row to the array as a hash
    rows << {
      "ID" => row[0],
      "FROM_INV" => row[1],
      "TO_INV" => row[2],
      "LENGTH" => row[3],
      "DIAMETER" => row[4],
      "COEFF" => row[5],
      "PARALLEL" => row[6]
    }
  end

  # Print the rows
  rows.each do |row|
    open_net.row_objects('hw_conduit').each do |ro|
      if ro.asset_id == row["ID"] then
        ro.user_number_1 = row["FROM_INV"]
        ro.user_number_2 = row["TO_INV"]
        ro.user_number_3 = row["LENGTH"]
        ro.user_number_4 = row["DIAMETER"]
        ro.user_number_5 = row["COEFF"]
        ro.user_number_6 = row["PARALLEL"]
        if ro.user_number_6 == 0 then ro.user_number_6 = 1 end
        ro.us_invert =row["FROM_INV"]
        ro.ds_invert =row["TO_INV"]
        ro.conduit_length = row["LENGTH"]
        ro.conduit_height = row["DIAMETER"]
        ro.bottom_roughness_N = row["COEFF"]
        ro.top_roughness_N = row["COEFF"]
        ro.number_of_barrels = ro.user_number_6
        ro.write
        break
      end
    end
  end
end
#========================================================================
# Access the current open network in the application
open_net = WSApplication.current_network

    # Define the configuration and CSV file paths
    csv=WSApplication.prompt "Pipe Hydraulics for an InfoSewer Scenario",
    [
    ['Pick the Scenario Name for the InfoSewer Dataset ','String',nil,nil,'FOLDER','Pipe Folder']
    ],false
    puts csv
#========================================================================
      # Initialize an empty array to hold the hashes
      rows = []

      csv_file_path  = File.join(csv, "scenario.csv")
      puts csv_file_path

      # Headers to exclude
      exclude_headers = ["USE_TIME", "TIME_SET", "USE_REPORT", "REPORT_SET", "USE_OPTION", "OPTION_SET","PISLT_SET"]

      # Read the CSV file
      CSV.open(csv_file_path, 'r', headers: true) do |csv|

      # Process the rows
      csv.each do |row|
        row_string = ""
        row.headers.each do |header|
          unless row[header].nil? || exclude_headers.include?(header)
            row_string += sprintf("%-15s: %s, ", header, row[header])
          end
        end
        puts row_string

          # Add the row to the array as a hash
          rows << row.to_h
        end
      end
      rows
#========================================================================

  open_net.scenarios do |scenario|
  open_net.current_scenario = scenario
    puts "Importing for Scenario #{open_net.current_scenario}"
      # Initialize 'pipe_set' variable
      pipe_set = nil                                                               
        rows.each do |row|                                                                                       
          if row['ID'] == open_net.current_scenario
            pipe_set = row['PIPE_SET'].upcase
            puts "Pipe Set: #{pipe_set}"
            break # Exit the loop once the matching row is found
          end
        end      
        # Set pipe_set to 'BASE' if the current scenario is 'BASE'
        if open_net.current_scenario.upcase == 'BASE' then pipe_set = 'BASE' end

    open_net.transaction_begin
    import_pipe_hydraulics(open_net,csv,pipe_set)
    open_net.transaction_commit
    # Call the print_csv_inflows_file method
    print_csv_inflows_file(open_net)
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step23_User_123_ICM_pipehyd_csv_Folder_Reader.rb" 
require 'csv'

# Define the print_csv_inflows_file method
def print_csv_inflows_file(open_net)
  # Define database fields for SWMM network nodes
  database_fields = [
    'us_invert',
		'ds_invert',
    'conduit_length',
    'conduit_height',
    'conduit_width',
    'number_of_barrels',
    'bottom_roughness_N',
    'top_roughness_N',
    'user_number_1',
    'user_number_2',
    'user_number_3',
    'user_number_4',
    'user_number_5',
    'user_number_6',
    'user_number_7',
    'user_number_8',
    'user_number_9',
    'user_number_10'
  ]
  
  # Define the data fields
  data_fields = ["ID", "FROM_INV", "TO_INV", "LENGTH", "DIAMETER", "COEFF", "PARALLEL"]

  open_net.clear_selection
  puts "Reading Scenario : #{open_net.current_scenario}"
  
  # Prepare hash for storing data of each field for database_fields
  fields_data = {}
  database_fields.each { |field| fields_data[field] = [] }
  
  # Initialize the count of processed rows
  row_count = 0
  total_expected = 0.0
  
  # Collect data for each field from sw_node
  open_net.row_objects('hw_conduit').each do |ro|
    row_count += 1
    database_fields.each do |field|
      fields_data[field] << ro[field] if ro[field]
    end
  end
  
  # Print min, max, mean, standard deviation, total, and row count for each field
  database_fields.each do |field|
    data = fields_data[field]
    if data.empty?
      #puts "#{field} has no data!"
      next
    end

    min_value = data.min
    max_value = data.max
    sum = data.inject(0.0) { |sum, val| sum + val }
    mean_value = sum / data.size
    # Calculate the standard deviation
    sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
    standard_deviation = Math.sqrt(sum_of_squares / data.size)
    total_value = sum
  
    # Updated printf statement with row count
    printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
           field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
  end
end

def import_pipe_hydraulics(open_net)    
  # Define the configuration and CSV file paths
  val=WSApplication.prompt "Pipe Hydraulics for an InfoSewer Scenario",
  [
  ['Pick the Scenario Name that Matches the InfoSewer Dataset ','String',nil,nil,'FOLDER','Pipe Folder']
  ],false
    # Exit the program if the user cancelled the prompt
    return  if val.nil?
  csv  = val[0] + "\\pipehyd.csv"
  puts csv

  # Initialize an empty array to hold the hashes
  rows = []

  # Open and read the CSV file
  CSV.foreach(csv, headers: true).with_index do |row, index|

    # Add the row to the array as a hash
    rows << {
      "ID" => row[0],
      "FROM_INV" => row[1],
      "TO_INV" => row[2],
      "LENGTH" => row[3],
      "DIAMETER" => row[4],
      "COEFF" => row[5],
      "PARALLEL" => row[6]
    }
  end

  # Print the rows
  rows.each do |row|
    open_net.row_objects('hw_conduit').each do |ro|
      if ro.asset_id == row["ID"] then
        ro.user_number_1 = row["FROM_INV"]
        ro.user_number_2 = row["TO_INV"]
        ro.user_number_3 = row["LENGTH"]
        ro.user_number_4 = row["DIAMETER"]
        ro.user_number_5 = row["COEFF"]
        ro.user_number_6 = row["PARALLEL"]
        if ro.user_number_6 == 0 then ro.user_number_6 = 1 end
        ro.us_invert =row["FROM_INV"]
        ro.ds_invert =row["TO_INV"]
        ro.conduit_length = row["LENGTH"]
        roconduit_height = row["DIAMETER"]
        ro.bottom_roughness_N = row["COEFF"]
        ro.top_roughness_N = row["COEFF"]
        ro.number_of_barrels = ro.user_number_6
        ro.write
        break
      end
    end
  end
end

# Access the current open network in the application
open_net = WSApplication.current_network

open_net.scenarios do |scenario|
  open_net.current_scenario = scenario
  text = WSApplication.message_box("Scenario #{open_net.current_scenario} to Import", 'OK', 'Information', nil)
    puts "Importing for Scenario #{open_net.current_scenario}"
    open_net.transaction_begin
    import_pipe_hydraulics(open_net)
    open_net.transaction_commit
    # Call the print_csv_inflows_file method
    print_csv_inflows_file(open_net)
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step24_User_123_ICM_anode_alink_csv.rb" 
require 'csv'
require 'pathname'

def import_anode(open_net)
  # Prompt the user to pick a folder
  val = WSApplication.prompt("Facilty for an InfoSewer Scenario", [
    ['Pick the Scenario Folder', 'String', nil, nil, 'FOLDER', 'Scenario Folder']
  ], false)

  # Check if the user canceled the prompt
  return if val.nil?

  folder_path = val[0]
  puts "Folder path: #{folder_path}"
  puts "If the CSV File is Empty - this means all nodes or links are active in the InfoSewer Scenario"

  # Initialize an empty array to hold the hashes
  rows = []

  # Iterate over all subdirectories in the given folder
  Pathname.new(folder_path).children.select(&:directory?).each do |dir|
    ['anode.csv', 'alink.csv'].each do |filename|
      puts Pathname.new(dir).basename
      $selection_set = Pathname.new(dir).basename
      puts filename
      csv_path = "#{dir}/#{filename}"

      # Check if the CSV file exists in the subdirectory
      if File.exist?(csv_path)
        begin
          File.open(csv_path, 'a') {}
          puts "Found #{filename} in #{csv_path}"
        rescue IOError => e
          puts "File #{filename} is already open"
        end
      end

        # Read the CSV file
        CSV.foreach(csv_path, headers: true) do |row|
          row_hash = row.to_h
          puts row.to_h
          row_hash.delete("TYPE") # Remove the "TYPE" key-value pair
          row_hash["dir_source"] = File.basename(dir.to_s) + "_" + File.basename(filename, '.*') # Combine 'dir' and 'source'
          rows.each do |row|
            row_hash = row.to_h
            rows << row_hash
            puts row_hash
          end
        end
      else
        raise "No #{filename} file found in #{dir}"
      end
    end

  rows.each do |row|
    open_net.row_objects('hw_conduit').each do |ro|
      if ro.asset_id == row["ID"] then
         ro.asset_id_flag = 'ISAC'  # Set the 'flag' field of the row object
         ro.write  # Write the changes to the database
      end
    end
  end

  rows.each do |row|
    open_net.row_objects('hw_node').each do |ro|
      if ro.node_id == row["ID"] then
         ro.node_id_flag = 'ISAC'  # Set the 'flag' field of the row object
         ro.write  # Write the changes to the database
      end
    end
  end

  rows.each do |row|
    open_net.row_objects('hw_subcatchment').each do |ro|
      if ro.subcatchment_id == row["ID"] then
         ro.subcatchment_id_flag = 'ISAC'  # Set the 'flag' field of the row object
         ro.write  # Write the changes to the database
      end
    end
  end
    db=WSApplication.current_database
    open_net.clear_selection
    group=db.find_root_model_object 'Model Group','DanaHDR'   # Find the model group - has to be created before use
    open_net.run_SQL "_links","flags.value='ISAC''"
    open_net.run_SQL "_nodes","flags.value='ISAC''"
    open_net.run_SQL "_subcatchments","flags.value='ISAC''"
    sl=group.new_model_object 'Selection List',$selection_set.to_s
    puts s1=sl.name
    open_net.save_selection sl
end

end

# Access the current open network in the application
open_net = WSApplication.current_network

# Call the import_anode method
open_net.transaction_begin
import_anode(open_net)
open_net.transaction_commit

# Indicate the completion of the import process
puts "Finished Import of InfoSewer Facility Manager to ICM InfoWorks"  
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step25_User_123_ICM_Scenario_csv.rb" 
require 'csv'
require 'pathname'

def import_scenario(open_net)
  # Prompt the user to pick a folder
  val = WSApplication.prompt "Folder for an InfoSewer or InfoSWMM Scenario", [
    ['Pick the IEDB or ISDB Folder - All existing scenarios will be deleted','String',nil,nil,'FOLDER','IEDB or ISDB Folder']], false
  folder_path = val[0]
  puts "Folder path: #{folder_path}"

  # Check if folder path is given
  return unless folder_path

  # Initialize an empty array to hold the hashes
  rows = []

  scenario_csv = "#{folder_path}/scenario.csv"
  puts "Scenario CSV: #{scenario_csv}"

  # Headers to exclude
  exclude_headers = ["USE_TIME", "TIME_SET", "USE_REPORT", "REPORT_SET", "USE_OPTION", "OPTION_SET","PISLT_SET"]

  # Read the CSV file
  CSV.open(scenario_csv, 'r', headers: true) do |csv|

  # Process the rows
  csv.each do |row|
    row_string = ""
    row.headers.each do |header|
      unless row[header].nil? || exclude_headers.include?(header)
        row_string += sprintf("%-15s: %s, ", header, row[header])
      end
    end
    puts row_string

      # Add the row to the array as a hash
      rows << row.to_h
    end
  end

  rows
end

# Access the current open network in the application
open_net = WSApplication.current_network

# Call the import_scenario method
rows = import_scenario(open_net)

added_scenarios_count = 0

# Delete all scenarios except 'Base'
open_net.scenarios do |scenario|
 if scenario != 'Base'
  open_net.delete_scenario(scenario)
 end
end

puts "All scenarios deleted"

# Add new scenarios from the CSV file
rows.each do |scenario|
 if scenario['ID'] != 'BASE'
   puts "Adding scenario #{scenario['ID']}"
   open_net.add_scenario(scenario['ID'],nil,'')
   added_scenarios_count += 1
 end
end

# Print the total number of scenarios added
puts "Total scenarios added: #{added_scenarios_count}" 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step2_InfoSewer_Link_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Conduit', 'Step2_InfoSewer_Link_csv.cfg', 'Link.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step3a_InfoSewer_Manhole_Loads_General_Lines_mhhyd_csv.rb" 
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step3_InfoSewer_manhole_hydraulics_ODIC..rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step3_InfoSewer_manhole_hydraulics_mhhyd_csv.cfg', 'mhhyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step4_InfoSewer_link_hydraulics_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Conduit', 'Step4_InfoSewer_link_hydraulics_pipehyd_csv.cfg', 'pipehyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step5_InfoSewer_pump_curve_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Pump', 'Step5_InfoSewer_pump_curve_pumphyd_csv.cfg', 'pumphyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step6_InfoSewer_pump_control_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Pump', 'Step6_InfoSewer_pump_control_control_csv.cfg', 'control.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step7_InfoSewer_Subcatchment_dwf_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Subcatchment', 'Step7_InfoSewer_subcatchment_dwf_mhhyd_csv.cfg', 'mhhyd.csv']
]

begin
  import_steps.each do |layer, cfg_file, csv_file|
    open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
    puts "Imported #{layer} layer from #{cfg_file}"
  end
  
rescue Errno::ENOENT => e
  puts "File not found error: #{e.message}"
rescue Errno::EACCES => e
  puts "File access error: #{e.message}"
rescue StandardError => e
  puts "An error occurred: #{e.message}"
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks" 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step8_InfoSewer_wwellhyd_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Define the configuration and CSV file paths
cfg = 'C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'
csv = 'C:\Users\Public\Documents\InfoSewer\RDII_NET!.IEDB'
puts csv
puts cfg

# List of import steps
import_steps = [
    ['Node', 'Step8_Infosewer_wetwell_wwellhyd_csv.cfg', 'wwellhyd.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
    begin
        open_net.odic_import_ex('csv', File.join(cfg, cfg_file), nil, layer, File.join(csv, csv_file))
        puts "Imported #{layer} layer from #{cfg_file}"
    rescue StandardError => e
        puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
    end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0100 - ODIC and SQL, Ruby  Scripts for Importing InfoSewer to ICM\Step9_InfoSewer_rdii_hydrograph_ODIC.rb" 
# Access the current open network in the application
open_net = WSApplication.current_network

# Prompt the user to pick a folder
csv = WSApplication.prompt "Folder for an InfoSewer IEDD", 
[ ['Pick the IEDB Folder ','String',nil,nil,'FOLDER','IEDB Folder']], false

cfg = 'C:\\Users\\dickinre\\Documents\\Open-Source-Support-main\\01 InfoWorks ICM\\InfoSewer to ICM\\Open-Source-Support\\01 InfoWorks ICM\\01 Ruby\\02 SWMM\\0100 - ODIC and SQL Scripts for Importing InfoSewer to ICM'

puts "CSV Folder: #{csv}"
puts "Config Folder: #{cfg}"

# List of import steps
import_steps = [
  ['RTK Hydrograph', 'Step9_rdii_hydrograph_csv.cfg', 'Hydrograph.csv']
]

import_steps.each do |layer, cfg_file, csv_file|
  begin
    cfg_path = File.join(cfg, cfg_file)
    csv_path = File.join(csv, csv_file)

    # Check if the files exist before trying to import
    if File.exist?(cfg_path) && File.exist?(csv_path)
      open_net.odic_import_ex('csv', cfg_path, nil, layer, csv_path)
      puts "Imported #{layer} layer from #{cfg_file}"
    else
      puts "Could not find files: #{cfg_path}, #{csv_path}"
    end
  rescue StandardError => e
    puts ("An error occurred during the import of #{layer} from #{cfg_file}: #{e.message}")
  end
end

# Indicate the completion of the import process
puts "Finished Import of InfoSewer to ICM InfoWorks" 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0102 - ICM InfoWorks Results to SWMM5  Node Inflows  Summary Table\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'us_flow'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Flow"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
              # Check if there are any selected elements
              if sel.nil?
                 puts "No elements were selected. Please select at least one element and try again."
                 exit
                 end
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0103 - ICM InfoWorks Results to SWMM5 Node Depths Summary Table\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'us_flow'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Flow"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0104 - ICM InfoWorks Results to SWMM5  Node Surcharging Table\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'us_flow'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Flow"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0105 - ICM InfoWorks Results to SWMM5  Conduit Surcharging  Summary Table\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'us_flow'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Flow"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0106 - ICM InfoWorks Results to SWMM5  Link Flows Summary Table\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Define the complete mapping table - needed for each InfoWorks network
# The first value in each array is the InfoWorks ID, the second value is the SWMM5 ID for the calibration file

asset_mapping = {
  'mid9.1' => 'outlet',
  'Inflow.1' => 'pipe1',
  'mid1.1' => 'pipe2',
  'mid2_1' => 'pipe3',
  'mid3.1' => 'pipe4',
  'mid4.1' => 'pipe5',
  'mid5.1' => 'pipe6',
  'mid6.1' => 'pipe7',
  'mid7.1' => 'pipe8',
  'mid8.1' => 'pipe9'
}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  exit
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs

# Define the result field name
res_field_name = 'us_flow'

# Output the headers for the SWMM5 Calibration File
puts ";Flows for Selected Conduits for Upstream Flow"
puts ";Conduit  Day      Time  Flow"
puts ";-----------------------------"

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Retrieve the Asset ID from the mapping
    asset_id = asset_mapping[sel.id]

    # Use the Asset ID in a puts statement for the SWMM5 Calibration file
    puts  asset_id

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      count = 0
 
      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f
        count += 1

        # Calculate the exact time for this result
        current_time = (count - 1).to_f * time_interval
  
        # Assuming current_time is in seconds
        days = current_time / (24 * 60 * 60) # Number of days
        remaining_seconds = current_time % (24 * 60 * 60)
        hours = remaining_seconds / (60 * 60) # Number of hours
        minutes = (remaining_seconds % (60 * 60)) / 60 # Number of minutes

        # Output the formatted data for SWMM5
        puts "         #{days.to_i}    #{hours.to_i}:#{format('%02d', minutes.to_i)}     #{'%.4f' % val}"
      end
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0107 - ICM InfoWorks Results to SWMM5 Subcatchment Runoff Summary\hw_UI_script_CFS.rb" 
# Import the 'date' library
require 'csv'
require 'date'

# Initialize an array to store all statistics
all_stats = []

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected Subcatchments
field_names = [
  'qfoul', 'qtrade', 'rainfall', 'evaprate', 'grndstor', 'soilstor', 'qsoil',
  'qinfsoil', 'qrdii', 'qinfilt', 'qinfgrnd', 'qground', 'plowfw', 'plowsnow',
  'impfw', 'pervfw', 'impmelt', 'pervmelt', 'impsnow', 'pervsnow', 'losttogw',
  'napi', 'qcatch', 'q_lid_in', 'q_lid_out', 'q_lid_drain', 'q_exceedance',
  'rainprof', 'effrain', 'qbase', 'v_exceedance', 'runoff', 'qsurf01',
  'qsurf02', 'qsurf03', 'qsurf04', 'qsurf05', 'qsurf06', 'qsurf07', 'qsurf08',
  'qsurf09', 'qsurf10', 'qsurf11', 'qsurf12'
]

  # Calculate the time interval in seconds assuming the time steps are evenly spaced
  time_interval = (ts[1] - ts[0]).abs
  # Print the time interval in seconds and minutes
  puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60.0]
  puts

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    ro = net.row_object('_subcatchments', sel.id)
    raise "Object with ID #{sel.id} is not a subcatchment." if ro.nil?

    field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        if rs_size == ts_size
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0

           ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            total_integrated_over_time += result.to_f * time_interval 
            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          mean_value = count > 0 ? total / count : 0

          total_integrated_over_time /= 3600.0 if res_field_name == 'rainfall'
          total_integrated_over_time = total_integrated_over_time * 12.0 / (sel.total_area * 43560.0) if res_field_name != 'rainfall'      
          (1..12).each do |i|
            field_name = "qsurf%02d" % i
            area_percent_key = "area_percent_#{i}".to_sym
          
            if res_field_name == field_name && sel.respond_to?(area_percent_key)
              area_percent_value = sel.send(area_percent_key) / 100.0
              puts area_percent_value
              total_integrated_over_time *= area_percent_value
            end
          end

          # Save statistics in the array
          all_stats << {
            subcatchment_id: sel.id,
            field_name: res_field_name,
            sum: total_integrated_over_time ,
            mean: mean_value,
            max: max_value,
            min: min_value,
            steps: count,
            area: sel.total_area
          }
        end

      rescue
        next
      end
    end

  rescue => e
    next
  end
end

# Print the summary header
puts '  *******************************************'
puts '  Subcatchment Runoff Summary (ICM InfoWorks)'
puts '  *******************************************'
puts ''
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts '                            Total      Total      Total      Total    qsurf01    qsurf02      Total       Total     Peak     Runoff    qsurf03    qsurf04    qsurf05    qsurf06    qsurf07    qsurf08    qsurf09    qsurf10    qsurf11    qsurf12'
puts '                           Precip      Runon       Evap      Infil     Runoff     Runoff     Runoff      Runoff   Runoff      Coeff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff'
puts '  Subcatchment                 in         in         in         in         in         in         in    10^6 gal      CFS                    in         in         in         in         in         in         in         in         in         in'
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'

field_width = 10 # Width for the field value
id_width = 21   # Width for the subcatchment ID 

# Initialize a hash to store aggregated data for each subcatchment
aggregated_data = {}

# Aggregate data
all_stats.each do |stat|
  sub_id = stat[:subcatchment_id]
  field_name = stat[:field_name]

  # Initialize subcatchment data if not already present
  aggregated_data[sub_id] ||= {}

  # Store all the statistics for the corresponding field
  aggregated_data[sub_id][field_name] = stat
end

# Print the aggregated data for each subcatchment
aggregated_data.each do |sub_id, data|
  output_line = "#{'%*s ' % [id_width, sub_id]}"

  # Append stats for specific fields to the output line
  # Example for rainfall
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:min]]}"
  end
  if data['evaprate']
    stats = data['evaprate']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qinfsoil']
    stats = data['qinfsoil']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf01']
    stats = data['qsurf01']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf02']
    stats = data['qsurf02']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['runoff']
    stats = data['runoff']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end

  # Similar blocks can be added for other fields like 'evaprate', 'qinfsoil', etc.

  # Example for runoff (with specific calculations for second and third runoff values)
  if data['runoff']
    stats = data['runoff']
    second_runoff = stats[:sum] * 43560.0 / 12.0 * 7.48 * stats[:area] / 1000.0 / 1000.0
    third_runoff  = stats[:max] 
    output_line += " #{'%*.3f' % [field_width, second_runoff]}"
    output_line += " #{'%*.3f' % [field_width, third_runoff]}"
  end

  # Calculate and append runoff coefficient (RC)
rainfall_sum = data['rainfall'] ? data['rainfall'][:sum] : 0
runoff_sum = data['runoff'] ? data['runoff'][:sum] : 0

# Ensure rainfall_sum is not zero to avoid division by zero
if rainfall_sum > 0
  rc = runoff_sum / rainfall_sum
  output_line += " #{'%*.3f' % [field_width, rc]}"
else
  output_line += " #{'%*s' % [field_width, 'N/A']}"  # If no rainfall data, RC cannot be computed
end

# Check and append qsurf03 to qsurf12
(3..12).each do |i|
  key = "qsurf%02d" % i  # Generates qsurf03, qsurf04, ..., qsurf12
  if data[key]
    stats = data[key]
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
end

  puts output_line
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0107 - ICM InfoWorks Results to SWMM5 Subcatchment Runoff Summary\hw_UI_script_CMS.rb" 
# Import the 'date' library
require 'csv'
require 'date'

# Initialize an array to store all statistics
all_stats = []

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected Subcatchments
field_names = [
  'qfoul', 'qtrade', 'rainfall', 'evaprate', 'grndstor', 'soilstor', 'qsoil',
  'qinfsoil', 'qrdii', 'qinfilt', 'qinfgrnd', 'qground', 'plowfw', 'plowsnow',
  'impfw', 'pervfw', 'impmelt', 'pervmelt', 'impsnow', 'pervsnow', 'losttogw',
  'napi', 'qcatch', 'q_lid_in', 'q_lid_out', 'q_lid_drain', 'q_exceedance',
  'rainprof', 'effrain', 'qbase', 'v_exceedance', 'runoff', 'qsurf01',
  'qsurf02', 'qsurf03', 'qsurf04', 'qsurf05', 'qsurf06', 'qsurf07', 'qsurf08',
  'qsurf09', 'qsurf10', 'qsurf11', 'qsurf12'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    ro = net.row_object('_subcatchments', sel.id)
    raise "Object with ID #{sel.id} is not a subcatchment." if ro.nil?

    field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        if rs_size == ts_size
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0

          # Assuming the time steps are evenly spaced, calculate the time interval in seconds
          time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1

          ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            total_integrated_over_time += result.to_f * time_interval 
            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          mean_value = count > 0 ? total / count : 0

          total_integrated_over_time /= 3600.0 if res_field_name == 'rainfall'
          total_integrated_over_time = total_integrated_over_time * 1000.0 / (sel.total_area * 10000.0) if res_field_name != 'rainfall'
          
          (1..12).each do |i|
            field_name = "qsurf%02d" % i
            area_percent_key = "area_percent_#{i}".to_sym
          
            if res_field_name == field_name && sel.respond_to?(area_percent_key)
              area_percent_value = sel.send(area_percent_key) / 100.0
              puts area_percent_value
              total_integrated_over_time *= area_percent_value
            end
          end

          # Save statistics in the array
          all_stats << {
            subcatchment_id: sel.id,
            field_name: res_field_name,
            sum: total_integrated_over_time ,
            mean: mean_value,
            max: max_value,
            min: min_value,
            steps: count,
            area: sel.total_area
          }
        end

      rescue
        next
      end
    end

  rescue => e
    next
  end
end

# Print the summary header
puts '  *******************************************'
puts '  Subcatchment Runoff Summary (ICM InfoWorks)'
puts '  *******************************************'
puts ''
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts '                            Total      Total      Total      Total    qsurf01    qsurf02      Total       Total     Peak     Runoff    qsurf03    qsurf04    qsurf05    qsurf06    qsurf07    qsurf08    qsurf09    qsurf10    qsurf11    qsurf12'
puts '                           Precip      Runon       Evap      Infil     Runoff     Runoff     Runoff      Runoff   Runoff      Coeff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff'
puts '  Subcatchment                 mm         mm         mm         mm         mm         mm         mm    10^6 ltr      CMS                    mm         mm         mm         mm         mm         mm         mm         mm         mm         mm'
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'

field_width = 10 # Width for the field value
id_width = 21   # Width for the subcatchment ID 

# Initialize a hash to store aggregated data for each subcatchment
aggregated_data = {}

# Aggregate data
all_stats.each do |stat|
  sub_id = stat[:subcatchment_id]
  field_name = stat[:field_name]

  # Initialize subcatchment data if not already present
  aggregated_data[sub_id] ||= {}

  # Store all the statistics for the corresponding field
  aggregated_data[sub_id][field_name] = stat
end

# Print the aggregated data for each subcatchment
aggregated_data.each do |sub_id, data|
  output_line = "#{'%*s ' % [id_width, sub_id]}"

  # Append stats for specific fields to the output line
  # Example for rainfall
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:min]]}"
  end
  if data['evaprate']
    stats = data['evaprate']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qinfsoil']
    stats = data['qinfsoil']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf01']
    stats = data['qsurf01']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf02']
    stats = data['qsurf02']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['runoff']
    stats = data['runoff']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end

  # Similar blocks can be added for other fields like 'evaprate', 'qinfsoil', etc.

  # Example for runoff (with specific calculations for second and third runoff values)
  if data['runoff']
    stats = data['runoff']
    second_runoff = stats[:sum] * 10000.0 / 1000.0 / 1000.0 *  stats[:area] 
    third_runoff  = stats[:max] 
    output_line += " #{'%*.4f' % [field_width, second_runoff]}"
    output_line += " #{'%*.4f' % [field_width, third_runoff]}"
  end

  # Calculate and append runoff coefficient (RC)
rainfall_sum = data['rainfall'] ? data['rainfall'][:sum] : 0
runoff_sum = data['runoff'] ? data['runoff'][:sum] : 0

# Ensure rainfall_sum is not zero to avoid division by zero
if rainfall_sum > 0
  rc = runoff_sum / rainfall_sum
  output_line += " #{'%*.3f' % [field_width, rc]}"
else
  output_line += " #{'%*s' % [field_width, 'N/A']}"  # If no rainfall data, RC cannot be computed
end

# Check and append qsurf03 to qsurf12
(3..12).each do |i|
  key = "qsurf%02d" % i  # Generates qsurf03, qsurf04, ..., qsurf12
  if data[key]
    stats = data[key]
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
end

  puts output_line
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0107 - ICM InfoWorks Results to SWMM5 Subcatchment Runoff Summary\hw_UI_script_MGD.rb" 
# Import the 'date' library
require 'csv'
require 'date'

# Initialize an array to store all statistics
all_stats = []

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the count of timesteps timesteps
ts_size = net.list_timesteps.count

# Get the list of timesteps
ts = net.list_timesteps

# Define the result field names to fetch the results for all selected Subcatchments
field_names = [
  'qfoul', 'qtrade', 'rainfall', 'evaprate', 'grndstor', 'soilstor', 'qsoil',
  'qinfsoil', 'qrdii', 'qinfilt', 'qinfgrnd', 'qground', 'plowfw', 'plowsnow',
  'impfw', 'pervfw', 'impmelt', 'pervmelt', 'impsnow', 'pervsnow', 'losttogw',
  'napi', 'qcatch', 'q_lid_in', 'q_lid_out', 'q_lid_drain', 'q_exceedance',
  'rainprof', 'effrain', 'qbase', 'v_exceedance', 'runoff', 'qsurf01',
  'qsurf02', 'qsurf03', 'qsurf04', 'qsurf05', 'qsurf06', 'qsurf07', 'qsurf08',
  'qsurf09', 'qsurf10', 'qsurf11', 'qsurf12'
]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    ro = net.row_object('_subcatchments', sel.id)
    raise "Object with ID #{sel.id} is not a subcatchment." if ro.nil?

    field_names.each do |res_field_name|
      begin
        rs_size = ro.results(res_field_name).count

        if rs_size == ts_size
          total = 0.0
          total_integrated_over_time = 0.0
          min_value = Float::INFINITY
          max_value = -Float::INFINITY
          count = 0

          # Assuming the time steps are evenly spaced, calculate the time interval in seconds
          time_interval = (ts[1] - ts[0]) * 24 * 60 * 60 if ts.size > 1

          ro.results(res_field_name).each_with_index do |result, time_step_index|
            total += result.to_f
            total_integrated_over_time += result.to_f * time_interval 
            min_value = [min_value, result.to_f].min
            max_value = [max_value, result.to_f].max
            count += 1
          end

          mean_value = count > 0 ? total / count : 0

          total_integrated_over_time /= 3600.0 if res_field_name == 'rainfall'
          total_integrated_over_time = total_integrated_over_time * 12.0 / (sel.total_area * 43560.0) if res_field_name != 'rainfall'      
          (1..12).each do |i|
            field_name = "qsurf%02d" % i
            area_percent_key = "area_percent_#{i}".to_sym
          
            if res_field_name == field_name && sel.respond_to?(area_percent_key)
              area_percent_value = sel.send(area_percent_key) / 100.0
              puts area_percent_value
              total_integrated_over_time *= area_percent_value
            end
          end

          # Save statistics in the array
          all_stats << {
            subcatchment_id: sel.id,
            field_name: res_field_name,
            sum: total_integrated_over_time ,
            mean: mean_value,
            max: max_value,
            min: min_value,
            steps: count,
            area: sel.total_area
          }
        end

      rescue
        next
      end
    end

  rescue => e
    next
  end
end

# Print the summary header
puts '  *******************************************'
puts '  Subcatchment Runoff Summary (ICM InfoWorks)'
puts '  *******************************************'
puts ''
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'
puts '                            Total      Total      Total      Total    qsurf01    qsurf02      Total       Total     Peak     Runoff    qsurf03    qsurf04    qsurf05    qsurf06    qsurf07    qsurf08    qsurf09    qsurf10    qsurf11    qsurf12'
puts '                           Precip      Runon       Evap      Infil     Runoff     Runoff     Runoff      Runoff   Runoff      Coeff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff     Runoff'
puts '  Subcatchment                 in         in         in         in         in         in         in    10^6 ltr      MGD                    in         in         in         in         in         in         in         in         in         in'
puts '  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------'

field_width = 10 # Width for the field value
id_width = 21   # Width for the subcatchment ID 

# Initialize a hash to store aggregated data for each subcatchment
aggregated_data = {}

# Aggregate data
all_stats.each do |stat|
  sub_id = stat[:subcatchment_id]
  field_name = stat[:field_name]

  # Initialize subcatchment data if not already present
  aggregated_data[sub_id] ||= {}

  # Store all the statistics for the corresponding field
  aggregated_data[sub_id][field_name] = stat
end

# Print the aggregated data for each subcatchment
aggregated_data.each do |sub_id, data|
  output_line = "#{'%*s ' % [id_width, sub_id]}"

  # Append stats for specific fields to the output line
  # Example for rainfall
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['rainfall']
    stats = data['rainfall']
    output_line += " #{'%*.3f' % [field_width, stats[:min]]}"
  end
  if data['evaprate']
    stats = data['evaprate']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qinfsoil']
    stats = data['qinfsoil']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf01']
    stats = data['qsurf01']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['qsurf02']
    stats = data['qsurf02']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
  if data['runoff']
    stats = data['runoff']
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end

  # Similar blocks can be added for other fields like 'evaprate', 'qinfsoil', etc.

  # Example for runoff (with specific calculations for second and third runoff values)
  if data['runoff']
    stats = data['runoff']
    second_runoff = stats[:sum] * 43560.0 / 12.0 *  stats[:area] 
    third_runoff  = stats[:max] 
    output_line += " #{'%*.4f' % [field_width, second_runoff]}"
    output_line += " #{'%*.4f' % [field_width, third_runoff]}"
  end

  # Calculate and append runoff coefficient (RC)
rainfall_sum = data['rainfall'] ? data['rainfall'][:sum] : 0
runoff_sum = data['runoff'] ? data['runoff'][:sum] : 0

# Ensure rainfall_sum is not zero to avoid division by zero
if rainfall_sum > 0
  rc = runoff_sum / rainfall_sum
  output_line += " #{'%*.3f' % [field_width, rc]}"
else
  output_line += " #{'%*s' % [field_width, 'N/A']}"  # If no rainfall data, RC cannot be computed
end

# Check and append qsurf03 to qsurf12
(3..12).each do |i|
  key = "qsurf%02d" % i  # Generates qsurf03, qsurf04, ..., qsurf12
  if data[key]
    stats = data[key]
    output_line += " #{'%*.3f' % [field_width, stats[:sum]]}"
  end
end

  puts output_line
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0108 - Spatial Scripts\1_split_link_into_chunks.rb" 
require_relative 'spatial'

DEFAULT_CHUNK_SIZE = 10.0
size = DEFAULT_CHUNK_SIZE

# Prompt user for size
# size = WSApplication.input_box("Specify a chunk size", "Split Lines into Chunks", DEFAULT_CHUNK_SIZE.to_s)
# size = size.to_f

network = WSApplication.current_network()
network.transaction_begin

network.row_objects_selection('wn_pipe').each do |link|
  InnoSpatial.split_link_into_chunks(network, link, size)
end

network.transaction_commit
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0108 - Spatial Scripts\2_split_links_around_node.rb" 
require_relative 'spatial'

DEFAULT_DISTANCE = 1.5
distance = DEFAULT_DISTANCE

# Prompt user for distance
# distance = WSApplication.input_box("Specify a distance", "Split Links Around Nodes", DEFAULT_DISTANCE.to_s)
# distance = distance.to_f

network = WSApplication.current_network()
network.transaction_begin

network.row_objects_selection('_nodes').each do |node|
  InnoSpatial.split_links_around_node(network, node, distance)
end

network.transaction_commit
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0108 - Spatial Scripts\spatial.rb" 
# Some parts of this code were adapted from the Turf.js library
# https://turfjs.org/
# https://github.com/Turfjs/turf

module InnoSpatial
  extend self

  # Splits all links around a node.
  #
  # @param network [WSOpenNetwork]
  # @param node [WSNode]
  # @param distance [Numeric] actual distance from the node to split
  def split_links_around_node(network, node, distance)
    node.us_links.each { |link| split_link_at_distance(network, link, link_length(link) - distance) }
    node.ds_links.each { |link| split_link_at_distance(network, link, distance) }
  end

  # Splits a link into chunks / segments. Optionally normalizes the size so that they are evenly spaced out, rather
  # than leaving an arbitrary short section at the end.
  #
  # @param network [WSOpenNetwork]
  # @param link [WSLink]
  # @chunk_size [Numeric] length of each chunk
  # @param normalize [Boolean] whether to normalize the chunk sizes (avoid annoying small lines at the ends)
  def split_link_into_chunks(network, link, chunk_size, normalize = true)
    length = InnoSpatial.link_length(link)

    if chunk_size >= length
      puts format("Cannot split link %s of length %0.2fm into chunks of size %0.2fm", link.id, length, chunk_size)
      return
    end

    segments = (length / chunk_size).floor
    if normalize
      chunk_size_norm = (length / segments)
      (segments - 1).times do |i|
        InnoSpatial.split_link_at_distance(network, link, chunk_size_norm, i + 1)
      end
    else
      segments.times do |i|
        InnoSpatial.split_link_at_distance(network, link, chunk_size, i + 1)
      end
    end
  end

  # Splits a link at the specified distance. A new node is generated using the link asset_id e.g. Badger_1
  #
  # @param network [WSOpenNetwork]
  # @param link [WSLink] the link to split, this becomes the post link (i.e. after the split)
  # @param distance [Numeric] actual distance along the link to make the split
  # @param node_i [Integer] optional index for the new node name, useful when chaining splits
  def split_link_at_distance(network, link, distance, node_i = 1)
    # Validate we're not trying to do something daft
    link_length = link_length(link)
    if distance >= link_length
      puts format("Link %s has length of %0.2f, cannot split with distance of %0.2f", link.id, link_length, distance)
      return
    end

    index = 0 # Current vertex index, so we know where we split
    split_node = nil # The new node at the split
    travelled = 0 # Distance travelled so far as we iterate the link segments

    iterate_link_segments(link) do |seg|
      # Calculate the length of this segment and check if this is the segment we need to split at
      length = distance(*seg)

      if travelled + length > distance
        # Split at this segment
        percent = (distance - travelled) / length # How far along this segment are we?

        # Create the node
        split_node = network.new_row_object('wn_node')
        split_node.id = format("%s_%i", link['asset_id'], node_i)
        split_node['x'] = lerp(seg[0], seg[2], percent)
        split_node['y'] = lerp(seg[1], seg[3], percent)
        split_node['z'] = lerp(link.us_node['z'], link.ds_node['z'], distance / link_length) # Lerp between US and DS elevation
        split_node['ground_level'] = lerp(link.us_node['ground_level'], link.ds_node['ground_level'], distance / link_length) # Lerp between US and DS elevation
        split_node.write
        break
      else
        # Haven't reached distance yet
        travelled += length
        index += 1
      end
    end

    # Create a new bends array for the pre and post links
    pre_bends, post_bends = [], []
    link['bends'].each_slice(2).with_index do |xy, i|
      if i > index
        post_bends = post_bends + xy
      elsif i == index
        split_xy = [split_node['x'], split_node['y']]
        pre_bends = pre_bends + xy + split_xy
        post_bends = post_bends + split_xy
      else
        pre_bends = pre_bends + xy
      end
    end

    # Create a new link, copy all fields across
    new_link = network.new_row_object('wn_pipe')
    link.table_info.fields.each do |field|
      new_link[field.name] = link[field.name]
    end

    # The new link becomes the pre-split link
    new_link['bends'] = pre_bends
    new_link['ds_node_id'] = split_node.id
    new_link.write

    # The existing link becomes the post-split link (to make it easy to chain operations i.e. line chunks)
    link['bends'] = post_bends
    link['us_node_id'] = split_node.id
    link.write
  end

  # Calculate the euclidean length of a link.
  #
  # @param link [WSLink]
  # @return [Numeric] the length
  def link_length(link)
    length = 0

    iterate_link_segments(link) do |segment|
      length += distance(*segment)
    end

    return length
  end

  # Find the euclidean (i.e. 2D) distance between two xy coordinates.
  #
  # @param ax [Numeric]
  # @param ay [Numeric]
  # @param bx [Numeric]
  # @param by [Numeric]
  # @return [Numeric] distance between the points
  def distance(ax, ay, bx, by)
    return Math.sqrt((ax - bx) ** 2 + (ay - by) ** 2)
  end

  # Iterates over link segments with overlap, yielding the array of coordinates
  # i.e. [ax, ay, bx, by], [bx, by, cx, cy]
  #
  # @param link [WSLink]
  def iterate_link_segments(link)
    bends = link['bends']
    i = 0

    while i < bends.length - 2
      s = bends[i,4]
      yield(s)
      i += 2
    end
  end

  # Lerp between two floats
  #
  # @param a [Numeric]
  # @param b [Numeric]
  # @param percent [Numeric] value (clamped between 0-1)
  # @return [Numeric]
  def lerp(a, b, percent)
    pct = percent.clamp(0, 1)
    return (1 - pct) * a + pct * b
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0109 - Statistics for Node User Numbers\hw_UI_script.rb" 
def print_csv_node_file(net)
	
	# Define database fields for InfoWorks network nodes
	database_fields = [
	  'user_number_1',
	  'user_number_2',
	  'user_number_3',
	  'user_number_4',
	  'user_number_5',
	  'user_number_6',
	  'user_number_7',
	  'user_number_8',
	  'user_number_9',
	  'user_number_10'
	]

	net.clear_selection
	puts "Scenario     : #{net.current_scenario}"
  
	# Prepare hash for storing data of each field for database_fields
	fields_data = {}
	database_fields.each { |field| fields_data[field] = [] }
  
	# Initialize the count of processed rows
	row_count = 0
	total_expected = 0.0
  
	# Collect data for each field from sw_node
	net.row_objects('hw_node').each do |ro|
	  row_count += 1
	  database_fields.each do |field|
		fields_data[field] << ro[field] if ro[field]
	  end
	end
  
	# Print min, max, mean, standard deviation, total, and row count for each field
	database_fields.each do |field|
	  data = fields_data[field]
	  if data.empty?
		#puts "#{field} has no data!"
		next
	  end

	 	  
	  min_value = data.min
	  max_value = data.max
	  sum = data.inject(0.0) { |sum, val| sum + val }
	  mean_value = sum / data.size
	  # Calculate the standard deviation
	  sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
	  standard_deviation = Math.sqrt(sum_of_squares / data.size)
	  total_value = sum
  
	  # Updated printf statement with row count
	  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
			 field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
	end
end
  
  # Usage example
  net = WSApplication.current_network
  print_csv_node_file(net) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0109 - Statistics for Node User Numbers\sw_UI_script.rb" 
def print_csv_node_file(net)
	
	# Define database fields for SWMM network nodes
	database_fields = [
	  "invert_elevation",
	  "ground_level",
	  "maximum_depth",
	  "initial_depth",
	  "surcharge_depth",
	  "ponded_area",
	  "inflow_baseline", 
	  "inflow_scaling",
	  "base_flow",
	  'user_number_1',
	  'user_number_2',
	  'user_number_3',
	  'user_number_4',
	  'user_number_5',
	  'user_number_6',
	  'user_number_7',
	  'user_number_8',
	  'user_number_9',
	  'user_number_10'
	]

	net.clear_selection
	puts "Scenario     : #{net.current_scenario}"
  
	# Prepare hash for storing data of each field for database_fields
	fields_data = {}
	database_fields.each { |field| fields_data[field] = [] }
  
	# Initialize the count of processed rows
	row_count = 0
	total_expected = 0.0
  
	# Collect data for each field from sw_node
	net.row_objects('sw_node').each do |ro|
	  row_count += 1
	  database_fields.each do |field|
		fields_data[field] << ro[field] if ro[field]
	  end
	end
  
	# Print min, max, mean, standard deviation, total, and row count for each field
	database_fields.each do |field|
	  data = fields_data[field]
	  if data.empty?
		#puts "#{field} has no data!"
		next
	  end

	 	  
	  min_value = data.min
	  max_value = data.max
	  sum = data.inject(0.0) { |sum, val| sum + val }
	  mean_value = sum / data.size
	  # Calculate the standard deviation
	  sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
	  standard_deviation = Math.sqrt(sum_of_squares / data.size)
	  total_value = sum
  
	  # Updated printf statement with row count
	  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
			 field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
	end
end
  
  # Usage example
  net = WSApplication.current_network
  print_csv_node_file(net) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0110 - Statistics for Link User Numbers\hw_UI_script.rb" 
def print_csv_inflows_file(net)
	
	# Define database fields for SWMM network nodes
	database_fields = [
		'us_invert',
		'ds_invert',
		'conduit_length',
		'conduit_height',
		'conduit_width',
		'number_of_barrels',
		'user_number_1',
		'user_number_2',
		'user_number_3',
		'user_number_4',
		'user_number_5',
		'user_number_6',
		'user_number_7',
		'user_number_8',
		'user_number_9',
		'user_number_10'
	]

	net.clear_selection
	puts "Scenario     : #{net.current_scenario}"
  
	# Prepare hash for storing data of each field for database_fields
	fields_data = {}
	database_fields.each { |field| fields_data[field] = [] }
  
	# Initialize the count of processed rows
	row_count = 0
	total_expected = 0.0
  
	# Collect data for each field from sw_node
	net.row_objects('hw_conduit').each do |ro|
	  row_count += 1
	  database_fields.each do |field|
		fields_data[field] << ro[field] if ro[field]
	  end
	end
  
	# Print min, max, mean, standard deviation, total, and row count for each field
	database_fields.each do |field|
	  data = fields_data[field]
	  if data.empty?
		#puts "#{field} has no data!"
		next
	  end

	 	  
	  min_value = data.min
	  max_value = data.max
	  sum = data.inject(0.0) { |sum, val| sum + val }
	  mean_value = sum / data.size
	  # Calculate the standard deviation
	  sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
	  standard_deviation = Math.sqrt(sum_of_squares / data.size)
	  total_value = sum
  
	  # Updated printf statement with row count
	  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
			 field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
	end
end
  
  # Usage example
  net = WSApplication.current_network
  print_csv_inflows_file(net) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0110 - Statistics for Link User Numbers\sw_UI_script.rb" 
def print_csv_inflows_file(net)
	
	# Define database fields for SWMM network nodes
	database_fields = [
		'us_invert',
		'ds_invert',
		'length',
		'conduit_height',
		'conduit_width',
		'number_of_barrels',
		'user_number_1',
		'user_number_2',
		'user_number_3',
		'user_number_4',
		'user_number_5',
		'user_number_6',
		'user_number_7',
		'user_number_8',
		'user_number_9',
		'user_number_10'
	]

	net.clear_selection
	puts "Scenario     : #{net.current_scenario}"
  
	# Prepare hash for storing data of each field for database_fields
	fields_data = {}
	database_fields.each { |field| fields_data[field] = [] }
  
	# Initialize the count of processed rows
	row_count = 0
	total_expected = 0.0
  
	# Collect data for each field from sw_node
	net.row_objects('sw_conduit').each do |ro|
	  row_count += 1
	  database_fields.each do |field|
		fields_data[field] << ro[field] if ro[field]
	  end
	end
  
	# Print min, max, mean, standard deviation, total, and row count for each field
	database_fields.each do |field|
	  data = fields_data[field]
	  if data.empty?
		#puts "#{field} has no data!"
		next
	  end

	 	  
	  min_value = data.min
	  max_value = data.max
	  sum = data.inject(0.0) { |sum, val| sum + val }
	  mean_value = sum / data.size
	  # Calculate the standard deviation
	  sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
	  standard_deviation = Math.sqrt(sum_of_squares / data.size)
	  total_value = sum
  
	  # Updated printf statement with row count
	  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
			 field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
	end
end
  
  # Usage example
  net = WSApplication.current_network
  print_csv_inflows_file(net) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0111 - All Node and Link URL Stats\hw_UI_script.rb" 
# Define the result fields for the HW_NODE table
hw_node_fields = ["depnod", "flood_level", "flooddepth", "floodvolume", "flvol", "max_depnod",
 "max_flooddepth", "max_floodvolume", "max_flvol", "max_qinfnod", "max_qnode", "max_qrain", 
 "qincum", "qinfnod", "qnode", "qrain", "vflood", "vground", "max_volume", "volbal", "volume", "pcvolbal"]

# Define the result fields for the HW_CONDUIT table
hw_conduit_fields = ["height", "HYDGRAD", "length", "max_qinflnk", "max_qlink", "max_Surcharge",
 "max_us_depth", "max_us_flow", "max_us_froude", "max_us_totalhead", "max_us_vel", "maxsurchargestate", 
 "pfc", "qinflnk", "qlicum", "qlink", "Surcharge", "type", "us_depth", "us_flow", "us_froude", "us_invert", 
 "us_qcum", "us_totalhead", "us_vel", "volume", "ds_depth", "ds_flow", "ds_froude", "ds_invert", "ds_qcum", 
 "ds_totalhead", "ds_vel", "max_ds_depth", "max_ds_flow", "max_ds_froude", "max_ds_totalhead", "max_ds_vel"]

 # Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Calculate the time interval in minutes assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs 
puts time_interval  

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name for downstream depth
res_field_name = 'ds_depth'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Find the maximum value and its index
      max_value = results.first.to_f
      max_index = 0

      results.each_with_index do |result, index|
        val = result.to_f
        if val > max_value
          max_value = val
          max_index = index
        end
      end

      # Get the time of maximum depth
      max_time = ts[max_index]

        # Calculate total seconds from the given time
        total_seconds = max_index * time_interval

        # Assuming total_seconds is calculated correctly as an integer value
        days = total_seconds / (24 * 3600)           # Calculates the number of days
        remaining_seconds = total_seconds % (24 * 3600)  # Remaining seconds after extracting days
        hours = remaining_seconds / 3600             # Calculates the number of hours
        remaining_seconds %= 3600                    # Remaining seconds after extracting hours
        minutes = remaining_seconds / 60             # Calculates the number of minutes
        seconds = remaining_seconds % 60             # Remaining seconds after extracting minutes

        # Format the time into a readable string with integer values
        formatted_time = "#{days}d #{hours}h #{minutes}m #{seconds}s"

        # Print the information with formatted maximum time
        puts "Link ID: #{sel.id}             Max DS Depth: #{'%9.3f' % max_value} at Time: #{formatted_time}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end

  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0112 - Add Nine 1D Results Points\hw_UI_script.rb" 

begin
    # Accessing current network
    net = WSApplication.current_network
    raise "Error: current network not found" if net.nil?
  
    # Accesing Row objects or collection of row objects 
    # There are four types of row objects: '_nodes', '_links', '_subcatchments', '_others'.
  
    # Get all the nodes or links or subcatchments as row object collection
    nodes_roc = net.row_object_collection('_nodes')
    raise "Error: nodes not found" if nodes_roc.nil?
  
    links_roc = net.row_object_collection('_links')
    raise "Error: links not found" if links_roc.nil?

    net.transaction_begin

    # Define the percentages at which to add result points
    percentages = [10, 20, 30, 40, 50, 60, 70, 80, 90]

    # Iterate through the selected links
    net.row_objects('hw_conduit').each do |ro|
        next unless ro.selected
    
        # Get the upstream and downstream nodes
        us_node_id = ro.us_node_id
        ds_node_id = ro.ds_node_id
        us_node = net.row_object('hw_node', us_node_id)
        ds_node = net.row_object('hw_node', ds_node_id)
    
        # Get the x, y coordinates of the upstream and downstream nodes
        us_x, us_y = us_node.x, us_node.y
        ds_x, ds_y = ds_node.x, ds_node.y
    
        # Iterate through the percentages
        percentages.each do |percentage|
        # Calculate the position along the link at which to add the result point
        position_x = us_x + (ds_x - us_x) * (percentage / 100.0)
        position_y = us_y + (ds_y - us_y) * (percentage / 100.0)
    
        # Create a new hw_1d_results_point
        result_point = net.new_row_object('hw_1d_results_point')
    
        # Set the properties of the new hw_1d_results_point
        result_point.point_id = "#{us_node_id}_#{percentage}"
        result_point.point_x = position_x
        result_point.point_y = position_y
        result_point.link_suffix = ro.link_suffix
        result_point.us_node_id = us_node_id
        result_point.start_length = ro.conduit_length * (percentage / 100.0)
    
        # Write the new hw_1d_results_point to the database
        result_point.write
        end
    end

    net.transaction_commit
    # clear selection
    net.clear_selection
  
rescue => e
    puts "Error: #{e.message}"
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0114 - GIS Export of Data Tables\hw_UI-GIS_export.rb" 
# INTERFACE SCRIPT
# Export CCTV Surveys & Manhole Surveys to GIS file via GIS_export method

nw=WSApplication.current_network

# Create an array for the tables to be exported
export_tables = ["hw_node","hw_conduit","hw_subcatchment"]

# Create a hash for the export options override the defaults
exp_options=Hash.new
exp_options['ExportFlags'] = false				# Boolean | Default = FALSE
exp_options['SkipEmptyTables'] = false			# Boolean | Default = FALSE
exp_options['Tables'] = export_tables			# Array of strings - If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.
#exp_options['Feature Dataset'] = 				# String | for GeoDatabases, the name of the feature dataset. Default=nil
#exp_options['UseArcGISCompatibility'] = false	# Boolean | Default = FALSE

# Export
nw.GIS_export(
	'SHP',							            # Format: SHP,TAB,MIF,GDB
	exp_options,				            	# Specified options override the default options
	'C:\Temp\ICM_Ruby_Network\InfoSewer'		# Export destination folder & filename prefix
) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0114 - GIS Export of Data Tables\sw_UI-GIS_export.rb" 
nw=WSApplication.current_network

# Create an array for the tables to be exported
export_tables = ["sw_node","sw_conduit","sw_subcatchment"]

# Create a hash for the export options override the defaults
exp_options=Hash.new
exp_options['ExportFlags'] = false				# Boolean | Default = FALSE
exp_options['SkipEmptyTables'] = false			# Boolean | Default = FALSE
exp_options['Tables'] = export_tables			# Array of strings - If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.
#exp_options['Feature Dataset'] = 				# String | for GeoDatabases, the name of the feature dataset. Default=nil
#exp_options['UseArcGISCompatibility'] = false	# Boolean | Default = FALSE

# Export
nw.GIS_export(
	'SHP',							        # Format: SHP,TAB,MIF,GDB
	exp_options,				            # Specified options override the default options
	'C:\Temp\ICM_Ruby_Network\InfoSWMM'		# Export destination folder & filename prefix
) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0116 - Export Choice List values\UI-ExportChoiceListValues.rb" 
## Export Choice List values from the database/network

require 'csv'											##call on the Ruby library CSV function

CSV.open("c:\\temp\\choices.csv", "wb") do |csv|		##open the CSV file and iterate through it

	nw = WSApplication.current_network					##use the current open network
	
		fc = nw.field_choices('cams_cctv_survey','category_code')					##select the Field Choice ‘text’ codes for: CCTV Survey – Category Code
		
		fd = nw.field_choice_descriptions('cams_cctv_survey','category_code')		##select the Field Choice descriptions codes for: CCTV Survey – Category Code
		
		i=0										##this starts a counter, needed to iterate through all the values
		
		tbl='cams_cctv_survey'					##sets a table name variable for the export
		
		col='category_code'						##sets a field name variable for the export
		
		if fc and fd then						##runs both fc & fd together
		
			fc.each do | value|											##runs through each fc to retrieve all values
			
			puts("""#{tbl}"",""#{col}"",""#{value}"",""#{fd[i]}""")		##where the output should go: to screen (“puts”) and what the output should be
			
			csv << ["#{tbl}", "#{col}", "#{value}", "#{fd[i]}"]			##where the output should go: csv (“<<” inserts as an additional line) and what the output should be
			
			i=i+1														##add 1 to the interaction counter
			
			end
		end
 
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0117 - Import-Export Snapshot file\IE-snapshot_export_ex.rb" 
begin

db = WSApplication.open('localhost:40000/IA_NEW',false)
nw = db.model_object_from_type_and_id('Collection Network', 1246)
nw.update
on = nw.open

exp=Hash.new
exp['SelectedOnly'] = false
exp['IncludeImageFiles'] = 	false
exp['IncludeGeoPlanPropertiesAndThemes'] = 	false
#exp['ChangesFromVersion'] = nil
#exp['Tables'] = ["cams_cctv_survey"]

on.snapshot_export_ex('export.isfc',exp)

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0117 - Import-Export Snapshot file\UI-snapshot_export_ex.rb" 
# Export to Snapshot File via snapshot_export_ex method


exportloc = WSApplication.file_dialog(false,'isfc','Collection Network Snapshot File','snapshot',false,false) # Save As dialog for export
if exportloc==nil
	WSApplication.message_box('Export location required','OK','!',nil)
else

nw=WSApplication.current_network

# Create an array for the tables to be exported
export_tables = ["cams_cctv_survey","cams_manhole_survey"]

# Create a hash for the export options override the defaults
exp_options=Hash.new
exp_options['SelectedOnly'] = true									# Boolean | Default = FALSE
exp_options['IncludeImageFiles'] = 	true							# Boolean | Default = FALSE
#exp_options['IncludeGeoPlanPropertiesAndThemes'] = 	false		# Boolean | Default = FALSE
#options['ChangesFromVersion'] = 									# Integer | Default = 0
#exp_options['Tables'] = export_tables								# Array of strings - If present, a list of the internal table names (as returned by the table_names method of this class) If not present then all tables will be exported.

# Export
nw.snapshot_export_ex(
	exportloc,			# Export destination file
	exp_options        	# Specified options override the default options
)

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0118 - Bulk Data Import\IE-Snapshot-Bulk-Import.rb" 
begin

# Open an InfoAsset Manager database.
db = WSApplication.open('localhost:40000/IA_2020.2',false)

# Choose Network to Import into.
nw = db.model_object_from_type_and_id('Collection Network', 32)

# Choose import source parent directory, subfolders will be included.
dir = 'C:/Temp/Data/'

# State which file type extensions are to be used. Separate each by a comma(,).
ext = 'isfc,isf'


# Open the network
on = nw.open

# Update network before importing snapshot files
nw.update

# Create a hash for the options of the import method
options=Hash.new
options['AllowDeletes'] = true									#Boolean
options['ImportGeoPlanPropertiesAndThemes'] = false				#Boolean
options['UpdateExistingObjectsFoundByID'] = false 				#Boolean
options['UpdateExistingObjectsFoundByUID'] = true				#Boolean
options['ImportImageFiles'] = true								#Boolean


puts "Data location: #{dir}"

# Identify files in the directory and import
Dir.glob(dir+'**/*.{'+ext+'}').each do |fname|
	puts "Importing #{fname}"
    on.snapshot_import_ex(fname, options)	# Set the import method. Currently: snapshot_import_ex
end

puts "Import complete."


# Commit network
nw.commit("#{ext} data imported from #{dir}")

puts "Network committed."

end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0118 - Bulk Data Import\UI-Snapshot-Bulk-Import-Filename.rb" 
#Import a file with a non-specific filename
#Import a .isfc file from the diretcory with 'survey' within the name

begin

# Open the current InfoAsset Manager Network.
nw=WSApplication.current_network


# Identify files in the directory & sub-directories and import
Dir.glob('C:/Temp/data/**/*'+'survey'+'*.isfc').each do |fname|
	puts "Importing #{fname}"
   nw.snapshot_import_ex(fname, nil)
end

puts "Import complete."

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0118 - Bulk Data Import\UI-Snapshot-Bulk-Import.rb" 
begin

# Open the current InfoAsset Manager Network.
nw=WSApplication.current_network

# Choose import source parent directory, subfolders will be included.
dir = "C:/Temp/Data/"

# State which file type extensions are to be used. Separate each by a comma(,).
ext = 'isfc,isf'
#ext = 'xml'


# Create a hash for the options of the import method
options=Hash.new
options['AllowDeletes'] = true									#Boolean
options['ImportGeoPlanPropertiesAndThemes'] = false				#Boolean
options['UpdateExistingObjectsFoundByID'] = false 				#Boolean
options['UpdateExistingObjectsFoundByUID'] = true				#Boolean
options['ImportImageFiles'] = true								#Boolean

# Start a transaction so all files imports are one transaction,. not available for all methods
#nw.transaction_begin

puts "Data location: #{dir}"

# Identify files in the directory and sub-directories
Dir.glob(dir+'**/*.{'+ext+'}').each do |fname|
	puts "Importing #{fname}"
   nw.snapshot_import_ex(fname, options)	# Set the import method and parameters. Currently: snapshot_import_ex
   #nw.mscc_import_cctv_surveys(fname, 'KT', false, 2, false, dir)
end

puts "Import complete."

#nw.transaction_commit

end

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0119 -  Export to CSV\UI-CSV_export-selection.rb" 
# Export a selection which you create to CSV file(s) via csv_export method

# Use the current network
nw=WSApplication.current_network

# Make a selecion of objects based on type
nw.clear_selection
nw.row_objects('cams_cctv_survey').each do |ro|
	ro.selected=true
end

# Create a hash for the export options override the defaults
exp_options=Hash.new
#exp_options['Use Display Precision'] = true		# Boolean | Default = true
#exp_options['Field Descriptions'] = false			# Boolean | Default = false
#exp_options['Field Names'] = true					# Boolean | Default = true
#exp_options['Flag Fields '] = true					# Boolean | Default = true
#exp_options['Multiple Files'] = false				# Boolean | Default = false; Set to true to export to different files, false to export to the same file
#exp_options['Native System Types'] = false		# Boolean | Default = false
#exp_options['User Units'] = false					# Boolean | Default = false
#exp_options['Object Types'] = false				# Boolean | Default = false
exp_options['Selection Only'] = true				# Boolean | Default = false
#exp_options['Units Text'] = false					# Boolean | Default = false
#exp_options['Coordinate Arrays Format'] = 'Packed'	# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['Other Arrays Format'] = 'Packed'		# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['WGS84'] = false						# Boolean | Default = false; Set to true to convert coordinate values into WGS84


# Export the data
nw.csv_export(
	'C:\Temp\network.csv',		# Export destination folder & filename
	exp_options					# Specified options override the default options
) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0119 -  Export to CSV\UI-CSV_export.rb" 
# Export to CSV file(s) via csv_export method

nw=WSApplication.current_network

# Create a hash for the export options override the defaults
exp_options=Hash.new
#exp_options['Use Display Precision'] = true		# Boolean | Default = true
#exp_options['Field Descriptions'] = false			# Boolean | Default = false
#exp_options['Field Names'] = true					# Boolean | Default = true
#exp_options['Flag Fields '] = true					# Boolean | Default = true
#exp_options['Multiple Files'] = false				# Boolean | Default = false; Set to true to export to different files, false to export to the same file
#exp_options['Native System Types'] = false			# Boolean | Default = false
#exp_options['User Units'] = false					# Boolean | Default = false
#exp_options['Object Types'] = false				# Boolean | Default = false
#exp_options['Selection Only'] = false				# Boolean | Default = false
#exp_options['Units Text'] = false					# Boolean | Default = false
#exp_options['Coordinate Arrays Format'] = 'Packed'	# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['Other Arrays Format'] = 'Packed'		# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['WGS84'] = false						# Boolean | Default = false; Set to true to convert coordinate values into WGS84


# Export the data
nw.csv_export(
	'C:\Temp\network.csv'		# Export destination folder & filename
	exp_options					# Specified options override the default options
) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0119 -  Export to CSV\UIIE-CSV_export.rb" 
# Export to CSV file(s) via csv_export method

if WSApplication.ui?
	net=WSApplication.current_network		## Uses current open network when run in UI
else
	db=WSApplication.open
	dbnet=db.model_object_from_type_and_id 'Collection Network',2		## Run on Collection Network #2 in IE
	net=dbnet.open
end

# Create a hash for the export options override the defaults
exp_options=Hash.new
#exp_options['Use Display Precision'] = true		# Boolean | Default = true
#exp_options['Field Descriptions'] = false			# Boolean | Default = false
#exp_options['Field Names'] = true					# Boolean | Default = true
#exp_options['Flag Fields '] = true					# Boolean | Default = true
#exp_options['Multiple Files'] = false				# Boolean | Default = false; Set to true to export to different files, false to export to the same file
#exp_options['Native System Types'] = false			# Boolean | Default = false
#exp_options['User Units'] = false					# Boolean | Default = false
#exp_options['Object Types'] = false				# Boolean | Default = false
#exp_options['Selection Only'] = false				# Boolean | Default = false
#exp_options['Units Text'] = false					# Boolean | Default = false
#exp_options['Coordinate Arrays Format'] = 'Packed'	# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['Other Arrays Format'] = 'Packed'		# String | Default = Packed. Either: Packed, None, or Separate
#exp_options['WGS84'] = false						# Boolean | Default = false; Set to true to convert coordinate values into WGS84


# Export the data
net.csv_export(
	'C:\Temp\network.csv',		# Export destination folder & filename
	exp_options					# Specified options override the default options
) 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0120 -  Import-Export  XML\IE-befdss_export.rb" 
begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )

	log='C:\\temp\\log.txt'
	file='C:\\temp\\export.xml'

	#nw.befdss_export(Filename,Type,Images,SelectedSurveysOnly,LogFile)
	nw.befdss_export(file,'DP',true,false,log)

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0120 -  Import-Export  XML\IE-befdss_import_cctv-BulkImport.rb" 
begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )
	net=nw.open

	dir='C:/source/'	## Folder containing XML files to import

	puts "Data location: #{dir}"

	Dir.glob(dir+'**/*.xml').each do |fname|
		log='log_'+File.basename(fname)+'.txt'
		puts "Importing #{fname}"
		net.befdss_import_cctv(fname,'KT',false,false,1,false,log)
	end

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0120 -  Import-Export  XML\IE-befdss_import_cctv.rb" 
begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )

	log='C:\\temp\\log.txt'
	file='C:\\temp\\BEFDSS_01_01_DP.xml'

	#nw.befdss_import_cctv(Filename,Flag,Images,MatchExisting,GenerateIDsFrom,DuplicateIDs,LogFile)
	nw.befdss_import_cctv(file,'KT',true,false,1,false,log)

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0120 -  Import-Export  XML\IE-befdss_import_manhole_surveys.rb" 
begin
	db = WSApplication.open('//localhost:40000/MasterDatabase', false)
	nw = db.model_object_from_type_and_id('Collection Network',123 )

	log='C:\\temp\\log.txt'
	file='C:\\temp\\BEFDSS_01_01_M.xml'

	#nw.befdss_import_manhole_surveys(Filename,Flag,false,MatchExisting,GenerateIDsFrom,false,LogFile)
	nw.befdss_import_manhole_surveys(file,'KT',false,false,1,false,log)

end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0121 - Find Duplicate Link IDs\DuplicateLinkIDs.rb" 
nw=WSApplication.current_network
arr=nw.row_objects('_links')
links=Hash.new
arr.each do |o|
if links.has_key? o.id
puts "Duplicate ID #{o.id} found in tables #{o.table} and #{links[o.id]}"
else
links[o.id]=o.table
end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0122 -  Update from external CSV\UI-UpdateFromExternalCSV.rb" 
require "csv"

first=true
myHash=Hash.new
File.open (File.dirname(WSApplication.script_file) + '\\test.csv') do |f|
	f.each_line do |l|
		if first
			first=false
		else
			l.chomp!
			arr=CSV.parse_line(l)
			if !myHash.has_key? arr[0]
				fred=Array.new
				fred << nil
				fred << nil
				myHash[arr[0]]=fred
			end
			if myHash[arr[0]][0].nil? || arr[2]>myHash[arr[0]][0]
				myHash[arr[0]][0]=arr[0]
				myHash[arr[0]][1]=arr[1]
			end
		end
	end
end

db=WSApplication.current_network 
db.transaction_begin

db.row_objects('cams_manhole').each do |v|	
if myHash.has_key? v.user_text_1
		val=myHash.values_at(v.user_text_1)
puts val[0].to_s
		v.user_text_2=val[0][1].to_s
		v.write
	end
end

db.transaction_commit 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0123 - Update an object with values of another object through comparison\UI-CountConnections.rb" 
##Count the quantity of Connection Pipes with user_text_1 unique values.
net=WSApplication.current_network
connections=Hash.new
net.row_objects('cams_connection_pipe').each do |p|
		connection=p.user_text_1.downcase
	if !connection.nil? && connection.length>0
			if !connections.has_key? connection
				connections[connection]=1
			elsif connections.has_key? connection
				connections[connection]+=
		end
	end
end
##Write the count of Connection Pipes onto the Pipe based on the Asset ID
puts connections
net.transaction_begin
net.row_objects('cams_pipe').each do |i|
	connection=i.asset_id.downcase
	if !connection.nil?
		if connections.has_key? connection
			i.user_text_5=connections[connection]
			i.write
		end
	end
end
net.transaction_commit
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0123 - Update an object with values of another object through comparison\UI-CountRepairs.rb" 
##Count the quantity of 'Reactive Network' Pipe Repairs (user_text_8) based on Asset ID (user_text_10) and write to Pipe.
net=WSApplication.current_network
repairs=Hash.new
net.row_objects('cams_pipe_repair').each do |p|
	type=p.user_text_8.downcase
	if !type.nil? && type.length>0 && type=='reactive network'
		repair=p.user_text_10.downcase
		if !repair.nil? && repair.length>0
				if !repairs.has_key? repair
					repairs[repair]=1
				elsif repairs.has_key? repair
					repairs[repair]+=1
			end
		end
	end
end
##Write the count of 'Reactive Network' Pipe Repairs onto the Pipe based on the Asset ID
puts repairs
net.transaction_begin
net.row_objects('cams_pipe').each do |i|
	repair=i.asset_id.downcase
	if !repair.nil?
		if repairs.has_key? repair
			i.user_text_6=repairs[repair]
			i.write
		end
	end
end
net.transaction_commit
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0123 - Update an object with values of another object through comparison\UI-UpdateBlockagePropertyID.rb" 
net=WSApplication.current_network
properties=Hash.new
net.row_objects('cams_property').each do |p|
		id=p.id
		address=p.property_address.downcase
	if !address.nil? && address.length>0
			if !properties.has_key? address
				properties[address]=id
		end
	end
end
net.transaction_begin
net.row_objects('cams_incident_blockage').each do |i|
	if !i.property_id.nil? && i.property_id.length==0
		address=i.location.downcase
		if !address.nil?
			if properties.has_key? address
				i.property_id=properties[address]
				i.write
			end
		end
	end
end
net.transaction_commit
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0123 - Update an object with values of another object through comparison\UI-UpdateObjectFromObject_ByPrompt_3.rb" 
net=WSApplication.current_network

assets='cams_channel','cams_connection_node','cams_connection_pipe','cams_data_logger','cams_defence_area','cams_defence_structure','cams_flume','cams_general_asset','cams_general_line','cams_generator','cams_manhole','cams_orifice','cams_outlet','cams_pipe','cams_pump','cams_pump_station','cams_screen','cams_siphon','cams_sluice','cams_storage','cams_wtw','cams_ancillary','cams_valve','cams_vortex','cams_weir'
surveys='cams_cctv_survey','cams_cross_section_survey','cams_drain_test','cams_dye_test','cams_fog_inspection','cams_gps_survey','cams_general_survey','cams_general_survey_line','cams_manhole_survey','cams_mon_survey','cams_pump_station_survey','cams_smoke_defect','cams_smoke_test'
repairs='cams_general_maintenance','cams_manhole_repair','cams_pipe_clean','cams_pipe_repair','cams_pump_station_em','cams_pump_station_mm'
zones='cams_property','cams_zone','cams_work_package'
incidents='cams_incident_blockage','cams_incident_collapse','cams_incident_complaint','cams_incident_flooding','cams_incident_general','cams_incident_odor','cams_incident_pollution'

destobjects=surveys+incidents+repairs #Choose a list for the DESTINATION tables choices
sourceobjects=assets+zones #Choose a list for the SOURCE tables choices

val=WSApplication.prompt "Update Options",
[
['DESTINATION: Select an Object type to update','String','',nil,'LIST',destobjects],
['DESTINATION: Enter the field to be updated','String'],
['DESTINATION: Enter the comparison field','String'],
['SOURCE: Select a lookup Object type','String','',nil,'LIST',sourceobjects],
['SOURCE: Enter the field to update from','String'],
['SOURCE: Enter the comparison field','String'],
['OVERWRITE existing DESTINATION values?','Boolean',false],
['FLAG for updated values','String'],
],false

desttable=val[0].to_s
destlookup=val[1].to_s
destlookupflag=val[1].to_s+'_flag'
destcomp=val[2].to_s
sourcetable=val[3].to_s
sourcelookup=val[4].to_s
sourcecomp=val[5].to_s
overwrite=val[6].to_s
destflag=val[7].to_s


puts 'Object ' + desttable+ ' Field: ' + destlookup + ' will be updated with ' + sourcetable + ' Field ' + sourcelookup + ' by comparing ' + destcomp + ' to ' + sourcecomp
puts 'Destination Table: '+ desttable
puts 'Destination Field: '+ destlookup
puts 'Destination Comparison: '+ destcomp
puts 'Source Table: '+ sourcetable
puts 'Source Field: '+ sourcelookup
puts 'Source Comparison: '+ sourcecomp
puts 'Overwrite Existing Values: '+ overwrite

sourcevalues=Hash.new
net.row_objects(sourcetable).each do |p|
	id=p[sourcelookup]
		sourcevalue=p[sourcecomp].downcase
	if !sourcevalue.nil? && sourcevalue.length>0
			if !sourcevalues.has_key? sourcevalue
				sourcevalues[sourcevalue]=id
		end
	end
end

if overwrite=='false'
	net.transaction_begin
	net.row_objects(desttable).each do |i|
		if !i[destlookup].nil? && i[destlookup].length==0
			sourcevalue=i[destcomp].downcase
			if !sourcevalue.nil?
				if sourcevalues.has_key? sourcevalue
					i[destlookup]=sourcevalues[sourcevalue]
					i.write
					if i[destlookup]==sourcevalues[sourcevalue] && !i[destlookup].nil? && i[destlookup].length>0
						i[destlookupflag]=destflag
						i.write
					end
				end
			end
		end
	end
	net.transaction_commit
elsif overwrite=='true'
	net.transaction_begin
	net.row_objects(desttable).each do |i|
		sourcevalue=i[destcomp].downcase
		if !sourcevalue.nil?
			if sourcevalues.has_key? sourcevalue
				i[destlookup]=sourcevalues[sourcevalue]
				i.write
				if i[destlookup]==sourcevalues[sourcevalue] && !i[destlookup].nil? && i[destlookup].length>0
					i[destlookupflag]=destflag
					i.write
				end
			end
		end
	end
	net.transaction_commit
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-IncidentTraceUpstream-Incident.rb" 
net=WSApplication.current_network

net.row_object_collection_selection('cams_incident_flooding').each do |ri|
	rn=ri.navigate1('node')
		if !rn.nil?
		rn.selected=true
		end
	end

roc=net.row_object_collection_selection('cams_manhole')
selectedNodes=0
selectedLinks=0
if roc.length!=1
	puts 'Please select one incident'
else
	ro=roc[0]
	ro.selected=true
	selectedNodes+=1
	unprocessedLinks=Array.new
	ro.us_links.each do |l|
		if !l._seen
			unprocessedLinks << l
		end
	end
	while unprocessedLinks.size>0
		working=unprocessedLinks.shift
		working.selected=true
		selectedLinks+=1
		workingUSNode=working.navigate1('us_node')
			if !workingUSNode.nil?
				workingUSNode.selected=true
				selectedNodes+=1
				workingUSNode.us_links.each do |l|
					if !l._seen
						unprocessedLinks << l
						l._seen=true					
					end
			end
		end
	end
	puts 'Selected nodes '+selectedNodes.to_s
	puts 'Selected links '+selectedLinks.to_s
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-NodeTraceUpDownstream_ExcludeBy_InvertLevel.rb" 
#
# This is an example script, it is your responsibility to ensure any
# script you run is suitable for the purpose you have in mind
#
net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
if roc.length!=1
	puts 'Please select one manhole.'
else
	upstream=nil
	if WSApplication.message_box("Go upstream?\nYes = Upstream; No = Downstream","YesNo","?",true) == "Yes" then
		upstream=true
	else
		upstream=false
	end
	ro=roc[0]
	ro.selected=true
	unprocessedLinks=Array.new
	if upstream
		links=ro.us_links
	else
		links=ro.ds_links
	end
	links.each do |l|
		if !l._seen
			if l.us_invert>15
				unprocessedLinks << l
			end
			l._seen=true
		end
	end
	iterations=0
	while unprocessedLinks.size>0 
		working=unprocessedLinks.shift
		working.selected=true
		if upstream
			workingNode=working.us_node
		else
			workingNode=working.ds_node
		end
		if !workingNode.nil?
			workingNode.selected=true
			if upstream
				links=workingNode.us_links
			else
				links=workingNode.ds_links
			end
			links.each do |l|
				if !l._seen
					if l.us_invert>15
						unprocessedLinks << l
					end
					l._seen=true					
				end
			end
		end
	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-NodeTraceUpDownstream_ExcludeBy_PipeStatus.rb" 
#
# This is an example script, it is your responsbility to ensure any
# script you run is suitable for the purpose you have in mind
#
net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
if roc.length!=1
	puts 'Please select one manhole.'
else
	upstream=nil
	if WSApplication.message_box("Go upstream?\nYes = Upstream; No = Downstream","YesNo","?",true) == "Yes" then
		upstream=true
	else
		upstream=false
	end
	ro=roc[0]
	ro.selected=true
	unprocessedLinks=Array.new
	if upstream
		links=ro.us_links
	else
		links=ro.ds_links
	end
	links.each do |l|
		if !l._seen
			if l.status!='AB'	# Status field of Pipe to not include
				unprocessedLinks << l
			end
			l._seen=true
		end
	end
	iterations=0
	while unprocessedLinks.size>0 
		working=unprocessedLinks.shift
		working.selected=true
		if upstream
			workingNode=working.us_node
		else
			workingNode=working.ds_node
		end
		if !workingNode.nil?
			workingNode.selected=true
			if upstream
				links=workingNode.us_links
			else
				links=workingNode.ds_links
			end
			links.each do |l|
				if !l._seen
					if l.status!='AB'	# Status field of Pipe to not include
						unprocessedLinks << l
					end
					l._seen=true					
				end
			end
		end
	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-NodeTraceUpDownstream_ExcludeBy_SumPipeLength.rb" 
#
# This is an example script, it is your responsbility to ensure any
# script you run is suitable for the purpose you have in mind
#
net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
selectedNodes=0
selectedLinks=0
linksLength=0
if roc.length!=1
	puts 'Please select one manhole.'
else
	upstream=nil
	if WSApplication.message_box("Go upstream?\nYes = Upstream; No = Downstream","YesNo","?",true) == "Yes" then
		upstream=true
	else
		upstream=false
	end
	ro=roc[0]
	ro.selected=true
	selectedNodes+=1
	unprocessedLinks=Array.new
	if upstream
		links=ro.us_links
	else
		links=ro.ds_links
	end
	links.each do |l|
		if !l._seen
			unprocessedLinks << l
			l._seen=true
		end
	end
	iterations=0
	while unprocessedLinks.size>0 
		working=unprocessedLinks.shift
		working.selected=true
		selectedLinks+=1
		linksLength+=working.length
		if upstream
			workingNode=working.us_node
		else
			workingNode=working.ds_node
		end
		if !workingNode.nil?
			workingNode.selected=true
			selectedNodes+=1
			
		#	if workingNode.node_type!='F'		#Exclude Node_Type of 'F'
			
				if upstream
					links=workingNode.us_links
				else
					links=workingNode.ds_links
				end
				links.each do |l|
					if !l._seen
						unprocessedLinks << l
						l._seen=true					
					end
				end
			
		#	end									#End from NodeType exclusion
			
		end
	end
	puts 'Selected nodes '+selectedNodes.to_s
	puts 'Selected links '+selectedLinks.to_s
	linksLengthR=linksLength.round(3)
	puts 'Selected links Length '+linksLengthR.to_s+' (m)'
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-NodeTraceUpstream.rb" 
net=WSApplication.current_network
roc=net.row_object_collection_selection('cams_manhole')
selectedNodes=0
selectedLinks=0
if roc.length!=1
	puts 'Please select one manhole'
else
	ro=roc[0]
	ro.selected=true
	selectedNodes+=1
	unprocessedLinks=Array.new
	ro.us_links.each do |l|
		if !l._seen
			unprocessedLinks << l
		end
	end
	while unprocessedLinks.size>0
		working=unprocessedLinks.shift
		working.selected=true
		selectedLinks+=1
		workingUSNode=working.navigate1('us_node')
		if !workingUSNode.nil?
			workingUSNode.selected=true
			selectedNodes+=1
			workingUSNode.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
					l._seen=true					
				end
			end
		end
	end
	puts 'Selected nodes '+selectedNodes.to_s
	puts 'Selected links '+selectedLinks.to_s
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-PipesTraceUpstream_SumPipeLengths.rb" 
# Trace Upstream from selected Pipe(s) and sum the Length of the selected Upstream Pipes


db=WSApplication.current_database 
net=WSApplication.current_network
roc_pipe=net.row_objects_selection('cams_pipe')



if roc_pipe.length==0
	WSApplication.message_box "Please select one or more Pipes\nThen re-run the trace script","OK","Information", false
else
	roc_pipe.each do |ro_pipe|
	linksLength=0
	puts "\n#{ro_pipe.us_node_id}.#{ro_pipe.ds_node_id}.#{ro_pipe.link_suffix}"
		net.row_objects('_links').each do |l|
			l._seen=false
		end
		linksLength+=ro_pipe.length
		#net.clear_selection
		ro_node = ro_pipe.navigate1('us_node')
		selectedNodes=0
		selectedLinks=0
		
		ro=ro_node
		ro.selected=true
		selectedNodes+=1
		unprocessedLinks=Array.new
		ro.us_links.each do |l|
			if !l._seen
				unprocessedLinks << l
			end
		end
		while unprocessedLinks.size>0
			working=unprocessedLinks.shift
			working.selected=true
			selectedLinks+=1
			linksLength+=working.length
			workingUSNode=working.navigate1('us_node')
			if !workingUSNode.nil?
				workingUSNode.selected=true
				selectedNodes+=1
				workingUSNode.us_links.each do |l|
					if !l._seen
						unprocessedLinks << l
						l._seen=true					
					end
				end
			end
		end
		
		puts 'Selected nodes '+selectedNodes.to_s
		puts 'Selected links '+selectedLinks.to_s
		linksLengthR=linksLength.round(3).to_s
		puts "Selected links Length #{linksLengthR} (m)"
		


	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-PipesTraceUpstream_SumPipeLengths_WriteToField.rb" 
# Trace Upstream from selected Pipe(s) and sum the Length of the selected Upstream Pipes then write to a field


db=WSApplication.current_database 
net=WSApplication.current_network
roc_pipe=net.row_objects_selection('cams_pipe')



if roc_pipe.length==0
	WSApplication.message_box "Please select one or more Pipes\nThen re-run the trace script","OK","Information", false
else
	roc_pipe.each do |ro_pipe|
	$linksLength=0
	puts "\n#{ro_pipe.us_node_id}.#{ro_pipe.ds_node_id}.#{ro_pipe.link_suffix}"
		net.row_objects('_links').each do |l|
			l._seen=false
		end
		$linksLength+=ro_pipe.length
		#net.clear_selection
		ro_node = ro_pipe.navigate1('us_node')
		selectedNodes=0
		selectedLinks=0
		
		if ro_node != nil
			ro=ro_node
			ro.selected=true
			selectedNodes+=1
			unprocessedLinks=Array.new
			ro.us_links.each do |l|
				if !l._seen
					unprocessedLinks << l
				end
			end
			while unprocessedLinks.size>0
				working=unprocessedLinks.shift
				working.selected=true
				selectedLinks+=1
				$linksLength+=working.length
				workingUSNode=working.navigate1('us_node')
				if !workingUSNode.nil?
					workingUSNode.selected=true
					selectedNodes+=1
					workingUSNode.us_links.each do |l|
						if !l._seen
							unprocessedLinks << l
							l._seen=true					
						end
					end
				end
			end
		end

		net.transaction_begin
			ro_pipe.user_number_1=$linksLength		## Write the Length of links to the user_number_1 field of the starting Pipe
			ro_pipe.write
		net.transaction_commit
		
		puts 'Selected nodes '+selectedNodes.to_s
		puts 'Selected links '+selectedLinks.to_s
		linksLengthR=$linksLength.round(3).to_s
		puts "Selected links Length #{linksLengthR} (m)"

	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0124 -  Network Trace\UI-PipeTraceUpstream_SaveToSelectionList.rb" 
# Trace Upstream from selected Pipe(s) and create a Selection List of the selected Upstream Pipes


db=WSApplication.current_database 
net=WSApplication.current_network
roc_pipe=net.row_objects_selection('cams_pipe')

if roc_pipe.length==0
	puts 'Please select one or more Pipes'
else
	roc_pipe.each do |ro_pipe|
		net.row_objects('_links').each do |l|
			l._seen=false
		end
		net.clear_selection
		ro_node = ro_pipe.navigate1('us_node')
		puts ro_node.object_id
		selectedNodes=0
		selectedLinks=0
		ro=ro_node
		ro.selected=true
		selectedNodes+=1
		unprocessedLinks=Array.new
		ro.us_links.each do |l|
			if !l._seen
				unprocessedLinks << l
			end
		end
		while unprocessedLinks.size>0
			working=unprocessedLinks.shift
			working.selected=true
			selectedLinks+=1
			workingUSNode=working.navigate1('us_node')
			if !workingUSNode.nil?
				workingUSNode.selected=true
				selectedNodes+=1
				workingUSNode.us_links.each do |l|
					if !l._seen
						unprocessedLinks << l
						l._seen=true					
					end
				end
			end
		end
		puts 'Selected nodes '+selectedNodes.to_s
		puts 'Selected links '+selectedLinks.to_s
		
		# Asset Group location to save a new Selection List to
		mo_assetgrp = db.model_object_from_type_and_id('Asset group',3)
		
		# Create a Selection List in the above Asset Group
		mo_sellist=mo_assetgrp.new_model_object('Selection list',ro_node.object_id.to_s)
		
		# Save the Selection to the above Selection List
		net.save_selection(mo_sellist)

	end
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0125 - Tracing\1_shortest_path_dijkstra.rb" 
def dijkstra(start, target)
  working = Array.new
  working_hash = Hash.new
  calculated = Array.new
  calculated_hash = Hash.new

  start._val = 0.0
  start._from = nil
  start._link = nil

  working << start
  working_hash[start.id] = 0

  until working.empty?
    min = nil
    min_index = -1

    (0...working.size).each do |i|
      if min.nil? || working[i]._val < min
        min = working[i]._val
        min_index = i
      end
    end

    raise 'Index error' if min_index < 0

    current = working.delete_at(min_index)
    return current if current.id == target

    working_hash.delete(current.id)

    calculated << current
    calculated_hash[current.id]=0

    (0..1).each do |dir|
      links = (dir == 0) ? current.ds_links : current.us_links

      links.each do |link|
        node = (dir == 0) ? link.ds_node : link.us_node
        next if node.nil? || calculated_hash.include?(node&.id)

        if working_hash.include?(node.id)
          index = -1

          (0...working.size).each do |i|
            if working[i].id == node.id
              index = i
              break
            end
          end

          raise "Working object #{node.id} in hash but not array" if index == -1
        else
          working << node
          working_hash[node.id] = 0
          index = working.size - 1
        end

        working[index]._val = current._val + link.conduit_length
        working[index]._from = current
        working[index]._link = link
      end
    end
  end
end

# Open the current UI network
network = WSApplication.current_network

# Get the selected nodes, we expect exactly 2
nodes = network.row_objects_selection('_nodes')
raise "Select exactly 2 nodes!" if nodes.size != 2

# Find the shortest path
found = dijkstra(nodes[0], nodes[1].id)

# Select the path
until found.nil?
  found.selected = true
  found._link.selected = true unless found._link.nil?
  found = found._from
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0125 - Tracing\2_boundary_trace.rb" 
# We can't access control directly (yet) so we rely on this hack setting tags on them
#
# @param network [WSOpenNetwork]
def find_boundary_links(network)
  network.clear_selection
  network.run_SQL('_links', "SELECT WHERE joined.pipe_closed = true")
  network.run_SQL('Valve', "SELECT WHERE (joined.mode IS NOT NULL) AND NOT (joined.mode = 'THV' AND joined.opening <> 0)")
  network.row_objects_selection('_links').each { |link| link._boundary = true }
  network.clear_selection
end

# Trace out from a link, given some boundary conditions. Selects links and nodes as we go.
#
# @param link [WSLink]
# @param conditions [Hash]
# @return [Array<WSLink>] returns an array of newly selected links
def trace_out_link(link, conditions)
  links = []

  # Find all connected links, stop at boundary nodes
  [link.us_node, link.ds_node].each do |node|
    if conditions[:nodes].include?(node.table)
      node.selected = true if conditions[:trace_to_node]
      next
    else
      node.selected = true
      node.us_links.each { |link| links << link unless check_boundary_conditions(link, conditions) }
      node.ds_links.each { |link| links << link unless check_boundary_conditions(link, conditions) }
    end
  end

  links.each do |link|
    link._seen = true
    link.selected = true
  end

  return links
end

# Check the boundary conditions for a link.
#
# @param link [WSLink]
# @param conditions [Hash]
# @return [Boolean] whether to reject the link i.e. true means this is a boundary
def check_boundary_conditions(link, conditions)
  return true if link._seen
  return true if link._boundary
  return true if conditions[:links].include?(link.table)
  return true if link['area'] != conditions[:area]
  return false
end

# Open the current UI network
network = WSApplication.current_network

# Find the initial link we'll use to start the trace
initial_link = network.row_objects_selection('_links').first
raise "No link(s) selected for trace" if initial_link.nil?

# Boundary conditions
find_boundary_links(network)
conditions = {
  trace_to_node: true,
  nodes: ['wn_transfer_node', 'wn_fixed_head', 'wn_reservoir'],
  links: ['wn_pst', 'wn_meter'],
  area: initial_link['area']
}

# Trace
initial_link.selected = true
pending_links = [initial_link]
until pending_links.empty?
  working_link = pending_links.shift
  traced = trace_out_link(working_link, conditions)
  pending_links = pending_links.concat(traced)
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0126  - Copy selected subcatchments with user suffix\hw_UI_script.rb" 
net = WSApplication.current_network

# Ask the user for the list of suffixes they want to use
suffixes = ["Horton", "GreenAmpt", "Constant"] # Change this to the list of your suffixes

# Initialize counters
original_selected_count = 0
new_subcatchments_added = 0

# Loops through all subcatchment objects
net.row_objects('hw_subcatchment').each do |subcatchment|
    
    # Check if the catchment is selected
    if subcatchment.selected?
        
        # Increment the counter for original selected subcatchments
        original_selected_count += 1
        
        # Loop through the list of suffixes
        suffixes.each do |suffix|
            
            # Start a 'transaction'
            net.transaction_begin
            
            # Create a new subcatchment object
            new_object = net.new_row_object('hw_subcatchment')
            
            # Name it with '_<suffix>' suffix
            new_object['subcatchment_id'] = "#{subcatchment['subcatchment_id']}_#{suffix}"
            
            # Loop through each column
            new_object.table_info.fields.each do |field|
                
                # Copy across the field value if it's not the subcatchment name
                if field.name != 'subcatchment_id'
                    new_object[field.name] = subcatchment[field.name]
                end
            end
            
            # Increment the counter for new subcatchments added
            new_subcatchments_added += 1
            
            # Write changes
            new_object.write
            
            # End the 'transaction'
            net.transaction_commit
        end
    end
end

# Output the count of original selected subcatchments and new subcatchments added
puts "Number of original selected subcatchments: #{original_selected_count}"
puts "Number of new subcatchments added: #{new_subcatchments_added}"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0126  - Copy selected subcatchments with user suffix\sw_UI_script.rb" 
net = WSApplication.current_network

# Ask the user for the list of suffixes they want to use
suffixes = ["Horton", "GreenAmpt", "Constant"] # Change this to the list of your suffixes

# Initialize counters
original_selected_count = 0
new_subcatchments_added = 0

# Loops through all subcatchment objects
net.row_objects('sw_subcatchment').each do |subcatchment|
    
    # Check if the catchment is selected
    if subcatchment.selected?
        
        # Increment the counter for original selected subcatchments
        original_selected_count += 1
        
        # Loop through the list of suffixes
        suffixes.each do |suffix|
            
            # Start a 'transaction'
            net.transaction_begin
            
            # Create a new subcatchment object
            new_object = net.new_row_object('sw_subcatchment')
            
            # Name it with '_<suffix>' suffix
            new_object['subcatchment_id'] = "#{subcatchment['subcatchment_id']}_#{suffix}"
            
            # Loop through each column
            new_object.table_info.fields.each do |field|
                
                # Copy across the field value if it's not the subcatchment name
                if field.name != 'subcatchment_id'
                    new_object[field.name] = subcatchment[field.name]
                end
            end
            
            # Increment the counter for new subcatchments added
            new_subcatchments_added += 1
            
            # Write changes
            new_object.write
            
            # End the 'transaction'
            net.transaction_commit
        end
    end
end

# Output the count of original selected subcatchments and new subcatchments added
puts "Number of original selected subcatchments: #{original_selected_count}"
puts "Number of new subcatchments added: #{new_subcatchments_added}"
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0127 - Kutter Sql for ICM SWMM\kutter_tm.rb" 
# Kutter's Formula Calculation in Ruby

# Access the current network
net = WSApplication.current_network

# Loop over all links in the network
net.row_objects('_links').each do |link|
  # Retrieve the necessary properties from the link
  conduit_height = link.conduit_height # Replace with actual method to get conduit height in inches
  gradient = link.gradient # Replace with actual method to get slope (ft/ft * 100)
  roughness_n = link.bottom_roughness_N # Replace with actual method to get Manning's n

  # Calculate capacities
  full_capacity = (((conduit_height/12)**2) * 0.78539)*((41.65+0.00281/(gradient/100)+1.811/roughness_n) /
                    (1+(41.65+0.00281/(gradient/100))*roughness_n/((conduit_height/48)**0.5)))*(((conduit_height/48)*gradient/100)**0.5)
  three_quarter_capacity = ((((conduit_height/12)**2) * 0.78539)-((conduit_height/24)**2)*((2.0944-Math.sin(2.0944))/2))*
                    ((41.65+0.00281/(gradient/100)+1.811/roughness_n)/(1+(41.65+0.00281/(gradient/100))*roughness_n/((conduit_height/39.78)**0.5)))*(((conduit_height/39.78)*gradient/100)**0.5)
  half_capacity = 0.5*full_capacity
  pfc = link.Capacity # Replace with actual method to get PFC

# Print the title line
puts "%-10s %-20s %-15s %-25s %-30s %-25s %-25s %-25s" % ['Link ID', 'Diameter (inches)', 'Slope (ft/ft)', "Manning's N Roughness", 'ICM Calculated Capacity (CFS)', "Kutter's Full Capacity (CFS)", "Kutter's 3/4 Capacity (CFS)", "Kutter's 1/2 Capacity (CFS)"]

# Output the results
puts "%-10s %-20.4f %-15.4f %-25.4f %-30.4f %-25.4f %-25.4f %-25.4f" % [link.id, conduit_height, gradient / 100.0, roughness_n, pfc, full_capacity, three_quarter_capacity, half_capacity]
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0128 - InfoSewer Gravity Main Report, from ICM InfoWorks\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Initialize a hash to store the top ten values for each link
top_values = {}
# Initialize a hash to store the maximum values for each link
max_values = {}

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Calculate the time interval in seconds assuming the time steps are evenly spaced
time_interval = (ts[1] - ts[0]).abs
# Print the time interval in seconds and minutes
puts "Time interval: %.4f seconds or %.4f minutes" % [time_interval, time_interval / 60.0]

# Define the result field names
res_field_names = [ "us_depth", "us_flow", "ds_depth", "ds_flow"]

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Initialize arrays for us_d_over_D and us_q_over_Qfull
    us_d_over_D_values = []
    us_q_over_Qfull_values = []
    ds_d_over_D_values = []
    ds_q_over_Qfull_values = []

    res_field_names.each do |res_field_name|
      # Get the results for the specified field
      results = ro.results(res_field_name)
  
      # Ensure we have results for all timesteps
      if results.size == ts.size
        # Initialize variables for statistics
        total = 0.0
        count = 0
        min_value = results.first.to_f
        max_value = results.first.to_f

        # Iterate through the results and update statistics
        results.each do |result|
          val = result.to_f
          total += val
          min_value = [min_value, val].min
          max_value = [max_value, val].max
          count += 1

          # Calculate us_d_over_D and us_q_over_Qfull and store them in the arrays
          if res_field_name == 'us_depth'
            us_d_over_D_values << val / (ro.conduit_height / 100.0)
          elsif res_field_name == 'us_flow'
            us_q_over_Qfull_values << val / ro.capacity
          elsif res_field_name == 'ds_depth'
            ds_d_over_D_values << val / (ro.conduit_height / 100.0)
          elsif res_field_name == 'ds_flow'
            ds_q_over_Qfull_values << val / ro.capacity
          end
        end

        # Calculate the mean value
        mean_value = total / count

        # Print the statistics
        puts "Link: #{'%-12s' % sel.id} | Field: #{'%-19s' % res_field_name} | Mean: #{'%15.5f' % mean_value} | Max: #{'%15.5f' % max_value} | Min: #{'%15.5f' % min_value} | Steps: #{'%10d' % count}"
      else
        puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
      end
    end

    # Calculate and print the statistics for us_d_over_D and us_q_over_Qfull
    if us_d_over_D_values.any?
      mean = us_d_over_D_values.sum / us_d_over_D_values.size
      min, max = us_d_over_D_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_d_over_D         | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_d_over_D_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if us_q_over_Qfull_values.any?
      mean = us_q_over_Qfull_values.sum / us_q_over_Qfull_values.size
      min, max = us_q_over_Qfull_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_q_over_Qfull     | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_q_over_Qfull_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if us_d_over_D_values.any?
      mean = us_d_over_D_values.sum / us_d_over_D_values.size
      min, max = us_d_over_D_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_d_over_D         | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_d_over_D_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if us_q_over_Qfull_values.any?
      mean = us_q_over_Qfull_values.sum / us_q_over_Qfull_values.size
      min, max = us_q_over_Qfull_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: us_q_over_Qfull     | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % us_q_over_Qfull_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if ds_d_over_D_values.any?
      mean = ds_d_over_D_values.sum / ds_d_over_D_values.size
      min, max = ds_d_over_D_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: ds_d_over_D         | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % ds_d_over_D_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end
    if ds_q_over_Qfull_values.any?
      mean = ds_q_over_Qfull_values.sum / ds_q_over_Qfull_values.size
      min, max = ds_q_over_Qfull_values.minmax
      puts "Link: #{'%-12s' % sel.id} | Field: ds_q_over_Qfull     | Mean: #{'%15.5f' % mean} | Max: #{'%15.5f' % max} | Min: #{'%15.5f' % min} | Steps: #{'%10d' % ds_q_over_Qfull_values.size} | Capacity: #{'%15.5f' % ro.capacity} | Conduit Height: #{'%15.5f' % ro.conduit_height}"
    end

      # Calculate the maximum for us_d_over_D and ds_d_over_D
      if us_d_over_D_values.any?
        max_us_d_over_D = us_d_over_D_values.max
        max_values[sel.id] = { 'us_d_over_D' => max_us_d_over_D }
      end
      if ds_d_over_D_values.any?
        max_ds_d_over_D = ds_d_over_D_values.max
        max_values[sel.id] = { 'ds_d_over_D' => max_ds_d_over_D }
      end

  rescue => e
    # Output error message if any error occurred during processing this object
    #puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
net.clear_selection
# Find the top ten links for us_d_over_D and ds_d_over_D
top_links_us = max_values.select { |id, fields| fields['us_d_over_D'] }.sort_by { |id, fields| -fields['us_d_over_D'] }.first(10).map(&:first)
top_links_ds = max_values.select { |id, fields| fields['ds_d_over_D'] }.sort_by { |id, fields| -fields['ds_d_over_D'] }.first(10).map(&:first)

# Select the top ten links in the network
net.row_objects('hw_conduit').each do |ro|
  top_links_us.each do |id|
    if ro.id == id then ro.selected = true end
  end
end
net.row_objects('hw_conduit').each do |ro|
  top_links_ds.each do |id|
    if ro.id == id then ro.selected = true end
  end
end

# Print the top ten links for us_d_over_D and ds_d_over_D
puts "Top 10 links for us_d_over_D: #{top_links_us.join(', ')}"
puts "Top 10 links for ds_d_over_D: #{top_links_ds.join(', ')}"
  
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0129 - ICM Information Hub Finder\hub.rb" 
#InfoWorks ICM Technical Information Hub

puts "1/ InfoWorks ICM Technical Information Hub for InfoWorks and SWMM Networks"
puts "https://boards.autodesk.com/4bf242?token=a671af9e76"
puts "Category                 ".ljust(30) + "Details"
puts "Support               ".ljust(30) + "Innovyze Support"
puts "                         ".ljust(30) + "Autodesk Support"
puts "Downloads             ".ljust(30) + "Innovyze Downloads Portal"
puts "                         ".ljust(30) + "Autodesk Downloads Portal"
puts "Versioning            ".ljust(30) + "Policy on Versioning"
puts "Release Info          ".ljust(30) + "What's New"
puts "                         ".ljust(30) + "Release Notes Post v2024.0"
puts "                         ".ljust(30) + "Known Issues"
puts "                         ".ljust(30) + "Release Notes Pre v2024.0"
puts "Roadmap               ".ljust(30) + "InfoWorks ICM Roadmap"
puts "                         ".ljust(30) + "Autodesk Water Solutions Roadmap"
puts "Licensing             ".ljust(30) + "Thales Licensing for InfoWorks ICM"
puts "                         ".ljust(30) + "Fixed Thales Licensing"
puts "                         ".ljust(30) + "Floating Thales Licensing"
puts "                         ".ljust(30) + "Autodesk Licensing"
puts "Technical Resources   ".ljust(30) + "Help Documentation"
puts "                         ".ljust(30) + "Knowledge Centered Services"
puts "                         ".ljust(30) + "System Requirements"
puts "                         ".ljust(30) + "Security Advisories"
puts "                         ".ljust(30) + "ICM Ideas Portal"
puts "2/ InfoWorks ICM Technical Information Hub for InfoWorks and SWMM Networks"
puts "https://boards.autodesk.com/4bf242?token=a671af9e76"
puts "Configuration          ".ljust(30) + "Innovyze Workgroup Products IT Architecture"
puts "                         ".ljust(30) + "Workgroup Data Server Administration"
puts "                         ".ljust(30) + "InfoWorks ICM Workgroup Best Practices"
puts "                         ".ljust(30) + "Configuration of Simulation Agents for InfoWorks"
puts "Learning               ".ljust(30) + "InfoWorks ICM On demand Training Course"
puts "                         ".ljust(30) + "InfoWorks ICM On demand Learning Units"
puts "                         ".ljust(30) + "InfoWorks ICM Basics tutorial series"
puts "                         ".ljust(30) + "One Water Blog"
puts "Scripting              ".ljust(30) + "Automation Scripts (GitHub)"
puts "                         ".ljust(30) + "InfoWorks ICM Exchange API"
puts "The Cloud              ".ljust(30) + "Ready to get started with our cloud capabilities?"
puts "                         ".ljust(30) + "Creating a Hub"
puts "                         ".ljust(30) + "Cloud vs On premise Database"
puts "                         ".ljust(30) + "Cloud Connection Requirements"
puts "                         ".ljust(30) + "Cloud Simulation Usage"                  
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0130 - InfoSewer Peaking Factors\hw_UI_script.rb" 
# Import the 'date' library
require 'date'

# Get the current network object from InfoWorks
net = WSApplication.current_network

# Get the list of timesteps
ts = net.list_timesteps

# Ensure there's more than one timestep before proceeding
if ts.size <= 1
  puts "Not enough timesteps available!"
  return # or some other form of early exit appropriate for your application
end

# Define the result field name
res_field_name = 'us_flow'

# Iterate through the selected objects in the network
net.each_selected do |sel|
  begin
    # Try to get the row object for the current link using upstream node id
    ro = net.row_object('_links', sel.id)
    
    # Skip the iteration if the row object is nil (not a link)
    next if ro.nil?

    # Get the results for the specified field
    results = ro.results(res_field_name)

    # Ensure we have results for all timesteps
    if results.size == ts.size
      # Initialize variables for statistics
      total = 0.0
      count = 0
      min_value = results.first.to_f
      max_value = results.first.to_f

      # Iterate through the results and update statistics
      results.each do |result|
        val = result.to_f

        val = val * 448.8 # Convert from MGD to GPM
        peak_gpm = val * 2.6/ (val*1.547)**0.16

        total += val
        min_value = [min_value, val].min
        max_value = [max_value, val].max
        count += 1

        # Print the value for each element
        puts "ICM Peaking Flow in link: #{'%.2f' % val}, Total Flow GPM: #{'%.2f' % peak_gpm}"
      end

      # Calculate the mean value
      mean_value = total / count
      
      # Print the statistics
      puts "Link: #{'%-12s' % sel.id} | Field: #{'%-12s' % res_field_name} | Mean: #{'%15.4f' % mean_value} | Max: #{'%15.4f' % max_value} | Min: #{'%15.4f' % min_value} | Steps: #{'%15d' % count}"
    else
      puts "Mismatch in timestep count for object ID #{sel.id}. Expected: #{ts.size}, Found: #{results.size}"
    end
  rescue => e
    # Output error message if any error occurred during processing this object
    puts "Error processing link with ID #{sel.id}, Field: #{res_field_name}. Error: #{e.message}"
  end
end
#==============================================================================
# Define database fields for ICM network nodes
database_fields = [
  'trade_flow',
  'base_flow',
  'additional_foul_flow',
  'user_number_1'
]

net.clear_selection
puts "Scenario     : #{net.current_scenario}"

# Prepare hash for storing data of each field for database_fields
fields_data = {}
database_fields.each { |field| fields_data[field] = [] }

# Initialize the count of processed rows
row_count = 0
total_expected = 0.0

# Collect data for each field from hw_subcatchment
net.row_objects('hw_subcatchment').each do |ro|
  row_count += 1
  database_fields.each do |field|
    fields_data[field] << ro[field] if ro[field]
  end
end

# Print min, max, mean, standard deviation, total, and row count for each field
database_fields.each do |field|
  data = fields_data[field]
  if data.empty?
    #puts "#{field} has no data!"
    next
  end

  min_value = data.min
  max_value = data.max
  sum = data.inject(0.0) { |sum, val| sum + val }
  mean_value = sum / data.size
  # Calculate the standard deviation
  sum_of_squares = data.inject(0.0) { |accum, i| accum + (i - mean_value) ** 2 }
  standard_deviation = Math.sqrt(sum_of_squares / data.size)
  total_value = sum

  # Updated printf statement with row count
  printf("%-30s | Row Count: %-10d | Min: %-10.3f | Max: %-10.3f | Mean: %-10.3f | Std Dev: %-10.2f | Total: %-10.2f\n", 
        field, data.size, min_value, max_value, mean_value, standard_deviation, total_value)
end 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0131 - Master RB Files\hw_parameters.rb" 
****hw_sim_parameters
	1. min_base_flow_depth
	2. base_flow_factor
	3. slope_base_flow_x2
	4. min_space_step
	5. max_space_step
	6. width_multiplier
	7. min_computational_nodes
	8. min_slot_width
	9. celerity_ratio
	10. lower_froude_number
	11. upper_froude_number
	12. start_timestep
	13. max_timestep
	14. phase_in_time
	15. steady_tol_flow
	16. steady_tol_depth
	17. ini_max_halvings
	18. ini_max_iterations
	19. ini_max_iterations_x2
	20. ini_tolerance_flow
	21. ini_scaling_flow
	22. ini_tolerance_depth
	23. ini_scaling_depth
	24. ini_tolerance_level
	25. ini_scaling_level
	26. ini_min_depth
	27. ini_min_node_area
	28. ini_time_weighting
	29. ini_tolerance_volbal
	30. ini_scaling_volbal
	31. sim_max_halvings
	32. sim_max_iterations
	33. sim_max_iterations_x2
	34. sim_tolerance_flow
	35. sim_scaling_flow
	36. sim_tolerance_depth
	37. sim_scaling_depth
	38. sim_tolerance_level
	39. sim_scaling_level
	40. sim_min_depth
	41. sim_min_node_area
	42. sim_time_weighting
	43. sim_tolerance_volbal
	44. sim_scaling_volbal
	45. stay_pressurised
	46. dont_linearise_k
	47. geometry_table_entries
	48. use_full_area_for_hl
	49. inflow_is_lateral
	50. hl_trans_bottom
	51. hl_trans_top
	52. use_villemonte
	53. pressure_drop_inertia
	54. ini_relax_tol
	55. sim_relax_tol
	56. use_2d_elevations
	57. drowned_bank_threshold
	58. inflow_manhole_link
	59. ground_slope_correction
	60. sim_node_affects_infiltration
	61. weight_by_n
	62. swmm5_rdii
****hw_manhole_defaults
	1. flood_area_1
	2. flood_area_2
	3. flood_depth_1
	4. flood_depth_2
	5. flood_type
	6. element_area_factor_2d
	7. benching_method
	8. 2d_link_type
****hw_conduit_defaults
	1. us_headloss_type
	2. ds_headloss_type
	3. roughness_type
	4. us_headloss_coeff
	5. ds_headloss_coeff
	6. bottom_roughness_Manning
	7. top_roughness_Manning
	8. bottom_roughness_CW
	9. top_roughness_CW
	10. top_roughness_N
	11. bottom_roughness_N
	12. bottom_roughness_HW
	13. top_roughness_HW
	14. sediment_depth
	15. inflow
	16. diff1d_type
	17. diff1d_d0
	18. diff1d_d1
	19. diff1d_d2
****hw_subcatchment_defaults
	1. additional_foul_flow
	2. area_measurement_type
	3. base_flow
	4. land_use_id
	5. rainfall_profile
	6. soil_class
	7. soil_class_host
	8. soil_class_type
	9. rafts_adapt_factor
****hw_large_catchment_parameters
	1. ck
	2. ct
	3. k1
	4. k2
	5. k3
	6. t1
	7. t2
	8. t3
****hw_snow_parameters
	1. antecedent_temp_idx
	2. elevation
	3. impervious_adc
	4. negative_melt_ratio
	5. pervious_adc
	6. snow_temperature
****hw_wq_params
	1. ammonia_20c_decay_rate
	2. ammonia_temp_coeff
	3. base_salinity
	4. base_susp_solids_factor
	5. base_suspended_solids
	6. bod5_20c_decay_rate
	7. bod5_temp_coeff
	8. coliforms_t90
	9. coliforms_t90_night
	10. limit_deposition_rate
	11. limit_erosion_rate
	12. max_deposition_rate
	13. max_erosion_rate
	14. no2_20c_decay_rate
	15. no2_temp_coeff
	16. org_nitr_20c_decay_rate
	17. org_nitr_temp_coeff
	18. reaer_calc_params
	19. reaer_coeff
	20. reaer_temp_coeff
	21. salinity_coeff
	22. salt_const_conc
	23. structure_aer_coeff
	24. suspended_solids_coeff
	25. temp_constant_temp
	26. temp_equilib_water_temp
	27. temp_heat_transfer_coeff
	28. space_step_multiplier
	29. initial_state_steps
	30. initialisation_timestep
	31. initialisation_tolerance
	32. trajectory_switching_iterations
	33. trajectory_max_iterations
	34. trajectory_absolute_tolerance
	35. trajectory_relative_tolerance
	36. node_solver_max_iterations
	37. node_solver_relative_tolerance
	38. node_solver_time_weighting
	39. bed_depth_max_iterations
	40. bed_depth_relative_tolerance
	41. deposition_limit
	42. bed_d50
	43. bed_s
	44. cw_max_iterations
	45. cw_relative_tolerance
	46. erosion_model
	47. aldepth_method_1D
	48. d50_sf1
	49. s_sf1
	50. settling_velocity_sf1
	51. eta1_sf1
	52. eta2_sf1
	53. alpha_deposition_sf1
	54. beta_deposition_sf1
	55. gamma_deposition_sf1
	56. alpha_erosion_sf1
	57. beta_erosion_sf1
	58. gamma_erosion_sf1
	59. d50_sf2
	60. s_sf2
	61. settling_velocity_sf2
	62. eta1_sf2
	63. eta2_sf2
	64. alpha_deposition_sf2
	65. beta_deposition_sf2
	66. gamma_deposition_sf2
	67. alpha_erosion_sf2
	68. beta_erosion_sf2
	69. gamma_erosion_sf2
	70. eta1_composite
	71. eta2_composite
	72. alpha_deposition_composite
	73. beta_deposition_composite
	74. gamma_deposition_composite
	75. alpha_erosion_composite
	76. beta_erosion_composite
	77. gamma_erosion_composite
	78. phy_n_uptake_half_sat
	79. phy_p_uptake_half_sat
	80. phy_s_uptake_half_sat
	81. phy_n_c_ratio
	82. phy_p_c_ratio
	83. phy_s_c_ratio
	84. phy_grad_low_temp
	85. phy_int_low_temp
	86. phy_grad_high_temp
	87. phy_int_high_temp
	88. phy_crit_temp
	89. phy_pmax_solar_rad
	90. phy_light_ext_factor
	91. phy_resp_rate_20
	92. phy_resp_q10
	93. phy_mort_rate
	94. phy_decay_20
	95. h2s_free_flow
	96. h2s_full_flow
	97. h2s_ion_coeff
	98. h2s_sol_sulph
	99. h2s_sulph_loss
	100. phy_temp_dep
	101. phy_sett_vel
	102. ad_rate_20
	103. temp_dep_factor
	104. sat_ad_ratio
	105. half_sat_langmuir
	106. ben_n_uptake_half_sat
	107. ben_p_uptake_half_sat
	108. ben_s_uptake_half_sat
	109. ben_n_c_ratio
	110. ben_p_c_ratio
	111. ben_s_c_ratio
	112. ben_pmax_solar_rad
	113. ben_resp_rate_20
	114. ben_resp_q10
	115. ben_mort_rate
	116. mac_n_uptake_half_sat
	117. mac_p_uptake_half_sat
	118. mac_s_uptake_half_sat
	119. mac_n_c_ratio
	120. mac_p_c_ratio
	121. mac_s_c_ratio
	122. mac_pmax_solar_rad
	123. mac_prod_rate_20
	124. mac_growth_q10
	125. mac_loss_leach
	126. mac_loss_exude
	127. mac_seed_conc
	128. mac_mort_rate
	129. washoff_model
	130. sweep_start_month
	131. sweep_start_day
	132. na_pollutants
		 determinant
		 rainfall_conc
		 groundwater_conc
		 rdii_conc
		 snow_build_up
	133. sweep_end_month
	134. pot_factors
		 determinant
		 sediment_fraction
		 potency_factor
	135. sweep_end_day
	136. dens_sf1
	137. settling_calc_sf1
	138. 2D_settling_velocity_sf1
	139. corey_shape_factor_sf1
	140. porosity_sf1
	141. roughness_sf1
	142. d16_sf1
	143. d35_sf1
	144. d84_sf1
	145. d90_sf1
	146. repose_sf1
	147. dens_sf2
	148. settling_calc_sf2
	149. 2D_settling_velocity_sf2
	150. corey_shape_factor_sf2
	151. roughness_sf2
	152. porosity_sf2
	153. d16_sf2
	154. d35_sf2
	155. d84_sf2
	156. d90_sf2
	157. repose_sf2
	158. calibration
	159. aldepth_method
	160. aldepth
	161. aldepth_factor
	162. model_type
	163. total_load_model
	164. nbconc_method
	165. nbconc
	166. skinfric_method
	167. bedload_calibration
	168. bedload_formula
	169. critical_shields_method
	170. critical_shields
	171. k_coefficient
	172. a_coefficient
	173. b_coefficient
	174. exp1_coefficient
	175. exp2_coefficient
	176. exp3_coefficient
	177. exp4_coefficient
	178. exp5_coefficient
	179. exp6_coefficient
****hw_node
	1. node_id
	2. node_id_flag
	3. storage_array
		 level
		 area
		 perimeter
	4. storage_array_flag
	5. node_type
	6. node_type_flag
	7. asset_id
	8. asset_id_flag
	9. system_type
	10. system_type_flag
	11. connection_type
	12. connection_type_flag
	13. 2d_connect_line
	14. 2d_connect_line_flag
	15. lateral_node_id
	16. lateral_link_suffix
	17. asset_uid
	18. infonet_id
	19. x
	20. x_flag
	21. y
	22. y_flag
	23. ground_level
	24. ground_level_flag
	25. flood_level
	26. flood_level_flag
	27. shaft_area_additional
	28. shaft_area_additional_flag
	29. shaft_area_add_comp
	30. shaft_area_add_comp_flag
	31. shaft_area_add_simplify
	32. shaft_area_add_simplify_flag
	33. shaft_area_add_ncorrect
	34. shaft_area_add_ncorrect_flag
	35. shaft_area_additional_total
	36. chamber_area_additional
	37. chamber_area_additional_flag
	38. chamber_area_add_comp
	39. chamber_area_add_comp_flag
	40. chamber_area_add_simplify
	41. chamber_area_add_simplify_flag
	42. chamber_area_add_ncorrect
	43. chamber_area_add_ncorrect_flag
	44. chamber_area_additional_total
	45. chamber_roof
	46. chamber_roof_flag
	47. chamber_floor
	48. chamber_floor_flag
	49. chamber_area
	50. chamber_area_flag
	51. shaft_area
	52. shaft_area_flag
	53. flood_type
	54. flood_type_flag
	55. element_area_factor_2d
	56. element_area_factor_2d_flag
	57. flooding_discharge_coeff
	58. flooding_discharge_coeff_flag
	59. benching_method
	60. benching_method_flag
	61. 2d_link_type
	62. 2d_link_type_flag
	63. floodable_area
	64. floodable_area_flag
	65. flood_depth_1
	66. flood_depth_1_flag
	67. flood_depth_2
	68. flood_depth_2_flag
	69. flood_area_1
	70. flood_area_1_flag
	71. flood_area_2
	72. flood_area_2_flag
	73. base_area
	74. base_area_flag
	75. perimeter
	76. perimeter_flag
	77. infiltration_coeff
	78. infiltration_coeff_flag
	79. porosity
	80. porosity_flag
	81. vegetation_level
	82. vegetation_level_flag
	83. liner_level
	84. liner_level_flag
	85. infiltratn_coeff_abv_vegn
	86. infiltratn_coeff_abv_vegn_flag
	87. infiltratn_coeff_abv_liner
	88. infiltratn_coeff_abv_liner_flag
	89. infiltratn_coeff_blw_liner
	90. infiltratn_coeff_blw_liner_flag
	91. relative_stages
	92. inlet_input_type
	93. inlet_input_type_flag
	94. inlet_type
	95. inlet_type_flag
	96. cross_slope
	97. cross_slope_flag
	98. grate_width
	99. grate_width_flag
	100. grate_length
	101. grate_length_flag
	102. opening_length
	103. opening_length_flag
	104. opening_height
	105. opening_height_flag
	106. gutter_depression
	107. gutter_depression_flag
	108. lateral_depression
	109. lateral_depression_flag
	110. velocity_splashover
	111. velocity_splashover_flag
	112. debris
	113. debris_flag
	114. depth_weir
	115. depth_weir_flag
	116. clear_opening
	117. clear_opening_flag
	118. head_discharge_id
	119. head_discharge_id_flag
	120. flow_efficiency_id
	121. flow_efficiency_id_flag
	122. inlet_UE_a
	123. inlet_UE_a_flag
	124. inlet_UE_b
	125. inlet_UE_b_flag
	126. n_gullies
	127. n_gullies_flag
	128. num_transverse_bars
	129. num_transverse_bars_flag
	130. num_longitudinal_bars
	131. num_longitudinal_bars_flag
	132. num_diagonal_bars
	133. num_diagonal_bars_flag
	134. min_area_inc_voids
	135. min_area_inc_voids_flag
	136. area_of_voids
	137. area_of_voids_flag
	138. half_road_width
	139. half_road_width_flag
	140. notes
	141. notes_flag
	142. hyperlinks
		 description
		 url
	143. hyperlinks_flag
	144. user_number_1
	145. user_number_1_flag
	146. user_number_2
	147. user_number_2_flag
	148. user_number_3
	149. user_number_3_flag
	150. user_number_4
	151. user_number_4_flag
	152. user_number_5
	153. user_number_5_flag
	154. user_number_6
	155. user_number_6_flag
	156. user_number_7
	157. user_number_7_flag
	158. user_number_8
	159. user_number_8_flag
	160. user_number_9
	161. user_number_9_flag
	162. user_number_10
	163. user_number_10_flag
	164. user_text_1
	165. user_text_1_flag
	166. user_text_2
	167. user_text_2_flag
	168. user_text_3
	169. user_text_3_flag
	170. user_text_4
	171. user_text_4_flag
	172. user_text_5
	173. user_text_5_flag
	174. user_text_6
	175. user_text_6_flag
	176. user_text_7
	177. user_text_7_flag
	178. user_text_8
	179. user_text_8_flag
	180. user_text_9
	181. user_text_9_flag
	182. user_text_10
	183. user_text_10_flag
****hw_conduit
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. asset_id
	10. asset_id_flag
	11. sewer_reference
	12. sewer_reference_flag
	13. system_type
	14. system_type_flag
	15. branch_id
	16. branch_id_flag
	17. point_array
	18. is_merged
	19. asset_uid
	20. infonet_us_node_id
	21. infonet_ds_node_id
	22. infonet_link_suffix
	23. us_settlement_eff
	24. us_settlement_eff_flag
	25. ds_settlement_eff
	26. ds_settlement_eff_flag
	27. solution_model
	28. solution_model_flag
	29. min_computational_nodes
	30. min_computational_nodes_flag
	31. critical_sewer_category
	32. critical_sewer_category_flag
	33. taking_off_reference
	34. taking_off_reference_flag
	35. conduit_material
	36. conduit_material_flag
	37. design_group
	38. design_group_flag
	39. site_condition
	40. site_condition_flag
	41. ground_condition
	42. ground_condition_flag
	43. conduit_type
	44. conduit_type_flag
	45. min_space_step
	46. min_space_step_flag
	47. slot_width
	48. slot_width_flag
	49. connection_coefficient
	50. connection_coefficient_flag
	51. shape
	52. shape_flag
	53. conduit_width
	54. conduit_width_flag
	55. conduit_height
	56. conduit_height_flag
	57. springing_height
	58. springing_height_flag
	59. sediment_depth
	60. sediment_depth_flag
	61. number_of_barrels
	62. number_of_barrels_flag
	63. roughness_type
	64. roughness_type_flag
	65. bottom_roughness_CW
	66. bottom_roughness_CW_flag
	67. top_roughness_CW
	68. top_roughness_CW_flag
	69. bottom_roughness_Manning
	70. bottom_roughness_Manning_flag
	71. top_roughness_Manning
	72. top_roughness_Manning_flag
	73. bottom_roughness_N
	74. bottom_roughness_N_flag
	75. top_roughness_N
	76. top_roughness_N_flag
	77. bottom_roughness_HW
	78. bottom_roughness_HW_flag
	79. top_roughness_HW
	80. top_roughness_HW_flag
	81. conduit_length
	82. conduit_length_flag
	83. inflow
	84. inflow_flag
	85. gradient
	86. gradient_flag
	87. capacity
	88. capacity_flag
	89. us_invert
	90. us_invert_flag
	91. ds_invert
	92. ds_invert_flag
	93. us_headloss_type
	94. us_headloss_type_flag
	95. ds_headloss_type
	96. ds_headloss_type_flag
	97. us_headloss_coeff
	98. us_headloss_coeff_flag
	99. ds_headloss_coeff
	100. ds_headloss_coeff_flag
	101. base_height
	102. base_height_flag
	103. infiltration_coeff_base
	104. infiltration_coeff_base_flag
	105. infiltration_coeff_side
	106. infiltration_coeff_side_flag
	107. fill_material_conductivity
	108. fill_material_conductivity_flag
	109. porosity
	110. porosity_flag
	111. diff1d_type
	112. diff1d_type_flag
	113. diff1d_d0
	114. diff1d_d0_flag
	115. diff1d_d1
	116. diff1d_d1_flag
	117. diff1d_d2
	118. diff1d_d2_flag
	119. inlet_type_code
	120. inlet_type_code_flag
	121. reverse_flow_model
	122. reverse_flow_model_flag
	123. equation
	124. equation_flag
	125. k
	126. k_flag
	127. m
	128. m_flag
	129. c
	130. c_flag
	131. y
	132. y_flag
	133. us_ki
	134. us_ki_flag
	135. us_ko
	136. us_ko_flag
	137. outlet_type_code
	138. outlet_type_code_flag
	139. equation_o
	140. equation_o_flag
	141. k_o
	142. k_o_flag
	143. m_o
	144. m_o_flag
	145. c_o
	146. c_o_flag
	147. y_o
	148. y_o_flag
	149. ds_ki
	150. ds_ki_flag
	151. ds_ko
	152. ds_ko_flag
	153. notes
	154. notes_flag
	155. hyperlinks
		 description
		 url
	156. hyperlinks_flag
	157. user_number_1
	158. user_number_1_flag
	159. user_number_2
	160. user_number_2_flag
	161. user_number_3
	162. user_number_3_flag
	163. user_number_4
	164. user_number_4_flag
	165. user_number_5
	166. user_number_5_flag
	167. user_number_6
	168. user_number_6_flag
	169. user_number_7
	170. user_number_7_flag
	171. user_number_8
	172. user_number_8_flag
	173. user_number_9
	174. user_number_9_flag
	175. user_number_10
	176. user_number_10_flag
	177. user_text_1
	178. user_text_1_flag
	179. user_text_2
	180. user_text_2_flag
	181. user_text_3
	182. user_text_3_flag
	183. user_text_4
	184. user_text_4_flag
	185. user_text_5
	186. user_text_5_flag
	187. user_text_6
	188. user_text_6_flag
	189. user_text_7
	190. user_text_7_flag
	191. user_text_8
	192. user_text_8_flag
	193. user_text_9
	194. user_text_9_flag
	195. user_text_10
	196. user_text_10_flag
****hw_flap_valve
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. valve_type
	16. valve_type_flag
	17. point_array
	18. invert
	19. invert_flag
	20. diameter
	21. diameter_flag
	22. height
	23. height_flag
	24. width
	25. width_flag
	26. discharge_coeff
	27. discharge_coeff_flag
	28. ds_settlement_eff
	29. ds_settlement_eff_flag
	30. us_settlement_eff
	31. us_settlement_eff_flag
	32. branch_id
	33. branch_id_flag
	34. hyperlinks
		 description
		 url
	35. hyperlinks_flag
	36. asset_uid
	37. infonet_id
	38. notes
	39. notes_flag
	40. user_number_1
	41. user_number_1_flag
	42. user_number_2
	43. user_number_2_flag
	44. user_number_3
	45. user_number_3_flag
	46. user_number_4
	47. user_number_4_flag
	48. user_number_5
	49. user_number_5_flag
	50. user_number_6
	51. user_number_6_flag
	52. user_number_7
	53. user_number_7_flag
	54. user_number_8
	55. user_number_8_flag
	56. user_number_9
	57. user_number_9_flag
	58. user_number_10
	59. user_number_10_flag
	60. user_text_1
	61. user_text_1_flag
	62. user_text_2
	63. user_text_2_flag
	64. user_text_3
	65. user_text_3_flag
	66. user_text_4
	67. user_text_4_flag
	68. user_text_5
	69. user_text_5_flag
	70. user_text_6
	71. user_text_6_flag
	72. user_text_7
	73. user_text_7_flag
	74. user_text_8
	75. user_text_8_flag
	76. user_text_9
	77. user_text_9_flag
	78. user_text_10
	79. user_text_10_flag
****hw_orifice
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. invert
	17. invert_flag
	18. diameter
	19. diameter_flag
	20. discharge_coeff
	21. discharge_coeff_flag
	22. secondary_discharge_coeff
	23. secondary_discharge_coeff_flag
	24. opening_type
	25. opening_type_flag
	26. limiting_discharge
	27. limiting_discharge_flag
	28. minimum_flow
	29. minimum_flow_flag
	30. maximum_flow
	31. maximum_flow_flag
	32. positive_change_in_flow
	33. positive_change_in_flow_flag
	34. negative_change_in_flow
	35. negative_change_in_flow_flag
	36. threshold
	37. threshold_flag
	38. ds_settlement_eff
	39. ds_settlement_eff_flag
	40. us_settlement_eff
	41. us_settlement_eff_flag
	42. branch_id
	43. branch_id_flag
	44. hyperlinks
		 description
		 url
	45. hyperlinks_flag
	46. asset_uid
	47. infonet_id
	48. notes
	49. notes_flag
	50. user_number_1
	51. user_number_1_flag
	52. user_number_2
	53. user_number_2_flag
	54. user_number_3
	55. user_number_3_flag
	56. user_number_4
	57. user_number_4_flag
	58. user_number_5
	59. user_number_5_flag
	60. user_number_6
	61. user_number_6_flag
	62. user_number_7
	63. user_number_7_flag
	64. user_number_8
	65. user_number_8_flag
	66. user_number_9
	67. user_number_9_flag
	68. user_number_10
	69. user_number_10_flag
	70. user_text_1
	71. user_text_1_flag
	72. user_text_2
	73. user_text_2_flag
	74. user_text_3
	75. user_text_3_flag
	76. user_text_4
	77. user_text_4_flag
	78. user_text_5
	79. user_text_5_flag
	80. user_text_6
	81. user_text_6_flag
	82. user_text_7
	83. user_text_7_flag
	84. user_text_8
	85. user_text_8_flag
	86. user_text_9
	87. user_text_9_flag
	88. user_text_10
	89. user_text_10_flag
****hw_pump
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. switch_on_level
	17. switch_on_level_flag
	18. switch_off_level
	19. switch_off_level_flag
	20. delay
	21. delay_flag
	22. off_delay
	23. off_delay_flag
	24. discharge
	25. discharge_flag
	26. base_level
	27. base_level_flag
	28. head_discharge_id
	29. head_discharge_id_flag
	30. minimum_flow
	31. minimum_flow_flag
	32. maximum_flow
	33. maximum_flow_flag
	34. positive_change_in_flow
	35. positive_change_in_flow_flag
	36. negative_change_in_flow
	37. negative_change_in_flow_flag
	38. threshold
	39. threshold_flag
	40. maximum_speed
	41. maximum_speed_flag
	42. minimum_speed
	43. minimum_speed_flag
	44. positive_change_in_speed
	45. positive_change_in_speed_flag
	46. negative_change_in_speed
	47. negative_change_in_speed_flag
	48. nominal_speed
	49. nominal_speed_flag
	50. threshold_speed
	51. threshold_speed_flag
	52. ds_settlement_eff
	53. ds_settlement_eff_flag
	54. us_settlement_eff
	55. us_settlement_eff_flag
	56. nominal_flow
	57. nominal_flow_flag
	58. electric_hydraulic_ratio
	59. electric_hydraulic_ratio_flag
	60. branch_id
	61. branch_id_flag
	62. hyperlinks
		 description
		 url
	63. hyperlinks_flag
	64. asset_uid
	65. infonet_id
	66. notes
	67. notes_flag
	68. user_number_1
	69. user_number_1_flag
	70. user_number_2
	71. user_number_2_flag
	72. user_number_3
	73. user_number_3_flag
	74. user_number_4
	75. user_number_4_flag
	76. user_number_5
	77. user_number_5_flag
	78. user_number_6
	79. user_number_6_flag
	80. user_number_7
	81. user_number_7_flag
	82. user_number_8
	83. user_number_8_flag
	84. user_number_9
	85. user_number_9_flag
	86. user_number_10
	87. user_number_10_flag
	88. user_text_1
	89. user_text_1_flag
	90. user_text_2
	91. user_text_2_flag
	92. user_text_3
	93. user_text_3_flag
	94. user_text_4
	95. user_text_4_flag
	96. user_text_5
	97. user_text_5_flag
	98. user_text_6
	99. user_text_6_flag
	100. user_text_7
	101. user_text_7_flag
	102. user_text_8
	103. user_text_8_flag
	104. user_text_9
	105. user_text_9_flag
	106. user_text_10
	107. user_text_10_flag
****hw_sluice
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. invert
	17. invert_flag
	18. width
	19. width_flag
	20. discharge_coeff
	21. discharge_coeff_flag
	22. overgate_discharge_coeff
	23. overgate_discharge_coeff_flag
	24. secondary_discharge_coeff
	25. secondary_discharge_coeff_flag
	26. opening
	27. opening_flag
	28. opening_degrees
	29. opening_degrees_flag
	30. opening_type
	31. opening_type_flag
	32. minimum_opening
	33. minimum_opening_flag
	34. minimum_opening_deg
	35. minimum_opening_deg_flag
	36. gate_depth
	37. gate_depth_flag
	38. maximum_opening
	39. maximum_opening_flag
	40. maximum_opening_deg
	41. maximum_opening_deg_flag
	42. positive_speed
	43. positive_speed_flag
	44. positive_speed_deg
	45. positive_speed_deg_flag
	46. negative_speed
	47. negative_speed_flag
	48. negative_speed_deg
	49. negative_speed_deg_flag
	50. gate_chord
	51. gate_chord_flag
	52. gate_radius
	53. gate_radius_flag
	54. pivot_height
	55. pivot_height_flag
	56. threshold
	57. threshold_flag
	58. threshold_degrees
	59. threshold_degrees_flag
	60. ds_settlement_eff
	61. ds_settlement_eff_flag
	62. us_settlement_eff
	63. us_settlement_eff_flag
	64. branch_id
	65. branch_id_flag
	66. hyperlinks
		 description
		 url
	67. hyperlinks_flag
	68. asset_uid
	69. infonet_id
	70. notes
	71. notes_flag
	72. user_number_1
	73. user_number_1_flag
	74. user_number_2
	75. user_number_2_flag
	76. user_number_3
	77. user_number_3_flag
	78. user_number_4
	79. user_number_4_flag
	80. user_number_5
	81. user_number_5_flag
	82. user_number_6
	83. user_number_6_flag
	84. user_number_7
	85. user_number_7_flag
	86. user_number_8
	87. user_number_8_flag
	88. user_number_9
	89. user_number_9_flag
	90. user_number_10
	91. user_number_10_flag
	92. user_text_1
	93. user_text_1_flag
	94. user_text_2
	95. user_text_2_flag
	96. user_text_3
	97. user_text_3_flag
	98. user_text_4
	99. user_text_4_flag
	100. user_text_5
	101. user_text_5_flag
	102. user_text_6
	103. user_text_6_flag
	104. user_text_7
	105. user_text_7_flag
	106. user_text_8
	107. user_text_8_flag
	108. user_text_9
	109. user_text_9_flag
	110. user_text_10
	111. user_text_10_flag
****hw_user_control
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. start_level
	17. start_level_flag
	18. head_discharge_id
	19. head_discharge_id_flag
	20. modular_limit
	21. modular_limit_flag
	22. ds_settlement_eff
	23. ds_settlement_eff_flag
	24. us_settlement_eff
	25. us_settlement_eff_flag
	26. branch_id
	27. branch_id_flag
	28. hyperlinks
		 description
		 url
	29. hyperlinks_flag
	30. asset_uid
	31. infonet_id
	32. notes
	33. notes_flag
	34. user_number_1
	35. user_number_1_flag
	36. user_number_2
	37. user_number_2_flag
	38. user_number_3
	39. user_number_3_flag
	40. user_number_4
	41. user_number_4_flag
	42. user_number_5
	43. user_number_5_flag
	44. user_number_6
	45. user_number_6_flag
	46. user_number_7
	47. user_number_7_flag
	48. user_number_8
	49. user_number_8_flag
	50. user_number_9
	51. user_number_9_flag
	52. user_number_10
	53. user_number_10_flag
	54. user_text_1
	55. user_text_1_flag
	56. user_text_2
	57. user_text_2_flag
	58. user_text_3
	59. user_text_3_flag
	60. user_text_4
	61. user_text_4_flag
	62. user_text_5
	63. user_text_5_flag
	64. user_text_6
	65. user_text_6_flag
	66. user_text_7
	67. user_text_7_flag
	68. user_text_8
	69. user_text_8_flag
	70. user_text_9
	71. user_text_9_flag
	72. user_text_10
	73. user_text_10_flag
****hw_weir
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. crest
	17. crest_flag
	18. width
	19. width_flag
	20. height
	21. height_flag
	22. gate_height
	23. gate_height_flag
	24. length
	25. length_flag
	26. orientation
	27. orientation_flag
	28. discharge_coeff
	29. discharge_coeff_flag
	30. reverse_gate_discharge_coeff
	31. reverse_gate_discharge_coeff_flag
	32. secondary_discharge_coeff
	33. secondary_discharge_coeff_flag
	34. modular_limit
	35. modular_limit_flag
	36. notch_height
	37. notch_height_flag
	38. notch_angle
	39. notch_angle_flag
	40. notch_width
	41. notch_width_flag
	42. number_of_notches
	43. number_of_notches_flag
	44. ds_settlement_eff
	45. ds_settlement_eff_flag
	46. us_settlement_eff
	47. us_settlement_eff_flag
	48. minimum_value
	49. minimum_value_flag
	50. maximum_value
	51. maximum_value_flag
	52. minimum_crest
	53. minimum_crest_flag
	54. maximum_crest
	55. maximum_crest_flag
	56. minimum_opening
	57. minimum_opening_flag
	58. maximum_opening
	59. maximum_opening_flag
	60. initial_opening
	61. initial_opening_flag
	62. positive_speed
	63. positive_speed_flag
	64. negative_speed
	65. negative_speed_flag
	66. threshold
	67. threshold_flag
	68. branch_id
	69. branch_id_flag
	70. hyperlinks
		 description
		 url
	71. hyperlinks_flag
	72. asset_uid
	73. infonet_id
	74. notes
	75. notes_flag
	76. user_number_1
	77. user_number_1_flag
	78. user_number_2
	79. user_number_2_flag
	80. user_number_3
	81. user_number_3_flag
	82. user_number_4
	83. user_number_4_flag
	84. user_number_5
	85. user_number_5_flag
	86. user_number_6
	87. user_number_6_flag
	88. user_number_7
	89. user_number_7_flag
	90. user_number_8
	91. user_number_8_flag
	92. user_number_9
	93. user_number_9_flag
	94. user_number_10
	95. user_number_10_flag
	96. user_text_1
	97. user_text_1_flag
	98. user_text_2
	99. user_text_2_flag
	100. user_text_3
	101. user_text_3_flag
	102. user_text_4
	103. user_text_4_flag
	104. user_text_5
	105. user_text_5_flag
	106. user_text_6
	107. user_text_6_flag
	108. user_text_7
	109. user_text_7_flag
	110. user_text_8
	111. user_text_8_flag
	112. user_text_9
	113. user_text_9_flag
	114. user_text_10
	115. user_text_10_flag
****hw_flume
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. invert
	17. invert_flag
	18. width
	19. width_flag
	20. length
	21. length_flag
	22. side_slope
	23. side_slope_flag
	24. ds_settlement_eff
	25. ds_settlement_eff_flag
	26. us_settlement_eff
	27. us_settlement_eff_flag
	28. branch_id
	29. branch_id_flag
	30. hyperlinks
		 description
		 url
	31. hyperlinks_flag
	32. asset_uid
	33. infonet_id
	34. notes
	35. notes_flag
	36. user_number_1
	37. user_number_1_flag
	38. user_number_2
	39. user_number_2_flag
	40. user_number_3
	41. user_number_3_flag
	42. user_number_4
	43. user_number_4_flag
	44. user_number_5
	45. user_number_5_flag
	46. user_number_6
	47. user_number_6_flag
	48. user_number_7
	49. user_number_7_flag
	50. user_number_8
	51. user_number_8_flag
	52. user_number_9
	53. user_number_9_flag
	54. user_number_10
	55. user_number_10_flag
	56. user_text_1
	57. user_text_1_flag
	58. user_text_2
	59. user_text_2_flag
	60. user_text_3
	61. user_text_3_flag
	62. user_text_4
	63. user_text_4_flag
	64. user_text_5
	65. user_text_5_flag
	66. user_text_6
	67. user_text_6_flag
	68. user_text_7
	69. user_text_7_flag
	70. user_text_8
	71. user_text_8_flag
	72. user_text_9
	73. user_text_9_flag
	74. user_text_10
	75. user_text_10_flag
****hw_siphon
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. crest
	17. crest_flag
	18. crown_level
	19. crown_level_flag
	20. priming_level
	21. priming_level_flag
	22. outlet_level
	23. outlet_level_flag
	24. soffit_level
	25. soffit_level_flag
	26. width
	27. width_flag
	28. cd_siphon
	29. cd_siphon_flag
	30. cd_weir
	31. cd_weir_flag
	32. number_of_siphons
	33. number_of_siphons_flag
	34. ds_settlement_eff
	35. ds_settlement_eff_flag
	36. us_settlement_eff
	37. us_settlement_eff_flag
	38. branch_id
	39. branch_id_flag
	40. hyperlinks
		 description
		 url
	41. hyperlinks_flag
	42. asset_uid
	43. infonet_id
	44. notes
	45. notes_flag
	46. user_number_1
	47. user_number_1_flag
	48. user_number_2
	49. user_number_2_flag
	50. user_number_3
	51. user_number_3_flag
	52. user_number_4
	53. user_number_4_flag
	54. user_number_5
	55. user_number_5_flag
	56. user_number_6
	57. user_number_6_flag
	58. user_number_7
	59. user_number_7_flag
	60. user_number_8
	61. user_number_8_flag
	62. user_number_9
	63. user_number_9_flag
	64. user_number_10
	65. user_number_10_flag
	66. user_text_1
	67. user_text_1_flag
	68. user_text_2
	69. user_text_2_flag
	70. user_text_3
	71. user_text_3_flag
	72. user_text_4
	73. user_text_4_flag
	74. user_text_5
	75. user_text_5_flag
	76. user_text_6
	77. user_text_6_flag
	78. user_text_7
	79. user_text_7_flag
	80. user_text_8
	81. user_text_8_flag
	82. user_text_9
	83. user_text_9_flag
	84. user_text_10
	85. user_text_10_flag
****hw_screen
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. crest
	17. crest_flag
	18. width
	19. width_flag
	20. height
	21. height_flag
	22. angle
	23. angle_flag
	24. kirschmer
	25. kirschmer_flag
	26. bar_width
	27. bar_width_flag
	28. bar_spacing
	29. bar_spacing_flag
	30. ds_settlement_eff
	31. ds_settlement_eff_flag
	32. us_settlement_eff
	33. us_settlement_eff_flag
	34. branch_id
	35. branch_id_flag
	36. hyperlinks
		 description
		 url
	37. hyperlinks_flag
	38. asset_uid
	39. infonet_id
	40. notes
	41. notes_flag
	42. user_number_1
	43. user_number_1_flag
	44. user_number_2
	45. user_number_2_flag
	46. user_number_3
	47. user_number_3_flag
	48. user_number_4
	49. user_number_4_flag
	50. user_number_5
	51. user_number_5_flag
	52. user_number_6
	53. user_number_6_flag
	54. user_number_7
	55. user_number_7_flag
	56. user_number_8
	57. user_number_8_flag
	58. user_number_9
	59. user_number_9_flag
	60. user_number_10
	61. user_number_10_flag
	62. user_text_1
	63. user_text_1_flag
	64. user_text_2
	65. user_text_2_flag
	66. user_text_3
	67. user_text_3_flag
	68. user_text_4
	69. user_text_4_flag
	70. user_text_5
	71. user_text_5_flag
	72. user_text_6
	73. user_text_6_flag
	74. user_text_7
	75. user_text_7_flag
	76. user_text_8
	77. user_text_8_flag
	78. user_text_9
	79. user_text_9_flag
	80. user_text_10
	81. user_text_10_flag
****hw_channel
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. number_of_barrels
	17. number_of_barrels_flag
	18. length
	19. length_flag
	20. shape
	21. shape_flag
	22. base_flow_depth
	23. base_flow_depth_flag
	24. sediment_depth
	25. sediment_depth_flag
	26. solution_model
	27. solution_model_flag
	28. us_invert
	29. us_invert_flag
	30. us_headloss_type
	31. us_headloss_type_flag
	32. us_headloss_coeff
	33. us_headloss_coeff_flag
	34. us_settlement_eff
	35. us_settlement_eff_flag
	36. ds_invert
	37. ds_invert_flag
	38. ds_headloss_type
	39. ds_headloss_type_flag
	40. ds_headloss_coeff
	41. ds_headloss_coeff_flag
	42. ds_settlement_eff
	43. ds_settlement_eff_flag
	44. min_computational_nodes
	45. min_computational_nodes_flag
	46. inflow
	47. inflow_flag
	48. gradient
	49. gradient_flag
	50. capacity
	51. capacity_flag
	52. is_merged
	53. branch_id
	54. branch_id_flag
	55. hyperlinks
		 description
		 url
	56. hyperlinks_flag
	57. base_height
	58. base_height_flag
	59. infiltration_coeff_base
	60. infiltration_coeff_base_flag
	61. infiltration_coeff_side
	62. infiltration_coeff_side_flag
	63. diff1d_type
	64. diff1d_type_flag
	65. diff1d_d0
	66. diff1d_d0_flag
	67. diff1d_d1
	68. diff1d_d1_flag
	69. diff1d_d2
	70. diff1d_d2_flag
	71. notes
	72. notes_flag
	73. user_number_1
	74. user_number_1_flag
	75. user_number_2
	76. user_number_2_flag
	77. user_number_3
	78. user_number_3_flag
	79. user_number_4
	80. user_number_4_flag
	81. user_number_5
	82. user_number_5_flag
	83. user_number_6
	84. user_number_6_flag
	85. user_number_7
	86. user_number_7_flag
	87. user_number_8
	88. user_number_8_flag
	89. user_number_9
	90. user_number_9_flag
	91. user_number_10
	92. user_number_10_flag
	93. user_text_1
	94. user_text_1_flag
	95. user_text_2
	96. user_text_2_flag
	97. user_text_3
	98. user_text_3_flag
	99. user_text_4
	100. user_text_4_flag
	101. user_text_5
	102. user_text_5_flag
	103. user_text_6
	104. user_text_6_flag
	105. user_text_7
	106. user_text_7_flag
	107. user_text_8
	108. user_text_8_flag
	109. user_text_9
	110. user_text_9_flag
	111. user_text_10
	112. user_text_10_flag
****hw_channel_defaults
	1. inflow
	2. ds_headloss_type
	3. us_headloss_type
	4. ds_headloss_coeff
	5. us_headloss_coeff
	6. roughness_type
	7. sediment_depth
	8. diff1d_type
	9. diff1d_d0
	10. diff1d_d1
	11. diff1d_d2
****hw_river_reach_defaults
	1. inflow
	2. ds_headloss_type
	3. us_headloss_type
	4. ds_headloss_coeff
	5. us_headloss_coeff
	6. sediment_depth
	7. aldepth_factor
	8. aldepth_factor_flag
	9. aldepth
	10. aldepth_flag
	11. max_erosion_rate
	12. max_erosion_rate_flag
	13. max_deposition_rate
	14. max_deposition_rate_flag
	15. diff1d_type
	16. diff1d_d0
	17. diff1d_d1
	18. diff1d_d2
****hw_culvert_inlet
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. invert
	17. invert_flag
	18. equation
	19. equation_flag
	20. inlet_type_code
	21. inlet_type_code_flag
	22. k
	23. k_flag
	24. m
	25. m_flag
	26. c
	27. c_flag
	28. y
	29. y_flag
	30. headloss_coeff
	31. headloss_coeff_flag
	32. reverse_flow_model
	33. reverse_flow_model_flag
	34. outlet_headloss_coeff
	35. outlet_headloss_coeff_flag
	36. ds_settlement_eff
	37. ds_settlement_eff_flag
	38. us_settlement_eff
	39. us_settlement_eff_flag
	40. branch_id
	41. branch_id_flag
	42. hyperlinks
		 description
		 url
	43. hyperlinks_flag
	44. notes
	45. notes_flag
	46. user_number_1
	47. user_number_1_flag
	48. user_number_2
	49. user_number_2_flag
	50. user_number_3
	51. user_number_3_flag
	52. user_number_4
	53. user_number_4_flag
	54. user_number_5
	55. user_number_5_flag
	56. user_number_6
	57. user_number_6_flag
	58. user_number_7
	59. user_number_7_flag
	60. user_number_8
	61. user_number_8_flag
	62. user_number_9
	63. user_number_9_flag
	64. user_number_10
	65. user_number_10_flag
	66. user_text_1
	67. user_text_1_flag
	68. user_text_2
	69. user_text_2_flag
	70. user_text_3
	71. user_text_3_flag
	72. user_text_4
	73. user_text_4_flag
	74. user_text_5
	75. user_text_5_flag
	76. user_text_6
	77. user_text_6_flag
	78. user_text_7
	79. user_text_7_flag
	80. user_text_8
	81. user_text_8_flag
	82. user_text_9
	83. user_text_9_flag
	84. user_text_10
	85. user_text_10_flag
****hw_culvert_outlet
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. invert
	17. invert_flag
	18. headloss_coeff
	19. headloss_coeff_flag
	20. reverse_flow_model
	21. reverse_flow_model_flag
	22. equation
	23. equation_flag
	24. inlet_type_code
	25. inlet_type_code_flag
	26. k
	27. k_flag
	28. m
	29. m_flag
	30. c
	31. c_flag
	32. y
	33. y_flag
	34. inlet_headloss_coeff
	35. inlet_headloss_coeff_flag
	36. us_settlement_eff
	37. us_settlement_eff_flag
	38. ds_settlement_eff
	39. ds_settlement_eff_flag
	40. branch_id
	41. branch_id_flag
	42. hyperlinks
		 description
		 url
	43. hyperlinks_flag
	44. notes
	45. notes_flag
	46. user_number_1
	47. user_number_1_flag
	48. user_number_2
	49. user_number_2_flag
	50. user_number_3
	51. user_number_3_flag
	52. user_number_4
	53. user_number_4_flag
	54. user_number_5
	55. user_number_5_flag
	56. user_number_6
	57. user_number_6_flag
	58. user_number_7
	59. user_number_7_flag
	60. user_number_8
	61. user_number_8_flag
	62. user_number_9
	63. user_number_9_flag
	64. user_number_10
	65. user_number_10_flag
	66. user_text_1
	67. user_text_1_flag
	68. user_text_2
	69. user_text_2_flag
	70. user_text_3
	71. user_text_3_flag
	72. user_text_4
	73. user_text_4_flag
	74. user_text_5
	75. user_text_5_flag
	76. user_text_6
	77. user_text_6_flag
	78. user_text_7
	79. user_text_7_flag
	80. user_text_8
	81. user_text_8_flag
	82. user_text_9
	83. user_text_9_flag
	84. user_text_10
	85. user_text_10_flag
****hw_blockage
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. system_type
	10. system_type_flag
	11. asset_id
	12. asset_id_flag
	13. sewer_reference
	14. sewer_reference_flag
	15. point_array
	16. length
	17. length_flag
	18. ds_settlement_eff
	19. ds_settlement_eff_flag
	20. us_settlement_eff
	21. us_settlement_eff_flag
	22. branch_id
	23. branch_id_flag
	24. blockage_type
	25. blockage_type_flag
	26. blockage_proportion
	27. blockage_proportion_flag
	28. inlet_loss_coefficient
	29. inlet_loss_coefficient_flag
	30. outlet_loss_coefficient
	31. outlet_loss_coefficient_flag
	32. positive_prop_change
	33. positive_prop_change_flag
	34. negative_prop_change
	35. negative_prop_change_flag
	36. threshold
	37. threshold_flag
	38. hyperlinks
		 description
		 url
	39. hyperlinks_flag
	40. asset_uid
	41. infonet_id
	42. notes
	43. notes_flag
	44. user_number_1
	45. user_number_1_flag
	46. user_number_2
	47. user_number_2_flag
	48. user_number_3
	49. user_number_3_flag
	50. user_number_4
	51. user_number_4_flag
	52. user_number_5
	53. user_number_5_flag
	54. user_number_6
	55. user_number_6_flag
	56. user_number_7
	57. user_number_7_flag
	58. user_number_8
	59. user_number_8_flag
	60. user_number_9
	61. user_number_9_flag
	62. user_number_10
	63. user_number_10_flag
	64. user_text_1
	65. user_text_1_flag
	66. user_text_2
	67. user_text_2_flag
	68. user_text_3
	69. user_text_3_flag
	70. user_text_4
	71. user_text_4_flag
	72. user_text_5
	73. user_text_5_flag
	74. user_text_6
	75. user_text_6_flag
	76. user_text_7
	77. user_text_7_flag
	78. user_text_8
	79. user_text_8_flag
	80. user_text_9
	81. user_text_9_flag
	82. user_text_10
	83. user_text_10_flag
****hw_bridge_blockage
	1. id
	2. id_flag
	3. bridge_us_node_id
	4. bridge_us_node_id_flag
	5. bridge_link_suffix
	6. bridge_link_suffix_flag
	7. system_type
	8. system_type_flag
	9. asset_id
	10. asset_id_flag
	11. point_array
	12. blockage_proportion
	13. blockage_proportion_flag
	14. inlet_loss_coefficient
	15. inlet_loss_coefficient_flag
	16. outlet_loss_coefficient
	17. outlet_loss_coefficient_flag
	18. positive_prop_change
	19. positive_prop_change_flag
	20. negative_prop_change
	21. negative_prop_change_flag
	22. threshold
	23. threshold_flag
	24. hyperlinks
		 description
		 url
	25. hyperlinks_flag
	26. notes
	27. notes_flag
	28. user_number_1
	29. user_number_1_flag
	30. user_number_2
	31. user_number_2_flag
	32. user_number_3
	33. user_number_3_flag
	34. user_number_4
	35. user_number_4_flag
	36. user_number_5
	37. user_number_5_flag
	38. user_number_6
	39. user_number_6_flag
	40. user_number_7
	41. user_number_7_flag
	42. user_number_8
	43. user_number_8_flag
	44. user_number_9
	45. user_number_9_flag
	46. user_number_10
	47. user_number_10_flag
	48. user_text_1
	49. user_text_1_flag
	50. user_text_2
	51. user_text_2_flag
	52. user_text_3
	53. user_text_3_flag
	54. user_text_4
	55. user_text_4_flag
	56. user_text_5
	57. user_text_5_flag
	58. user_text_6
	59. user_text_6_flag
	60. user_text_7
	61. user_text_7_flag
	62. user_text_8
	63. user_text_8_flag
	64. user_text_9
	65. user_text_9_flag
	66. user_text_10
	67. user_text_10_flag
****hw_shape
	1. shape_id
	2. shape_id_flag
	3. shape_type
	4. shape_type_flag
	5. shape_description
	6. shape_description_flag
	7. geometry
		 height
		 left
		 right
	8. geometry_flag
	9. hyperlinks
		 description
		 url
	10. hyperlinks_flag
	11. normalised
	12. notes
	13. notes_flag
	14. user_number_1
	15. user_number_1_flag
	16. user_number_2
	17. user_number_2_flag
	18. user_number_3
	19. user_number_3_flag
	20. user_number_4
	21. user_number_4_flag
	22. user_number_5
	23. user_number_5_flag
	24. user_number_6
	25. user_number_6_flag
	26. user_number_7
	27. user_number_7_flag
	28. user_number_8
	29. user_number_8_flag
	30. user_number_9
	31. user_number_9_flag
	32. user_number_10
	33. user_number_10_flag
	34. user_text_1
	35. user_text_1_flag
	36. user_text_2
	37. user_text_2_flag
	38. user_text_3
	39. user_text_3_flag
	40. user_text_4
	41. user_text_4_flag
	42. user_text_5
	43. user_text_5_flag
	44. user_text_6
	45. user_text_6_flag
	46. user_text_7
	47. user_text_7_flag
	48. user_text_8
	49. user_text_8_flag
	50. user_text_9
	51. user_text_9_flag
	52. user_text_10
	53. user_text_10_flag
****hw_head_discharge
	1. head_discharge_id
	2. head_discharge_id_flag
	3. head_discharge_description
	4. head_discharge_description_flag
	5. HDP_table
		 head
		 discharge
		 power
	6. HDP_table_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_runoff_surface
	1. runoff_index
	2. runoff_index_flag
	3. surface_description
	4. surface_description_flag
	5. runoff_routing_type
	6. runoff_routing_type_flag
	7. runoff_routing_value
	8. runoff_routing_value_flag
	9. runoff_volume_type
	10. runoff_volume_type_flag
	11. surface_type
	12. surface_type_flag
	13. ground_slope
	14. ground_slope_flag
	15. initial_loss_type
	16. initial_loss_type_flag
	17. initial_loss_value
	18. initial_loss_value_flag
	19. initial_abstraction_factor
	20. initial_abstraction_factor_flag
	21. routing_model
	22. routing_model_flag
	23. runoff_coefficient
	24. runoff_coefficient_flag
	25. minimum_runoff
	26. minimum_runoff_flag
	27. maximum_runoff
	28. maximum_runoff_flag
	29. rafts_adapt_factor
	30. rafts_adapt_factor_flag
	31. equivalent_roughness
	32. equivalent_roughness_flag
	33. runoff_distribution_factor
	34. runoff_distribution_factor_flag
	35. moisture_depth_parameter
	36. moisture_depth_parameter_flag
	37. storage_depth
	38. storage_depth_flag
	39. initial_infiltration
	40. initial_infiltration_flag
	41. limiting_infiltration
	42. limiting_infiltration_flag
	43. decay_factor
	44. decay_factor_flag
	45. drying_time
	46. drying_time_flag
	47. max_infiltration_volume
	48. max_infiltration_volume_flag
	49. recovery_factor
	50. recovery_factor_flag
	51. number_of_reservoirs
	52. number_of_reservoirs_flag
	53. depression_loss
	54. depression_loss_flag
	55. average_capillary_suction
	56. average_capillary_suction_flag
	57. saturated_hydraulic_conductivity
	58. saturated_hydraulic_conductivity_flag
	59. initial_moisture_deficit
	60. initial_moisture_deficit_flag
	61. halpha
	62. halpha_flag
	63. hbeta
	64. hbeta_flag
	65. hrecovery
	66. hrecovery_flag
	67. initial_loss_porosity
	68. initial_loss_porosity_flag
	69. infiltration_coeff
	70. infiltration_coeff_flag
	71. maximum_deficit
	72. maximum_deficit_flag
	73. hyperlinks
		 description
		 url
	74. hyperlinks_flag
	75. effective_impermeability
	76. effective_impermeability_flag
	77. precipitation_decay
	78. precipitation_decay_flag
	79. power_coeff_paved
	80. power_coeff_paved_flag
	81. storage_depth_paved
	82. storage_depth_paved_flag
	83. napi_decay_coeff
	84. napi_decay_coeff_flag
	85. power_coeff_pervious
	86. power_coeff_pervious_flag
	87. storage_depth_pervious
	88. storage_depth_pervious_flag
	89. minimum_napi
	90. minimum_napi_flag
	91. saturated_rainfall
	92. saturated_rainfall_flag
	93. notes
	94. notes_flag
	95. user_number_1
	96. user_number_1_flag
	97. user_number_2
	98. user_number_2_flag
	99. user_number_3
	100. user_number_3_flag
	101. user_number_4
	102. user_number_4_flag
	103. user_number_5
	104. user_number_5_flag
	105. user_number_6
	106. user_number_6_flag
	107. user_number_7
	108. user_number_7_flag
	109. user_number_8
	110. user_number_8_flag
	111. user_number_9
	112. user_number_9_flag
	113. user_number_10
	114. user_number_10_flag
	115. user_text_1
	116. user_text_1_flag
	117. user_text_2
	118. user_text_2_flag
	119. user_text_3
	120. user_text_3_flag
	121. user_text_4
	122. user_text_4_flag
	123. user_text_5
	124. user_text_5_flag
	125. user_text_6
	126. user_text_6_flag
	127. user_text_7
	128. user_text_7_flag
	129. user_text_8
	130. user_text_8_flag
	131. user_text_9
	132. user_text_9_flag
	133. user_text_10
	134. user_text_10_flag
****hw_land_use
	1. land_use_id
	2. land_use_id_flag
	3. population_density
	4. population_density_flag
	5. wastewater_profile
	6. wastewater_profile_flag
	7. connectivity
	8. connectivity_flag
	9. pollution_index
	10. pollution_index_flag
	11. land_use_description
	12. land_use_description_flag
	13. runoff_index_1
	14. runoff_index_1_flag
	15. p_area_1
	16. p_area_1_flag
	17. runoff_index_2
	18. runoff_index_2_flag
	19. p_area_2
	20. p_area_2_flag
	21. runoff_index_3
	22. runoff_index_3_flag
	23. p_area_3
	24. p_area_3_flag
	25. runoff_index_4
	26. runoff_index_4_flag
	27. p_area_4
	28. p_area_4_flag
	29. runoff_index_5
	30. runoff_index_5_flag
	31. p_area_5
	32. p_area_5_flag
	33. runoff_index_6
	34. runoff_index_6_flag
	35. p_area_6
	36. p_area_6_flag
	37. runoff_index_7
	38. runoff_index_7_flag
	39. p_area_7
	40. p_area_7_flag
	41. runoff_index_8
	42. runoff_index_8_flag
	43. p_area_8
	44. p_area_8_flag
	45. runoff_index_9
	46. runoff_index_9_flag
	47. p_area_9
	48. p_area_9_flag
	49. runoff_index_10
	50. runoff_index_10_flag
	51. p_area_10
	52. p_area_10_flag
	53. runoff_index_11
	54. runoff_index_11_flag
	55. p_area_11
	56. p_area_11_flag
	57. runoff_index_12
	58. runoff_index_12_flag
	59. p_area_12
	60. p_area_12_flag
	61. hyperlinks
		 description
		 url
	62. hyperlinks_flag
	63. notes
	64. notes_flag
	65. user_number_1
	66. user_number_1_flag
	67. user_number_2
	68. user_number_2_flag
	69. user_number_3
	70. user_number_3_flag
	71. user_number_4
	72. user_number_4_flag
	73. user_number_5
	74. user_number_5_flag
	75. user_number_6
	76. user_number_6_flag
	77. user_number_7
	78. user_number_7_flag
	79. user_number_8
	80. user_number_8_flag
	81. user_number_9
	82. user_number_9_flag
	83. user_number_10
	84. user_number_10_flag
	85. user_text_1
	86. user_text_1_flag
	87. user_text_2
	88. user_text_2_flag
	89. user_text_3
	90. user_text_3_flag
	91. user_text_4
	92. user_text_4_flag
	93. user_text_5
	94. user_text_5_flag
	95. user_text_6
	96. user_text_6_flag
	97. user_text_7
	98. user_text_7_flag
	99. user_text_8
	100. user_text_8_flag
	101. user_text_9
	102. user_text_9_flag
	103. user_text_10
	104. user_text_10_flag
****hw_snow_pack
	1. ID
	2. ID_flag
	3. fraction_ploughable
	4. fraction_ploughable_flag
	5. plough_snow_depth
	6. plough_snow_depth_flag
	7. imp_snow_depth
	8. imp_snow_depth_flag
	9. perv_snow_depth
	10. perv_snow_depth_flag
	11. plough_min_melt
	12. plough_min_melt_flag
	13. imp_min_melt
	14. imp_min_melt_flag
	15. perv_min_melt
	16. perv_min_melt_flag
	17. plough_max_melt
	18. plough_max_melt_flag
	19. imp_max_melt
	20. imp_max_melt_flag
	21. perv_max_melt
	22. perv_max_melt_flag
	23. plough_base_temp
	24. plough_base_temp_flag
	25. imp_base_temp
	26. imp_base_temp_flag
	27. perv_base_temp
	28. perv_base_temp_flag
	29. plough_free_water
	30. plough_free_water_flag
	31. imp_free_water
	32. imp_free_water_flag
	33. perv_free_water
	34. perv_free_water_flag
	35. plough_depth
	36. plough_depth_flag
	37. out_of_watershed
	38. out_of_watershed_flag
	39. to_impervious
	40. to_impervious_flag
	41. to_pervious
	42. to_pervious_flag
	43. to_immediate_melt
	44. to_immediate_melt_flag
	45. to_subcatchment
	46. to_subcatchment_flag
	47. subcatchment_id
	48. subcatchment_id_flag
	49. hyperlinks
		 description
		 url
	50. hyperlinks_flag
	51. notes
	52. notes_flag
	53. user_number_1
	54. user_number_1_flag
	55. user_number_2
	56. user_number_2_flag
	57. user_number_3
	58. user_number_3_flag
	59. user_number_4
	60. user_number_4_flag
	61. user_number_5
	62. user_number_5_flag
	63. user_number_6
	64. user_number_6_flag
	65. user_number_7
	66. user_number_7_flag
	67. user_number_8
	68. user_number_8_flag
	69. user_number_9
	70. user_number_9_flag
	71. user_number_10
	72. user_number_10_flag
	73. user_text_1
	74. user_text_1_flag
	75. user_text_2
	76. user_text_2_flag
	77. user_text_3
	78. user_text_3_flag
	79. user_text_4
	80. user_text_4_flag
	81. user_text_5
	82. user_text_5_flag
	83. user_text_6
	84. user_text_6_flag
	85. user_text_7
	86. user_text_7_flag
	87. user_text_8
	88. user_text_8_flag
	89. user_text_9
	90. user_text_9_flag
	91. user_text_10
	92. user_text_10_flag
****hw_headloss
	1. headloss_type
	2. headloss_type_flag
	3. curve_type
	4. curve_type_flag
	5. min_surcharge_ratio
	6. min_surcharge_ratio_flag
	7. surcharge_ratio_step
	8. surcharge_ratio_step_flag
	9. surcharge_ratio_factor_array
	10. surcharge_ratio_factor_array_flag
	11. min_velocity
	12. min_velocity_flag
	13. velocity_step
	14. velocity_step_flag
	15. velocity_factor_array
	16. velocity_factor_array_flag
	17. hyperlinks
		 description
		 url
	18. hyperlinks_flag
	19. notes
	20. notes_flag
	21. user_number_1
	22. user_number_1_flag
	23. user_number_2
	24. user_number_2_flag
	25. user_number_3
	26. user_number_3_flag
	27. user_number_4
	28. user_number_4_flag
	29. user_number_5
	30. user_number_5_flag
	31. user_number_6
	32. user_number_6_flag
	33. user_number_7
	34. user_number_7_flag
	35. user_number_8
	36. user_number_8_flag
	37. user_number_9
	38. user_number_9_flag
	39. user_number_10
	40. user_number_10_flag
	41. user_text_1
	42. user_text_1_flag
	43. user_text_2
	44. user_text_2_flag
	45. user_text_3
	46. user_text_3_flag
	47. user_text_4
	48. user_text_4_flag
	49. user_text_5
	50. user_text_5_flag
	51. user_text_6
	52. user_text_6_flag
	53. user_text_7
	54. user_text_7_flag
	55. user_text_8
	56. user_text_8_flag
	57. user_text_9
	58. user_text_9_flag
	59. user_text_10
	60. user_text_10_flag
****hw_ground_infiltration
	1. ground_id
	2. ground_id_flag
	3. soil_depth
	4. soil_depth_flag
	5. percolation_coefficient
	6. percolation_coefficient_flag
	7. baseflow_coefficient
	8. baseflow_coefficient_flag
	9. infiltration_coefficient
	10. infiltration_coefficient_flag
	11. percolation_threshold
	12. percolation_threshold_flag
	13. percolation_percentage
	14. percolation_percentage_flag
	15. soil_porosity
	16. soil_porosity_flag
	17. ground_porosity
	18. ground_porosity_flag
	19. baseflow_threshold
	20. baseflow_threshold_flag
	21. baseflow_threshold_type
	22. baseflow_threshold_type_flag
	23. infiltration_threshold
	24. infiltration_threshold_flag
	25. infiltration_threshold_type
	26. infiltration_threshold_type_flag
	27. hyperlinks
		 description
		 url
	28. hyperlinks_flag
	29. evapotranspiration_type
	30. evapotranspiration_type_flag
	31. evapotranspiration_depth
	32. evapotranspiration_depth_flag
	33. evapotranspiration_fac_Jan
	34. evapotranspiration_fac_Jan_flag
	35. evapotranspiration_fac_Feb
	36. evapotranspiration_fac_Feb_flag
	37. evapotranspiration_fac_Mar
	38. evapotranspiration_fac_Mar_flag
	39. evapotranspiration_fac_Apr
	40. evapotranspiration_fac_Apr_flag
	41. evapotranspiration_fac_May
	42. evapotranspiration_fac_May_flag
	43. evapotranspiration_fac_Jun
	44. evapotranspiration_fac_Jun_flag
	45. evapotranspiration_fac_Jul
	46. evapotranspiration_fac_Jul_flag
	47. evapotranspiration_fac_Aug
	48. evapotranspiration_fac_Aug_flag
	49. evapotranspiration_fac_Sep
	50. evapotranspiration_fac_Sep_flag
	51. evapotranspiration_fac_Oct
	52. evapotranspiration_fac_Oct_flag
	53. evapotranspiration_fac_Nov
	54. evapotranspiration_fac_Nov_flag
	55. evapotranspiration_fac_Dec
	56. evapotranspiration_fac_Dec_flag
	57. notes
	58. notes_flag
	59. user_number_1
	60. user_number_1_flag
	61. user_number_2
	62. user_number_2_flag
	63. user_number_3
	64. user_number_3_flag
	65. user_number_4
	66. user_number_4_flag
	67. user_number_5
	68. user_number_5_flag
	69. user_number_6
	70. user_number_6_flag
	71. user_number_7
	72. user_number_7_flag
	73. user_number_8
	74. user_number_8_flag
	75. user_number_9
	76. user_number_9_flag
	77. user_number_10
	78. user_number_10_flag
	79. user_text_1
	80. user_text_1_flag
	81. user_text_2
	82. user_text_2_flag
	83. user_text_3
	84. user_text_3_flag
	85. user_text_4
	86. user_text_4_flag
	87. user_text_5
	88. user_text_5_flag
	89. user_text_6
	90. user_text_6_flag
	91. user_text_7
	92. user_text_7_flag
	93. user_text_8
	94. user_text_8_flag
	95. user_text_9
	96. user_text_9_flag
	97. user_text_10
	98. user_text_10_flag
****hw_subcatchment
	1. subcatchment_id
	2. subcatchment_id_flag
	3. system_type
	4. system_type_flag
	5. lateral_links
		 node_id
		 link_suffix
		 weight
	6. lateral_links_flag
	7. refh_descriptors
		 bfihost
		 propwet
		 dplbar
		 dpsbar
		 urbext1990
		 urbext2000
		 urbext_choice
		 cmax_method
		 cmax_factor
		 tp_method
		 tp_factor
		 up_method
		 up_factor
		 uk_method
		 uk_factor
		 bl_method
		 bl_factor
		 br_method
		 br_factor
		 model_type
		 IsDirty
		 country
		 scale
		 saar
		 refh2_version
		 cmax_value
		 cmax_flag
		 tp_value
		 tp_flag
		 uk_value
		 uk_flag
		 up_value
		 up_flag
		 bl_value
		 bl_flag
		 br_value
		 br_flag
	8. refh_descriptors_flag
	9. drains_to
	10. drains_to_flag
	11. node_id
	12. node_id_flag
	13. link_suffix
	14. link_suffix_flag
	15. to_subcatchment_id
	16. to_subcatchment_id_flag
	17. 2d_pt_id
	18. 2d_pt_id_flag
	19. lateral_weights
	20. lateral_weights_flag
	21. boundary_array
	22. suds_controls
		 id
		 suds_structure
		 control_type
		 area
		 num_units
		 area_subcatchment_pct
		 unit_surface_width
		 initial_saturation_pct
		 impervious_area_treated_pct
		 outflow_to
		 drain_to_subcatchment
		 drain_to_node
		 surface
		 pervious_area_treated_pct
	23. suds_controls_flag
	24. swmm_coverage
		 land_use
		 area
	25. capacity_limit
	26. capacity_limit_flag
	27. exceed_flow_type
	28. exceed_flow_type_flag
	29. total_area
	30. total_area_flag
	31. contributing_area
	32. contributing_area_flag
	33. x
	34. x_flag
	35. y
	36. y_flag
	37. catchment_slope
	38. catchment_slope_flag
	39. ukwir_soil_runoff
	40. ukwir_soil_runoff_flag
	41. soil_class_type
	42. soil_class_type_flag
	43. soil_class
	44. soil_class_flag
	45. soil_class_host
	46. soil_class_host_flag
	47. max_soil_moisture_capacity
	48. max_soil_moisture_capacity_flag
	49. curve_number
	50. curve_number_flag
	51. drying_time
	52. drying_time_flag
	53. rainfall_profile
	54. rainfall_profile_flag
	55. evaporation_profile
	56. evaporation_profile_flag
	57. area_average_rain
	58. area_average_rain_flag
	59. catchment_dimension
	60. catchment_dimension_flag
	61. unit_hydrograph_id
	62. unit_hydrograph_id_flag
	63. snow_pack_id
	64. snow_pack_id_flag
	65. baseflow_calc
	66. baseflow_calc_flag
	67. soil_moist_def
	68. soil_moist_def_flag
	69. srm_runoff_coeff
	70. srm_runoff_coeff_flag
	71. srm_k1
	72. srm_k1_flag
	73. srm_k2
	74. srm_k2_flag
	75. srm_tdly
	76. srm_tdly_flag
	77. arma_id
	78. arma_id_flag
	79. output_lag
	80. output_lag_flag
	81. bypass_runoff
	82. bypass_runoff_flag
	83. uh_definition
	84. uh_definition_flag
	85. tc_method
	86. tc_method_flag
	87. overland_flow_time
	88. overland_flow_time_flag
	89. flood_wave_celerity
	90. flood_wave_celerity_flag
	91. equivalent_roughness
	92. equivalent_roughness_flag
	93. hydraulic_radius
	94. hydraulic_radius_flag
	95. pwri_coefficient
	96. pwri_coefficient_flag
	97. time_of_concentration
	98. time_of_concentration_flag
	99. tc_timestep_factor
	100. tc_timestep_factor_flag
	101. tc_time_to_peak_factor
	102. tc_time_to_peak_factor_flag
	103. time_to_peak
	104. time_to_peak_flag
	105. base_time
	106. base_time_flag
	107. lag_time
	108. lag_time_flag
	109. peaking_coeff
	110. peaking_coeff_flag
	111. uh_peak
	112. uh_peak_flag
	113. uh_kink
	114. uh_kink_flag
	115. non-linear_routing_method
	116. non-linear_routing_method_flag
	117. lag_time_method
	118. lag_time_method_flag
	119. storage_factor
	120. storage_factor_flag
	121. storage_exponent
	122. storage_exponent_flag
	123. internal_routing
	124. internal_routing_flag
	125. percent_routed
	126. percent_routed_flag
	127. rafts_per_surface
	128. degree_urbanisation
	129. degree_urbanisation_flag
	130. rafts_adapt_factor
	131. rafts_adapt_factor_flag
	132. rafts_b
	133. rafts_b_flag
	134. rafts_n
	135. rafts_n_flag
	136. connectivity
	137. connectivity_flag
	138. wastewater_profile
	139. wastewater_profile_flag
	140. population
	141. population_flag
	142. trade_flow
	143. trade_flow_flag
	144. additional_foul_flow
	145. additional_foul_flow_flag
	146. base_flow
	147. base_flow_flag
	148. trade_profile
	149. trade_profile_flag
	150. ground_id
	151. ground_id_flag
	152. ground_node
	153. ground_node_flag
	154. baseflow_lag
	155. baseflow_lag_flag
	156. baseflow_recharge
	157. baseflow_recharge_flag
	158. land_use_id
	159. land_use_id_flag
	160. pdm_descriptor_id
	161. pdm_descriptor_id_flag
	162. area_measurement_type
	163. area_measurement_type_flag
	164. area_absolute_1
	165. area_absolute_1_flag
	166. area_absolute_2
	167. area_absolute_2_flag
	168. area_absolute_3
	169. area_absolute_3_flag
	170. area_absolute_4
	171. area_absolute_4_flag
	172. area_absolute_5
	173. area_absolute_5_flag
	174. area_absolute_6
	175. area_absolute_6_flag
	176. area_absolute_7
	177. area_absolute_7_flag
	178. area_absolute_8
	179. area_absolute_8_flag
	180. area_absolute_9
	181. area_absolute_9_flag
	182. area_absolute_10
	183. area_absolute_10_flag
	184. area_absolute_11
	185. area_absolute_11_flag
	186. area_absolute_12
	187. area_absolute_12_flag
	188. area_percent_1
	189. area_percent_1_flag
	190. area_percent_2
	191. area_percent_2_flag
	192. area_percent_3
	193. area_percent_3_flag
	194. area_percent_4
	195. area_percent_4_flag
	196. area_percent_5
	197. area_percent_5_flag
	198. area_percent_6
	199. area_percent_6_flag
	200. area_percent_7
	201. area_percent_7_flag
	202. area_percent_8
	203. area_percent_8_flag
	204. area_percent_9
	205. area_percent_9_flag
	206. area_percent_10
	207. area_percent_10_flag
	208. area_percent_11
	209. area_percent_11_flag
	210. area_percent_12
	211. area_percent_12_flag
	212. notes
	213. notes_flag
	214. hyperlinks
		 description
		 url
	215. hyperlinks_flag
	216. user_number_1
	217. user_number_1_flag
	218. user_number_2
	219. user_number_2_flag
	220. user_number_3
	221. user_number_3_flag
	222. user_number_4
	223. user_number_4_flag
	224. user_number_5
	225. user_number_5_flag
	226. user_number_6
	227. user_number_6_flag
	228. user_number_7
	229. user_number_7_flag
	230. user_number_8
	231. user_number_8_flag
	232. user_number_9
	233. user_number_9_flag
	234. user_number_10
	235. user_number_10_flag
	236. user_text_1
	237. user_text_1_flag
	238. user_text_2
	239. user_text_2_flag
	240. user_text_3
	241. user_text_3_flag
	242. user_text_4
	243. user_text_4_flag
	244. user_text_5
	245. user_text_5_flag
	246. user_text_6
	247. user_text_6_flag
	248. user_text_7
	249. user_text_7_flag
	250. user_text_8
	251. user_text_8_flag
	252. user_text_9
	253. user_text_9_flag
	254. user_text_10
	255. user_text_10_flag
****hw_polygon
	1. polygon_id
	2. polygon_id_flag
	3. category_id
	4. category_id_flag
	5. area
	6. area_flag
	7. boundary_array
	8. hyperlinks
		 description
		 url
	9. hyperlinks_flag
	10. notes
	11. notes_flag
	12. user_number_1
	13. user_number_1_flag
	14. user_number_2
	15. user_number_2_flag
	16. user_number_3
	17. user_number_3_flag
	18. user_number_4
	19. user_number_4_flag
	20. user_number_5
	21. user_number_5_flag
	22. user_number_6
	23. user_number_6_flag
	24. user_number_7
	25. user_number_7_flag
	26. user_number_8
	27. user_number_8_flag
	28. user_number_9
	29. user_number_9_flag
	30. user_number_10
	31. user_number_10_flag
	32. user_text_1
	33. user_text_1_flag
	34. user_text_2
	35. user_text_2_flag
	36. user_text_3
	37. user_text_3_flag
	38. user_text_4
	39. user_text_4_flag
	40. user_text_5
	41. user_text_5_flag
	42. user_text_6
	43. user_text_6_flag
	44. user_text_7
	45. user_text_7_flag
	46. user_text_8
	47. user_text_8_flag
	48. user_text_9
	49. user_text_9_flag
	50. user_text_10
	51. user_text_10_flag
****hw_unit_hydrograph
	1. ID
	2. ID_flag
	3. R1
	4. R1_flag
	5. T1
	6. T1_flag
	7. K1
	8. K1_flag
	9. R2
	10. R2_flag
	11. T2
	12. T2_flag
	13. K2
	14. K2_flag
	15. R3
	16. R3_flag
	17. T3
	18. T3_flag
	19. K3
	20. K3_flag
	21. Dmax1
	22. Dmax1_flag
	23. Drec1
	24. Drec1_flag
	25. D01
	26. D01_flag
	27. Dmax2
	28. Dmax2_flag
	29. Drec2
	30. Drec2_flag
	31. D02
	32. D02_flag
	33. Dmax3
	34. Dmax3_flag
	35. Drec3
	36. Drec3_flag
	37. D03
	38. D03_flag
	39. hyperlinks
		 description
		 url
	40. hyperlinks_flag
	41. notes
	42. notes_flag
	43. user_number_1
	44. user_number_1_flag
	45. user_number_2
	46. user_number_2_flag
	47. user_number_3
	48. user_number_3_flag
	49. user_number_4
	50. user_number_4_flag
	51. user_number_5
	52. user_number_5_flag
	53. user_number_6
	54. user_number_6_flag
	55. user_number_7
	56. user_number_7_flag
	57. user_number_8
	58. user_number_8_flag
	59. user_number_9
	60. user_number_9_flag
	61. user_number_10
	62. user_number_10_flag
	63. user_text_1
	64. user_text_1_flag
	65. user_text_2
	66. user_text_2_flag
	67. user_text_3
	68. user_text_3_flag
	69. user_text_4
	70. user_text_4_flag
	71. user_text_5
	72. user_text_5_flag
	73. user_text_6
	74. user_text_6_flag
	75. user_text_7
	76. user_text_7_flag
	77. user_text_8
	78. user_text_8_flag
	79. user_text_9
	80. user_text_9_flag
	81. user_text_10
	82. user_text_10_flag
****hw_unit_hydrograph_month
	1. ID
	2. ID_flag
	3. Month
	4. Month_flag
	5. R1
	6. R1_flag
	7. T1
	8. T1_flag
	9. K1
	10. K1_flag
	11. R2
	12. R2_flag
	13. T2
	14. T2_flag
	15. K2
	16. K2_flag
	17. R3
	18. R3_flag
	19. T3
	20. T3_flag
	21. K3
	22. K3_flag
	23. Dmax1
	24. Dmax1_flag
	25. Drec1
	26. Drec1_flag
	27. D01
	28. D01_flag
	29. Dmax2
	30. Dmax2_flag
	31. Drec2
	32. Drec2_flag
	33. D02
	34. D02_flag
	35. Dmax3
	36. Dmax3_flag
	37. Drec3
	38. Drec3_flag
	39. D03
	40. D03_flag
	41. hyperlinks
		 description
		 url
	42. hyperlinks_flag
	43. notes
	44. notes_flag
	45. user_number_1
	46. user_number_1_flag
	47. user_number_2
	48. user_number_2_flag
	49. user_number_3
	50. user_number_3_flag
	51. user_number_4
	52. user_number_4_flag
	53. user_number_5
	54. user_number_5_flag
	55. user_number_6
	56. user_number_6_flag
	57. user_number_7
	58. user_number_7_flag
	59. user_number_8
	60. user_number_8_flag
	61. user_number_9
	62. user_number_9_flag
	63. user_number_10
	64. user_number_10_flag
	65. user_text_1
	66. user_text_1_flag
	67. user_text_2
	68. user_text_2_flag
	69. user_text_3
	70. user_text_3_flag
	71. user_text_4
	72. user_text_4_flag
	73. user_text_5
	74. user_text_5_flag
	75. user_text_6
	76. user_text_6_flag
	77. user_text_7
	78. user_text_7_flag
	79. user_text_8
	80. user_text_8_flag
	81. user_text_9
	82. user_text_9_flag
	83. user_text_10
	84. user_text_10_flag
****hw_channel_shape
	1. shape_id
	2. shape_id_flag
	3. profile
		 X
		 Z
		 roughness_CW
		 roughness_Manning
		 new_panel
		 roughness_N
	4. profile_flag
	5. roughness_type
	6. roughness_type_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_general_line
	1. line_id
	2. line_id_flag
	3. asset_id
	4. asset_id_flag
	5. general_line_xy
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. category
	9. category_flag
	10. length
	11. length_flag
	12. notes
	13. notes_flag
	14. user_number_1
	15. user_number_1_flag
	16. user_number_2
	17. user_number_2_flag
	18. user_number_3
	19. user_number_3_flag
	20. user_number_4
	21. user_number_4_flag
	22. user_number_5
	23. user_number_5_flag
	24. user_number_6
	25. user_number_6_flag
	26. user_number_7
	27. user_number_7_flag
	28. user_number_8
	29. user_number_8_flag
	30. user_number_9
	31. user_number_9_flag
	32. user_number_10
	33. user_number_10_flag
	34. user_text_1
	35. user_text_1_flag
	36. user_text_2
	37. user_text_2_flag
	38. user_text_3
	39. user_text_3_flag
	40. user_text_4
	41. user_text_4_flag
	42. user_text_5
	43. user_text_5_flag
	44. user_text_6
	45. user_text_6_flag
	46. user_text_7
	47. user_text_7_flag
	48. user_text_8
	49. user_text_8_flag
	50. user_text_9
	51. user_text_9_flag
	52. user_text_10
	53. user_text_10_flag
****hw_porous_wall
	1. line_id
	2. line_id_flag
	3. asset_id
	4. asset_id_flag
	5. porosity
	6. porosity_flag
	7. crest_level
	8. crest_level_flag
	9. general_line_xy
	10. height
	11. height_flag
	12. level
	13. level_flag
	14. remove_wall
	15. remove_wall_flag
	16. wall_removal_trigger
	17. wall_removal_trigger_flag
	18. use_diff_across_wall
	19. use_diff_across_wall_flag
	20. depth_threshold
	21. depth_threshold_flag
	22. elevation_threshold
	23. elevation_threshold_flag
	24. velocity_threshold
	25. velocity_threshold_flag
	26. unit_flow_threshold
	27. unit_flow_threshold_flag
	28. total_head_threshold
	29. total_head_threshold_flag
	30. force_threshold
	31. force_threshold_flag
	32. hydro_press_coeff
	33. hydro_press_coeff_flag
	34. hyperlinks
		 description
		 url
	35. hyperlinks_flag
	36. length
	37. length_flag
	38. notes
	39. notes_flag
	40. user_number_1
	41. user_number_1_flag
	42. user_number_2
	43. user_number_2_flag
	44. user_number_3
	45. user_number_3_flag
	46. user_number_4
	47. user_number_4_flag
	48. user_number_5
	49. user_number_5_flag
	50. user_number_6
	51. user_number_6_flag
	52. user_number_7
	53. user_number_7_flag
	54. user_number_8
	55. user_number_8_flag
	56. user_number_9
	57. user_number_9_flag
	58. user_number_10
	59. user_number_10_flag
	60. user_text_1
	61. user_text_1_flag
	62. user_text_2
	63. user_text_2_flag
	64. user_text_3
	65. user_text_3_flag
	66. user_text_4
	67. user_text_4_flag
	68. user_text_5
	69. user_text_5_flag
	70. user_text_6
	71. user_text_6_flag
	72. user_text_7
	73. user_text_7_flag
	74. user_text_8
	75. user_text_8_flag
	76. user_text_9
	77. user_text_9_flag
	78. user_text_10
	79. user_text_10_flag
****hw_2d_zone
	1. zone_id
	2. zone_id_flag
	3. boundary_type
	4. boundary_type_flag
	5. area
	6. area_flag
	7. max_triangle_area
	8. max_triangle_area_flag
	9. min_mesh_element_area
	10. min_mesh_element_area_flag
	11. max_height_variation
	12. max_height_variation_flag
	13. mesh_generation
	14. mesh_generation_flag
	15. terrain_sensitive_mesh
	16. terrain_sensitive_mesh_flag
	17. boundary_array
	18. minimum_angle
	19. minimum_angle_flag
	20. roughness
	21. roughness_flag
	22. roughness_definition_id
	23. roughness_definition_id_flag
	24. apply_rainfall_directly
	25. apply_rainfall_directly_flag
	26. apply_rainfall_subcatch
	27. apply_rainfall_subcatch_flag
	28. rainfall_profile
	29. rainfall_profile_flag
	30. infiltration_surface_id
	31. infiltration_surface_id_flag
	32. turbulence_model_id
	33. turbulence_model_id_flag
	34. rainfall_percentage
	35. rainfall_percentage_flag
	36. mesh_summary
	37. mesh_summary_flag
	38. hyperlinks
		 description
		 url
	39. hyperlinks_flag
	40. notes
	41. notes_flag
	42. user_number_1
	43. user_number_1_flag
	44. user_number_2
	45. user_number_2_flag
	46. user_number_3
	47. user_number_3_flag
	48. user_number_4
	49. user_number_4_flag
	50. user_number_5
	51. user_number_5_flag
	52. user_number_6
	53. user_number_6_flag
	54. user_number_7
	55. user_number_7_flag
	56. user_number_8
	57. user_number_8_flag
	58. user_number_9
	59. user_number_9_flag
	60. user_number_10
	61. user_number_10_flag
	62. user_text_1
	63. user_text_1_flag
	64. user_text_2
	65. user_text_2_flag
	66. user_text_3
	67. user_text_3_flag
	68. user_text_4
	69. user_text_4_flag
	70. user_text_5
	71. user_text_5_flag
	72. user_text_6
	73. user_text_6_flag
	74. user_text_7
	75. user_text_7_flag
	76. user_text_8
	77. user_text_8_flag
	78. user_text_9
	79. user_text_9_flag
	80. user_text_10
	81. user_text_10_flag
****hw_mesh_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. max_triangle_area
	6. max_triangle_area_flag
	7. apply_min_elt_size
	8. apply_min_elt_size_flag
	9. min_mesh_element_area
	10. min_mesh_element_area_flag
	11. ground_level_mod
	12. ground_level_mod_flag
	13. raise_by
	14. raise_by_flag
	15. level
	16. level_flag
	17. boundary_array
	18. hyperlinks
		 description
		 url
	19. hyperlinks_flag
	20. notes
	21. notes_flag
	22. user_number_1
	23. user_number_1_flag
	24. user_number_2
	25. user_number_2_flag
	26. user_number_3
	27. user_number_3_flag
	28. user_number_4
	29. user_number_4_flag
	30. user_number_5
	31. user_number_5_flag
	32. user_number_6
	33. user_number_6_flag
	34. user_number_7
	35. user_number_7_flag
	36. user_number_8
	37. user_number_8_flag
	38. user_number_9
	39. user_number_9_flag
	40. user_number_10
	41. user_number_10_flag
	42. user_text_1
	43. user_text_1_flag
	44. user_text_2
	45. user_text_2_flag
	46. user_text_3
	47. user_text_3_flag
	48. user_text_4
	49. user_text_4_flag
	50. user_text_5
	51. user_text_5_flag
	52. user_text_6
	53. user_text_6_flag
	54. user_text_7
	55. user_text_7_flag
	56. user_text_8
	57. user_text_8_flag
	58. user_text_9
	59. user_text_9_flag
	60. user_text_10
	61. user_text_10_flag
****hw_roughness_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. exclude_from_2d_mesh
	7. exclude_from_2d_mesh_flag
	8. roughness
	9. roughness_flag
	10. roughness_definition_id
	11. roughness_definition_id_flag
	12. priority
	13. priority_flag
	14. hyperlinks
		 description
		 url
	15. hyperlinks_flag
	16. notes
	17. notes_flag
	18. user_number_1
	19. user_number_1_flag
	20. user_number_2
	21. user_number_2_flag
	22. user_number_3
	23. user_number_3_flag
	24. user_number_4
	25. user_number_4_flag
	26. user_number_5
	27. user_number_5_flag
	28. user_number_6
	29. user_number_6_flag
	30. user_number_7
	31. user_number_7_flag
	32. user_number_8
	33. user_number_8_flag
	34. user_number_9
	35. user_number_9_flag
	36. user_number_10
	37. user_number_10_flag
	38. user_text_1
	39. user_text_1_flag
	40. user_text_2
	41. user_text_2_flag
	42. user_text_3
	43. user_text_3_flag
	44. user_text_4
	45. user_text_4_flag
	46. user_text_5
	47. user_text_5_flag
	48. user_text_6
	49. user_text_6_flag
	50. user_text_7
	51. user_text_7_flag
	52. user_text_8
	53. user_text_8_flag
	54. user_text_9
	55. user_text_9_flag
	56. user_text_10
	57. user_text_10_flag
****hw_2d_ic_polygon
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****hw_2d_point_source
	1. point_id
	2. point_id_flag
	3. x
	4. x_flag
	5. y
	6. y_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_2d_boundary_line
	1. line_id
	2. line_id_flag
	3. line_type
	4. line_type_flag
	5. general_line_xy
	6. bed_load_boundary
	7. bed_load_boundary_flag
	8. suspended_load_boundary
	9. suspended_load_boundary_flag
	10. head_unit_discharge_id
	11. head_unit_discharge_id_flag
	12. hyperlinks
		 description
		 url
	13. hyperlinks_flag
	14. length
	15. length_flag
	16. notes
	17. notes_flag
	18. user_number_1
	19. user_number_1_flag
	20. user_number_2
	21. user_number_2_flag
	22. user_number_3
	23. user_number_3_flag
	24. user_number_4
	25. user_number_4_flag
	26. user_number_5
	27. user_number_5_flag
	28. user_number_6
	29. user_number_6_flag
	30. user_number_7
	31. user_number_7_flag
	32. user_number_8
	33. user_number_8_flag
	34. user_number_9
	35. user_number_9_flag
	36. user_number_10
	37. user_number_10_flag
	38. user_text_1
	39. user_text_1_flag
	40. user_text_2
	41. user_text_2_flag
	42. user_text_3
	43. user_text_3_flag
	44. user_text_4
	45. user_text_4_flag
	46. user_text_5
	47. user_text_5_flag
	48. user_text_6
	49. user_text_6_flag
	50. user_text_7
	51. user_text_7_flag
	52. user_text_8
	53. user_text_8_flag
	54. user_text_9
	55. user_text_9_flag
	56. user_text_10
	57. user_text_10_flag
****hw_irregular_weir
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. chainage_elevation
		 chainage
		 elevation
	6. chainage_elevation_flag
	7. ds_node_id
	8. ds_node_id_flag
	9. link_type
	10. link_type_flag
	11. system_type
	12. system_type_flag
	13. asset_id
	14. asset_id_flag
	15. sewer_reference
	16. sewer_reference_flag
	17. point_array
	18. discharge_coeff
	19. discharge_coeff_flag
	20. modular_limit
	21. modular_limit_flag
	22. us_settlement_eff
	23. us_settlement_eff_flag
	24. ds_settlement_eff
	25. ds_settlement_eff_flag
	26. crest
	27. crest_flag
	28. branch_id
	29. branch_id_flag
	30. hyperlinks
		 description
		 url
	31. hyperlinks_flag
	32. notes
	33. notes_flag
	34. user_number_1
	35. user_number_1_flag
	36. user_number_2
	37. user_number_2_flag
	38. user_number_3
	39. user_number_3_flag
	40. user_number_4
	41. user_number_4_flag
	42. user_number_5
	43. user_number_5_flag
	44. user_number_6
	45. user_number_6_flag
	46. user_number_7
	47. user_number_7_flag
	48. user_number_8
	49. user_number_8_flag
	50. user_number_9
	51. user_number_9_flag
	52. user_number_10
	53. user_number_10_flag
	54. user_text_1
	55. user_text_1_flag
	56. user_text_2
	57. user_text_2_flag
	58. user_text_3
	59. user_text_3_flag
	60. user_text_4
	61. user_text_4_flag
	62. user_text_5
	63. user_text_5_flag
	64. user_text_6
	65. user_text_6_flag
	66. user_text_7
	67. user_text_7_flag
	68. user_text_8
	69. user_text_8_flag
	70. user_text_9
	71. user_text_9_flag
	72. user_text_10
	73. user_text_10_flag
****hw_river_reach
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. section_spacing
		 key
		 spacing
	6. section_spacing_flag
	7. ds_node_id
	8. ds_node_id_flag
	9. link_type
	10. link_type_flag
	11. system_type
	12. system_type_flag
	13. asset_id
	14. asset_id_flag
	15. boundary_array
	16. point_array
	17. length
	18. length_flag
	19. left_bank
		 X
		 Y
		 Z
		 discharge_coeff
		 modular_ratio
		 section_marker
		 rtc_definition
	20. left_bank_flag
	21. right_bank
		 X
		 Y
		 Z
		 discharge_coeff
		 modular_ratio
		 section_marker
		 rtc_definition
	22. right_bank_flag
	23. sections
		 key
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
	24. sections_flag
	25. conveyance
		 key
		 depth
		 conveyance
		 area
		 width
		 perimeter
	26. conveyance_flag
	27. sediment_depth
	28. sediment_depth_flag
	29. us_headloss_type
	30. us_headloss_type_flag
	31. us_headloss_coeff
	32. us_headloss_coeff_flag
	33. us_sediment_grading
	34. us_sediment_grading_flag
	35. ds_headloss_type
	36. ds_headloss_type_flag
	37. ds_headloss_coeff
	38. ds_headloss_coeff_flag
	39. solution_model
	40. solution_model_flag
	41. ds_sediment_grading
	42. ds_sediment_grading_flag
	43. inflow
	44. inflow_flag
	45. us_invert
	46. us_invert_flag
	47. ds_invert
	48. ds_invert_flag
	49. is_merged
	50. branch_id
	51. branch_id_flag
	52. left_node_id
	53. left_node_id_flag
	54. left_reach_node_id
	55. left_reach_node_id_flag
	56. left_reach_link_suffix
	57. left_reach_link_suffix_flag
	58. left_2d_zone_id
	59. left_2d_zone_id_flag
	60. right_node_id
	61. right_node_id_flag
	62. right_reach_node_id
	63. right_reach_node_id_flag
	64. right_reach_link_suffix
	65. right_reach_link_suffix_flag
	66. right_2d_zone_id
	67. right_2d_zone_id_flag
	68. base_height
	69. base_height_flag
	70. infiltration_coeff_base
	71. infiltration_coeff_base_flag
	72. infiltration_coeff_side
	73. infiltration_coeff_side_flag
	74. erosion_limit_type
	75. erosion_limit_type_flag
	76. erosion_depth_limit
	77. erosion_depth_limit_flag
	78. erosion_level_limit
	79. erosion_level_limit_flag
	80. limit_deposit_depth
	81. limit_deposit_depth_flag
	82. deposit_limit
	83. deposit_limit_flag
	84. bed_updating
	85. bed_updating_flag
	86. aldepth_factor
	87. aldepth_factor_flag
	88. aldepth
	89. aldepth_flag
	90. max_erosion_rate
	91. max_erosion_rate_flag
	92. max_deposition_rate
	93. max_deposition_rate_flag
	94. limit_erosion_rate
	95. limit_erosion_rate_flag
	96. limit_deposit_rate
	97. limit_deposit_rate_flag
	98. diff1d_type
	99. diff1d_type_flag
	100. diff1d_d0
	101. diff1d_d0_flag
	102. diff1d_d1
	103. diff1d_d1_flag
	104. diff1d_d2
	105. diff1d_d2_flag
	106. notes
	107. notes_flag
	108. hyperlinks
		 description
		 url
	109. hyperlinks_flag
	110. user_number_1
	111. user_number_1_flag
	112. user_number_2
	113. user_number_2_flag
	114. user_number_3
	115. user_number_3_flag
	116. user_number_4
	117. user_number_4_flag
	118. user_number_5
	119. user_number_5_flag
	120. user_number_6
	121. user_number_6_flag
	122. user_number_7
	123. user_number_7_flag
	124. user_number_8
	125. user_number_8_flag
	126. user_number_9
	127. user_number_9_flag
	128. user_number_10
	129. user_number_10_flag
	130. user_text_1
	131. user_text_1_flag
	132. user_text_2
	133. user_text_2_flag
	134. user_text_3
	135. user_text_3_flag
	136. user_text_4
	137. user_text_4_flag
	138. user_text_5
	139. user_text_5_flag
	140. user_text_6
	141. user_text_6_flag
	142. user_text_7
	143. user_text_7_flag
	144. user_text_8
	145. user_text_8_flag
	146. user_text_9
	147. user_text_9_flag
	148. user_text_10
	149. user_text_10_flag
****hw_porous_polygon
	1. polygon_id
	2. polygon_id_flag
	3. asset_id
	4. asset_id_flag
	5. porosity
	6. porosity_flag
	7. boundary_array
	8. crest_level
	9. crest_level_flag
	10. height
	11. height_flag
	12. level
	13. level_flag
	14. remove_wall
	15. remove_wall_flag
	16. wall_removal_trigger
	17. wall_removal_trigger_flag
	18. use_diff_across_wall
	19. use_diff_across_wall_flag
	20. depth_threshold
	21. depth_threshold_flag
	22. elevation_threshold
	23. elevation_threshold_flag
	24. velocity_threshold
	25. velocity_threshold_flag
	26. unit_flow_threshold
	27. unit_flow_threshold_flag
	28. total_head_threshold
	29. total_head_threshold_flag
	30. force_threshold
	31. force_threshold_flag
	32. hydro_press_coeff
	33. hydro_press_coeff_flag
	34. hyperlinks
		 description
		 url
	35. hyperlinks_flag
	36. no_rainfall
	37. no_rainfall_flag
	38. area
	39. area_flag
	40. notes
	41. notes_flag
	42. user_number_1
	43. user_number_1_flag
	44. user_number_2
	45. user_number_2_flag
	46. user_number_3
	47. user_number_3_flag
	48. user_number_4
	49. user_number_4_flag
	50. user_number_5
	51. user_number_5_flag
	52. user_number_6
	53. user_number_6_flag
	54. user_number_7
	55. user_number_7_flag
	56. user_number_8
	57. user_number_8_flag
	58. user_number_9
	59. user_number_9_flag
	60. user_number_10
	61. user_number_10_flag
	62. user_text_1
	63. user_text_1_flag
	64. user_text_2
	65. user_text_2_flag
	66. user_text_3
	67. user_text_3_flag
	68. user_text_4
	69. user_text_4_flag
	70. user_text_5
	71. user_text_5_flag
	72. user_text_6
	73. user_text_6_flag
	74. user_text_7
	75. user_text_7_flag
	76. user_text_8
	77. user_text_8_flag
	78. user_text_9
	79. user_text_9_flag
	80. user_text_10
	81. user_text_10_flag
****hw_cross_section_survey
	1. id
	2. id_flag
	3. hyperlinks
		 description
		 url
	4. hyperlinks_flag
	5. section_array
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
	6. section_array_flag
	7. length
	8. length_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_flow_efficiency
	1. flow_efficiency_id
	2. flow_efficiency_id_flag
	3. flow_efficiency_description
	4. flow_efficiency_description_flag
	5. FE_table
		 flow
		 efficiency
	6. FE_table_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_bank_survey
	1. id
	2. id_flag
	3. length
	4. length_flag
	5. bank_array
		 X
		 Y
		 Z
		 discharge_coeff
		 modular_ratio
		 rtc_definition
	6. bank_array_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_bridge
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. bridge_deck
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
		 opening_id
		 opening_side
	6. bridge_deck_flag
	7. ds_bridge_section
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
		 opening_id
		 opening_side
	8. ds_bridge_section_flag
	9. ds_link_section
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
		 opening_id
		 opening_side
	10. ds_link_section_flag
	11. us_bridge_section
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
		 opening_id
		 opening_side
	12. us_bridge_section_flag
	13. us_link_section
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
		 opening_id
		 opening_side
	14. us_link_section_flag
	15. ds_node_id
	16. ds_node_id_flag
	17. link_type
	18. link_type_flag
	19. system_type
	20. system_type_flag
	21. asset_id
	22. asset_id_flag
	23. boundary_array
	24. point_array
	25. length
	26. length_flag
	27. discharge_coeff
	28. discharge_coeff_flag
	29. modular_limit
	30. modular_limit_flag
	31. sediment_depth
	32. sediment_depth_flag
	33. us_headloss_type
	34. us_headloss_type_flag
	35. us_headloss_coeff
	36. us_headloss_coeff_flag
	37. us_sediment_grading_contraction
	38. us_sediment_grading_contraction_flag
	39. us_sediment_grading_expansion
	40. us_sediment_grading_expansion_flag
	41. ds_headloss_type
	42. ds_headloss_type_flag
	43. ds_headloss_coeff
	44. ds_headloss_coeff_flag
	45. ds_sediment_grading_contraction
	46. ds_sediment_grading_contraction_flag
	47. ds_sediment_grading_expansion
	48. ds_sediment_grading_expansion_flag
	49. inflow
	50. inflow_flag
	51. us_invert
	52. us_invert_flag
	53. ds_invert
	54. ds_invert_flag
	55. is_merged
	56. branch_id
	57. branch_id_flag
	58. skew_angle
	59. skew_angle_flag
	60. skew_openings
	61. skew_openings_flag
	62. contraction_loss
	63. contraction_loss_flag
	64. expansion_loss
	65. expansion_loss_flag
	66. reverse_contraction_loss
	67. reverse_contraction_loss_flag
	68. reverse_expansion_loss
	69. reverse_expansion_loss_flag
	70. base_height_exp
	71. base_height_exp_flag
	72. infiltration_coeff_base_exp
	73. infiltration_coeff_base_exp_flag
	74. infiltration_coeff_side_exp
	75. infiltration_coeff_side_exp_flag
	76. base_height_con
	77. base_height_con_flag
	78. infiltration_coeff_base_con
	79. infiltration_coeff_base_con_flag
	80. infiltration_coeff_side_con
	81. infiltration_coeff_side_con_flag
	82. erosion_limit_type_contraction
	83. erosion_limit_type_contraction_flag
	84. erosion_depth_limit_contraction
	85. erosion_depth_limit_contraction_flag
	86. erosion_level_limit_contraction
	87. erosion_level_limit_contraction_flag
	88. limit_deposit_depth_contraction
	89. limit_deposit_depth_contraction_flag
	90. deposit_limit_contraction
	91. deposit_limit_contraction_flag
	92. bed_updating_contraction
	93. bed_updating_contraction_flag
	94. aldepth_factor_contraction
	95. aldepth_factor_contraction_flag
	96. aldepth_contraction
	97. aldepth_contraction_flag
	98. max_erosion_rate_contraction
	99. max_erosion_rate_contraction_flag
	100. max_deposition_rate_contraction
	101. max_deposition_rate_contraction_flag
	102. limit_erosion_rate_contraction
	103. limit_erosion_rate_contraction_flag
	104. limit_deposit_rate_contraction
	105. limit_deposit_rate_contraction_flag
	106. erosion_limit_type_expansion
	107. erosion_limit_type_expansion_flag
	108. erosion_depth_limit_expansion
	109. erosion_depth_limit_expansion_flag
	110. erosion_level_limit_expansion
	111. erosion_level_limit_expansion_flag
	112. limit_deposit_depth_expansion
	113. limit_deposit_depth_expansion_flag
	114. deposit_limit_expansion
	115. deposit_limit_expansion_flag
	116. bed_updating_expansion
	117. bed_updating_expansion_flag
	118. aldepth_factor_expansion
	119. aldepth_factor_expansion_flag
	120. aldepth_expansion
	121. aldepth_expansion_flag
	122. max_erosion_rate_expansion
	123. max_erosion_rate_expansion_flag
	124. max_deposition_rate_expansion
	125. max_deposition_rate_expansion_flag
	126. limit_erosion_rate_expansion
	127. limit_erosion_rate_expansion_flag
	128. limit_deposit_rate_expansion
	129. limit_deposit_rate_expansion_flag
	130. diff1d_type_cont
	131. diff1d_type_cont_flag
	132. diff1d_d0_cont
	133. diff1d_d0_cont_flag
	134. diff1d_d1_cont
	135. diff1d_d1_cont_flag
	136. diff1d_d2_cont
	137. diff1d_d2_cont_flag
	138. diff1d_type_exp
	139. diff1d_type_exp_flag
	140. diff1d_d0_exp
	141. diff1d_d0_exp_flag
	142. diff1d_d1_exp
	143. diff1d_d1_exp_flag
	144. diff1d_d2_exp
	145. diff1d_d2_exp_flag
	146. notes
	147. notes_flag
	148. hyperlinks
		 description
		 url
	149. hyperlinks_flag
	150. user_number_1
	151. user_number_1_flag
	152. user_number_2
	153. user_number_2_flag
	154. user_number_3
	155. user_number_3_flag
	156. user_number_4
	157. user_number_4_flag
	158. user_number_5
	159. user_number_5_flag
	160. user_number_6
	161. user_number_6_flag
	162. user_number_7
	163. user_number_7_flag
	164. user_number_8
	165. user_number_8_flag
	166. user_number_9
	167. user_number_9_flag
	168. user_number_10
	169. user_number_10_flag
	170. user_text_1
	171. user_text_1_flag
	172. user_text_2
	173. user_text_2_flag
	174. user_text_3
	175. user_text_3_flag
	176. user_text_4
	177. user_text_4_flag
	178. user_text_5
	179. user_text_5_flag
	180. user_text_6
	181. user_text_6_flag
	182. user_text_7
	183. user_text_7_flag
	184. user_text_8
	185. user_text_8_flag
	186. user_text_9
	187. user_text_9_flag
	188. user_text_10
	189. user_text_10_flag
****hw_bridge_inlet
	1. id
	2. id_flag
	3. bridge_us_node_id
	4. bridge_us_node_id_flag
	5. bridge_link_suffix
	6. bridge_link_suffix_flag
	7. system_type
	8. system_type_flag
	9. asset_id
	10. asset_id_flag
	11. point_array
	12. invert
	13. invert_flag
	14. equation
	15. equation_flag
	16. k
	17. k_flag
	18. m
	19. m_flag
	20. c
	21. c_flag
	22. y
	23. y_flag
	24. headloss_coeff
	25. headloss_coeff_flag
	26. reverse_flow_model
	27. reverse_flow_model_flag
	28. outlet_headloss_coeff
	29. outlet_headloss_coeff_flag
	30. hyperlinks
		 description
		 url
	31. hyperlinks_flag
	32. notes
	33. notes_flag
	34. user_number_1
	35. user_number_1_flag
	36. user_number_2
	37. user_number_2_flag
	38. user_number_3
	39. user_number_3_flag
	40. user_number_4
	41. user_number_4_flag
	42. user_number_5
	43. user_number_5_flag
	44. user_number_6
	45. user_number_6_flag
	46. user_number_7
	47. user_number_7_flag
	48. user_number_8
	49. user_number_8_flag
	50. user_number_9
	51. user_number_9_flag
	52. user_number_10
	53. user_number_10_flag
	54. user_text_1
	55. user_text_1_flag
	56. user_text_2
	57. user_text_2_flag
	58. user_text_3
	59. user_text_3_flag
	60. user_text_4
	61. user_text_4_flag
	62. user_text_5
	63. user_text_5_flag
	64. user_text_6
	65. user_text_6_flag
	66. user_text_7
	67. user_text_7_flag
	68. user_text_8
	69. user_text_8_flag
	70. user_text_9
	71. user_text_9_flag
	72. user_text_10
	73. user_text_10_flag
****hw_bridge_opening
	1. id
	2. id_flag
	3. bridge_us_node_id
	4. bridge_us_node_id_flag
	5. piers
		 id
		 offset
		 elevation
		 width
		 roughness_N
	6. piers_flag
	7. bridge_link_suffix
	8. bridge_link_suffix_flag
	9. inlet_id
	10. inlet_id_flag
	11. outlet_id
	12. outlet_id_flag
	13. inlet_blockage_id
	14. inlet_blockage_id_flag
	15. system_type
	16. system_type_flag
	17. outlet_blockage_id
	18. outlet_blockage_id_flag
	19. asset_id
	20. asset_id_flag
	21. point_array
	22. conduit_length
	23. conduit_length_flag
	24. shape
	25. shape_flag
	26. conduit_width
	27. conduit_width_flag
	28. conduit_height
	29. conduit_height_flag
	30. springing_height
	31. springing_height_flag
	32. roughness_N
	33. roughness_N_flag
	34. us_invert
	35. us_invert_flag
	36. us_headloss_type
	37. us_headloss_type_flag
	38. us_headloss_coeff
	39. us_headloss_coeff_flag
	40. ds_invert
	41. ds_invert_flag
	42. ds_headloss_type
	43. ds_headloss_type_flag
	44. ds_headloss_coeff
	45. ds_headloss_coeff_flag
	46. inflow
	47. inflow_flag
	48. hyperlinks
		 description
		 url
	49. hyperlinks_flag
	50. asset_uid
	51. diff1d_type
	52. diff1d_type_flag
	53. diff1d_d0
	54. diff1d_d0_flag
	55. diff1d_d1
	56. diff1d_d1_flag
	57. diff1d_d2
	58. diff1d_d2_flag
	59. notes
	60. notes_flag
	61. user_number_1
	62. user_number_1_flag
	63. user_number_2
	64. user_number_2_flag
	65. user_number_3
	66. user_number_3_flag
	67. user_number_4
	68. user_number_4_flag
	69. user_number_5
	70. user_number_5_flag
	71. user_number_6
	72. user_number_6_flag
	73. user_number_7
	74. user_number_7_flag
	75. user_number_8
	76. user_number_8_flag
	77. user_number_9
	78. user_number_9_flag
	79. user_number_10
	80. user_number_10_flag
	81. user_text_1
	82. user_text_1_flag
	83. user_text_2
	84. user_text_2_flag
	85. user_text_3
	86. user_text_3_flag
	87. user_text_4
	88. user_text_4_flag
	89. user_text_5
	90. user_text_5_flag
	91. user_text_6
	92. user_text_6_flag
	93. user_text_7
	94. user_text_7_flag
	95. user_text_8
	96. user_text_8_flag
	97. user_text_9
	98. user_text_9_flag
	99. user_text_10
	100. user_text_10_flag
****hw_bridge_outlet
	1. id
	2. id_flag
	3. bridge_us_node_id
	4. bridge_us_node_id_flag
	5. bridge_link_suffix
	6. bridge_link_suffix_flag
	7. system_type
	8. system_type_flag
	9. asset_id
	10. asset_id_flag
	11. point_array
	12. invert
	13. invert_flag
	14. headloss_coeff
	15. headloss_coeff_flag
	16. reverse_flow_model
	17. reverse_flow_model_flag
	18. equation
	19. equation_flag
	20. k
	21. k_flag
	22. m
	23. m_flag
	24. c
	25. c_flag
	26. y
	27. y_flag
	28. inlet_headloss_coeff
	29. inlet_headloss_coeff_flag
	30. hyperlinks
		 description
		 url
	31. hyperlinks_flag
	32. notes
	33. notes_flag
	34. user_number_1
	35. user_number_1_flag
	36. user_number_2
	37. user_number_2_flag
	38. user_number_3
	39. user_number_3_flag
	40. user_number_4
	41. user_number_4_flag
	42. user_number_5
	43. user_number_5_flag
	44. user_number_6
	45. user_number_6_flag
	46. user_number_7
	47. user_number_7_flag
	48. user_number_8
	49. user_number_8_flag
	50. user_number_9
	51. user_number_9_flag
	52. user_number_10
	53. user_number_10_flag
	54. user_text_1
	55. user_text_1_flag
	56. user_text_2
	57. user_text_2_flag
	58. user_text_3
	59. user_text_3_flag
	60. user_text_4
	61. user_text_4_flag
	62. user_text_5
	63. user_text_5_flag
	64. user_text_6
	65. user_text_6_flag
	66. user_text_7
	67. user_text_7_flag
	68. user_text_8
	69. user_text_8_flag
	70. user_text_9
	71. user_text_9_flag
	72. user_text_10
	73. user_text_10_flag
****hw_storage_area
	1. polygon_id
	2. polygon_id_flag
	3. boundary_array
	4. boundary_array_flag
	5. node_id
	6. node_id_flag
	7. area
	8. area_flag
	9. hyperlinks
		 description
		 url
	10. hyperlinks_flag
	11. notes
	12. notes_flag
	13. user_number_1
	14. user_number_1_flag
	15. user_number_2
	16. user_number_2_flag
	17. user_number_3
	18. user_number_3_flag
	19. user_number_4
	20. user_number_4_flag
	21. user_number_5
	22. user_number_5_flag
	23. user_number_6
	24. user_number_6_flag
	25. user_number_7
	26. user_number_7_flag
	27. user_number_8
	28. user_number_8_flag
	29. user_number_9
	30. user_number_9_flag
	31. user_number_10
	32. user_number_10_flag
	33. user_text_1
	34. user_text_1_flag
	35. user_text_2
	36. user_text_2_flag
	37. user_text_3
	38. user_text_3_flag
	39. user_text_4
	40. user_text_4_flag
	41. user_text_5
	42. user_text_5_flag
	43. user_text_6
	44. user_text_6_flag
	45. user_text_7
	46. user_text_7_flag
	47. user_text_8
	48. user_text_8_flag
	49. user_text_9
	50. user_text_9_flag
	51. user_text_10
	52. user_text_10_flag
****hw_2d_zone_defaults
	1. mesh_generation
	2. rainfall_profile
****hw_rtc
	1. rtc_data
****hw_2d_infil_surface
	1. surface_id
	2. surface_id_flag
	3. runoff_volume_type
	4. runoff_volume_type_flag
	5. initial_infiltration
	6. initial_infiltration_flag
	7. limiting_infiltration
	8. limiting_infiltration_flag
	9. decay_factor
	10. decay_factor_flag
	11. hyperlinks
		 description
		 url
	12. hyperlinks_flag
	13. recovery_factor
	14. recovery_factor_flag
	15. runoff_coefficient
	16. runoff_coefficient_flag
	17. infiltration_coeff
	18. infiltration_coeff_flag
	19. average_capillary_suction
	20. average_capillary_suction_flag
	21. saturated_hydraulic_conductivity
	22. saturated_hydraulic_conductivity_flag
	23. initial_moisture_deficit
	24. initial_moisture_deficit_flag
	25. defconloss_infil_loss_coeff
	26. defconloss_infil_loss_coeff_flag
	27. defconloss_max_deficit
	28. defconloss_max_deficit_flag
	29. notes
	30. notes_flag
	31. user_number_1
	32. user_number_1_flag
	33. user_number_2
	34. user_number_2_flag
	35. user_number_3
	36. user_number_3_flag
	37. user_number_4
	38. user_number_4_flag
	39. user_number_5
	40. user_number_5_flag
	41. user_number_6
	42. user_number_6_flag
	43. user_number_7
	44. user_number_7_flag
	45. user_number_8
	46. user_number_8_flag
	47. user_number_9
	48. user_number_9_flag
	49. user_number_10
	50. user_number_10_flag
	51. user_text_1
	52. user_text_1_flag
	53. user_text_2
	54. user_text_2_flag
	55. user_text_3
	56. user_text_3_flag
	57. user_text_4
	58. user_text_4_flag
	59. user_text_5
	60. user_text_5_flag
	61. user_text_6
	62. user_text_6_flag
	63. user_text_7
	64. user_text_7_flag
	65. user_text_8
	66. user_text_8_flag
	67. user_text_9
	68. user_text_9_flag
	69. user_text_10
	70. user_text_10_flag
****hw_2d_infiltration_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. infiltration_surface_id
	7. infiltration_surface_id_flag
	8. rainfall_percentage
	9. rainfall_percentage_flag
	10. exclude_from_2d_mesh
	11. exclude_from_2d_mesh_flag
	12. hyperlinks
		 description
		 url
	13. hyperlinks_flag
	14. notes
	15. notes_flag
	16. user_number_1
	17. user_number_1_flag
	18. user_number_2
	19. user_number_2_flag
	20. user_number_3
	21. user_number_3_flag
	22. user_number_4
	23. user_number_4_flag
	24. user_number_5
	25. user_number_5_flag
	26. user_number_6
	27. user_number_6_flag
	28. user_number_7
	29. user_number_7_flag
	30. user_number_8
	31. user_number_8_flag
	32. user_number_9
	33. user_number_9_flag
	34. user_number_10
	35. user_number_10_flag
	36. user_text_1
	37. user_text_1_flag
	38. user_text_2
	39. user_text_2_flag
	40. user_text_3
	41. user_text_3_flag
	42. user_text_4
	43. user_text_4_flag
	44. user_text_5
	45. user_text_5_flag
	46. user_text_6
	47. user_text_6_flag
	48. user_text_7
	49. user_text_7_flag
	50. user_text_8
	51. user_text_8_flag
	52. user_text_9
	53. user_text_9_flag
	54. user_text_10
	55. user_text_10_flag
****hw_2d_wq_ic_polygon
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****hw_2d_inf_ic_polygon
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****hw_inline_bank
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. system_type
	8. system_type_flag
	9. link_type
	10. link_type_flag
	11. asset_id
	12. asset_id_flag
	13. bank
		 X
		 Y
		 Z
		 discharge_coeff
		 modular_ratio
		 rtc_definition
	14. bank_flag
	15. zone_id
	16. zone_id_flag
	17. crest
	18. crest_flag
	19. branch_id
	20. branch_id_flag
	21. notes
	22. notes_flag
	23. hyperlinks
		 description
		 url
	24. hyperlinks_flag
	25. point_array
	26. user_number_1
	27. user_number_1_flag
	28. user_number_2
	29. user_number_2_flag
	30. user_number_3
	31. user_number_3_flag
	32. user_number_4
	33. user_number_4_flag
	34. user_number_5
	35. user_number_5_flag
	36. user_number_6
	37. user_number_6_flag
	38. user_number_7
	39. user_number_7_flag
	40. user_number_8
	41. user_number_8_flag
	42. user_number_9
	43. user_number_9_flag
	44. user_number_10
	45. user_number_10_flag
	46. user_text_1
	47. user_text_1_flag
	48. user_text_2
	49. user_text_2_flag
	50. user_text_3
	51. user_text_3_flag
	52. user_text_4
	53. user_text_4_flag
	54. user_text_5
	55. user_text_5_flag
	56. user_text_6
	57. user_text_6_flag
	58. user_text_7
	59. user_text_7_flag
	60. user_text_8
	61. user_text_8_flag
	62. user_text_9
	63. user_text_9_flag
	64. user_text_10
	65. user_text_10_flag
****hw_general_point
	1. point_id
	2. point_id_flag
	3. asset_id
	4. asset_id_flag
	5. general_point_x
	6. general_point_x_flag
	7. general_point_y
	8. general_point_y_flag
	9. general_point_z
	10. general_point_z_flag
	11. hyperlinks
		 description
		 url
	12. hyperlinks_flag
	13. category
	14. category_flag
	15. notes
	16. notes_flag
	17. user_number_1
	18. user_number_1_flag
	19. user_number_2
	20. user_number_2_flag
	21. user_number_3
	22. user_number_3_flag
	23. user_number_4
	24. user_number_4_flag
	25. user_number_5
	26. user_number_5_flag
	27. user_number_6
	28. user_number_6_flag
	29. user_number_7
	30. user_number_7_flag
	31. user_number_8
	32. user_number_8_flag
	33. user_number_9
	34. user_number_9_flag
	35. user_number_10
	36. user_number_10_flag
	37. user_text_1
	38. user_text_1_flag
	39. user_text_2
	40. user_text_2_flag
	41. user_text_3
	42. user_text_3_flag
	43. user_text_4
	44. user_text_4_flag
	45. user_text_5
	46. user_text_5_flag
	47. user_text_6
	48. user_text_6_flag
	49. user_text_7
	50. user_text_7_flag
	51. user_text_8
	52. user_text_8_flag
	53. user_text_9
	54. user_text_9_flag
	55. user_text_10
	56. user_text_10_flag
****hw_2d_linear_structure
	1. line_id
	2. line_id_flag
	3. asset_id
	4. asset_id_flag
	5. structure_type
	6. structure_type_flag
	7. weir_type
	8. weir_type_flag
	9. horiz_sect_len
	10. horiz_sect_len_flag
	11. discharge
	12. discharge_flag
	13. crest_level
	14. crest_level_flag
	15. height
	16. height_flag
	17. level
	18. level_flag
	19. remove_wall
	20. remove_wall_flag
	21. wall_removal_trigger
	22. wall_removal_trigger_flag
	23. head_unit_discharge_id
	24. head_unit_discharge_id_flag
	25. use_diff_across_wall
	26. use_diff_across_wall_flag
	27. depth_threshold
	28. depth_threshold_flag
	29. velocity_threshold
	30. velocity_threshold_flag
	31. unit_flow_threshold
	32. unit_flow_threshold_flag
	33. elevation_threshold
	34. elevation_threshold_flag
	35. total_head_threshold
	36. total_head_threshold_flag
	37. force_threshold
	38. force_threshold_flag
	39. hydro_press_coeff
	40. hydro_press_coeff_flag
	41. blockage
	42. blockage_flag
	43. porosity
	44. porosity_flag
	45. headloss_spec
	46. headloss_spec_flag
	47. headloss_type
	48. headloss_type_flag
	49. headloss_coeff
	50. headloss_coeff_flag
	51. us_unit_headloss_coeff
	52. us_unit_headloss_coeff_flag
	53. ds_unit_headloss_coeff
	54. ds_unit_headloss_coeff_flag
	55. headloss_coeff2
	56. headloss_coeff2_flag
	57. us_headloss_coeff
	58. us_headloss_coeff_flag
	59. ds_headloss_coeff
	60. ds_headloss_coeff_flag
	61. lateral_friction
	62. lateral_friction_flag
	63. use_direction
	64. use_direction_flag
	65. hyperlinks
		 description
		 url
	66. hyperlinks_flag
	67. sections
		 X
		 Y
		 Z
		 rtc_definition
	68. length
	69. length_flag
	70. notes
	71. notes_flag
	72. user_number_1
	73. user_number_1_flag
	74. user_number_2
	75. user_number_2_flag
	76. user_number_3
	77. user_number_3_flag
	78. user_number_4
	79. user_number_4_flag
	80. user_number_5
	81. user_number_5_flag
	82. user_number_6
	83. user_number_6_flag
	84. user_number_7
	85. user_number_7_flag
	86. user_number_8
	87. user_number_8_flag
	88. user_number_9
	89. user_number_9_flag
	90. user_number_10
	91. user_number_10_flag
	92. user_text_1
	93. user_text_1_flag
	94. user_text_2
	95. user_text_2_flag
	96. user_text_3
	97. user_text_3_flag
	98. user_text_4
	99. user_text_4_flag
	100. user_text_5
	101. user_text_5_flag
	102. user_text_6
	103. user_text_6_flag
	104. user_text_7
	105. user_text_7_flag
	106. user_text_8
	107. user_text_8_flag
	108. user_text_9
	109. user_text_9_flag
	110. user_text_10
	111. user_text_10_flag
****hw_2d_sluice
	1. line_id
	2. line_id_flag
	3. asset_id
	4. asset_id_flag
	5. discharge_coeff
	6. discharge_coeff_flag
	7. secondary_discharge_coeff
	8. secondary_discharge_coeff_flag
	9. overgate_discharge_coeff
	10. overgate_discharge_coeff_flag
	11. opening
	12. opening_flag
	13. gate_depth
	14. gate_depth_flag
	15. length
	16. length_flag
	17. linear_structure_id
	18. linear_structure_id_flag
	19. notes
	20. notes_flag
	21. start_length
	22. start_length_flag
	23. headloss_spec
	24. headloss_spec_flag
	25. headloss_type
	26. headloss_type_flag
	27. headloss_coeff
	28. headloss_coeff_flag
	29. us_unit_headloss_coeff
	30. us_unit_headloss_coeff_flag
	31. ds_unit_headloss_coeff
	32. ds_unit_headloss_coeff_flag
	33. headloss_coeff2
	34. headloss_coeff2_flag
	35. us_headloss_coeff
	36. us_headloss_coeff_flag
	37. ds_headloss_coeff
	38. ds_headloss_coeff_flag
	39. lateral_friction
	40. lateral_friction_flag
	41. blockage
	42. blockage_flag
	43. use_direction
	44. use_direction_flag
	45. crest_level
	46. crest_level_flag
	47. flow_type
	48. flow_type_flag
	49. over_flow_type
	50. over_flow_type_flag
	51. height
	52. height_flag
	53. level
	54. level_flag
	55. point_array
	56. hyperlinks
		 description
		 url
	57. hyperlinks_flag
	58. user_number_1
	59. user_number_1_flag
	60. user_number_2
	61. user_number_2_flag
	62. user_number_3
	63. user_number_3_flag
	64. user_number_4
	65. user_number_4_flag
	66. user_number_5
	67. user_number_5_flag
	68. user_number_6
	69. user_number_6_flag
	70. user_number_7
	71. user_number_7_flag
	72. user_number_8
	73. user_number_8_flag
	74. user_number_9
	75. user_number_9_flag
	76. user_number_10
	77. user_number_10_flag
	78. user_text_1
	79. user_text_1_flag
	80. user_text_2
	81. user_text_2_flag
	82. user_text_3
	83. user_text_3_flag
	84. user_text_4
	85. user_text_4_flag
	86. user_text_5
	87. user_text_5_flag
	88. user_text_6
	89. user_text_6_flag
	90. user_text_7
	91. user_text_7_flag
	92. user_text_8
	93. user_text_8_flag
	94. user_text_9
	95. user_text_9_flag
	96. user_text_10
	97. user_text_10_flag
****hw_tvd_connector
	1. id
	2. id_flag
	3. category_id
	4. category_id_flag
	5. boundary_array
	6. boundary_array_flag
	7. input_a_units
	8. input_a_units_flag
	9. input_a
	10. input_a_flag
	11. input_b_units
	12. input_b_units_flag
	13. input_b
	14. input_b_flag
	15. input_c_units
	16. input_c_units_flag
	17. input_c
	18. input_c_flag
	19. output_units
	20. output_units_flag
	21. expression_units
	22. expression_units_flag
	23. output_expression
	24. output_expression_flag
	25. resampling_buffer
	26. resampling_buffer_flag
	27. connected_object_type
	28. connected_object_type_flag
	29. connected_object_id
	30. connected_object_id_flag
	31. usage
	32. usage_flag
	33. input_attribute
	34. input_attribute_flag
	35. comparison_result
	36. comparison_result_flag
	37. hyperlinks
		 description
		 url
	38. hyperlinks_flag
	39. arma_id
	40. arma_id_flag
	41. notes
	42. notes_flag
	43. area
	44. area_flag
	45. x
	46. x_flag
	47. y
	48. y_flag
	49. user_number_1
	50. user_number_1_flag
	51. user_number_2
	52. user_number_2_flag
	53. user_number_3
	54. user_number_3_flag
	55. user_number_4
	56. user_number_4_flag
	57. user_number_5
	58. user_number_5_flag
	59. user_number_6
	60. user_number_6_flag
	61. user_number_7
	62. user_number_7_flag
	63. user_number_8
	64. user_number_8_flag
	65. user_number_9
	66. user_number_9_flag
	67. user_number_10
	68. user_number_10_flag
	69. user_text_1
	70. user_text_1_flag
	71. user_text_2
	72. user_text_2_flag
	73. user_text_3
	74. user_text_3_flag
	75. user_text_4
	76. user_text_4_flag
	77. user_text_5
	78. user_text_5_flag
	79. user_text_6
	80. user_text_6_flag
	81. user_text_7
	82. user_text_7_flag
	83. user_text_8
	84. user_text_8_flag
	85. user_text_9
	86. user_text_9_flag
	87. user_text_10
	88. user_text_10_flag
****hw_2d_results_polygon
	1. polygon_id
	2. polygon_id_flag
	3. boundary_array
	4. area
	5. area_flag
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****hw_2d_results_line
	1. line_id
	2. line_id_flag
	3. line_xy
	4. hyperlinks
		 description
		 url
	5. hyperlinks_flag
	6. notes
	7. notes_flag
	8. user_number_1
	9. user_number_1_flag
	10. user_number_2
	11. user_number_2_flag
	12. user_number_3
	13. user_number_3_flag
	14. user_number_4
	15. user_number_4_flag
	16. user_number_5
	17. user_number_5_flag
	18. user_number_6
	19. user_number_6_flag
	20. user_number_7
	21. user_number_7_flag
	22. user_number_8
	23. user_number_8_flag
	24. user_number_9
	25. user_number_9_flag
	26. user_number_10
	27. user_number_10_flag
	28. user_text_1
	29. user_text_1_flag
	30. user_text_2
	31. user_text_2_flag
	32. user_text_3
	33. user_text_3_flag
	34. user_text_4
	35. user_text_4_flag
	36. user_text_5
	37. user_text_5_flag
	38. user_text_6
	39. user_text_6_flag
	40. user_text_7
	41. user_text_7_flag
	42. user_text_8
	43. user_text_8_flag
	44. user_text_9
	45. user_text_9_flag
	46. user_text_10
	47. user_text_10_flag
****hw_2d_results_point
	1. point_id
	2. point_id_flag
	3. point_x
	4. point_x_flag
	5. point_y
	6. point_y_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_1d_results_point
	1. point_id
	2. point_id_flag
	3. us_node_id
	4. us_node_id_flag
	5. link_suffix
	6. link_suffix_flag
	7. opening_id
	8. opening_id_flag
	9. point_x
	10. point_x_flag
	11. point_y
	12. point_y_flag
	13. hyperlinks
		 description
		 url
	14. hyperlinks_flag
	15. start_length
	16. start_length_flag
	17. notes
	18. notes_flag
	19. user_number_1
	20. user_number_1_flag
	21. user_number_2
	22. user_number_2_flag
	23. user_number_3
	24. user_number_3_flag
	25. user_number_4
	26. user_number_4_flag
	27. user_number_5
	28. user_number_5_flag
	29. user_number_6
	30. user_number_6_flag
	31. user_number_7
	32. user_number_7_flag
	33. user_number_8
	34. user_number_8_flag
	35. user_number_9
	36. user_number_9_flag
	37. user_number_10
	38. user_number_10_flag
	39. user_text_1
	40. user_text_1_flag
	41. user_text_2
	42. user_text_2_flag
	43. user_text_3
	44. user_text_3_flag
	45. user_text_4
	46. user_text_4_flag
	47. user_text_5
	48. user_text_5_flag
	49. user_text_6
	50. user_text_6_flag
	51. user_text_7
	52. user_text_7_flag
	53. user_text_8
	54. user_text_8_flag
	55. user_text_9
	56. user_text_9_flag
	57. user_text_10
	58. user_text_10_flag
****hw_2d_bridge
	1. line_id
	2. line_id_flag
	3. asset_id
	4. asset_id_flag
	5. discharge_coeff
	6. discharge_coeff_flag
	7. secondary_discharge_coeff
	8. secondary_discharge_coeff_flag
	9. overgate_discharge_coeff
	10. overgate_discharge_coeff_flag
	11. length
	12. length_flag
	13. linear_structure_id
	14. linear_structure_id_flag
	15. notes
	16. notes_flag
	17. start_length
	18. start_length_flag
	19. headloss_spec
	20. headloss_spec_flag
	21. headloss_type
	22. headloss_type_flag
	23. headloss_coeff
	24. headloss_coeff_flag
	25. us_unit_headloss_coeff
	26. us_unit_headloss_coeff_flag
	27. ds_unit_headloss_coeff
	28. ds_unit_headloss_coeff_flag
	29. headloss_coeff2
	30. headloss_coeff2_flag
	31. us_headloss_coeff
	32. us_headloss_coeff_flag
	33. ds_headloss_coeff
	34. ds_headloss_coeff_flag
	35. lateral_friction
	36. lateral_friction_flag
	37. blockage
	38. blockage_flag
	39. use_direction
	40. use_direction_flag
	41. crest_level
	42. crest_level_flag
	43. flow_type
	44. flow_type_flag
	45. over_flow_type
	46. over_flow_type_flag
	47. height
	48. height_flag
	49. level
	50. level_flag
	51. off_sections
		 cross_chainage
		 Z
		 opening
		 deck_level
	52. point_array
	53. sections
		 X
		 Y
		 Z
		 opening
		 deck_level
	54. hyperlinks
		 description
		 url
	55. hyperlinks_flag
	56. user_number_1
	57. user_number_1_flag
	58. user_number_2
	59. user_number_2_flag
	60. user_number_3
	61. user_number_3_flag
	62. user_number_4
	63. user_number_4_flag
	64. user_number_5
	65. user_number_5_flag
	66. user_number_6
	67. user_number_6_flag
	68. user_number_7
	69. user_number_7_flag
	70. user_number_8
	71. user_number_8_flag
	72. user_number_9
	73. user_number_9_flag
	74. user_number_10
	75. user_number_10_flag
	76. user_text_1
	77. user_text_1_flag
	78. user_text_2
	79. user_text_2_flag
	80. user_text_3
	81. user_text_3_flag
	82. user_text_4
	83. user_text_4_flag
	84. user_text_5
	85. user_text_5_flag
	86. user_text_6
	87. user_text_6_flag
	88. user_text_7
	89. user_text_7_flag
	90. user_text_8
	91. user_text_8_flag
	92. user_text_9
	93. user_text_9_flag
	94. user_text_10
	95. user_text_10_flag
****hw_spatial_rain_zone
	1. id
	2. id_flag
	3. boundary_array
	4. boundary_array_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. notes
	8. notes_flag
	9. area
	10. area_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_spatial_rain_source
	1. id
	2. id_flag
	3. source_type
	4. source_type_flag
	5. stream_or_category
	6. stream_or_category_flag
	7. priority
	8. priority_flag
	9. start_time
	10. start_time_flag
	11. end_time
	12. end_time_flag
	13. hyperlinks
		 description
		 url
	14. hyperlinks_flag
	15. notes
	16. notes_flag
	17. user_number_1
	18. user_number_1_flag
	19. user_number_2
	20. user_number_2_flag
	21. user_number_3
	22. user_number_3_flag
	23. user_number_4
	24. user_number_4_flag
	25. user_number_5
	26. user_number_5_flag
	27. user_number_6
	28. user_number_6_flag
	29. user_number_7
	30. user_number_7_flag
	31. user_number_8
	32. user_number_8_flag
	33. user_number_9
	34. user_number_9_flag
	35. user_number_10
	36. user_number_10_flag
	37. user_text_1
	38. user_text_1_flag
	39. user_text_2
	40. user_text_2_flag
	41. user_text_3
	42. user_text_3_flag
	43. user_text_4
	44. user_text_4_flag
	45. user_text_5
	46. user_text_5_flag
	47. user_text_6
	48. user_text_6_flag
	49. user_text_7
	50. user_text_7_flag
	51. user_text_8
	52. user_text_8_flag
	53. user_text_9
	54. user_text_9_flag
	55. user_text_10
	56. user_text_10_flag
****hw_pdm_descriptor
	1. descriptor_id
	2. descriptor_id_flag
	3. re_type
	4. re_type_flag
	5. rainfac
	6. rainfac_flag
	7. rainfac_cal_step
	8. rainfac_cal_step_flag
	9. rainfac_cal_tol
	10. rainfac_cal_tol_flag
	11. rainfac_cal_min
	12. rainfac_cal_min_flag
	13. rainfac_cal_max
	14. rainfac_cal_max_flag
	15. cmin
	16. cmin_flag
	17. cmin_cal_step
	18. cmin_cal_step_flag
	19. cmin_cal_tol
	20. cmin_cal_tol_flag
	21. cmin_cal_min
	22. cmin_cal_min_flag
	23. cmin_cal_max
	24. cmin_cal_max_flag
	25. cmax
	26. cmax_flag
	27. cmax_cal_step
	28. cmax_cal_step_flag
	29. cmax_cal_tol
	30. cmax_cal_tol_flag
	31. cmax_cal_min
	32. cmax_cal_min_flag
	33. cmax_cal_max
	34. cmax_cal_max_flag
	35. b
	36. b_flag
	37. b_cal_step
	38. b_cal_step_flag
	39. b_cal_tol
	40. b_cal_tol_flag
	41. b_cal_min
	42. b_cal_min_flag
	43. b_cal_max
	44. b_cal_max_flag
	45. be
	46. be_flag
	47. be_cal_step
	48. be_cal_step_flag
	49. be_cal_tol
	50. be_cal_tol_flag
	51. be_cal_min
	52. be_cal_min_flag
	53. be_cal_max
	54. be_cal_max_flag
	55. k1
	56. k1_flag
	57. k1_cal_step
	58. k1_cal_step_flag
	59. k1_cal_tol
	60. k1_cal_tol_flag
	61. k1_cal_min
	62. k1_cal_min_flag
	63. k1_cal_max
	64. k1_cal_max_flag
	65. k2
	66. k2_flag
	67. k2_cal_step
	68. k2_cal_step_flag
	69. k2_cal_tol
	70. k2_cal_tol_flag
	71. k2_cal_min
	72. k2_cal_min_flag
	73. k2_cal_max
	74. k2_cal_max_flag
	75. kb
	76. kb_flag
	77. kb_cal_step
	78. kb_cal_step_flag
	79. kb_cal_tol
	80. kb_cal_tol_flag
	81. kb_cal_min
	82. kb_cal_min_flag
	83. kb_cal_max
	84. kb_cal_max_flag
	85. kg
	86. kg_flag
	87. kg_cal_step
	88. kg_cal_step_flag
	89. kg_cal_tol
	90. kg_cal_tol_flag
	91. kg_cal_min
	92. kg_cal_min_flag
	93. kg_cal_max
	94. kg_cal_max_flag
	95. St
	96. St_flag
	97. St_cal_step
	98. St_cal_step_flag
	99. St_cal_tol
	100. St_cal_tol_flag
	101. St_cal_min
	102. St_cal_min_flag
	103. St_cal_max
	104. St_cal_max_flag
	105. bg
	106. bg_flag
	107. bg_cal_step
	108. bg_cal_step_flag
	109. bg_cal_tol
	110. bg_cal_tol_flag
	111. bg_cal_min
	112. bg_cal_min_flag
	113. bg_cal_max
	114. bg_cal_max_flag
	115. alpha_d
	116. alpha_d_flag
	117. alpha_d_cal_step
	118. alpha_d_cal_step_flag
	119. alpha_d_cal_tol
	120. alpha_d_cal_tol_flag
	121. alpha_d_cal_min
	122. alpha_d_cal_min_flag
	123. alpha_d_cal_max
	124. alpha_d_cal_max_flag
	125. qsat_d
	126. qsat_d_flag
	127. qsat_d_cal_step
	128. qsat_d_cal_step_flag
	129. qsat_d_cal_tol
	130. qsat_d_cal_tol_flag
	131. qsat_d_cal_min
	132. qsat_d_cal_min_flag
	133. qsat_d_cal_max
	134. qsat_d_cal_max_flag
	135. beta_d
	136. beta_d_flag
	137. beta_d_cal_step
	138. beta_d_cal_step_flag
	139. beta_d_cal_tol
	140. beta_d_cal_tol_flag
	141. beta_d_cal_min
	142. beta_d_cal_min_flag
	143. beta_d_cal_max
	144. beta_d_cal_max_flag
	145. fi
	146. fi_flag
	147. fi_cal_step
	148. fi_cal_step_flag
	149. fi_cal_tol
	150. fi_cal_tol_flag
	151. fi_cal_min
	152. fi_cal_min_flag
	153. fi_cal_max
	154. fi_cal_max_flag
	155. ki
	156. ki_flag
	157. ki_cal_step
	158. ki_cal_step_flag
	159. ki_cal_tol
	160. ki_cal_tol_flag
	161. ki_cal_min
	162. ki_cal_min_flag
	163. ki_cal_max
	164. ki_cal_max_flag
	165. kinf
	166. kinf_flag
	167. kinf_cal_step
	168. kinf_cal_step_flag
	169. kinf_cal_tol
	170. kinf_cal_tol_flag
	171. kinf_cal_min
	172. kinf_cal_min_flag
	173. kinf_cal_max
	174. kinf_cal_max_flag
	175. kfreeze
	176. kfreeze_flag
	177. kfreeze_cal_step
	178. kfreeze_cal_step_flag
	179. kfreeze_cal_tol
	180. kfreeze_cal_tol_flag
	181. kfreeze_cal_min
	182. kfreeze_cal_min_flag
	183. kfreeze_cal_max
	184. kfreeze_cal_max_flag
	185. kt
	186. kt_flag
	187. kt_cal_step
	188. kt_cal_step_flag
	189. kt_cal_tol
	190. kt_cal_tol_flag
	191. kt_cal_min
	192. kt_cal_min_flag
	193. kt_cal_max
	194. kt_cal_max_flag
	195. smd_type
	196. smd_type_flag
	197. theta
	198. theta_flag
	199. theta_cal_step
	200. theta_cal_step_flag
	201. theta_cal_tol
	202. theta_cal_tol_flag
	203. theta_cal_min
	204. theta_cal_min_flag
	205. theta_cal_max
	206. theta_cal_max_flag
	207. alpha
	208. alpha_flag
	209. alpha_cal_step
	210. alpha_cal_step_flag
	211. alpha_cal_tol
	212. alpha_cal_tol_flag
	213. alpha_cal_min
	214. alpha_cal_min_flag
	215. alpha_cal_max
	216. alpha_cal_max_flag
	217. beta
	218. beta_flag
	219. beta_cal_step
	220. beta_cal_step_flag
	221. beta_cal_tol
	222. beta_cal_tol_flag
	223. beta_cal_min
	224. beta_cal_min_flag
	225. beta_cal_max
	226. beta_cal_max_flag
	227. tdly
	228. tdly_flag
	229. tdly_cal_step
	230. tdly_cal_step_flag
	231. tdly_cal_tol
	232. tdly_cal_tol_flag
	233. tdly_cal_min
	234. tdly_cal_min_flag
	235. tdly_cal_max
	236. tdly_cal_max_flag
	237. rr_type
	238. rr_type_flag
	239. ss_type
	240. ss_type_flag
	241. if_type
	242. if_type_flag
	243. bs_type
	244. bs_type_flag
	245. notes
	246. notes_flag
	247. hyperlinks
		 description
		 url
	248. hyperlinks_flag
	249. user_number_1
	250. user_number_1_flag
	251. user_number_2
	252. user_number_2_flag
	253. user_number_3
	254. user_number_3_flag
	255. user_number_4
	256. user_number_4_flag
	257. user_number_5
	258. user_number_5_flag
	259. user_number_6
	260. user_number_6_flag
	261. user_number_7
	262. user_number_7_flag
	263. user_number_8
	264. user_number_8_flag
	265. user_number_9
	266. user_number_9_flag
	267. user_number_10
	268. user_number_10_flag
	269. user_text_1
	270. user_text_1_flag
	271. user_text_2
	272. user_text_2_flag
	273. user_text_3
	274. user_text_3_flag
	275. user_text_4
	276. user_text_4_flag
	277. user_text_5
	278. user_text_5_flag
	279. user_text_6
	280. user_text_6_flag
	281. user_text_7
	282. user_text_7_flag
	283. user_text_8
	284. user_text_8_flag
	285. user_text_9
	286. user_text_9_flag
	287. user_text_10
	288. user_text_10_flag
****hw_damage_receptor
	1. point_id
	2. point_id_flag
	3. x
	4. x_flag
	5. y
	6. y_flag
	7. link_shapes_table
	8. link_shapes_table_flag
	9. link_shapes_ref_field
	10. link_shapes_ref_field_flag
	11. link_shapes_ref
	12. link_shapes_ref_flag
	13. code_1
	14. code_1_flag
	15. component_1
	16. component_1_flag
	17. weight_1
	18. weight_1_flag
	19. code_2
	20. code_2_flag
	21. component_2
	22. component_2_flag
	23. weight_2
	24. weight_2_flag
	25. code_3
	26. code_3_flag
	27. component_3
	28. component_3_flag
	29. weight_3
	30. weight_3_flag
	31. code_4
	32. code_4_flag
	33. component_4
	34. component_4_flag
	35. weight_4
	36. weight_4_flag
	37. area
	38. area_flag
	39. floor_level
	40. floor_level_flag
	41. floor_type
	42. floor_type_flag
	43. value
	44. value_flag
	45. threshold_height
	46. threshold_height_flag
	47. hyperlinks
		 description
		 url
	48. hyperlinks_flag
	49. notes
	50. notes_flag
	51. user_number_1
	52. user_number_1_flag
	53. user_number_2
	54. user_number_2_flag
	55. user_number_3
	56. user_number_3_flag
	57. user_number_4
	58. user_number_4_flag
	59. user_number_5
	60. user_number_5_flag
	61. user_number_6
	62. user_number_6_flag
	63. user_number_7
	64. user_number_7_flag
	65. user_number_8
	66. user_number_8_flag
	67. user_number_9
	68. user_number_9_flag
	69. user_number_10
	70. user_number_10_flag
	71. user_text_1
	72. user_text_1_flag
	73. user_text_2
	74. user_text_2_flag
	75. user_text_3
	76. user_text_3_flag
	77. user_text_4
	78. user_text_4_flag
	79. user_text_5
	80. user_text_5_flag
	81. user_text_6
	82. user_text_6_flag
	83. user_text_7
	84. user_text_7_flag
	85. user_text_8
	86. user_text_8_flag
	87. user_text_9
	88. user_text_9_flag
	89. user_text_10
	90. user_text_10_flag
****hw_head_unit_discharge
	1. head_unit_discharge_id
	2. head_unit_discharge_id_flag
	3. head_unit_discharge_description
	4. head_unit_discharge_description_flag
	5. HUDP_table
		 head
		 unit_discharge
	6. HUDP_table_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_2d_sed_ic_polygon
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****hw_mesh_level_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. level_type
	6. level_type_flag
	7. use_upper_limit
	8. use_upper_limit_flag
	9. upper_limit_level
	10. upper_limit_level_flag
	11. use_lower_limit
	12. use_lower_limit_flag
	13. lower_limit_level
	14. lower_limit_level_flag
	15. level_sections
		 X
		 Y
		 vertex_elev_type
		 elevation
		 elev_adjust
	16. level
	17. level_flag
	18. raise_by
	19. raise_by_flag
	20. hyperlinks
		 description
		 url
	21. hyperlinks_flag
	22. notes
	23. notes_flag
	24. user_number_1
	25. user_number_1_flag
	26. user_number_2
	27. user_number_2_flag
	28. user_number_3
	29. user_number_3_flag
	30. user_number_4
	31. user_number_4_flag
	32. user_number_5
	33. user_number_5_flag
	34. user_number_6
	35. user_number_6_flag
	36. user_number_7
	37. user_number_7_flag
	38. user_number_8
	39. user_number_8_flag
	40. user_number_9
	41. user_number_9_flag
	42. user_number_10
	43. user_number_10_flag
	44. user_text_1
	45. user_text_1_flag
	46. user_text_2
	47. user_text_2_flag
	48. user_text_3
	49. user_text_3_flag
	50. user_text_4
	51. user_text_4_flag
	52. user_text_5
	53. user_text_5_flag
	54. user_text_6
	55. user_text_6_flag
	56. user_text_7
	57. user_text_7_flag
	58. user_text_8
	59. user_text_8_flag
	60. user_text_9
	61. user_text_9_flag
	62. user_text_10
	63. user_text_10_flag
****hw_risk_impact_zone
	1. polygon_id
	2. polygon_id_flag
	3. category_id
	4. category_id_flag
	5. area
	6. area_flag
	7. boundary_array
	8. hyperlinks
		 description
		 url
	9. hyperlinks_flag
	10. notes
	11. notes_flag
	12. user_number_1
	13. user_number_1_flag
	14. user_number_2
	15. user_number_2_flag
	16. user_number_3
	17. user_number_3_flag
	18. user_number_4
	19. user_number_4_flag
	20. user_number_5
	21. user_number_5_flag
	22. user_number_6
	23. user_number_6_flag
	24. user_number_7
	25. user_number_7_flag
	26. user_number_8
	27. user_number_8_flag
	28. user_number_9
	29. user_number_9_flag
	30. user_number_10
	31. user_number_10_flag
	32. user_text_1
	33. user_text_1_flag
	34. user_text_2
	35. user_text_2_flag
	36. user_text_3
	37. user_text_3_flag
	38. user_text_4
	39. user_text_4_flag
	40. user_text_5
	41. user_text_5_flag
	42. user_text_6
	43. user_text_6_flag
	44. user_text_7
	45. user_text_7_flag
	46. user_text_8
	47. user_text_8_flag
	48. user_text_9
	49. user_text_9_flag
	50. user_text_10
	51. user_text_10_flag
****hw_sediment_grading
	1. grading_id
	2. grading_id_flag
	3. grading_type
	4. grading_type_flag
	5. sf1_weight
	6. sf1_weight_flag
	7. sf2_weight
	8. sf2_weight_flag
	9. hyperlinks
		 description
		 url
	10. hyperlinks_flag
	11. notes
	12. notes_flag
	13. user_number_1
	14. user_number_1_flag
	15. user_number_2
	16. user_number_2_flag
	17. user_number_3
	18. user_number_3_flag
	19. user_number_4
	20. user_number_4_flag
	21. user_number_5
	22. user_number_5_flag
	23. user_number_6
	24. user_number_6_flag
	25. user_number_7
	26. user_number_7_flag
	27. user_number_8
	28. user_number_8_flag
	29. user_number_9
	30. user_number_9_flag
	31. user_number_10
	32. user_number_10_flag
	33. user_text_1
	34. user_text_1_flag
	35. user_text_2
	36. user_text_2_flag
	37. user_text_3
	38. user_text_3_flag
	39. user_text_4
	40. user_text_4_flag
	41. user_text_5
	42. user_text_5_flag
	43. user_text_6
	44. user_text_6_flag
	45. user_text_7
	46. user_text_7_flag
	47. user_text_8
	48. user_text_8_flag
	49. user_text_9
	50. user_text_9_flag
	51. user_text_10
	52. user_text_10_flag
****hw_suds_control
	1. control_id
	2. control_id_flag
	3. control_type
	4. control_type_flag
	5. surf_berm_height
	6. surf_berm_height_flag
	7. surf_storage_depth
	8. surf_storage_depth_flag
	9. surf_veg_vol_fraction
	10. surf_veg_vol_fraction_flag
	11. surf_roughness_n
	12. surf_roughness_n_flag
	13. surf_slope
	14. surf_slope_flag
	15. surf_xslope
	16. surf_xslope_flag
	17. pave_thickness
	18. pave_thickness_flag
	19. pave_void_ratio
	20. pave_void_ratio_flag
	21. pave_impervious_surf_fraction
	22. pave_impervious_surf_fraction_flag
	23. pave_permeability
	24. pave_permeability_flag
	25. pave_clogging_factor
	26. pave_clogging_factor_flag
	27. pave_regen_interval
	28. pave_regen_interval_flag
	29. pave_regen_fraction
	30. pave_regen_fraction_flag
	31. soil_class
	32. soil_class_flag
	33. soil_thickness
	34. soil_thickness_flag
	35. soil_porosity
	36. soil_porosity_flag
	37. soil_field_capacity
	38. soil_field_capacity_flag
	39. soil_wilting_point
	40. soil_wilting_point_flag
	41. soil_conductivity
	42. soil_conductivity_flag
	43. soil_conductivity_slope
	44. soil_conductivity_slope_flag
	45. soil_suction_head
	46. soil_suction_head_flag
	47. storage_barrel_height
	48. storage_barrel_height_flag
	49. storage_thickness
	50. storage_thickness_flag
	51. storage_void_ratio
	52. storage_void_ratio_flag
	53. storage_seepage_rate
	54. storage_seepage_rate_flag
	55. storage_clogging_factor
	56. storage_clogging_factor_flag
	57. underdrain_flow_coefficient
	58. underdrain_flow_coefficient_flag
	59. underdrain_flow_exponent
	60. underdrain_flow_exponent_flag
	61. underdrain_offset_height
	62. underdrain_offset_height_flag
	63. underdrain_delay
	64. underdrain_delay_flag
	65. underdrain_flow_capacity
	66. underdrain_flow_capacity_flag
	67. drainagemat_thickness
	68. drainagemat_thickness_flag
	69. drainagemat_void_fraction
	70. drainagemat_void_fraction_flag
	71. drainagemat_roughness
	72. drainagemat_roughness_flag
	73. notes
	74. notes_flag
	75. user_number_1
	76. user_number_1_flag
	77. user_number_2
	78. user_number_2_flag
	79. user_number_3
	80. user_number_3_flag
	81. user_number_4
	82. user_number_4_flag
	83. user_number_5
	84. user_number_5_flag
	85. user_number_6
	86. user_number_6_flag
	87. user_number_7
	88. user_number_7_flag
	89. user_number_8
	90. user_number_8_flag
	91. user_number_9
	92. user_number_9_flag
	93. user_number_10
	94. user_number_10_flag
	95. user_text_1
	96. user_text_1_flag
	97. user_text_2
	98. user_text_2_flag
	99. user_text_3
	100. user_text_3_flag
	101. user_text_4
	102. user_text_4_flag
	103. user_text_5
	104. user_text_5_flag
	105. user_text_6
	106. user_text_6_flag
	107. user_text_7
	108. user_text_7_flag
	109. user_text_8
	110. user_text_8_flag
	111. user_text_9
	112. user_text_9_flag
	113. user_text_10
	114. user_text_10_flag
	115. hyperlinks
		 description
		 url
	116. hyperlinks_flag
****hw_2d_line_source
	1. line_id
	2. line_id_flag
	3. general_line_xy
	4. hyperlinks
		 description
		 url
	5. hyperlinks_flag
	6. length
	7. length_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****hw_2d_turbulence_model
	1. model_id
	2. model_id_flag
	3. const_eddy_visc
	4. const_eddy_visc_flag
	5. vert_eddy_visc_equn
	6. vert_eddy_visc_equn_flag
	7. parab_eddy_visc_coeff
	8. parab_eddy_visc_coeff_flag
	9. horz_eddy_visc_equn
	10. horz_eddy_visc_equn_flag
	11. mix_eddy_visc_coeff
	12. mix_eddy_visc_coeff_flag
	13. smag_eddy_visc_coeff
	14. smag_eddy_visc_coeff_flag
	15. hyperlinks
		 description
		 url
	16. hyperlinks_flag
	17. notes
	18. notes_flag
	19. user_number_1
	20. user_number_1_flag
	21. user_number_2
	22. user_number_2_flag
	23. user_number_3
	24. user_number_3_flag
	25. user_number_4
	26. user_number_4_flag
	27. user_number_5
	28. user_number_5_flag
	29. user_number_6
	30. user_number_6_flag
	31. user_number_7
	32. user_number_7_flag
	33. user_number_8
	34. user_number_8_flag
	35. user_number_9
	36. user_number_9_flag
	37. user_number_10
	38. user_number_10_flag
	39. user_text_1
	40. user_text_1_flag
	41. user_text_2
	42. user_text_2_flag
	43. user_text_3
	44. user_text_3_flag
	45. user_text_4
	46. user_text_4_flag
	47. user_text_5
	48. user_text_5_flag
	49. user_text_6
	50. user_text_6_flag
	51. user_text_7
	52. user_text_7_flag
	53. user_text_8
	54. user_text_8_flag
	55. user_text_9
	56. user_text_9_flag
	57. user_text_10
	58. user_text_10_flag
****hw_2d_turbulence_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. turbulence_model_id
	7. turbulence_model_id_flag
	8. exclude_from_2d_mesh
	9. exclude_from_2d_mesh_flag
	10. hyperlinks
		 description
		 url
	11. hyperlinks_flag
	12. notes
	13. notes_flag
	14. user_number_1
	15. user_number_1_flag
	16. user_number_2
	17. user_number_2_flag
	18. user_number_3
	19. user_number_3_flag
	20. user_number_4
	21. user_number_4_flag
	22. user_number_5
	23. user_number_5_flag
	24. user_number_6
	25. user_number_6_flag
	26. user_number_7
	27. user_number_7_flag
	28. user_number_8
	29. user_number_8_flag
	30. user_number_9
	31. user_number_9_flag
	32. user_number_10
	33. user_number_10_flag
	34. user_text_1
	35. user_text_1_flag
	36. user_text_2
	37. user_text_2_flag
	38. user_text_3
	39. user_text_3_flag
	40. user_text_4
	41. user_text_4_flag
	42. user_text_5
	43. user_text_5_flag
	44. user_text_6
	45. user_text_6_flag
	46. user_text_7
	47. user_text_7_flag
	48. user_text_8
	49. user_text_8_flag
	50. user_text_9
	51. user_text_9_flag
	52. user_text_10
	53. user_text_10_flag
****hw_2d_permeable_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. exclude_from_2d_mesh
	6. exclude_from_2d_mesh_flag
	7. drains_to
	8. drains_to_flag
	9. node_id
	10. node_id_flag
	11. link_suffix
	12. link_suffix_flag
	13. to_subcatchment_id
	14. to_subcatchment_id_flag
	15. lateral_links
		 node_id
		 link_suffix
		 weight
	16. lateral_links_flag
	17. lateral_weights
	18. lateral_weights_flag
	19. boundary_array
	20. hyperlinks
		 description
		 url
	21. hyperlinks_flag
	22. notes
	23. notes_flag
	24. user_number_1
	25. user_number_1_flag
	26. user_number_2
	27. user_number_2_flag
	28. user_number_3
	29. user_number_3_flag
	30. user_number_4
	31. user_number_4_flag
	32. user_number_5
	33. user_number_5_flag
	34. user_number_6
	35. user_number_6_flag
	36. user_number_7
	37. user_number_7_flag
	38. user_number_8
	39. user_number_8_flag
	40. user_number_9
	41. user_number_9_flag
	42. user_number_10
	43. user_number_10_flag
	44. user_text_1
	45. user_text_1_flag
	46. user_text_2
	47. user_text_2_flag
	48. user_text_3
	49. user_text_3_flag
	50. user_text_4
	51. user_text_4_flag
	52. user_text_5
	53. user_text_5_flag
	54. user_text_6
	55. user_text_6_flag
	56. user_text_7
	57. user_text_7_flag
	58. user_text_8
	59. user_text_8_flag
	60. user_text_9
	61. user_text_9_flag
	62. user_text_10
	63. user_text_10_flag
****hw_arma
	1. arma_type
	2. arma_type_flag
	3. error_calc
	4. error_calc_flag
	5. params
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****hw_swmm_land_use
	1. id
	2. id_flag
	3. hyperlinks
		 description
		 url
	4. hyperlinks_flag
	5. sweep_interval
	6. sweep_removal
	7. build_up
		 determinant
		 build_up_type
		 max_build_up
		 power_rate_constant
		 power_time_exponent
		 exp_rate_constant
		 saturation_constant
	8. washoff
		 determinant
		 washoff_type
		 exponential_washoff_coeff
		 rating_washoff_coeff
		 emc_washoff_coeff
		 washoff_exponent
		 sweep_removal
		 bmp_removal
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****hw_roughness_definition
	1. definition_id
	2. definition_id_flag
	3. number_of_bands
	4. number_of_bands_flag
	5. roughness_1
	6. roughness_1_flag
	7. depth_thld_1
	8. depth_thld_1_flag
	9. roughness_2
	10. roughness_2_flag
	11. depth_thld_2
	12. depth_thld_2_flag
	13. roughness_3
	14. roughness_3_flag
	15. hyperlinks
		 description
		 url
	16. hyperlinks_flag
	17. notes
	18. notes_flag
	19. user_number_1
	20. user_number_1_flag
	21. user_number_2
	22. user_number_2_flag
	23. user_number_3
	24. user_number_3_flag
	25. user_number_4
	26. user_number_4_flag
	27. user_number_5
	28. user_number_5_flag
	29. user_number_6
	30. user_number_6_flag
	31. user_number_7
	32. user_number_7_flag
	33. user_number_8
	34. user_number_8_flag
	35. user_number_9
	36. user_number_9_flag
	37. user_number_10
	38. user_number_10_flag
	39. user_text_1
	40. user_text_1_flag
	41. user_text_2
	42. user_text_2_flag
	43. user_text_3
	44. user_text_3_flag
	45. user_text_4
	46. user_text_4_flag
	47. user_text_5
	48. user_text_5_flag
	49. user_text_6
	50. user_text_6_flag
	51. user_text_7
	52. user_text_7_flag
	53. user_text_8
	54. user_text_8_flag
	55. user_text_9
	56. user_text_9_flag
	57. user_text_10
	58. user_text_10_flag
****hw_building
	1. building_id
	2. building_id_flag
	3. hyperlinks
		 description
		 url
	4. hyperlinks_flag
	5. system_type
	6. system_type_flag
	7. drains_to
	8. drains_to_flag
	9. node_id
	10. node_id_flag
	11. link_suffix
	12. link_suffix_flag
	13. 2d_pt_id
	14. 2d_pt_id_flag
	15. capacity_limit
	16. capacity_limit_flag
	17. total_area
	18. total_area_flag
	19. contributing_area
	20. contributing_area_flag
	21. exceed_flow_type
	22. exceed_flow_type_flag
	23. x
	24. x_flag
	25. y
	26. y_flag
	27. catchment_slope
	28. catchment_slope_flag
	29. rainfall_profile
	30. rainfall_profile_flag
	31. evaporation_profile
	32. evaporation_profile_flag
	33. output_lag
	34. output_lag_flag
	35. suds_controls
		 id
		 suds_structure
		 control_type
		 area
		 num_units
		 area_subcatchment_pct
		 unit_surface_width
		 initial_saturation_pct
		 impervious_area_treated_pct
		 outflow_to
		 drain_to_subcatchment
		 drain_to_node
		 surface
		 pervious_area_treated_pct
	36. suds_controls_flag
	37. roughness
	38. roughness_flag
	39. roughness_definition_id
	40. roughness_definition_id_flag
	41. level_type
	42. level_type_flag
	43. use_lower_limit
	44. use_lower_limit_flag
	45. lower_limit_level
	46. lower_limit_level_flag
	47. use_upper_limit
	48. use_upper_limit_flag
	49. upper_limit_level
	50. upper_limit_level_flag
	51. level_sections
		 X
		 Y
		 vertex_elev_type
		 elevation
		 elev_adjust
	52. level
	53. level_flag
	54. raise_by
	55. raise_by_flag
	56. porosity
	57. porosity_flag
	58. height
	59. height_flag
	60. notes
	61. notes_flag
	62. user_number_1
	63. user_number_1_flag
	64. user_number_2
	65. user_number_2_flag
	66. user_number_3
	67. user_number_3_flag
	68. user_number_4
	69. user_number_4_flag
	70. user_number_5
	71. user_number_5_flag
	72. user_number_6
	73. user_number_6_flag
	74. user_number_7
	75. user_number_7_flag
	76. user_number_8
	77. user_number_8_flag
	78. user_number_9
	79. user_number_9_flag
	80. user_number_10
	81. user_number_10_flag
	82. user_text_1
	83. user_text_1_flag
	84. user_text_2
	85. user_text_2_flag
	86. user_text_3
	87. user_text_3_flag
	88. user_text_4
	89. user_text_4_flag
	90. user_text_5
	91. user_text_5_flag
	92. user_text_6
	93. user_text_6_flag
	94. user_text_7
	95. user_text_7_flag
	96. user_text_8
	97. user_text_8_flag
	98. user_text_9
	99. user_text_9_flag
	100. user_text_10
	101. user_text_10_flag
****hw_2d_connect_line
	1. line_id
	2. line_id_flag
	3. length
	4. length_flag
	5. general_line_xy
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0131 - Master RB Files\sw_parameters.rb" 
****sw_options
	1. units
	2. allow_ponding
	3. infiltration
	4. force_main_equation
	5. min_slope
	6. min_surfarea
	7. inertial_damping
	8. normal_flow_limited
	9. head_tolerance
	10. max_trials
****sw_subcatchment
	1. subcatchment_id
	2. subcatchment_id_flag
	3. coverages
		 land_use
		 area
	4. coverages_flag
	5. loadings
		 pollutant
		 build_up
	6. loadings_flag
	7. soil
		 soil
		 area
	8. soil_flag
	9. raingauge_id
	10. raingauge_id_flag
	11. sw_drains_to
	12. sw_drains_to_flag
	13. outlet_id
	14. outlet_id_flag
	15. area
	16. area_flag
	17. hydraulic_length
	18. hydraulic_length_flag
	19. x
	20. x_flag
	21. y
	22. y_flag
	23. width
	24. width_flag
	25. catchment_slope
	26. catchment_slope_flag
	27. area_average_rain
	28. area_average_rain_flag
	29. percent_impervious
	30. percent_impervious_flag
	31. roughness_impervious
	32. roughness_impervious_flag
	33. roughness_pervious
	34. roughness_pervious_flag
	35. storage_impervious
	36. storage_impervious_flag
	37. boundary_array
	38. storage_pervious
	39. storage_pervious_flag
	40. percent_no_storage
	41. percent_no_storage_flag
	42. route_to
	43. route_to_flag
	44. infiltration
	45. infiltration_flag
	46. percent_routed
	47. percent_routed_flag
	48. initial_infiltration
	49. initial_infiltration_flag
	50. limiting_infiltration
	51. limiting_infiltration_flag
	52. decay_factor
	53. decay_factor_flag
	54. initial_abstraction_factor
	55. initial_abstraction_factor_flag
	56. drying_time
	57. drying_time_flag
	58. max_infiltration_volume
	59. max_infiltration_volume_flag
	60. aquifer_id
	61. aquifer_id_flag
	62. aquifer_node_id
	63. aquifer_node_id_flag
	64. aquifer_elevation
	65. aquifer_elevation_flag
	66. aquifer_initial_groundwater
	67. aquifer_initial_groundwater_flag
	68. aquifer_initial_moisture_content
	69. aquifer_initial_moisture_content_flag
	70. elevation
	71. elevation_flag
	72. groundwater_coefficient
	73. groundwater_coefficient_flag
	74. groundwater_exponent
	75. groundwater_exponent_flag
	76. groundwater_threshold
	77. groundwater_threshold_flag
	78. initial_moisture_deficit
	79. initial_moisture_deficit_flag
	80. lateral_gwf_equation
	81. lateral_gwf_equation_flag
	82. deep_gwf_equation
	83. deep_gwf_equation_flag
	84. surface_coefficient
	85. surface_coefficient_flag
	86. surface_depth
	87. surface_depth_flag
	88. surface_exponent
	89. surface_exponent_flag
	90. surface_groundwater_coefficient
	91. surface_groundwater_coefficient_flag
	92. curve_number
	93. curve_number_flag
	94. average_capillary_suction
	95. average_capillary_suction_flag
	96. saturated_hydraulic_conductivity
	97. saturated_hydraulic_conductivity_flag
	98. initial_abstraction_type
	99. initial_abstraction_type_flag
	100. runoff_model_type
	101. runoff_model_type_flag
	102. shape_factor
	103. shape_factor_flag
	104. initial_abstraction
	105. initial_abstraction_flag
	106. time_of_concentration
	107. time_of_concentration_flag
	108. snow_pack_id
	109. snow_pack_id_flag
	110. curb_length
	111. curb_length_flag
	112. suds_controls
		 id
		 suds_structure
		 control_type
		 area
		 num_units
		 area_subcatchment_pct
		 unit_surface_width
		 initial_saturation_pct
		 impervious_area_treated_pct
		 outflow_to
		 drain_to_subcatchment
		 drain_to_node
		 pervious_area_treated_pct
	113. suds_controls_flag
	114. n_perv_pattern
	115. n_perv_pattern_flag
	116. dstore_pattern
	117. dstore_pattern_flag
	118. infil_pattern
	119. infil_pattern_flag
	120. hyperlinks
		 description
		 url
	121. hyperlinks_flag
	122. notes
	123. notes_flag
	124. user_number_1
	125. user_number_1_flag
	126. user_number_2
	127. user_number_2_flag
	128. user_number_3
	129. user_number_3_flag
	130. user_number_4
	131. user_number_4_flag
	132. user_number_5
	133. user_number_5_flag
	134. user_number_6
	135. user_number_6_flag
	136. user_number_7
	137. user_number_7_flag
	138. user_number_8
	139. user_number_8_flag
	140. user_number_9
	141. user_number_9_flag
	142. user_number_10
	143. user_number_10_flag
	144. user_text_1
	145. user_text_1_flag
	146. user_text_2
	147. user_text_2_flag
	148. user_text_3
	149. user_text_3_flag
	150. user_text_4
	151. user_text_4_flag
	152. user_text_5
	153. user_text_5_flag
	154. user_text_6
	155. user_text_6_flag
	156. user_text_7
	157. user_text_7_flag
	158. user_text_8
	159. user_text_8_flag
	160. user_text_9
	161. user_text_9_flag
	162. user_text_10
	163. user_text_10_flag
****sw_node
	1. node_id
	2. node_id_flag
	3. node_type
	4. node_type_flag
	5. x
	6. y
	7. route_subcatchment
	8. route_subcatchment_flag
	9. unit_hydrograph_id
	10. unit_hydrograph_id_flag
	11. unit_hydrograph_area
	12. unit_hydrograph_area_flag
	13. ground_level
	14. ground_level_flag
	15. invert_elevation
	16. invert_elevation_flag
	17. maximum_depth
	18. maximum_depth_flag
	19. surcharge_depth
	20. surcharge_depth_flag
	21. initial_depth
	22. initial_depth_flag
	23. ponded_area
	24. ponded_area_flag
	25. flood_type
	26. flood_type_flag
	27. flooding_discharge_coeff
	28. flooding_discharge_coeff_flag
	29. initial_moisture_deficit
	30. initial_moisture_deficit_flag
	31. suction_head
	32. suction_head_flag
	33. evaporation_factor
	34. evaporation_factor_flag
	35. treatment
		 pollutant
		 result
		 function
	36. treatment_flag
	37. outfall_type
	38. outfall_type_flag
	39. pollutant_inflows
		 pollutant
	40. pollutant_inflows_flag
	41. flap_gate
	42. flap_gate_flag
	43. tidal_curve_id
	44. tidal_curve_id_flag
	45. storage_type
	46. storage_type_flag
	47. storage_curve
	48. storage_curve_flag
	49. functional_coefficient
	50. functional_coefficient_flag
	51. functional_constant
	52. functional_constant_flag
	53. functional_exponent
	54. functional_exponent_flag
	55. fixed_stage
	56. fixed_stage_flag
	57. conductivity
	58. conductivity_flag
	59. inflow_baseline
	60. inflow_baseline_flag
	61. inflow_scaling
	62. inflow_scaling_flag
	63. inflow_pattern
	64. inflow_pattern_flag
	65. base_flow
	66. base_flow_flag
	67. bf_pattern_1
	68. bf_pattern_1_flag
	69. bf_pattern_2
	70. bf_pattern_2_flag
	71. bf_pattern_3
	72. bf_pattern_3_flag
	73. bf_pattern_4
	74. bf_pattern_4_flag
	75. additional_dwf
		 baseline
		 bf_pattern_1
		 bf_pattern_2
		 bf_pattern_3
		 bf_pattern_4
	76. additional_dwf_flag
	77. pollutant_dwf
		 pollutant
	78. pollutant_dwf_flag
	79. hyperlinks
		 description
		 url
	80. hyperlinks_flag
	81. notes
	82. notes_flag
	83. user_number_1
	84. user_number_1_flag
	85. user_number_2
	86. user_number_2_flag
	87. user_number_3
	88. user_number_3_flag
	89. user_number_4
	90. user_number_4_flag
	91. user_number_5
	92. user_number_5_flag
	93. user_number_6
	94. user_number_6_flag
	95. user_number_7
	96. user_number_7_flag
	97. user_number_8
	98. user_number_8_flag
	99. user_number_9
	100. user_number_9_flag
	101. user_number_10
	102. user_number_10_flag
	103. user_text_1
	104. user_text_1_flag
	105. user_text_2
	106. user_text_2_flag
	107. user_text_3
	108. user_text_3_flag
	109. user_text_4
	110. user_text_4_flag
	111. user_text_5
	112. user_text_5_flag
	113. user_text_6
	114. user_text_6_flag
	115. user_text_7
	116. user_text_7_flag
	117. user_text_8
	118. user_text_8_flag
	119. user_text_9
	120. user_text_9_flag
	121. user_text_10
	122. user_text_10_flag
****sw_tvd_connector
	1. id
	2. id_flag
	3. category_id
	4. category_id_flag
	5. boundary_array
	6. input_a_units
	7. input_a_units_flag
	8. input_a
	9. input_a_flag
	10. input_b_units
	11. input_b_units_flag
	12. input_b
	13. input_b_flag
	14. input_c_units
	15. input_c_units_flag
	16. input_c
	17. input_c_flag
	18. output_units
	19. output_units_flag
	20. expression_units
	21. expression_units_flag
	22. output_expression
	23. output_expression_flag
	24. resampling_buffer
	25. resampling_buffer_flag
	26. connected_object_type
	27. connected_object_type_flag
	28. connected_object_id
	29. connected_object_id_flag
	30. usage
	31. usage_flag
	32. input_attribute
	33. input_attribute_flag
	34. comparison_result
	35. comparison_result_flag
	36. hyperlinks
		 description
		 url
	37. hyperlinks_flag
	38. notes
	39. notes_flag
	40. area
	41. area_flag
	42. x
	43. x_flag
	44. y
	45. y_flag
	46. user_number_1
	47. user_number_1_flag
	48. user_number_2
	49. user_number_2_flag
	50. user_number_3
	51. user_number_3_flag
	52. user_number_4
	53. user_number_4_flag
	54. user_number_5
	55. user_number_5_flag
	56. user_number_6
	57. user_number_6_flag
	58. user_number_7
	59. user_number_7_flag
	60. user_number_8
	61. user_number_8_flag
	62. user_number_9
	63. user_number_9_flag
	64. user_number_10
	65. user_number_10_flag
	66. user_text_1
	67. user_text_1_flag
	68. user_text_2
	69. user_text_2_flag
	70. user_text_3
	71. user_text_3_flag
	72. user_text_4
	73. user_text_4_flag
	74. user_text_5
	75. user_text_5_flag
	76. user_text_6
	77. user_text_6_flag
	78. user_text_7
	79. user_text_7_flag
	80. user_text_8
	81. user_text_8_flag
	82. user_text_9
	83. user_text_9_flag
	84. user_text_10
	85. user_text_10_flag
****sw_polygon
	1. polygon_id
	2. polygon_id_flag
	3. category_id
	4. category_id_flag
	5. area
	6. area_flag
	7. boundary_array
	8. hyperlinks
		 description
		 url
	9. hyperlinks_flag
	10. notes
	11. notes_flag
	12. user_number_1
	13. user_number_1_flag
	14. user_number_2
	15. user_number_2_flag
	16. user_number_3
	17. user_number_3_flag
	18. user_number_4
	19. user_number_4_flag
	20. user_number_5
	21. user_number_5_flag
	22. user_number_6
	23. user_number_6_flag
	24. user_number_7
	25. user_number_7_flag
	26. user_number_8
	27. user_number_8_flag
	28. user_number_9
	29. user_number_9_flag
	30. user_number_10
	31. user_number_10_flag
	32. user_text_1
	33. user_text_1_flag
	34. user_text_2
	35. user_text_2_flag
	36. user_text_3
	37. user_text_3_flag
	38. user_text_4
	39. user_text_4_flag
	40. user_text_5
	41. user_text_5_flag
	42. user_text_6
	43. user_text_6_flag
	44. user_text_7
	45. user_text_7_flag
	46. user_text_8
	47. user_text_8_flag
	48. user_text_9
	49. user_text_9_flag
	50. user_text_10
	51. user_text_10_flag
****sw_raingage
	1. raingage_id
	2. raingage_id_flag
	3. x
	4. y
	5. scf
	6. scf_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****sw_controls
	1. controls_data
	2. controls_data_flag
	3. hyperlinks
		 description
		 url
	4. hyperlinks_flag
	5. notes
	6. notes_flag
	7. user_number_1
	8. user_number_1_flag
	9. user_number_2
	10. user_number_2_flag
	11. user_number_3
	12. user_number_3_flag
	13. user_number_4
	14. user_number_4_flag
	15. user_number_5
	16. user_number_5_flag
	17. user_number_6
	18. user_number_6_flag
	19. user_number_7
	20. user_number_7_flag
	21. user_number_8
	22. user_number_8_flag
	23. user_number_9
	24. user_number_9_flag
	25. user_number_10
	26. user_number_10_flag
	27. user_text_1
	28. user_text_1_flag
	29. user_text_2
	30. user_text_2_flag
	31. user_text_3
	32. user_text_3_flag
	33. user_text_4
	34. user_text_4_flag
	35. user_text_5
	36. user_text_5_flag
	37. user_text_6
	38. user_text_6_flag
	39. user_text_7
	40. user_text_7_flag
	41. user_text_8
	42. user_text_8_flag
	43. user_text_9
	44. user_text_9_flag
	45. user_text_10
	46. user_text_10_flag
****sw_transect
	1. id
	2. id_flag
	3. left_roughness
	4. left_roughness_flag
	5. right_roughness
	6. right_roughness_flag
	7. channel_roughness
	8. channel_roughness_flag
	9. left_offset
	10. left_offset_flag
	11. right_offset
	12. right_offset_flag
	13. width_factor
	14. width_factor_flag
	15. elevation_adjust
	16. elevation_adjust_flag
	17. meander_factor
	18. meander_factor_flag
	19. profile
		 x
		 z
	20. profile_flag
	21. hyperlinks
		 description
		 url
	22. hyperlinks_flag
	23. notes
	24. notes_flag
	25. user_number_1
	26. user_number_1_flag
	27. user_number_2
	28. user_number_2_flag
	29. user_number_3
	30. user_number_3_flag
	31. user_number_4
	32. user_number_4_flag
	33. user_number_5
	34. user_number_5_flag
	35. user_number_6
	36. user_number_6_flag
	37. user_number_7
	38. user_number_7_flag
	39. user_number_8
	40. user_number_8_flag
	41. user_number_9
	42. user_number_9_flag
	43. user_number_10
	44. user_number_10_flag
	45. user_text_1
	46. user_text_1_flag
	47. user_text_2
	48. user_text_2_flag
	49. user_text_3
	50. user_text_3_flag
	51. user_text_4
	52. user_text_4_flag
	53. user_text_5
	54. user_text_5_flag
	55. user_text_6
	56. user_text_6_flag
	57. user_text_7
	58. user_text_7_flag
	59. user_text_8
	60. user_text_8_flag
	61. user_text_9
	62. user_text_9_flag
	63. user_text_10
	64. user_text_10_flag
****sw_conduit
	1. id
	2. id_flag
	3. us_node_id
	4. us_node_id_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. length
	8. length_flag
	9. point_array
	10. shape
	11. shape_flag
	12. horiz_ellipse_size_code
	13. horiz_ellipse_size_code_flag
	14. vert_ellipse_size_code
	15. vert_ellipse_size_code_flag
	16. arch_material
	17. arch_material_flag
	18. arch_concrete_size_code
	19. arch_concrete_size_code_flag
	20. arch_plate_18_size_code
	21. arch_plate_18_size_code_flag
	22. arch_plate_31_size_code
	23. arch_plate_31_size_code_flag
	24. arch_steel_half_size_code
	25. arch_steel_half_size_code_flag
	26. arch_steel_inch_size_code
	27. arch_steel_inch_size_code_flag
	28. conduit_height
	29. conduit_height_flag
	30. conduit_width
	31. conduit_width_flag
	32. number_of_barrels
	33. number_of_barrels_flag
	34. roughness_DW
	35. roughness_DW_flag
	36. roughness_HW
	37. roughness_HW_flag
	38. top_radius
	39. top_radius_flag
	40. left_slope
	41. left_slope_flag
	42. right_slope
	43. right_slope_flag
	44. triangle_height
	45. triangle_height_flag
	46. bottom_radius
	47. bottom_radius_flag
	48. shape_curve
	49. shape_curve_flag
	50. shape_exponent
	51. shape_exponent_flag
	52. transect
	53. transect_flag
	54. us_invert
	55. us_invert_flag
	56. ds_invert
	57. ds_invert_flag
	58. us_headloss_coeff
	59. us_headloss_coeff_flag
	60. ds_headloss_coeff
	61. ds_headloss_coeff_flag
	62. Mannings_N
	63. Mannings_N_flag
	64. initial_flow
	65. initial_flow_flag
	66. max_flow
	67. max_flow_flag
	68. bottom_mannings_N
	69. bottom_mannings_N_flag
	70. roughness_depth_threshold
	71. roughness_depth_threshold_flag
	72. sediment_depth
	73. sediment_depth_flag
	74. av_headloss_coeff
	75. av_headloss_coeff_flag
	76. seepage_rate
	77. seepage_rate_flag
	78. culvert_code
	79. culvert_code_flag
	80. flap_gate
	81. flap_gate_flag
	82. branch_id
	83. branch_id_flag
	84. hyperlinks
		 description
		 url
	85. hyperlinks_flag
	86. notes
	87. notes_flag
	88. user_number_1
	89. user_number_1_flag
	90. user_number_2
	91. user_number_2_flag
	92. user_number_3
	93. user_number_3_flag
	94. user_number_4
	95. user_number_4_flag
	96. user_number_5
	97. user_number_5_flag
	98. user_number_6
	99. user_number_6_flag
	100. user_number_7
	101. user_number_7_flag
	102. user_number_8
	103. user_number_8_flag
	104. user_number_9
	105. user_number_9_flag
	106. user_number_10
	107. user_number_10_flag
	108. user_text_1
	109. user_text_1_flag
	110. user_text_2
	111. user_text_2_flag
	112. user_text_3
	113. user_text_3_flag
	114. user_text_4
	115. user_text_4_flag
	116. user_text_5
	117. user_text_5_flag
	118. user_text_6
	119. user_text_6_flag
	120. user_text_7
	121. user_text_7_flag
	122. user_text_8
	123. user_text_8_flag
	124. user_text_9
	125. user_text_9_flag
	126. user_text_10
	127. user_text_10_flag
****sw_weir
	1. id
	2. id_flag
	3. us_node_id
	4. us_node_id_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. crest
	10. crest_flag
	11. weir_height
	12. weir_height_flag
	13. weir_width
	14. weir_width_flag
	15. left_slope
	16. left_slope_flag
	17. right_slope
	18. right_slope_flag
	19. var_dis_coeff
	20. var_dis_coeff_flag
	21. discharge_coeff
	22. discharge_coeff_flag
	23. sideflow_discharge_coeff
	24. sideflow_discharge_coeff_flag
	25. weir_curve
	26. weir_curve_flag
	27. flap_gate
	28. flap_gate_flag
	29. end_contractions
	30. end_contractions_flag
	31. secondary_discharge_coeff
	32. secondary_discharge_coeff_flag
	33. allows_surcharge
	34. allows_surcharge_flag
	35. width
	36. width_flag
	37. surface
	38. surface_flag
	39. branch_id
	40. branch_id_flag
	41. point_array
	42. hyperlinks
		 description
		 url
	43. hyperlinks_flag
	44. notes
	45. notes_flag
	46. user_number_1
	47. user_number_1_flag
	48. user_number_2
	49. user_number_2_flag
	50. user_number_3
	51. user_number_3_flag
	52. user_number_4
	53. user_number_4_flag
	54. user_number_5
	55. user_number_5_flag
	56. user_number_6
	57. user_number_6_flag
	58. user_number_7
	59. user_number_7_flag
	60. user_number_8
	61. user_number_8_flag
	62. user_number_9
	63. user_number_9_flag
	64. user_number_10
	65. user_number_10_flag
	66. user_text_1
	67. user_text_1_flag
	68. user_text_2
	69. user_text_2_flag
	70. user_text_3
	71. user_text_3_flag
	72. user_text_4
	73. user_text_4_flag
	74. user_text_5
	75. user_text_5_flag
	76. user_text_6
	77. user_text_6_flag
	78. user_text_7
	79. user_text_7_flag
	80. user_text_8
	81. user_text_8_flag
	82. user_text_9
	83. user_text_9_flag
	84. user_text_10
	85. user_text_10_flag
****sw_orifice
	1. id
	2. id_flag
	3. us_node_id
	4. us_node_id_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. link_type
	8. link_type_flag
	9. shape
	10. shape_flag
	11. orifice_height
	12. orifice_height_flag
	13. orifice_width
	14. orifice_width_flag
	15. invert
	16. invert_flag
	17. point_array
	18. discharge_coeff
	19. discharge_coeff_flag
	20. flap_gate
	21. flap_gate_flag
	22. time_to_open
	23. time_to_open_flag
	24. branch_id
	25. branch_id_flag
	26. hyperlinks
		 description
		 url
	27. hyperlinks_flag
	28. notes
	29. notes_flag
	30. user_number_1
	31. user_number_1_flag
	32. user_number_2
	33. user_number_2_flag
	34. user_number_3
	35. user_number_3_flag
	36. user_number_4
	37. user_number_4_flag
	38. user_number_5
	39. user_number_5_flag
	40. user_number_6
	41. user_number_6_flag
	42. user_number_7
	43. user_number_7_flag
	44. user_number_8
	45. user_number_8_flag
	46. user_number_9
	47. user_number_9_flag
	48. user_number_10
	49. user_number_10_flag
	50. user_text_1
	51. user_text_1_flag
	52. user_text_2
	53. user_text_2_flag
	54. user_text_3
	55. user_text_3_flag
	56. user_text_4
	57. user_text_4_flag
	58. user_text_5
	59. user_text_5_flag
	60. user_text_6
	61. user_text_6_flag
	62. user_text_7
	63. user_text_7_flag
	64. user_text_8
	65. user_text_8_flag
	66. user_text_9
	67. user_text_9_flag
	68. user_text_10
	69. user_text_10_flag
****sw_pump
	1. id
	2. id_flag
	3. us_node_id
	4. us_node_id_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. ideal
	8. ideal_flag
	9. pump_curve
	10. pump_curve_flag
	11. initial_status
	12. initial_status_flag
	13. start_up_depth
	14. start_up_depth_flag
	15. shut_off_depth
	16. shut_off_depth_flag
	17. point_array
	18. branch_id
	19. branch_id_flag
	20. hyperlinks
		 description
		 url
	21. hyperlinks_flag
	22. notes
	23. notes_flag
	24. user_number_1
	25. user_number_1_flag
	26. user_number_2
	27. user_number_2_flag
	28. user_number_3
	29. user_number_3_flag
	30. user_number_4
	31. user_number_4_flag
	32. user_number_5
	33. user_number_5_flag
	34. user_number_6
	35. user_number_6_flag
	36. user_number_7
	37. user_number_7_flag
	38. user_number_8
	39. user_number_8_flag
	40. user_number_9
	41. user_number_9_flag
	42. user_number_10
	43. user_number_10_flag
	44. user_text_1
	45. user_text_1_flag
	46. user_text_2
	47. user_text_2_flag
	48. user_text_3
	49. user_text_3_flag
	50. user_text_4
	51. user_text_4_flag
	52. user_text_5
	53. user_text_5_flag
	54. user_text_6
	55. user_text_6_flag
	56. user_text_7
	57. user_text_7_flag
	58. user_text_8
	59. user_text_8_flag
	60. user_text_9
	61. user_text_9_flag
	62. user_text_10
	63. user_text_10_flag
****sw_outlet
	1. id
	2. id_flag
	3. us_node_id
	4. us_node_id_flag
	5. ds_node_id
	6. ds_node_id_flag
	7. start_level
	8. start_level_flag
	9. flap_gate
	10. flap_gate_flag
	11. rating_curve_type
	12. rating_curve_type_flag
	13. head_discharge_id
	14. head_discharge_id_flag
	15. discharge_coefficient
	16. discharge_coefficient_flag
	17. discharge_exponent
	18. discharge_exponent_flag
	19. point_array
	20. branch_id
	21. branch_id_flag
	22. hyperlinks
		 description
		 url
	23. hyperlinks_flag
	24. notes
	25. notes_flag
	26. user_number_1
	27. user_number_1_flag
	28. user_number_2
	29. user_number_2_flag
	30. user_number_3
	31. user_number_3_flag
	32. user_number_4
	33. user_number_4_flag
	34. user_number_5
	35. user_number_5_flag
	36. user_number_6
	37. user_number_6_flag
	38. user_number_7
	39. user_number_7_flag
	40. user_number_8
	41. user_number_8_flag
	42. user_number_9
	43. user_number_9_flag
	44. user_number_10
	45. user_number_10_flag
	46. user_text_1
	47. user_text_1_flag
	48. user_text_2
	49. user_text_2_flag
	50. user_text_3
	51. user_text_3_flag
	52. user_text_4
	53. user_text_4_flag
	54. user_text_5
	55. user_text_5_flag
	56. user_text_6
	57. user_text_6_flag
	58. user_text_7
	59. user_text_7_flag
	60. user_text_8
	61. user_text_8_flag
	62. user_text_9
	63. user_text_9_flag
	64. user_text_10
	65. user_text_10_flag
****sw_spatial_rain_zone
	1. id
	2. id_flag
	3. boundary_array
	4. area
	5. area_flag
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag
****sw_spatial_rain_source
	1. id
	2. id_flag
	3. source_type
	4. source_type_flag
	5. stream_or_category
	6. stream_or_category_flag
	7. priority
	8. priority_flag
	9. start_time
	10. start_time_flag
	11. end_time
	12. end_time_flag
	13. hyperlinks
		 description
		 url
	14. hyperlinks_flag
	15. notes
	16. notes_flag
	17. user_number_1
	18. user_number_1_flag
	19. user_number_2
	20. user_number_2_flag
	21. user_number_3
	22. user_number_3_flag
	23. user_number_4
	24. user_number_4_flag
	25. user_number_5
	26. user_number_5_flag
	27. user_number_6
	28. user_number_6_flag
	29. user_number_7
	30. user_number_7_flag
	31. user_number_8
	32. user_number_8_flag
	33. user_number_9
	34. user_number_9_flag
	35. user_number_10
	36. user_number_10_flag
	37. user_text_1
	38. user_text_1_flag
	39. user_text_2
	40. user_text_2_flag
	41. user_text_3
	42. user_text_3_flag
	43. user_text_4
	44. user_text_4_flag
	45. user_text_5
	46. user_text_5_flag
	47. user_text_6
	48. user_text_6_flag
	49. user_text_7
	50. user_text_7_flag
	51. user_text_8
	52. user_text_8_flag
	53. user_text_9
	54. user_text_9_flag
	55. user_text_10
	56. user_text_10_flag
****sw_pollutant
	1. id
	2. id_flag
	3. units
	4. units_flag
	5. rainfall_conc
	6. rainfall_conc_flag
	7. groundwater_conc
	8. groundwater_conc_flag
	9. rdii_conc
	10. rdii_conc_flag
	11. dwf_conc
	12. dwf_conc_flag
	13. init_conc
	14. init_conc_flag
	15. decay_coeff
	16. decay_coeff_flag
	17. snow_build_up
	18. snow_build_up_flag
	19. co-pollutant
	20. co-pollutant_flag
	21. co-fraction
	22. co-fraction_flag
	23. hyperlinks
		 description
		 url
	24. hyperlinks_flag
	25. notes
	26. notes_flag
	27. user_number_1
	28. user_number_1_flag
	29. user_number_2
	30. user_number_2_flag
	31. user_number_3
	32. user_number_3_flag
	33. user_number_4
	34. user_number_4_flag
	35. user_number_5
	36. user_number_5_flag
	37. user_number_6
	38. user_number_6_flag
	39. user_number_7
	40. user_number_7_flag
	41. user_number_8
	42. user_number_8_flag
	43. user_number_9
	44. user_number_9_flag
	45. user_number_10
	46. user_number_10_flag
	47. user_text_1
	48. user_text_1_flag
	49. user_text_2
	50. user_text_2_flag
	51. user_text_3
	52. user_text_3_flag
	53. user_text_4
	54. user_text_4_flag
	55. user_text_5
	56. user_text_5_flag
	57. user_text_6
	58. user_text_6_flag
	59. user_text_7
	60. user_text_7_flag
	61. user_text_8
	62. user_text_8_flag
	63. user_text_9
	64. user_text_9_flag
	65. user_text_10
	66. user_text_10_flag
****sw_land_use
	1. id
	2. id_flag
	3. build_up
		 pollutant
		 build_up_type
		 max_build_up
		 power_rate_constant
		 power_time_exponent
		 exp_rate_constant
		 saturation_constant
		 unit
	4. build_up_flag
	5. washoff
		***badger***
	6. washoff_flag
	7. sweep_interval
	8. sweep_interval_flag
	9. sweep_removal
	10. sweep_removal_flag
	11. last_sweep
	12. last_sweep_flag
	13. hyperlinks
		 description
		 url
	14. hyperlinks_flag
	15. notes
	16. notes_flag
	17. user_number_1
	18. user_number_1_flag
	19. user_number_2
	20. user_number_2_flag
	21. user_number_3
	22. user_number_3_flag
	23. user_number_4
	24. user_number_4_flag
	25. user_number_5
	26. user_number_5_flag
	27. user_number_6
	28. user_number_6_flag
	29. user_number_7
	30. user_number_7_flag
	31. user_number_8
	32. user_number_8_flag
	33. user_number_9
	34. user_number_9_flag
	35. user_number_10
	36. user_number_10_flag
	37. user_text_1
	38. user_text_1_flag
	39. user_text_2
	40. user_text_2_flag
	41. user_text_3
	42. user_text_3_flag
	43. user_text_4
	44. user_text_4_flag
	45. user_text_5
	46. user_text_5_flag
	47. user_text_6
	48. user_text_6_flag
	49. user_text_7
	50. user_text_7_flag
	51. user_text_8
	52. user_text_8_flag
	53. user_text_9
	54. user_text_9_flag
	55. user_text_10
	56. user_text_10_flag
****sw_uh_group
	1. id
	2. id_flag
	3. raingage_id
	4. raingage_id_flag
	5. uh_all
	6. uh_all_flag
	7. uh_jan
	8. uh_jan_flag
	9. uh_feb
	10. uh_feb_flag
	11. uh_mar
	12. uh_mar_flag
	13. uh_apr
	14. uh_apr_flag
	15. uh_may
	16. uh_may_flag
	17. uh_jun
	18. uh_jun_flag
	19. uh_jul
	20. uh_jul_flag
	21. uh_aug
	22. uh_aug_flag
	23. uh_sep
	24. uh_sep_flag
	25. uh_oct
	26. uh_oct_flag
	27. uh_nov
	28. uh_nov_flag
	29. uh_dec
	30. uh_dec_flag
	31. hyperlinks
		 description
		 url
	32. hyperlinks_flag
	33. notes
	34. notes_flag
	35. user_number_1
	36. user_number_1_flag
	37. user_number_2
	38. user_number_2_flag
	39. user_number_3
	40. user_number_3_flag
	41. user_number_4
	42. user_number_4_flag
	43. user_number_5
	44. user_number_5_flag
	45. user_number_6
	46. user_number_6_flag
	47. user_number_7
	48. user_number_7_flag
	49. user_number_8
	50. user_number_8_flag
	51. user_number_9
	52. user_number_9_flag
	53. user_number_10
	54. user_number_10_flag
	55. user_text_1
	56. user_text_1_flag
	57. user_text_2
	58. user_text_2_flag
	59. user_text_3
	60. user_text_3_flag
	61. user_text_4
	62. user_text_4_flag
	63. user_text_5
	64. user_text_5_flag
	65. user_text_6
	66. user_text_6_flag
	67. user_text_7
	68. user_text_7_flag
	69. user_text_8
	70. user_text_8_flag
	71. user_text_9
	72. user_text_9_flag
	73. user_text_10
	74. user_text_10_flag
****sw_uh
	1. group_id
	2. group_id_flag
	3. month
	4. month_flag
	5. R1
	6. R1_flag
	7. T1
	8. T1_flag
	9. K1
	10. K1_flag
	11. R2
	12. R2_flag
	13. T2
	14. T2_flag
	15. K2
	16. K2_flag
	17. R3
	18. R3_flag
	19. T3
	20. T3_flag
	21. K3
	22. K3_flag
	23. Dmax1
	24. Dmax1_flag
	25. Drec1
	26. Drec1_flag
	27. D01
	28. D01_flag
	29. Dmax2
	30. Dmax2_flag
	31. Drec2
	32. Drec2_flag
	33. D02
	34. D02_flag
	35. Dmax3
	36. Dmax3_flag
	37. Drec3
	38. Drec3_flag
	39. D03
	40. D03_flag
	41. hyperlinks
		 description
		 url
	42. hyperlinks_flag
	43. notes
	44. notes_flag
	45. user_number_1
	46. user_number_1_flag
	47. user_number_2
	48. user_number_2_flag
	49. user_number_3
	50. user_number_3_flag
	51. user_number_4
	52. user_number_4_flag
	53. user_number_5
	54. user_number_5_flag
	55. user_number_6
	56. user_number_6_flag
	57. user_number_7
	58. user_number_7_flag
	59. user_number_8
	60. user_number_8_flag
	61. user_number_9
	62. user_number_9_flag
	63. user_number_10
	64. user_number_10_flag
	65. user_text_1
	66. user_text_1_flag
	67. user_text_2
	68. user_text_2_flag
	69. user_text_3
	70. user_text_3_flag
	71. user_text_4
	72. user_text_4_flag
	73. user_text_5
	74. user_text_5_flag
	75. user_text_6
	76. user_text_6_flag
	77. user_text_7
	78. user_text_7_flag
	79. user_text_8
	80. user_text_8_flag
	81. user_text_9
	82. user_text_9_flag
	83. user_text_10
	84. user_text_10_flag
****sw_curve_control
	1. id
	2. id_flag
	3. data
		 variable
		 setting
	4. data_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. notes
	8. notes_flag
	9. user_number_1
	10. user_number_1_flag
	11. user_number_2
	12. user_number_2_flag
	13. user_number_3
	14. user_number_3_flag
	15. user_number_4
	16. user_number_4_flag
	17. user_number_5
	18. user_number_5_flag
	19. user_number_6
	20. user_number_6_flag
	21. user_number_7
	22. user_number_7_flag
	23. user_number_8
	24. user_number_8_flag
	25. user_number_9
	26. user_number_9_flag
	27. user_number_10
	28. user_number_10_flag
	29. user_text_1
	30. user_text_1_flag
	31. user_text_2
	32. user_text_2_flag
	33. user_text_3
	34. user_text_3_flag
	35. user_text_4
	36. user_text_4_flag
	37. user_text_5
	38. user_text_5_flag
	39. user_text_6
	40. user_text_6_flag
	41. user_text_7
	42. user_text_7_flag
	43. user_text_8
	44. user_text_8_flag
	45. user_text_9
	46. user_text_9_flag
	47. user_text_10
	48. user_text_10_flag
****sw_curve_pump
	1. id
	2. id_flag
	3. pump1_data
		 volume_increment
		 outflow
	4. pump1_data_flag
	5. pump2_data
		 depth_increment
		 outflow
	6. pump2_data_flag
	7. pump3_data
		 head_difference
		 outflow
	8. pump3_data_flag
	9. pump4_data
		 continuous_depth
		 outflow
	10. pump4_data_flag
	11. type
	12. type_flag
	13. hyperlinks
		 description
		 url
	14. hyperlinks_flag
	15. notes
	16. notes_flag
	17. user_number_1
	18. user_number_1_flag
	19. user_number_2
	20. user_number_2_flag
	21. user_number_3
	22. user_number_3_flag
	23. user_number_4
	24. user_number_4_flag
	25. user_number_5
	26. user_number_5_flag
	27. user_number_6
	28. user_number_6_flag
	29. user_number_7
	30. user_number_7_flag
	31. user_number_8
	32. user_number_8_flag
	33. user_number_9
	34. user_number_9_flag
	35. user_number_10
	36. user_number_10_flag
	37. user_text_1
	38. user_text_1_flag
	39. user_text_2
	40. user_text_2_flag
	41. user_text_3
	42. user_text_3_flag
	43. user_text_4
	44. user_text_4_flag
	45. user_text_5
	46. user_text_5_flag
	47. user_text_6
	48. user_text_6_flag
	49. user_text_7
	50. user_text_7_flag
	51. user_text_8
	52. user_text_8_flag
	53. user_text_9
	54. user_text_9_flag
	55. user_text_10
	56. user_text_10_flag
****sw_curve_rating
	1. id
	2. id_flag
	3. data
		 head
		 outflow
	4. data_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. notes
	8. notes_flag
	9. user_number_1
	10. user_number_1_flag
	11. user_number_2
	12. user_number_2_flag
	13. user_number_3
	14. user_number_3_flag
	15. user_number_4
	16. user_number_4_flag
	17. user_number_5
	18. user_number_5_flag
	19. user_number_6
	20. user_number_6_flag
	21. user_number_7
	22. user_number_7_flag
	23. user_number_8
	24. user_number_8_flag
	25. user_number_9
	26. user_number_9_flag
	27. user_number_10
	28. user_number_10_flag
	29. user_text_1
	30. user_text_1_flag
	31. user_text_2
	32. user_text_2_flag
	33. user_text_3
	34. user_text_3_flag
	35. user_text_4
	36. user_text_4_flag
	37. user_text_5
	38. user_text_5_flag
	39. user_text_6
	40. user_text_6_flag
	41. user_text_7
	42. user_text_7_flag
	43. user_text_8
	44. user_text_8_flag
	45. user_text_9
	46. user_text_9_flag
	47. user_text_10
	48. user_text_10_flag
****sw_curve_shape
	1. id
	2. id_flag
	3. data
		 normalized_depth
		 normalized_width
	4. data_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. notes
	8. notes_flag
	9. user_number_1
	10. user_number_1_flag
	11. user_number_2
	12. user_number_2_flag
	13. user_number_3
	14. user_number_3_flag
	15. user_number_4
	16. user_number_4_flag
	17. user_number_5
	18. user_number_5_flag
	19. user_number_6
	20. user_number_6_flag
	21. user_number_7
	22. user_number_7_flag
	23. user_number_8
	24. user_number_8_flag
	25. user_number_9
	26. user_number_9_flag
	27. user_number_10
	28. user_number_10_flag
	29. user_text_1
	30. user_text_1_flag
	31. user_text_2
	32. user_text_2_flag
	33. user_text_3
	34. user_text_3_flag
	35. user_text_4
	36. user_text_4_flag
	37. user_text_5
	38. user_text_5_flag
	39. user_text_6
	40. user_text_6_flag
	41. user_text_7
	42. user_text_7_flag
	43. user_text_8
	44. user_text_8_flag
	45. user_text_9
	46. user_text_9_flag
	47. user_text_10
	48. user_text_10_flag
****sw_curve_tidal
	1. id
	2. id_flag
	3. data
		 hour
		 elevation
	4. data_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. notes
	8. notes_flag
	9. user_number_1
	10. user_number_1_flag
	11. user_number_2
	12. user_number_2_flag
	13. user_number_3
	14. user_number_3_flag
	15. user_number_4
	16. user_number_4_flag
	17. user_number_5
	18. user_number_5_flag
	19. user_number_6
	20. user_number_6_flag
	21. user_number_7
	22. user_number_7_flag
	23. user_number_8
	24. user_number_8_flag
	25. user_number_9
	26. user_number_9_flag
	27. user_number_10
	28. user_number_10_flag
	29. user_text_1
	30. user_text_1_flag
	31. user_text_2
	32. user_text_2_flag
	33. user_text_3
	34. user_text_3_flag
	35. user_text_4
	36. user_text_4_flag
	37. user_text_5
	38. user_text_5_flag
	39. user_text_6
	40. user_text_6_flag
	41. user_text_7
	42. user_text_7_flag
	43. user_text_8
	44. user_text_8_flag
	45. user_text_9
	46. user_text_9_flag
	47. user_text_10
	48. user_text_10_flag
****sw_curve_storage
	1. id
	2. id_flag
	3. data
		 depth
		 surface_area
	4. data_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. notes
	8. notes_flag
	9. user_number_1
	10. user_number_1_flag
	11. user_number_2
	12. user_number_2_flag
	13. user_number_3
	14. user_number_3_flag
	15. user_number_4
	16. user_number_4_flag
	17. user_number_5
	18. user_number_5_flag
	19. user_number_6
	20. user_number_6_flag
	21. user_number_7
	22. user_number_7_flag
	23. user_number_8
	24. user_number_8_flag
	25. user_number_9
	26. user_number_9_flag
	27. user_number_10
	28. user_number_10_flag
	29. user_text_1
	30. user_text_1_flag
	31. user_text_2
	32. user_text_2_flag
	33. user_text_3
	34. user_text_3_flag
	35. user_text_4
	36. user_text_4_flag
	37. user_text_5
	38. user_text_5_flag
	39. user_text_6
	40. user_text_6_flag
	41. user_text_7
	42. user_text_7_flag
	43. user_text_8
	44. user_text_8_flag
	45. user_text_9
	46. user_text_9_flag
	47. user_text_10
	48. user_text_10_flag
****sw_aquifer
	1. id
	2. id_flag
	3. soil_porosity
	4. soil_porosity_flag
	5. soil_wilting_point
	6. soil_wilting_point_flag
	7. soil_field_capacity
	8. soil_field_capacity_flag
	9. conductivity
	10. conductivity_flag
	11. conductivity_slope
	12. conductivity_slope_flag
	13. tension_slope
	14. tension_slope_flag
	15. evapotranspiration_fraction
	16. evapotranspiration_fraction_flag
	17. evapotranspiration_depth
	18. evapotranspiration_depth_flag
	19. seepage_rate
	20. seepage_rate_flag
	21. elevation
	22. elevation_flag
	23. initial_groundwater
	24. initial_groundwater_flag
	25. initial_moisture_content
	26. initial_moisture_content_flag
	27. time_pattern_id
	28. time_pattern_id_flag
	29. hyperlinks
		 description
		 url
	30. hyperlinks_flag
	31. notes
	32. notes_flag
	33. user_number_1
	34. user_number_1_flag
	35. user_number_2
	36. user_number_2_flag
	37. user_number_3
	38. user_number_3_flag
	39. user_number_4
	40. user_number_4_flag
	41. user_number_5
	42. user_number_5_flag
	43. user_number_6
	44. user_number_6_flag
	45. user_number_7
	46. user_number_7_flag
	47. user_number_8
	48. user_number_8_flag
	49. user_number_9
	50. user_number_9_flag
	51. user_number_10
	52. user_number_10_flag
	53. user_text_1
	54. user_text_1_flag
	55. user_text_2
	56. user_text_2_flag
	57. user_text_3
	58. user_text_3_flag
	59. user_text_4
	60. user_text_4_flag
	61. user_text_5
	62. user_text_5_flag
	63. user_text_6
	64. user_text_6_flag
	65. user_text_7
	66. user_text_7_flag
	67. user_text_8
	68. user_text_8_flag
	69. user_text_9
	70. user_text_9_flag
	71. user_text_10
	72. user_text_10_flag
****sw_suds_control
	1. control_id
	2. control_id_flag
	3. control_type
	4. control_type_flag
	5. surf_berm_height
	6. surf_berm_height_flag
	7. surf_storage_depth
	8. surf_storage_depth_flag
	9. surf_veg_vol_fraction
	10. surf_veg_vol_fraction_flag
	11. surf_roughness_n
	12. surf_roughness_n_flag
	13. surf_slope
	14. surf_slope_flag
	15. surf_xslope
	16. surf_xslope_flag
	17. pave_thickness
	18. pave_thickness_flag
	19. pave_void_ratio
	20. pave_void_ratio_flag
	21. pave_impervious_surf_fraction
	22. pave_impervious_surf_fraction_flag
	23. pave_permeability
	24. pave_permeability_flag
	25. pave_clogging_factor
	26. pave_clogging_factor_flag
	27. pave_regen_interval
	28. pave_regen_interval_flag
	29. pave_regen_fraction
	30. pave_regen_fraction_flag
	31. soil_class
	32. soil_class_flag
	33. soil_thickness
	34. soil_thickness_flag
	35. soil_porosity
	36. soil_porosity_flag
	37. soil_field_capacity
	38. soil_field_capacity_flag
	39. soil_wilting_point
	40. soil_wilting_point_flag
	41. soil_conductivity
	42. soil_conductivity_flag
	43. soil_conductivity_slope
	44. soil_conductivity_slope_flag
	45. soil_suction_head
	46. soil_suction_head_flag
	47. storage_barrel_height
	48. storage_barrel_height_flag
	49. storage_thickness
	50. storage_thickness_flag
	51. storage_void_ratio
	52. storage_void_ratio_flag
	53. storage_seepage_rate
	54. storage_seepage_rate_flag
	55. storage_clogging_factor
	56. storage_clogging_factor_flag
	57. underdrain_flow_coefficient
	58. underdrain_flow_coefficient_flag
	59. underdrain_flow_exponent
	60. underdrain_flow_exponent_flag
	61. underdrain_offset_height
	62. underdrain_offset_height_flag
	63. underdrain_delay
	64. underdrain_delay_flag
	65. underdrain_flow_capacity
	66. underdrain_flow_capacity_flag
	67. underdrain_close_depth
	68. underdrain_open_depth
	69. underdrain_control_curve
	70. underdrain_poll_removal
		 pollutant
		 removal_percent
	71. underdrain_poll_removal_flag
	72. drainagemat_thickness
	73. drainagemat_thickness_flag
	74. drainagemat_void_fraction
	75. drainagemat_void_fraction_flag
	76. drainagemat_roughness
	77. drainagemat_roughness_flag
	78. hyperlinks
		 description
		 url
	79. hyperlinks_flag
	80. notes
	81. notes_flag
	82. user_number_1
	83. user_number_1_flag
	84. user_number_2
	85. user_number_2_flag
	86. user_number_3
	87. user_number_3_flag
	88. user_number_4
	89. user_number_4_flag
	90. user_number_5
	91. user_number_5_flag
	92. user_number_6
	93. user_number_6_flag
	94. user_number_7
	95. user_number_7_flag
	96. user_number_8
	97. user_number_8_flag
	98. user_number_9
	99. user_number_9_flag
	100. user_number_10
	101. user_number_10_flag
	102. user_text_1
	103. user_text_1_flag
	104. user_text_2
	105. user_text_2_flag
	106. user_text_3
	107. user_text_3_flag
	108. user_text_4
	109. user_text_4_flag
	110. user_text_5
	111. user_text_5_flag
	112. user_text_6
	113. user_text_6_flag
	114. user_text_7
	115. user_text_7_flag
	116. user_text_8
	117. user_text_8_flag
	118. user_text_9
	119. user_text_9_flag
	120. user_text_10
	121. user_text_10_flag
****sw_snow_pack
	1. id
	2. id_flag
	3. plow_min_melt
	4. plow_min_melt_flag
	5. imp_min_melt
	6. imp_min_melt_flag
	7. perv_min_melt
	8. perv_min_melt_flag
	9. plow_max_melt
	10. plow_max_melt_flag
	11. imp_max_melt
	12. imp_max_melt_flag
	13. perv_max_melt
	14. perv_max_melt_flag
	15. plow_base_temp
	16. plow_base_temp_flag
	17. imp_base_temp
	18. imp_base_temp_flag
	19. perv_base_temp
	20. perv_base_temp_flag
	21. plow_free_water
	22. plow_free_water_flag
	23. imp_free_water
	24. imp_free_water_flag
	25. perv_free_water
	26. perv_free_water_flag
	27. plow_snow_depth
	28. plow_snow_depth_flag
	29. imp_snow_depth
	30. imp_snow_depth_flag
	31. perv_snow_depth
	32. perv_snow_depth_flag
	33. plow_initial_free_water
	34. plow_initial_free_water_flag
	35. imp_initial_free_water
	36. imp_initial_free_water_flag
	37. perv_initial_free_water
	38. perv_initial_free_water_flag
	39. imp_100_cover
	40. imp_100_cover_flag
	41. perv_100_cover
	42. perv_100_cover_flag
	43. fraction_plowable
	44. fraction_plowable_flag
	45. plow_depth
	46. plow_depth_flag
	47. out_of_watershed
	48. out_of_watershed_flag
	49. hyperlinks
		 description
		 url
	50. hyperlinks_flag
	51. to_impervious
	52. to_impervious_flag
	53. to_pervious
	54. to_pervious_flag
	55. to_immediate_melt
	56. to_immediate_melt_flag
	57. to_subcatchment
	58. to_subcatchment_flag
	59. subcatchment_id
	60. subcatchment_id_flag
	61. notes
	62. notes_flag
	63. user_number_1
	64. user_number_1_flag
	65. user_number_2
	66. user_number_2_flag
	67. user_number_3
	68. user_number_3_flag
	69. user_number_4
	70. user_number_4_flag
	71. user_number_5
	72. user_number_5_flag
	73. user_number_6
	74. user_number_6_flag
	75. user_number_7
	76. user_number_7_flag
	77. user_number_8
	78. user_number_8_flag
	79. user_number_9
	80. user_number_9_flag
	81. user_number_10
	82. user_number_10_flag
	83. user_text_1
	84. user_text_1_flag
	85. user_text_2
	86. user_text_2_flag
	87. user_text_3
	88. user_text_3_flag
	89. user_text_4
	90. user_text_4_flag
	91. user_text_5
	92. user_text_5_flag
	93. user_text_6
	94. user_text_6_flag
	95. user_text_7
	96. user_text_7_flag
	97. user_text_8
	98. user_text_8_flag
	99. user_text_9
	100. user_text_9_flag
	101. user_text_10
	102. user_text_10_flag
****sw_title
	1. controls_data
	2. controls_data_flag
	3. name
	4. name_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. memo
	8. memo_flag
	9. user_number_1
	10. user_number_1_flag
	11. user_number_2
	12. user_number_2_flag
	13. user_number_3
	14. user_number_3_flag
	15. user_number_4
	16. user_number_4_flag
	17. user_number_5
	18. user_number_5_flag
	19. user_number_6
	20. user_number_6_flag
	21. user_number_7
	22. user_number_7_flag
	23. user_number_8
	24. user_number_8_flag
	25. user_number_9
	26. user_number_9_flag
	27. user_number_10
	28. user_number_10_flag
	29. user_text_1
	30. user_text_1_flag
	31. user_text_2
	32. user_text_2_flag
	33. user_text_3
	34. user_text_3_flag
	35. user_text_4
	36. user_text_4_flag
	37. user_text_5
	38. user_text_5_flag
	39. user_text_6
	40. user_text_6_flag
	41. user_text_7
	42. user_text_7_flag
	43. user_text_8
	44. user_text_8_flag
	45. user_text_9
	46. user_text_9_flag
	47. user_text_10
	48. user_text_10_flag
****sw_snow_parameters
	1. adc
	2. antecedent_temp_idx
	3. elevation
	4. latitude
	5. longitude_correction
	6. negative_melt_ratio
	7. snow_temperature
****sw_curve_weir
	1. id
	2. id_flag
	3. data
		 head
		 coefficient
	4. data_flag
	5. sideflow_data
		 head
		 coefficient
	6. sideflow_data_flag
	7. type
	8. type_flag
	9. hyperlinks
		 description
		 url
	10. hyperlinks_flag
	11. notes
	12. notes_flag
	13. user_number_1
	14. user_number_1_flag
	15. user_number_2
	16. user_number_2_flag
	17. user_number_3
	18. user_number_3_flag
	19. user_number_4
	20. user_number_4_flag
	21. user_number_5
	22. user_number_5_flag
	23. user_number_6
	24. user_number_6_flag
	25. user_number_7
	26. user_number_7_flag
	27. user_number_8
	28. user_number_8_flag
	29. user_number_9
	30. user_number_9_flag
	31. user_number_10
	32. user_number_10_flag
	33. user_text_1
	34. user_text_1_flag
	35. user_text_2
	36. user_text_2_flag
	37. user_text_3
	38. user_text_3_flag
	39. user_text_4
	40. user_text_4_flag
	41. user_text_5
	42. user_text_5_flag
	43. user_text_6
	44. user_text_6_flag
	45. user_text_7
	46. user_text_7_flag
	47. user_text_8
	48. user_text_8_flag
	49. user_text_9
	50. user_text_9_flag
	51. user_text_10
	52. user_text_10_flag
****sw_curve_underdrain
	1. id
	2. id_flag
	3. data
		 depth
		 factor
	4. data_flag
	5. hyperlinks
		 description
		 url
	6. hyperlinks_flag
	7. notes
	8. notes_flag
	9. user_number_1
	10. user_number_1_flag
	11. user_number_2
	12. user_number_2_flag
	13. user_number_3
	14. user_number_3_flag
	15. user_number_4
	16. user_number_4_flag
	17. user_number_5
	18. user_number_5_flag
	19. user_number_6
	20. user_number_6_flag
	21. user_number_7
	22. user_number_7_flag
	23. user_number_8
	24. user_number_8_flag
	25. user_number_9
	26. user_number_9_flag
	27. user_number_10
	28. user_number_10_flag
	29. user_text_1
	30. user_text_1_flag
	31. user_text_2
	32. user_text_2_flag
	33. user_text_3
	34. user_text_3_flag
	35. user_text_4
	36. user_text_4_flag
	37. user_text_5
	38. user_text_5_flag
	39. user_text_6
	40. user_text_6_flag
	41. user_text_7
	42. user_text_7_flag
	43. user_text_8
	44. user_text_8_flag
	45. user_text_9
	46. user_text_9_flag
	47. user_text_10
	48. user_text_10_flag
****sw_soil
	1. id
	2. id_flag
	3. initial_infiltration
	4. initial_infiltration_flag
	5. limiting_infiltration
	6. limiting_infiltration_flag
	7. decay_factor
	8. decay_factor_flag
	9. drying_time
	10. drying_time_flag
	11. max_infiltration_volume
	12. max_infiltration_volume_flag
	13. initial_moisture_deficit
	14. initial_moisture_deficit_flag
	15. curve_number
	16. curve_number_flag
	17. average_capillary_suction
	18. average_capillary_suction_flag
	19. saturated_hydraulic_conductivity
	20. saturated_hydraulic_conductivity_flag
	21. hyperlinks
		 description
		 url
	22. hyperlinks_flag
	23. notes
	24. notes_flag
	25. user_number_1
	26. user_number_1_flag
	27. user_number_2
	28. user_number_2_flag
	29. user_number_3
	30. user_number_3_flag
	31. user_number_4
	32. user_number_4_flag
	33. user_number_5
	34. user_number_5_flag
	35. user_number_6
	36. user_number_6_flag
	37. user_number_7
	38. user_number_7_flag
	39. user_number_8
	40. user_number_8_flag
	41. user_number_9
	42. user_number_9_flag
	43. user_number_10
	44. user_number_10_flag
	45. user_text_1
	46. user_text_1_flag
	47. user_text_2
	48. user_text_2_flag
	49. user_text_3
	50. user_text_3_flag
	51. user_text_4
	52. user_text_4_flag
	53. user_text_5
	54. user_text_5_flag
	55. user_text_6
	56. user_text_6_flag
	57. user_text_7
	58. user_text_7_flag
	59. user_text_8
	60. user_text_8_flag
	61. user_text_9
	62. user_text_9_flag
	63. user_text_10
	64. user_text_10_flag
****sw_2d_zone
	1. zone_id
	2. zone_id_flag
	3. boundary_type
	4. boundary_type_flag
	5. area
	6. area_flag
	7. max_triangle_area
	8. max_triangle_area_flag
	9. min_mesh_element_area
	10. min_mesh_element_area_flag
	11. max_height_variation
	12. max_height_variation_flag
	13. mesh_generation
	14. mesh_generation_flag
	15. terrain_sensitive_mesh
	16. terrain_sensitive_mesh_flag
	17. boundary_array
	18. minimum_angle
	19. minimum_angle_flag
	20. roughness
	21. roughness_flag
	22. roughness_definition_id
	23. roughness_definition_id_flag
	24. apply_rainfall_directly
	25. apply_rainfall_directly_flag
	26. apply_rainfall_subcatch
	27. apply_rainfall_subcatch_flag
	28. rainfall_profile
	29. rainfall_profile_flag
	30. rainfall_percentage
	31. rainfall_percentage_flag
	32. mesh_summary
	33. mesh_summary_flag
	34. hyperlinks
		 description
		 url
	35. hyperlinks_flag
	36. notes
	37. notes_flag
	38. user_number_1
	39. user_number_1_flag
	40. user_number_2
	41. user_number_2_flag
	42. user_number_3
	43. user_number_3_flag
	44. user_number_4
	45. user_number_4_flag
	46. user_number_5
	47. user_number_5_flag
	48. user_number_6
	49. user_number_6_flag
	50. user_number_7
	51. user_number_7_flag
	52. user_number_8
	53. user_number_8_flag
	54. user_number_9
	55. user_number_9_flag
	56. user_number_10
	57. user_number_10_flag
	58. user_text_1
	59. user_text_1_flag
	60. user_text_2
	61. user_text_2_flag
	62. user_text_3
	63. user_text_3_flag
	64. user_text_4
	65. user_text_4_flag
	66. user_text_5
	67. user_text_5_flag
	68. user_text_6
	69. user_text_6_flag
	70. user_text_7
	71. user_text_7_flag
	72. user_text_8
	73. user_text_8_flag
	74. user_text_9
	75. user_text_9_flag
	76. user_text_10
	77. user_text_10_flag
****sw_general_line
	1. line_id
	2. line_id_flag
	3. asset_id
	4. asset_id_flag
	5. general_line_xy
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. category
	9. category_flag
	10. length
	11. length_flag
	12. notes
	13. notes_flag
	14. user_number_1
	15. user_number_1_flag
	16. user_number_2
	17. user_number_2_flag
	18. user_number_3
	19. user_number_3_flag
	20. user_number_4
	21. user_number_4_flag
	22. user_number_5
	23. user_number_5_flag
	24. user_number_6
	25. user_number_6_flag
	26. user_number_7
	27. user_number_7_flag
	28. user_number_8
	29. user_number_8_flag
	30. user_number_9
	31. user_number_9_flag
	32. user_number_10
	33. user_number_10_flag
	34. user_text_1
	35. user_text_1_flag
	36. user_text_2
	37. user_text_2_flag
	38. user_text_3
	39. user_text_3_flag
	40. user_text_4
	41. user_text_4_flag
	42. user_text_5
	43. user_text_5_flag
	44. user_text_6
	45. user_text_6_flag
	46. user_text_7
	47. user_text_7_flag
	48. user_text_8
	49. user_text_8_flag
	50. user_text_9
	51. user_text_9_flag
	52. user_text_10
	53. user_text_10_flag
****sw_mesh_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. max_triangle_area
	6. max_triangle_area_flag
	7. apply_min_elt_size
	8. apply_min_elt_size_flag
	9. min_mesh_element_area
	10. min_mesh_element_area_flag
	11. boundary_array
	12. hyperlinks
		 description
		 url
	13. hyperlinks_flag
	14. notes
	15. notes_flag
	16. user_number_1
	17. user_number_1_flag
	18. user_number_2
	19. user_number_2_flag
	20. user_number_3
	21. user_number_3_flag
	22. user_number_4
	23. user_number_4_flag
	24. user_number_5
	25. user_number_5_flag
	26. user_number_6
	27. user_number_6_flag
	28. user_number_7
	29. user_number_7_flag
	30. user_number_8
	31. user_number_8_flag
	32. user_number_9
	33. user_number_9_flag
	34. user_number_10
	35. user_number_10_flag
	36. user_text_1
	37. user_text_1_flag
	38. user_text_2
	39. user_text_2_flag
	40. user_text_3
	41. user_text_3_flag
	42. user_text_4
	43. user_text_4_flag
	44. user_text_5
	45. user_text_5_flag
	46. user_text_6
	47. user_text_6_flag
	48. user_text_7
	49. user_text_7_flag
	50. user_text_8
	51. user_text_8_flag
	52. user_text_9
	53. user_text_9_flag
	54. user_text_10
	55. user_text_10_flag
****sw_porous_polygon
	1. polygon_id
	2. polygon_id_flag
	3. asset_id
	4. asset_id_flag
	5. porosity
	6. porosity_flag
	7. boundary_array
	8. crest_level
	9. crest_level_flag
	10. height
	11. height_flag
	12. level
	13. level_flag
	14. remove_wall
	15. remove_wall_flag
	16. wall_removal_trigger
	17. wall_removal_trigger_flag
	18. use_diff_across_wall
	19. use_diff_across_wall_flag
	20. depth_threshold
	21. depth_threshold_flag
	22. elevation_threshold
	23. elevation_threshold_flag
	24. velocity_threshold
	25. velocity_threshold_flag
	26. unit_flow_threshold
	27. unit_flow_threshold_flag
	28. total_head_threshold
	29. total_head_threshold_flag
	30. force_threshold
	31. force_threshold_flag
	32. hydro_press_coeff
	33. hydro_press_coeff_flag
	34. hyperlinks
		 description
		 url
	35. hyperlinks_flag
	36. no_rainfall
	37. no_rainfall_flag
	38. area
	39. area_flag
	40. notes
	41. notes_flag
	42. user_number_1
	43. user_number_1_flag
	44. user_number_2
	45. user_number_2_flag
	46. user_number_3
	47. user_number_3_flag
	48. user_number_4
	49. user_number_4_flag
	50. user_number_5
	51. user_number_5_flag
	52. user_number_6
	53. user_number_6_flag
	54. user_number_7
	55. user_number_7_flag
	56. user_number_8
	57. user_number_8_flag
	58. user_number_9
	59. user_number_9_flag
	60. user_number_10
	61. user_number_10_flag
	62. user_text_1
	63. user_text_1_flag
	64. user_text_2
	65. user_text_2_flag
	66. user_text_3
	67. user_text_3_flag
	68. user_text_4
	69. user_text_4_flag
	70. user_text_5
	71. user_text_5_flag
	72. user_text_6
	73. user_text_6_flag
	74. user_text_7
	75. user_text_7_flag
	76. user_text_8
	77. user_text_8_flag
	78. user_text_9
	79. user_text_9_flag
	80. user_text_10
	81. user_text_10_flag
****sw_roughness_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. exclude_from_2d_mesh
	7. exclude_from_2d_mesh_flag
	8. roughness
	9. roughness_flag
	10. roughness_definition_id
	11. roughness_definition_id_flag
	12. priority
	13. priority_flag
	14. hyperlinks
		 description
		 url
	15. hyperlinks_flag
	16. notes
	17. notes_flag
	18. user_number_1
	19. user_number_1_flag
	20. user_number_2
	21. user_number_2_flag
	22. user_number_3
	23. user_number_3_flag
	24. user_number_4
	25. user_number_4_flag
	26. user_number_5
	27. user_number_5_flag
	28. user_number_6
	29. user_number_6_flag
	30. user_number_7
	31. user_number_7_flag
	32. user_number_8
	33. user_number_8_flag
	34. user_number_9
	35. user_number_9_flag
	36. user_number_10
	37. user_number_10_flag
	38. user_text_1
	39. user_text_1_flag
	40. user_text_2
	41. user_text_2_flag
	42. user_text_3
	43. user_text_3_flag
	44. user_text_4
	45. user_text_4_flag
	46. user_text_5
	47. user_text_5_flag
	48. user_text_6
	49. user_text_6_flag
	50. user_text_7
	51. user_text_7_flag
	52. user_text_8
	53. user_text_8_flag
	54. user_text_9
	55. user_text_9_flag
	56. user_text_10
	57. user_text_10_flag
****sw_mesh_level_zone
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. level_type
	6. level_type_flag
	7. use_upper_limit
	8. use_upper_limit_flag
	9. upper_limit_level
	10. upper_limit_level_flag
	11. use_lower_limit
	12. use_lower_limit_flag
	13. lower_limit_level
	14. lower_limit_level_flag
	15. level_sections
		 X
		 Y
		 vertex_elev_type
		 elevation
		 elev_adjust
	16. level
	17. level_flag
	18. raise_by
	19. raise_by_flag
	20. hyperlinks
		 description
		 url
	21. hyperlinks_flag
	22. notes
	23. notes_flag
	24. user_number_1
	25. user_number_1_flag
	26. user_number_2
	27. user_number_2_flag
	28. user_number_3
	29. user_number_3_flag
	30. user_number_4
	31. user_number_4_flag
	32. user_number_5
	33. user_number_5_flag
	34. user_number_6
	35. user_number_6_flag
	36. user_number_7
	37. user_number_7_flag
	38. user_number_8
	39. user_number_8_flag
	40. user_number_9
	41. user_number_9_flag
	42. user_number_10
	43. user_number_10_flag
	44. user_text_1
	45. user_text_1_flag
	46. user_text_2
	47. user_text_2_flag
	48. user_text_3
	49. user_text_3_flag
	50. user_text_4
	51. user_text_4_flag
	52. user_text_5
	53. user_text_5_flag
	54. user_text_6
	55. user_text_6_flag
	56. user_text_7
	57. user_text_7_flag
	58. user_text_8
	59. user_text_8_flag
	60. user_text_9
	61. user_text_9_flag
	62. user_text_10
	63. user_text_10_flag
****sw_porous_wall
	1. line_id
	2. line_id_flag
	3. asset_id
	4. asset_id_flag
	5. porosity
	6. porosity_flag
	7. crest_level
	8. crest_level_flag
	9. general_line_xy
	10. height
	11. height_flag
	12. level
	13. level_flag
	14. remove_wall
	15. remove_wall_flag
	16. wall_removal_trigger
	17. wall_removal_trigger_flag
	18. use_diff_across_wall
	19. use_diff_across_wall_flag
	20. depth_threshold
	21. depth_threshold_flag
	22. elevation_threshold
	23. elevation_threshold_flag
	24. velocity_threshold
	25. velocity_threshold_flag
	26. unit_flow_threshold
	27. unit_flow_threshold_flag
	28. total_head_threshold
	29. total_head_threshold_flag
	30. force_threshold
	31. force_threshold_flag
	32. hydro_press_coeff
	33. hydro_press_coeff_flag
	34. hyperlinks
		 description
		 url
	35. hyperlinks_flag
	36. length
	37. length_flag
	38. notes
	39. notes_flag
	40. user_number_1
	41. user_number_1_flag
	42. user_number_2
	43. user_number_2_flag
	44. user_number_3
	45. user_number_3_flag
	46. user_number_4
	47. user_number_4_flag
	48. user_number_5
	49. user_number_5_flag
	50. user_number_6
	51. user_number_6_flag
	52. user_number_7
	53. user_number_7_flag
	54. user_number_8
	55. user_number_8_flag
	56. user_number_9
	57. user_number_9_flag
	58. user_number_10
	59. user_number_10_flag
	60. user_text_1
	61. user_text_1_flag
	62. user_text_2
	63. user_text_2_flag
	64. user_text_3
	65. user_text_3_flag
	66. user_text_4
	67. user_text_4_flag
	68. user_text_5
	69. user_text_5_flag
	70. user_text_6
	71. user_text_6_flag
	72. user_text_7
	73. user_text_7_flag
	74. user_text_8
	75. user_text_8_flag
	76. user_text_9
	77. user_text_9_flag
	78. user_text_10
	79. user_text_10_flag
****sw_roughness_definition
	1. definition_id
	2. definition_id_flag
	3. number_of_bands
	4. number_of_bands_flag
	5. roughness_1
	6. roughness_1_flag
	7. depth_thld_1
	8. depth_thld_1_flag
	9. roughness_2
	10. roughness_2_flag
	11. depth_thld_2
	12. depth_thld_2_flag
	13. roughness_3
	14. roughness_3_flag
	15. hyperlinks
		 description
		 url
	16. hyperlinks_flag
	17. notes
	18. notes_flag
	19. user_number_1
	20. user_number_1_flag
	21. user_number_2
	22. user_number_2_flag
	23. user_number_3
	24. user_number_3_flag
	25. user_number_4
	26. user_number_4_flag
	27. user_number_5
	28. user_number_5_flag
	29. user_number_6
	30. user_number_6_flag
	31. user_number_7
	32. user_number_7_flag
	33. user_number_8
	34. user_number_8_flag
	35. user_number_9
	36. user_number_9_flag
	37. user_number_10
	38. user_number_10_flag
	39. user_text_1
	40. user_text_1_flag
	41. user_text_2
	42. user_text_2_flag
	43. user_text_3
	44. user_text_3_flag
	45. user_text_4
	46. user_text_4_flag
	47. user_text_5
	48. user_text_5_flag
	49. user_text_6
	50. user_text_6_flag
	51. user_text_7
	52. user_text_7_flag
	53. user_text_8
	54. user_text_8_flag
	55. user_text_9
	56. user_text_9_flag
	57. user_text_10
	58. user_text_10_flag
****sw_2d_boundary_line
	1. line_id
	2. line_id_flag
	3. line_type
	4. line_type_flag
	5. general_line_xy
	6. bed_load_boundary
	7. bed_load_boundary_flag
	8. suspended_load_boundary
	9. suspended_load_boundary_flag
	10. head_unit_discharge_id
	11. head_unit_discharge_id_flag
	12. hyperlinks
		 description
		 url
	13. hyperlinks_flag
	14. length
	15. length_flag
	16. notes
	17. notes_flag
	18. user_number_1
	19. user_number_1_flag
	20. user_number_2
	21. user_number_2_flag
	22. user_number_3
	23. user_number_3_flag
	24. user_number_4
	25. user_number_4_flag
	26. user_number_5
	27. user_number_5_flag
	28. user_number_6
	29. user_number_6_flag
	30. user_number_7
	31. user_number_7_flag
	32. user_number_8
	33. user_number_8_flag
	34. user_number_9
	35. user_number_9_flag
	36. user_number_10
	37. user_number_10_flag
	38. user_text_1
	39. user_text_1_flag
	40. user_text_2
	41. user_text_2_flag
	42. user_text_3
	43. user_text_3_flag
	44. user_text_4
	45. user_text_4_flag
	46. user_text_5
	47. user_text_5_flag
	48. user_text_6
	49. user_text_6_flag
	50. user_text_7
	51. user_text_7_flag
	52. user_text_8
	53. user_text_8_flag
	54. user_text_9
	55. user_text_9_flag
	56. user_text_10
	57. user_text_10_flag
****sw_head_unit_discharge
	1. head_unit_discharge_id
	2. head_unit_discharge_id_flag
	3. head_unit_discharge_description
	4. head_unit_discharge_description_flag
	5. HUDP_table
		 head
		 unit_discharge
	6. HUDP_table_flag
	7. hyperlinks
		 description
		 url
	8. hyperlinks_flag
	9. notes
	10. notes_flag
	11. user_number_1
	12. user_number_1_flag
	13. user_number_2
	14. user_number_2_flag
	15. user_number_3
	16. user_number_3_flag
	17. user_number_4
	18. user_number_4_flag
	19. user_number_5
	20. user_number_5_flag
	21. user_number_6
	22. user_number_6_flag
	23. user_number_7
	24. user_number_7_flag
	25. user_number_8
	26. user_number_8_flag
	27. user_number_9
	28. user_number_9_flag
	29. user_number_10
	30. user_number_10_flag
	31. user_text_1
	32. user_text_1_flag
	33. user_text_2
	34. user_text_2_flag
	35. user_text_3
	36. user_text_3_flag
	37. user_text_4
	38. user_text_4_flag
	39. user_text_5
	40. user_text_5_flag
	41. user_text_6
	42. user_text_6_flag
	43. user_text_7
	44. user_text_7_flag
	45. user_text_8
	46. user_text_8_flag
	47. user_text_9
	48. user_text_9_flag
	49. user_text_10
	50. user_text_10_flag
****sw_river_reach
	1. us_node_id
	2. us_node_id_flag
	3. link_suffix
	4. link_suffix_flag
	5. section_spacing
		 key
		 spacing
	6. section_spacing_flag
	7. ds_node_id
	8. ds_node_id_flag
	9. boundary_array
	10. point_array
	11. left_bank
		 X
		 Y
		 Z
		 discharge_coeff
		 modular_ratio
		 section_marker
	12. left_bank_flag
	13. right_bank
		 X
		 Y
		 Z
		 discharge_coeff
		 modular_ratio
		 section_marker
	14. right_bank_flag
	15. sections
		 key
		 X
		 Y
		 Z
		 roughness_N
		 new_panel
	16. sections_flag
	17. conveyance
		 key
		 depth
		 conveyance
		 area
		 width
		 perimeter
	18. conveyance_flag
	19. left_node_id
	20. left_node_id_flag
	21. left_reach_node_id
	22. left_reach_node_id_flag
	23. left_2d_zone_id
	24. left_2d_zone_id_flag
	25. right_node_id
	26. right_node_id_flag
	27. right_reach_node_id
	28. right_reach_node_id_flag
	29. right_2d_zone_id
	30. right_2d_zone_id_flag
	31. notes
	32. notes_flag
	33. branch_id
	34. branch_id_flag
	35. user_number_1
	36. user_number_1_flag
	37. user_number_2
	38. user_number_2_flag
	39. user_number_3
	40. user_number_3_flag
	41. user_number_4
	42. user_number_4_flag
	43. user_number_5
	44. user_number_5_flag
	45. user_number_6
	46. user_number_6_flag
	47. user_number_7
	48. user_number_7_flag
	49. user_number_8
	50. user_number_8_flag
	51. user_number_9
	52. user_number_9_flag
	53. user_number_10
	54. user_number_10_flag
	55. hyperlinks
		 description
		 url
	56. hyperlinks_flag
	57. user_text_1
	58. user_text_1_flag
	59. user_text_2
	60. user_text_2_flag
	61. user_text_3
	62. user_text_3_flag
	63. user_text_4
	64. user_text_4_flag
	65. user_text_5
	66. user_text_5_flag
	67. user_text_6
	68. user_text_6_flag
	69. user_text_7
	70. user_text_7_flag
	71. user_text_8
	72. user_text_8_flag
	73. user_text_9
	74. user_text_9_flag
	75. user_text_10
	76. user_text_10_flag
****sw_2d_ic_polygon
	1. polygon_id
	2. polygon_id_flag
	3. area
	4. area_flag
	5. boundary_array
	6. hyperlinks
		 description
		 url
	7. hyperlinks_flag
	8. notes
	9. notes_flag
	10. user_number_1
	11. user_number_1_flag
	12. user_number_2
	13. user_number_2_flag
	14. user_number_3
	15. user_number_3_flag
	16. user_number_4
	17. user_number_4_flag
	18. user_number_5
	19. user_number_5_flag
	20. user_number_6
	21. user_number_6_flag
	22. user_number_7
	23. user_number_7_flag
	24. user_number_8
	25. user_number_8_flag
	26. user_number_9
	27. user_number_9_flag
	28. user_number_10
	29. user_number_10_flag
	30. user_text_1
	31. user_text_1_flag
	32. user_text_2
	33. user_text_2_flag
	34. user_text_3
	35. user_text_3_flag
	36. user_text_4
	37. user_text_4_flag
	38. user_text_5
	39. user_text_5_flag
	40. user_text_6
	41. user_text_6_flag
	42. user_text_7
	43. user_text_7_flag
	44. user_text_8
	45. user_text_8_flag
	46. user_text_9
	47. user_text_9_flag
	48. user_text_10
	49. user_text_10_flag

 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0134 - Input Message Box\Input Message Box.rb" 
# Modified from Innovyze Ruby Documentation

output = WSApplication.input_box("Message box prompt line 1\nMessage box prompt line 2\nMessage Box prompt line 3", 'Message box title', 'Here is some initial text')

if output.nil?
  puts "Cancel button hit, the input is: #{output}"
else
  puts "OK button hit, the input is: #{output}"
end
 
# FILENAME: "C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM\0135 - Create Subs from polygon\UI_script.rb" 
# Get the current network object
net = WSApplication.current_network

# Begin a transaction. This allows all changes to be committed at once at the end of the script.
net.transaction_begin

# Iterate over all polygon objects in the network
net.row_object_collection('hw_subcatchment').each do |polygon|
    # Check if the polygon is selected  
    if polygon.selected?
      # Get the boundary array of the polygon
      boundary_array = polygon.boundary_array
  
      # Calculate the centroid of the polygon
      centroid_x = boundary_array.each_slice(2).map(&:first).sum / (boundary_array.size / 2)
      centroid_y = boundary_array.each_slice(2).map(&:last).sum / (boundary_array.size / 2)
  
      # Calculate the width and height of the polygon
      width = boundary_array.each_slice(2).map(&:first).max - boundary_array.each_slice(2).map(&:first).min
      height = boundary_array.each_slice(2).map(&:last).max - boundary_array.each_slice(2).map(&:last).min
  
      # Calculate the coordinates of the 4 quadrants
      quadrant_1 = [centroid_x, centroid_y, centroid_x + width / 2, centroid_y + height / 2]
      quadrant_2 = [centroid_x, centroid_y, centroid_x - width / 2, centroid_y + height / 2]
      quadrant_3 = [centroid_x, centroid_y, centroid_x - width / 2, centroid_y - height / 2]
      quadrant_4 = [centroid_x, centroid_y, centroid_x + width / 2, centroid_y - height / 2]
            puts quadrant_1
            puts quadrant_2
      # Create new polygons for each quadrant
      # [quadrant_1, quadrant_2, quadrant_3, quadrant_4].each_with_index do |quadrant, index|
        new_polygon = net.new_row_object('hw_subcatchment')
        new_polygon['subcatchment_id'] = "#{subcatchment.id}#{index + 1}"
        new_polygon['boundary_array'] << quadrant_1
        new_polygon['boundary_array'] << quadrant_2
        new_polygon['boundary_array'] << quadrant_3
        new_polygon['boundary_array'] << quadrant_4
        new_polygon.write
      end
    end

# Commit the transaction, making all changes permanent
net.transaction_commit 
