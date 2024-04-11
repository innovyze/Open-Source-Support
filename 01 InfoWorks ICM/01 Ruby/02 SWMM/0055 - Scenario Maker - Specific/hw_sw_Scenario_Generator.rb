# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits 

current_network = WSApplication.current_network

THANK_YOU_MESSAGE = 'Thank you for using Ruby in ICM InfoWorks'

scenarios=Array.new
scenarios = [ 
  "PHASE0",
  "PHASE1",
 "PHASE2",
 "PHASE3",
 "PHASE4",
  "PHASE5",
  "AVG_BASE",
  "PHASE5_ASSUMEDMHS",
  "PHASE1_ASSUMEDMHS",
  "PHASE0_ASSUMEDMHS",
  "PHASE2_ASSUMEDMHS",
  "PHASE3_ASSUMEDMHS",
  "PHASE4_ASSUMEDMHS",
  "PHASE5_FIXED"  
]

current_network.scenarios do |scenario|
    if scenario != 'Base'
        current_network.delete_scenario(scenario)
    end
end
puts 'All scenarios deleted'

scenarios.each do |scenario|
	current_network.add_scenario(scenario,nil,'')
  end

puts THANK_YOU_MESSAGE

