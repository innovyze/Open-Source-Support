# InfoSewer to ICM InfoWorks Import Script using OCIC

This script automates the process of importing data from InfoSewer to ICM InfoWorks.

## Steps

1. The script first accesses the currently open network in the application.

2. It then prompts the user to select two folders:
   - The InfoSewer IEDB folder, which contains the CSV files to be imported.
   - The InfoSewer CFG file folder, which contains the configuration files for the import.

3. The script defines a list of import steps. Each step is an array that includes the layer name, the configuration file name, and the CSV file name.

4. The script then iterates over each import step. For each step, it:
   - Imports the data from the CSV file to the specified layer using the specified configuration file.
   - Prints a message indicating that the layer has been imported.
   - If an error occurs during the import, it catches the error and prints an error message.

5. Finally, the script prints a message indicating that the import process is finished.