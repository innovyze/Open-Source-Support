db=WSApplication.current_database
net=WSApplication.current_network

group=db.model_object_from_type_and_id('Asset Group',3)	## Where to create the Selection List object on the db
sl=group.new_model_object('Selection List','Selection')	## Create new Selection List called 'Selection'
net.save_selection(sl)									## Save current selection into the sl as above