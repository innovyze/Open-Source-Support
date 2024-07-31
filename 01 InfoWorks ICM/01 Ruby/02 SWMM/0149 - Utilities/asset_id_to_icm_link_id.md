Here's a markdown summary of the provided code:

```markdown
# ID Conversion Tool for Network Conduits

## Overview
This script converts a list of asset IDs to a new format based on upstream node IDs and link suffixes for network conduits.

## Key Components

1. **Input Processing**
   - Starts with a tab-separated string of IDs with units (e.g., "1 (mgd)")
   - Splits the input string and removes the "Time" header

2. **Network Access**
   - Uses `WSApplication.current_network` to access the current network

3. **ID Conversion Process**
   - Loops through each input ID:
     - Removes the " (mgd)" unit
     - Searches the network's hw_conduit collection
     - Matches the asset_id with the input ID
     - Creates a new ID format: "upstream_node_id.link_suffix"

4. **Output**
   - Prints each converted ID on a new line

## Conversion Logic
- Old format: "asset_id (mgd)"
- New format: "upstream_node_id.link_suffix"

## Note
The script assumes that the input IDs correspond to asset IDs in the hw_conduit collection of the current network.
```