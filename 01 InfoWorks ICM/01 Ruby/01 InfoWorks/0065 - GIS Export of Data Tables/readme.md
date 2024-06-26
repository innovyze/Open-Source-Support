# hw_UI-GIS_export.rb

This script is an interface script for exporting to a GIS file via the `GIS_export` method.

## Overview

1. The script first retrieves the current network using `WSApplication.current_network` and stores the network's name.

2. It then defines an array `export_tables` that contains the names of the tables to be exported for ICM InfoWorks.

3. A hash `exp_options` is created to override the default export options. The options include 'ExportFlags', 'SkipEmptyTables', and 'Tables'. The 'Tables' option is set to the `export_tables` array.

4. The script prompts the user to pick a folder for the export of ICM InfoWorks SHP files. The chosen folder path is stored in `folder_path`.

5. Finally, the `GIS_export` method is called on the current network to export the data. The method takes three arguments: the format ('SHP'), the export options (`exp_options`), and the destination folder (`folder_path`).
