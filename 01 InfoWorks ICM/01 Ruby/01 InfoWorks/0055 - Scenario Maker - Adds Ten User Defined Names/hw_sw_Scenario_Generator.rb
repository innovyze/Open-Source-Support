# Original Source https://github.com/ngerdts7/ICM_Tools123

current_network = WSApplication.current_network

MESSAGE = 'Thank you for using Ruby in InfoWorks ICM'

scenarios=Array.new
scenarios = 
  [
    "Phase1",
    "Phase2",
    "Phase3",
    "Phase4",
    "Phase5",
    "Phase6",
    "Phase7",
    "Phase8",
    "Phase9",
    "Phase10"
  ]

current_network.scenarios do |scenario|
    if scenario != 'Base'
        current_network.delete_scenario(scenario)
    end
end
puts 'All existing scenarios deleted'

scenarios.each do |scenario|
	current_network.add_scenario(scenario,nil,'')
  end
puts "\n"
puts 'New scenarios added: ' + scenarios.length.to_s
puts "\t" + scenarios.join("\n\t")
puts "\n"
puts MESSAGE