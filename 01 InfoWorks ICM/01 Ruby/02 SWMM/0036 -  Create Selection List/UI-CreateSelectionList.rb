db=WSApplication.current_database
net=WSApplication.current_network

group=db.model_object_from_type_and_id('Model Group',1)	## Where to create the Selection List object on the db
sl=group.new_model_object('Selection List','New_Selection')	## Create new Selection List called 'New_Selection'
net.save_selection(sl)									## Save current selection into the sl as above