## Markdown Summary

- **Network Initialization and Error Handling**
  - Accesses the current network via the InfoWorks API.
  - Raises an error if the network is not available.

- **Retrieving Row Objects**
  - Retrieves node row objects (`hw_node`) from the network.
  - Retrieves both nodes and subcatchments as arrays for further processing.
  - Checks for the existence of nodes and subcatchments, raising errors if necessary.

- **Building a Node Hash Map**
  - Iterates over node row objects.
  - Constructs a hash map where keys are coordinate pairs `[x, y]` and values are arrays of nodes at those coordinates.

- **Creating New Subcatchments**
  - Begins a transaction in the network.
  - For each unique coordinate group in the hash map:
    - Creates a new subcatchment object.
    - Sets the subcatchment's ID to the first node's ID from that group.
    - Sets its coordinates (x, y) and assigns a default total area.
    - Writes the new subcatchment to the network.
  - Commits the transaction to finalize the changes.

- **Reporting**
  - Prints the number of nodes, existing subcatchments, and the number of new subcatchments created.

- **Error Catching**
  - Handles exceptions by outputting an error message if any step fails.

Citations:
[1] https://github.com/chaitanyalakeshri/ruby_scripts