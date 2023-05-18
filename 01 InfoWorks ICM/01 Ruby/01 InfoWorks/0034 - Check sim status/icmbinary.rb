require 'io/console'                                                                                                       
def continue_story                                                                                                               
  print "press any key"                                                                                                    
  STDIN.getch                                                                                                              
  print "            \r" # extra space to overwrite in case next sentence is short                                                                                                              
end 

db = WSApplication.open 'UKWAL18001301:40000/Alex Support',false
sim1 = db.model_object_from_type_and_id 'Sim',1713
sim2 = db.model_object_from_type_and_id 'Sim',1714
status1 = sim1.status
status2 = sim2.status
success1 = sim1.success_substatus
success2 = sim2.success_substatus
puts status1
puts status2
puts success1
puts success2
continue_story