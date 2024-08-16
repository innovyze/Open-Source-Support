# Transfer conduit user defined headloss parameters between networks

This script series exports to CSV the headloss parameters from the user defined defaults conduit table in an open model network. It then imports the parameters from the CSV to the defaults table in another model network.

## How it Works

### Script 1: Exporting Data to CSV
The first script exports data from the 'hw_conduit_defaults' table in the currently open network of your InfoWorks ICM application to a CSV file.

**Key Points:**

- The script accesses the 'hw_conduit_defaults' table in the currently open network within InfoWorks ICM.
- It then generates a CSV file and populates it with data extracted from the 'hw_conduit_defaults' table.
- The CSV file is created in the 'D:/' directory under the name 'conduit_defaults.csv'.
- Please note that the directory 'D:/' might need to be altered to a different directory depending on your system configuration and where you intend to store the CSV file.

### Script 2: Importing Data from CSV
The second script imports data from a CSV file back into the 'hw_conduit_defaults' table in InfoWorks ICM.

**Key Points:**

- The script opens the CSV file located at 'D:/conduit_defaults.csv'. This is the same file that was created by the first script.
- For each row in the CSV file, the script locates the corresponding row in the 'hw_conduit_defaults' table and updates the fields with the values from the CSV row.
- A confirmation message is then printed to the console to indicate successful completion of the operation.

**Important:**

- If the CSV file is located in a different directory or has a different name, the directory 'D:/' and the file name 'conduit_defaults.csv' should be updated accordingly in the script.
- The script operates under the assumption that the CSV file exists and contains the correct data. If the file does not exist or the data is not as expected, the script might not function properly.