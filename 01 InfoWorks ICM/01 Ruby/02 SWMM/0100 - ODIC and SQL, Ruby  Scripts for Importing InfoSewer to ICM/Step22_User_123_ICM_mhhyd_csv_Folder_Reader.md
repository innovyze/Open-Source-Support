# Ruby Script for Importing InfoSewer Data to ICM InfoWorks

## Overview

This Ruby script is designed to import manhole load data from a CSV file, typically representing an InfoSewer scenario, into an open network in ICM InfoWorks. It further calculates and prints statistical data for various properties of SWMM network nodes.

## Key Components

### Methods

#### `print_csv_inflows_file(open_net)`

- **Purpose**: Calculates and prints statistical data (minimum, maximum, mean, standard deviation, total, and row count) for selected properties of SWMM network nodes.
- **Parameters**:
  - `open_net`: The current open network in the ICM application.
- **Database Fields Analyzed**:
  - Ground Level, Flood Level, Chamber Area, Shaft Area, User Numbers 1 through 10.

#### `import_node_loads(open_net)`

- **Purpose**: Imports manhole load data from a specified CSV file into the open network's `hw_node` and `hw_subcatchment` objects.
- **Parameters**:
  - `open_net`: The current open network in the ICM application.
- **User Prompt**: Asks for the scenario name that matches the InfoSewer dataset and the folder containing the CSV file (`mhhyd.csv`).
- **Data Imported**:
  - ID, Diameter, Rim Elevation, Loads 1 through 10, and Patterns 1 through 10.

### Workflow

1. **Initialization**: The script starts by accessing the current open network in ICM InfoWorks using `WSApplication.current_network`.
2. **Data Import**:
   - Prompts the user to select the InfoSewer dataset scenario and the manhole folder containing the CSV file.
   - Reads the CSV file and imports data into the `hw_node` and `hw_subcatchment` objects based on matching IDs.
3. **Statistical Analysis**:
   - Calls `print_csv_inflows_file` to perform statistical analysis on selected fields from the `hw_node` objects.
4. **Transaction Handling**:
   - Uses `transaction_begin` and `transaction_commit` to ensure the data import process is treated as a single transaction.
5. **Completion**:
   - Prints a confirmation message indicating the successful import of InfoSewer data to ICM InfoWorks.

## Additional Notes

- The script uses Ruby's `CSV` library to parse and process data from the CSV file.
- Provides interactive user prompts using `WSApplication.prompt` to gather necessary inputs.
- Ensures robust data handling and user feedback throughout the process.
