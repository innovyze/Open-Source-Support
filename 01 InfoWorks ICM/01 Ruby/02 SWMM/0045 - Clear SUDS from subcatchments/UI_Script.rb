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
end
on.transaction_commit

end_time=Time.now

net_time= end_time - start_time

puts
puts 'Script Runtime :'+ net_time.to_s + ' sec'
