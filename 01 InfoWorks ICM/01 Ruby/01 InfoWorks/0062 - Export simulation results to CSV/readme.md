# Export Simulation Results to CSV

This script exports simulation results from a selected table in the currently open network of your application to a CSV file. The results are customized for both simulations that start at time 0 and those that start at real dates.

## How It Works

The script exports data from the currently open network within your application, generating a CSV file and populates it with data extracted from the selected table. The CSV file is created in the 'D:/CSV/' directory with a name based on the field being processed.

**Key Points:**

- The script accesses the selected table from the network within the application.
- It then generates a CSV file and populates it with data extracted from the selected table.
- The CSV file is created in the 'D:/CSV/' directory with the network's name and the field being processed.
- The directory 'D:/CSV/' might need to be altered to a different directory depending on your system configuration and where you intend to store the CSV file.

![alt text](image.png)

## Summary
This script exports the results of a simulation from a network model in InfoWorks ICM to CSV files. The user is prompted to select a folder where the CSV files will be saved. The script then iterates over each field (e.g., 'us_flow', 'ds_flow', etc.) and each timestep, and writes the result values for each selected row object to the CSV file.

The script uses the WSApplication class to interact with the InfoWorks ICM application. It accesses the currently open network, gets the selected row objects from the '_links' table, and retrieves the timesteps for the network. The script also checks if the simulation starts at time 0 or a real date, and formats the time accordingly.

The script uses the File class to write the CSV content to the file. It opens the file in write mode, writes the CSV content, and then closes the file. The script also prints a confirmation message after each file is written.

This script is a useful tool for exporting simulation results to a more accessible format, which can then be used for further analysis or visualization.