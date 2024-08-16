# Copy a run and set 'Working' flag

## How it Works
This Ruby script is designed to automate the process of creating a new run in a model group within a WSApplication database. It uses specific parameters and data from the database, including rainfall event data and network scenario IDs, to create this new run.

The key steps involved are:

1. Establishing a connection to the database.
2. Retrieving specific model objects.
3. Extracting unique rainfall event data and network scenario data.
4. Creating a new run in the model group with the extracted data.
5. Setting the 'Working' flag for the new run.