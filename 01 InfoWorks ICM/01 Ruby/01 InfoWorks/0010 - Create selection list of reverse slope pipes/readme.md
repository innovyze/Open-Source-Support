# Create Selection List of Reverse Slope Pipes

This script iterates through all conduits in the 'hw_conduit' table. It selects conduits that have a negative gradient and their solution model is neither 'Pressure' nor 'ForceMain'. If no reverse slope pipes are found, it informs the user and exits the script.

The script then identifies the parent model group of the current network. It attempts to find the parent object assuming it's a 'Model Group'. If unsuccessful, it assumes the parent object is a 'Model Network' and finds its parent 'Model Group'.

Next, it defines the base name for the new selection list and checks if a selection list with the proposed name already exists within the model group. If it does, it appends an integer to the base name and increments the counter until an unused name is found.

Finally, it creates a new selection list with the available name in the parent model group and saves the currently selected conduits to the new selection list.