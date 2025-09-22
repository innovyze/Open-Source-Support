def delete_scenarios(current_network)
  # Collect all existing scenarios, excluding the "Base" scenario
  existing_scenario_names = []
  current_network.scenarios do |scenario|
    existing_scenario_names << scenario unless scenario == 'Base'
  end

  # Sort the scenario names alphabetically for user selection
  existing_scenario_names.sort!

  # Prompt the user to select scenarios to delete, including 'Delete All' option
  scenario_names_with_options = [["Delete all", 'Boolean']] + existing_scenario_names.map { |name| [name, 'Boolean'] }

  selected_scenarios_prompt = WSApplication.prompt("Select scenarios to delete", scenario_names_with_options, true)

  # Handle cases where the prompt result might be nil or the user clicked 'Cancel'
  if selected_scenarios_prompt.nil? || selected_scenarios_prompt.empty?
    WSApplication.message_box("Scenario selection was canceled. No scenarios were deleted.", "OK", "Information", false)
    return
  end

  # Determine if the 'Delete All' option was chosen
  delete_all = selected_scenarios_prompt[0] == true

  # If 'Delete All' is chosen, select all scenarios
  selected_scenarios_prompt = scenario_names_with_options.map.with_index { | _, i | i == 0 ? false : delete_all } if delete_all

  # Extract indices of selected scenarios
  selected_indices = selected_scenarios_prompt.each_index.select { |i| i > 0 && selected_scenarios_prompt[i] == true }

  # Map selected indices to scenario names
  selected_scenarios = selected_indices.map { |i| existing_scenario_names[i - 1] } # Adjust index to consider "Delete All"

  # Confirm deletion with the user
  user_choice = WSApplication.message_box("Are you sure you want to delete the selected scenarios: #{selected_scenarios.join(', ')}?", "YesNo", "?", false)

  if user_choice != "Yes"
    WSApplication.message_box("No scenarios were deleted. Script canceled.", "OK", "Information", false)
    return
  end

  # Initialize a counter for the number of scenarios deleted
  deleted_scenarios_count = 0

  # Delete the selected scenarios
  selected_scenarios.each do |scenario|
    current_network.delete_scenario(scenario)
    deleted_scenarios_count += 1
  end

  # Inform the user about the total number of scenarios deleted and remind to commit changes
  WSApplication.message_box("Scenarios deleted successfully. Please remember to commit your changes for the deletions to take effect.", "OK", "Information", false)
end

# Access the current network in the application
current_network = WSApplication.current_network

# Call the method to delete scenarios
delete_scenarios(current_network)