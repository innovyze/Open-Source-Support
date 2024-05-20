# Export to geodatabase (gdb)

This script exports selected network data to a Geodatabase (GDB) file using the Open Data Export Center (ODEC) of the WSApplication.

## How it Works

1. The script first accesses the current network of data.
2. It sets the options for the ODEC, specifically:
    - It sets the units to be used to 'User'.
    - It enables the option to export only selected network data.
    - It specifies the location and name of the Geodatabase file to which the data will be exported.
    - It also specifies the location and name of the configuration file to use for the export.
    - It specifies the Feature Class and Feature Dataset to use in the export.
3. It then calls the 'odecexportex' method of the network object to perform the export with the specified parameters.
4. Finally, it prints a message to let the user know that the selected objects have been exported.