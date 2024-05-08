# Copy a run and set 'Working' flag

## How it Works
This Ruby script is designed to automate the process of creating a new run in a model group within a WSApplication database. It uses specific parameters and data from the database, including rainfall event data and network scenario IDs, to create this new run.

Key steps include:

Establishing a connection to the database.
Retrieving specific model objects.
Extracting unique rainfall event data and network scenario data.
Creating a new run in the model group with the extracted data.