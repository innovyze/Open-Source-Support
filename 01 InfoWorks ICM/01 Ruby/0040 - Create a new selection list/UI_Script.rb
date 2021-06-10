db=WSApplication.current_database
net=WSApplication.current_network
net.clear_selection
group=db.find_root_model_object 'Model Group','New Selection'
net.run_SQL "_links","link_type = 'cond'"
sl=group.new_model_object 'Selection List','Conduits'
net.save_selection sl
