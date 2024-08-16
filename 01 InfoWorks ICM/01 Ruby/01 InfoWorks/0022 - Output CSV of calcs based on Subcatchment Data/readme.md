# Output CSV of calcs based on subcatchment data

This script is designed to analyze the properties of selected subcatchments in a network and write the results to a CSV file.

## How it Works

1. The script first accesses the current network of subcatchments and prompts the user to select a location to save the output CSV file.
2. It then creates an array with the headers for the data to be written to the CSV file and writes the headers to the file.
3. It initializes a new array and variables to hold the total values for each property that will be summarized.
4. It then goes through each subcatchment in the network. If a subcatchment is selected, it adds the properties of the subcatchment to the corresponding total variables, depending on the system type of the subcatchment.
5. After all selected subcatchments have been processed, it calculates the total values for each property across all system types and formats them to the desired precision.
6. The total values are then added to the array and written to the CSV file.
7. Finally, the script displays a message box to inform the user that the routine was completed successfully.