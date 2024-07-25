# InfoSewer/InfoSWMM Scenario Import Script

## Overview
This Ruby script imports scenarios from InfoSewer or InfoSWMM into InfoWorks ICM.

## Key Components

### Required Libraries
- `csv`: For CSV file handling
- `pathname`: For file path operations

### Main Function: `import_scenario`
1. Prompts user to select IEDB or ISDB folder
2. Reads `scenario.csv` from selected folder
3. Processes CSV data, excluding certain headers
4. Allows optional custom ordering of scenarios

### Scenario Processing
1. Deletes all existing scenarios except 'Base'
2. Imports new scenarios from CSV data
3. Adds scenarios to the current network

## Workflow

1. **User Input**
   - Select folder containing scenario data
   - Optionally specify custom scenario order

2. **CSV Processing**
   - Reads `scenario.csv`
   - Excludes specified headers: "FAC_TYPE", "USECLIMATE", "USE_REPORT", "USE_OPTION", "PISLT_SET"
   - Prints processed row data

3. **Scenario Ordering**
   - Uses custom order if provided
   - Otherwise, maintains original order

4. **Network Updates**
   - Deletes existing scenarios (except 'Base')
   - Adds imported scenarios to the network
   - Skips 'BASE' scenario during import

5. **Output**
   - Prints added scenarios in order
   - Displays total count of added scenarios

## Usage
- Run within InfoWorks ICM environment
- Requires an open network (`WSApplication.current_network`)
- User interaction for folder selection and optional scenario ordering

This script automates the process of importing and organizing scenarios from InfoSewer or InfoSWMM into InfoWorks ICM, providing a streamlined workflow for scenario management.