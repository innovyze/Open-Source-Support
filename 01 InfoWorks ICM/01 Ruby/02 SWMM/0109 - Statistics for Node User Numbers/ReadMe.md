# Ruby Code to Print CSV Node Stats 

## Overview
This code analyzes and prints statistics of Node data from a InfoWoprks network CSV file.

## Functionality  
- Gets inflow data fields from SWMM nodes 
- Stores data for each field in hash
- Calculates statistics:
  - Minimum 
  - Maximum
  - Mean 
  - Standard deviation
  - Total
  - Row count
- Prints statistics for each field

## Key Functions
- `row_objects()` - Gets node data   
- `clear_selection()` - Clears current selection
- `printf()` - Formats and prints stats

## Variables
- `database_fields` - List of inflow fields  
- `fields_data` - Hash storing field data
- `row_count` - Tracks rows processed

## Output
Printed statistics for each node field including min, max, mean, standard deviation, total value, and row count.

____________________________________________________________________________________________________________________________

# Ruby Code to Print SWMM Node Stats

## Overview
This code analyzes and prints statistics of node data from a SWMM network CSV file. 

## Functionality
- Gets node data fields from SWMM nodes
- Stores data for each field in hash 
- Calculates statistics:
  - Minimum
  - Maximum 
  - Mean
  - Standard deviation
  - Total 
  - Row count
- Prints statistics for each field  

## Key Functions  
- `row_objects()` - Gets node data
- `clear_selection()` - Clears selection
- `printf()` - Prints formatted stats

## Variables
- `database_fields` - List of node fields
- `fields_data` - Hash storing field data 
- `row_count` - Tracks rows processed  

## Output
Printed statistics for each node field including min, max, mean, standard deviation, total value, and row count.