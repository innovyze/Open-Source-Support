if WSApplication.ui?
	net=WSApplication.current_network
else
	db=WSApplication.open('',nil)
	mo=db.model_object_from_type_and_id 'Collection Network',322
	net=mo.open
end
net.revert
net.transaction_begin
(0...10).each do |i|
	(0...10).each do |j|
		o=net.new_row_object('cams_manhole')
		o.x=278000+10*i
		o.y=187000+10*j
		o.autoname
		o.write
	end
	f=File.open 'c:\\temp\\script.txt','w'
	f.puts "got to #{i}"
	f.close
end
net.transaction_commit
net.commit 'badger'
