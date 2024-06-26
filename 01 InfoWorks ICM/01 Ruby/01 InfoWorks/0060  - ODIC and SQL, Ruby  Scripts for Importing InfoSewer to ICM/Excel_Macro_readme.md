# Summary:
This macro converts Excel files with the ".dbf" extension located in a specified folder to CSV format and saves them in another specified folder. The macro disables screen updating, events, automatic calculations, and alerts during execution to improve performance and avoid interruptions. It prompts the user to select the source and destination folders using file dialog boxes. Then, it loops through all the ".dbf" files in the source folder, opens them one by one, saves them as CSV files in the destination folder, and closes them without saving changes.

## Overview

This VBA macro converts Excel files with the ".dbf" extension located in a specified source folder to CSV format. The CSV files are saved to a specified destination folder.

## Functionality

- Disables screen updating, events, automatic calculations, and alerts during execution to improve performance
- Prompts user to select source and destination folders via file dialog boxes
- Loops through all ".dbf" files in source folder
  - Opens each ".dbf" file
  - Saves as a CSV file in destination folder, named based on ".dbf" name
  - Closes file without saving changes
- Restores application settings after conversion

## Key Objects & Variables

- `Workbook (xObjWB)` - Represents each ".dbf" file  
- `String (xStrEFPath)` - Source folder path
- `String (xStrSPath)` - Destination folder path 
- `FileDialog (xObjFD)` - Select source folder
- `FileDialog (xObjSFD)` - Select destination folder

## Output

- All ".dbf" Excel files in source folder converted to CSV format
- CSV versions saved to selected destination folder