# InfoWorks ICM User Fields Export Script

## Purpose
This script exports user fields from specified tables in an InfoWorks ICM network model to CSV files.

## Key Features
- Exports data from `hw_node`, `hw_conduit`, and `hw_subcatchment` tables
- Allows user to specify the export folder
- Includes optional user description in file names
- Dynamically determines the appropriate ID field for each table
- Exports both numeric and text user fields (user_number_1 to user_number_10 and user_text_1 to user_text_10)

## Process
1. Prompts user for export folder and optional description
2. Iterates through each specified table
3. Creates a CSV file for each table with appropriate headers
4. Writes data rows including ID and all user fields
5. Provides runtime information

## Output
- Generates separate CSV files for each table
- File naming convention: `[network_name]_[table_name]_[user_description].csv`

## Notes
- Uses Ruby's CSV library for file operations
- Leverages WSApplication methods for network interaction
- Includes error handling and informative console output

## Runtime
The script provides execution time information upon completion.