# Set subcatchment drying time and commit changes
This Ruby script is designed to automate the process of adjusting a particular parameter ("drying_time") for all subcatchments within a currently open network in a WSApplication. The script then commits this change to the database.

## How it Works

The key steps involved are:

1. Accessing the currently open network in the application.
2. Starting a transaction where the script will make changes to the database.
3. Iterating over all subcatchments within the 'hw_subcatchment' table in the network.
4. For each subcatchment, the script sets 'drying_time' to 1 and writes this change back to the database.
5. Once all subcatchments have been updated, the transaction is committed, making the changes permanent in the database.
6. Committing the change to the database with a comment "Drying time was set to 1 day for all subcatchments".
7. Printing a message to inform the user that the drying time has been updated and they are now ready to update and rerun simulations.
