# Scenario Generator

This script, created by Robert Dickinson (RED), is used to create a user-defined number of new scenarios in ICM InfoWorks or ICM SWMM Networks. The original source of the script is [here](https://github.com/ngerdts7/ICM_Tools123), and it's also available at the [Autodesk Water Infrastructure GitHub](https://github.com/innovyze/Open-Source-Support/tree/main).    

## Code Summary

1. The script starts by getting the current network using `WSApplication.current_network`.

2. It defines a constant `THANK_YOU_MESSAGE` which is a string that will be printed at the end of the script.

3. It creates an array `scenarios` containing the letters 'A' to 'Z'. These will be used as the names of the new scenarios.

4. The script then iterates over all scenarios in the current network. If a scenario's name is not 'Base', the script deletes that scenario. After this step, all scenarios except 'Base' have been deleted.

5. It prints a message informing the user that all scenarios except the base were deleted. It also provides instructions on how to revert the changes if the user did not intend to delete the scenarios.

6. The script then iterates over the `scenarios` array. For each element in the array, it adds a new scenario to the current network with that element as the name.

7. It prints the number of scenarios added, which is the length of the `scenarios` array.

8. Finally, it prints the `THANK_YOU_MESSAGE`.

This script is useful for quickly setting up a specific set of scenarios in an ICM InfoWorks network.