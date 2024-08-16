# Ruby Script for Duplicating Selected Subcatchments in InfoWorks ICM

This Ruby script is used to duplicate selected subcatchments in the InfoWorks ICM software. Here's a summary of what it does:

- It first sets up the current network (`net`) and iterates over each subcatchment object in the network.

- For each subcatchment, it checks if the subcatchment is selected.

- If the subcatchment is selected, it starts a transaction and creates a new subcatchment object.

- It sets the ID of the new subcatchment to the ID of the original subcatchment with a "_copy" suffix.

- It then iterates over each field (column) in the subcatchment table. For each field, it checks if the field name is not 'subcatchment_id'. If it's not, it sets the value of the field in the new subcatchment to the value of the field in the original subcatchment.

- It writes the changes to the new subcatchment and commits the transaction.

- This process is repeated for each selected subcatchment in the network.                                                                                                                                                                                  