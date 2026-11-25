# Bifurcation Links Selection Script

This script selects all true bifurcation links in an InfoWorks ICM model network. A bifurcation link is a link that **leaves a node which has more than one outgoing link** (i.e. the node branches/splits flow into more than one downstream path).

Links that share both the same upstream (`us_node_id`) **and** downstream (`ds_node_id`) node as another link are parallel links (a loop between the same two nodes) rather than a true branch, so these are explicitly **excluded** from the selection.

The script works across all link types, since it reads from the generic `_links` table, which covers conduits, channels, orifices, pumps, sluices, etc.

## How it Works

1. The script first accesses the current network and clears any existing selection.

2. It creates an array of `[us_node_id, ds_node_id, link_id]` for every link in the network.

3. The links are grouped by their upstream (`us_node_id`). Any group containing more than one link means more than one link leaves that node — a candidate bifurcation point.

4. Within each candidate group, the links are further grouped by their downstream (`ds_node_id`). Any sub-group with more than one link shares the same us **and** ds node — these are parallel links, not a true bifurcation, and are omitted. Only links whose us/ds pair is unique within the group (i.e. they branch off to a different downstream path) are kept.

5. Finally, the script iterates over each link in the network. If a link's ID is in the filtered list, the script selects that link.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically select all true bifurcation links in the network, while ignoring parallel/looped links that merely share the same us and ds nodes.
