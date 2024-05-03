# Trace network downstream or upstream of selected object
These scripts allow tracing all assets upstream or downstream of a selected node or link.
## Version 1 - Trace network downstream of selected node
![](gif001.gif)
## Version 2 - Trace network upstread of selected node
![](gif002.gif)
## Version 3 - Trace network downstream of selected link
![](gif003.gif)
## Version 4 - Trace network upstread of selected link
![](gif004.gif) 
 
# Ruby Script for Selecting Unprocessed Links in InfoWorks ICM - version 1

This Ruby script is used to select unprocessed links in the InfoWorks ICM software. Here's a summary of what it does:

- It first sets up the current network (`net`) and retrieves the current selection of nodes (`roc`).

- It initializes an empty array (`unprocessedLinks`) to hold the unprocessed links.

- It then iterates over each node in the selection.

- For each node, it iterates over each downstream link (`ds_links`).

- If a link has not been seen (processed) before, it adds the link to the `unprocessedLinks` array and marks it as seen.

- It then enters a loop that continues until all links have been processed.

- In each iteration of the loop, it removes the first link from `unprocessedLinks` and marks it as selected.

- It retrieves the downstream node of the link.

- If the downstream node exists and has not been seen before, it marks the node as selected.

- It then iterates over each downstream link of the node.

- If a link has not been seen before, it adds the link to `unprocessedLinks`, marks it as selected, and marks it as seen.

- This process continues until all links have been processed.