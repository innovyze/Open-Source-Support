# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits 

current_network = WSApplication.current_network

THANK_YOU_MESSAGE = 'Thank you for using Ruby in ICM InfoWorks'

scenarios=Array.new
scenarios = ['SF484_IA_10mm','S456__IA_10mm','SF284_IA_10mm','SF484_IA_10mm_100ImPerv','S456__IA_10mm_100ImPerv','SF284__IA_10mm_100ImPerv']

scenarios.each do |scenario|
	current_network.add_scenario(scenario,nil,'')
  end

puts THANK_YOU_MESSAGE
