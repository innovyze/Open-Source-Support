def exit_script
	error=WSApplication.message_box "Script stopped: The input was invalid.",'OK','stop',false
	exit if error=='OK'
end

begin
	# First prompt for number of flags to be changed
	$flag_count=WSApplication.prompt("How many flags do you want to change?",[['Number of flags','Number',0,0,'RANGE',0,10]],false)
	exit_script if $flag_count.nil? || $flag_count[0]==0
	# Generates a layout for the next prompt on the back of the answer
	$layout=Array.new
	$i=1
	while $i<=$flag_count[0].to_i
		$layout<<["Old flag ##{$i}",'String']
		$layout<<["New flag ##{$i}",'String']
		$i+=1
	end
	# Second prompt for old and new flags
	$flags_array=WSApplication.prompt "Which flags do you want to replace?",$layout,false
	if $flags_array.nil?
		exit_script
	elsif $flags_array.any?{ |_| _.nil? }
		exit_script
	end
	# Sorts answers. Stolen from here https://stackoverflow.com/questions/17728135/partition-array-using-index-in-ruby
	$old_flags, $new_flags = $flags_array.partition.with_index { |_,i| i.even? }
	# Real logic begins
	$net=WSApplication.current_network
	$net.transaction_begin
	$net.tables.each do |table|
		fields=table.fields
		fields.each do |field|
			if field.name.match? (/_flag/)
				$net.row_objects(table.name).each do |row|
					i=0
					while i<$old_flags.length
						old_flag=$old_flags[i]
						new_flag=$new_flags[i]
						row[field.name]=new_flag if row[field.name]==old_flag
						i+=1
					end
					row.write
				end
			end
		end
	end
	$net.transaction_commit
	success_message="Flags #{$old_flags} replaced by flags #{$new_flags} in all model object fields"
	WSApplication.message_box(success_message,'OK',nil,false)
rescue SystemExit
end