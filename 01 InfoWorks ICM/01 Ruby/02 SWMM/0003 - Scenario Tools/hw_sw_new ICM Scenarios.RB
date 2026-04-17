# Original Source: https://github.com/ngerdts7/ICM_Tools123
# RED + ChatGPT edits

# Access the current network from the WSApplication
current_network = WSApplication.current_network

# Define a constant message to be displayed at the end
THANK_YOU_MESSAGE = 'Thank you for using Ruby in ICM InfoWorks'

# Create an array to hold the scenarios
scenarios = Array.new

# Define the scenarios - these represent different modeling scenarios to be added to the network
scenarios = ['SF484_IA_10mm', 'S456__IA_10mm', 'SF284_IA_10mm', 'SF484_IA_10mm_100ImPerv', 'S456__IA_10mm_100ImPerv', 'SF284__IA_10mm_100ImPerv']

# Iterate through each scenario in the scenarios array
scenarios.each do |scenario|
  # Add the scenario to the current network
  # The parameters are (name, description, folder) - description and folder are left empty in this case
  current_network.add_scenario(scenario, nil, '')

  # Optional: You could add a message here to confirm that the scenario was added successfully
  puts "Scenario #{scenario} has been added successfully."
end

# Print the thank you message after all scenarios have been added
puts THANK_YOU_MESSAGE