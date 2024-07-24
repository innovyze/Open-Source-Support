# Create Selection List from CSV

This Ruby script helps you create a selection list in your network from data stored in specific CSV files, specifically nodes, links, and/or subcatchments.

## Inputs You Need:

A Folder with Specific CSV Files: You'll be asked to select a folder on your computer. This folder should have one or more of the following CSV files, named exactly as:
- Nodes.csv
- Links.csv
- Subcatchments.csv

The script will work even if you only have one or two of these files.

Content in CSV Files: Each of these CSV files should have a list of IDs in a column. The column should be named Node ID for Nodes.csv, Link ID for Links.csv, and Subcatchment ID for Subcatchments.csv. For links, the IDs should be of format us_node_id.link_suffix.

## What The Script Does:

The script reads these CSV files, looks for the IDs you've listed, and then selects those entities (nodes, links, or subcatchments) in your network.

## Outputs You Get:

Selection List: After the script has done its job, you'll be asked to name your new selection list. If the name you choose is already taken, the script will add an '!' to the end of the name until it's unique.