# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits 

current_network = WSApplication.current_network

THANK_YOU_MESSAGE = 'Thank you for using Ruby in ICM InfoWorks'

scenarios=Array.new
scenarios = ['d50_sf1','s_sf1','settling_velocity_sf1','dens_sf1','settling_calc_sf1','2D_settling_velocity_sf1','porosity_sf1','roughness_sf1','repose_sf1']

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
