require 'io/console'                                                                                                       
def continue_story                                                                                                               
  print "press any key"                                                                                                    
  STDIN.getch                                                                                                              
  print "            \r" # extra space to overwrite in case next sentence is short                                                                                                              
end 

WSApplication.open 'UKWAL18001301:40000/Alex Support'
puts "Database created"
continue_story