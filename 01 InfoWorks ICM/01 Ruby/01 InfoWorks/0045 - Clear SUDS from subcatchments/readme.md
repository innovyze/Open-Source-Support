# Clear SUDS from subcatchments

This script is designed to clear the Sustainable Urban Drainage System (SuDS) control data from all the subcatchments in a network. It also tracks and displays the time it takes to execute the script.

## How it Works

1. The script first accesses the current network of data.
2. It records the current time as the start time for the script.
3. It begins a transaction, which ensures all changes made within the transaction are either fully applied or completely rolled back, maintaining data integrity.
4. It then goes through each subcatchment in the network and:
    - Sets the size of the SuDS controls to zero, effectively clearing it.
    - Writes the changes to the SuDS controls and the subcatchment.
5. Once all subcatchments have been processed, it commits the transaction, applying all changes to the network.
6. It records the current time as the end time for the script and calculates the time it took to execute the script.
7. Finally, it prints the runtime of the script.