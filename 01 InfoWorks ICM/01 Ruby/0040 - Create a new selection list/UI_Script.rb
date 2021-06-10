db=WSApplication.current_database
net=WSApplication.current_network
net.clear_selection
group=db.model_object_from_type_and_id 'Model Group',5
net.run_SQL 'hw_node','x>644220'
sl=group.new_model_object 'Selection List','Andrew'
net.save_selection sl