# Flow Monitor Input Dialog Box Script

This script is used to manage flow monitors in an InfoWorks ICM model network. It selects all upstream nodes and links for each flow monitor link and saves the selection to a model group or master group.

## How it Works

1. The script first accesses the current network.

2. It then defines a method `ustrace` that takes a link as an argument and returns an array of all upstream nodes and links for that link.

3. The script prompts the user to enter the ID of the master group or model group where the selection list will be saved, and whether the ID is for a master group or model group.

4. The script accesses the current database and gets the model object for the entered ID.

5. It gets the current selection of links in the network and marks each link as seen.

6. For each link in the selection, the script clears the current selection, gets the upstream nodes and links using the `ustrace` method, and selects each upstream node and link.

7. The script also selects all upstream subcatchments that drain to the selected nodes.

8. Finally, the script saves the selection to a new selection list in the specified model group or master group, and clears the current selection.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically prompt you to enter the ID of the master group or model group where the selection list will be saved, and whether the ID is for a master group or model group. The script will then select all upstream nodes and links for each flow monitor link and save the selection to the specified group.

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks.