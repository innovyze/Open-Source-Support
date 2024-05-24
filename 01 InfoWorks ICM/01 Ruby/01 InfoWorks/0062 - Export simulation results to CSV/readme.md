# Export Simulation Results to CSV

This script exports simulation results from a selected table in the currently open network of your application to a CSV file. The results are customized for both simulations that start at time 0 and those that start at real dates.

## How It Works

The script exports data from the currently open network within your application, generating a CSV file and populates it with data extracted from the selected table. The CSV file is created in the 'D:/CSV/' directory with a name based on the field being processed.

**Key Points:**

- The script accesses the selected table from the network within the application.
- It then generates a CSV file and populates it with data extracted from the selected table.
- The CSV file is created in the 'D:/CSV/' directory with the network's name and the field being processed.
- The directory 'D:/CSV/' might need to be altered to a different directory depending on your system configuration and where you intend to store the CSV file.