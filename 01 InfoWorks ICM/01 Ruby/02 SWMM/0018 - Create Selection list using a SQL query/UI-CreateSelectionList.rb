db=WSApplication.current_database
net=WSApplication.current_network

group=db.model_object_from_type_and_id('yarra',1)	## Where to create the Selection List object on the db
sl=group.new_model_object('Selection List','Anode')	## Create new Selection List called 'New_Selection'
sl=group.new_model_object('Selection List','Alink')	## Create new Selection List called 'New_Selection'
net.save_selection(sl)									## Save current selection into the sl as above