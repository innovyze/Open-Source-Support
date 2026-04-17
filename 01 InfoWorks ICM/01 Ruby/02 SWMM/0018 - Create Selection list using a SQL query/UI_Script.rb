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
