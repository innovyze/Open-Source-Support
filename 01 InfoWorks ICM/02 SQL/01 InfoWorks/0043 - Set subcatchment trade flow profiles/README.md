# User Prompt Trade Profile

This SQL script is designed to define and map unique trade profile numbers to each profile name in the subcatchment table of a network model.

## How it Works

The script operates in a series of steps:

1. **Variable Definition**: The script starts by defining a variable for the trade profile number and a list for unique profile names.

2. **Unique Profile Names Retrieval**: The script fetches all unique profile names from the entire subcatchment table.

3. **Profile Mapping Loop**: The script then enters a loop where it goes through all the unique profile names. For each profile name, it prompts the user to define a trade profile number, and updates the trade profile number in the subcatchment table.

4. **Trade Profile Mapping Output**: The script finally outputs a table mapping the trade profile number to the trade profile name.

## Usage

To use this script, simply run it in the context of a network model. The script will automatically prompt you to input trade profile numbers for each unique profile name and then update these in the subcatchment table. It will also provide a table mapping the trade profile number to the trade profile name.

## Note

This script uses the `user_text_1` field for profile names. If your data format or location is different, you may need to modify the script accordingly to match your specific needs.




# Auto-assign Trade Profile

This script is designed to automatically assign and map unique trade profile numbers to each profile name in the subcatchment table of a network model. The script also handles blank profile names.

## How it Works

The script operates in a series of steps:

1. **Unique Profile Names Retrieval**: The script fetches all unique profile names from the entire subcatchment table, excluding blanks.

2. **Profile Mapping Loop**: The script then enters a loop where it goes through all the unique profile names. For each profile name, it automatically assigns a trade profile number based on its order in the list, and updates this number in the subcatchment table.

3. **Blank Profile Names Handling**: After going through all unique profile names, the script assigns a trade profile number of '0' to all blank profile names in the subcatchment table.

4. **Trade Profile Mapping Output**: The script finally outputs a table mapping the trade profile number to the profile name.

## Usage

To use this script, simply run it in the context of a network model. The script will automatically assign trade profile numbers to each unique profile name and update these in the subcatchment table. It will also handle blank profile names, assigning them a trade profile number of '0'. Finally, it will provide a table mapping the trade profile number to the profile name.

## Note

This script uses the `user_text_1` field for profile names. If your data format or location is different, you may need to modify the script accordingly to match your specific needs.
