# Original Source https://github.com/ngerdts7/ICM_Tools123
# RED + CoPilot edits 

cn = WSApplication.current_network

THANK_YOU_MESSAGE1 = "That's it! You've successfully added scenarios your ICM InfoWorks network. Thank you for using our Ruby script."
THANK_YOU_MESSAGE2 = "If you have any questions or need further assistance, don't hesitate to reach out to the Autodesk EBCS Team."
THANK_YOU_MESSAGE3 = "Happy Modeling! or Happy Modelling! (depending on your location)"

# Define the factors
factors = [-0.25, -0.10, 0.10, 0.25]
parameters = ['bottom_roughness_N']

# Generate scenarios for each parameter and factor
scenarios = parameters.product(factors).map do |parameter, factor|
  "#{parameter}_factor_#{(factor*100).to_i}"
end

cn.scenarios do |scenario|
  if scenario != 'Base'
    cn.delete_scenario(scenario)
  end
end

puts "Operation successful! All scenarios, except for the base scenario, have been deleted and new scenarios have been added."
puts "If this action was performed in error, don't worry! You can easily revert these changes."
puts "Just go to the ICM Explorer Window and select 'Revert Changes' to restore the deleted scenarios."
puts

# Iterate over each scenario and corresponding factor
scenarios.zip(factors).each do |scenario, factor|
  cn.add_scenario(scenario, nil, '')
  cn.current_scenario = scenario
  cn.transaction_begin
  BR_N = []
  
  puts "The factor for scenario is #{factor}"
  
  ro = cn.row_objects('hw_conduit').each do |ro|
    ro.bottom_roughness_N = ro.bottom_roughness_N * (1 + factor)
    BR_N << ro.bottom_roughness_N if ro.bottom_roughness_N
    ro.write
  end
  puts "The total #{cn.current_scenario} bottom roughness of all links in the network is #{BR_N.sum.round(5)} for #{BR_N.count} links"
  cn.transaction_commit    
end

puts "Number of scenarios added: #{scenarios.length}"
puts
puts THANK_YOU_MESSAGE1
puts THANK_YOU_MESSAGE2
puts THANK_YOU_MESSAGE3
