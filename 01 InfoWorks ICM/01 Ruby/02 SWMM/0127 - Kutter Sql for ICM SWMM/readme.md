# Kutter's Formula Calculation Script for InfoWorks ICM

This script calculates the full, 3/4, and 1/2 pipe capacities using Kutter's formula and compares them with the capacity calculated by InfoWorks ICM.

## How it Works

1. The script first defines the Kutter's formula for full pipe capacity, 3/4 pipe capacity, and 1/2 pipe capacity. The formula is based on the pipe's diameter, slope, and Manning's roughness coefficient.

2. It then sets the `user_number_1`, `user_number_2`, and `user_number_3` variables to the calculated full, 3/4, and 1/2 pipe capacities, respectively.

3. Finally, the script selects the pipe's diameter, slope, Manning's roughness coefficient, ICM calculated capacity, and the calculated full, 3/4, and 1/2 pipe capacities. It groups the results by the pipe's ID.



## Usage

To use this script, simply run it in the context of an open database in InfoWorks ICM. The script will automatically calculate the full, 3/4, and 1/2 pipe capacities using Kutter's formula, 
compare them with the capacity calculated by InfoWorks ICM, and select the results.



  Here is a Markdown summary of the Ruby code:

# Ruby Code to Calculate Link Capacities

## Overview
This code calculates full, 3/4, and 1/2 depth capacities for links in an InfoWorks network using Kutter's formula. It compares to the ICM calculated capacities.

## Functionality
- Loops through all links
- Retrieves properties: 
  - Height
  - Slope 
  - Roughness
- Calculates Kutter's capacities at:
  - Full depth
  - 3/4 depth
  - 1/2 depth
- Retrieves ICM calculated capacity 
- Prints comparison table

## Formulas 
- Kutter's formula used to calculate capacities
- Depth ratios used for 3/4 and 1/2 depth capacities

## Output
- Printed table comparing ICM vs. Kutter's calculated link capacities at various depths  

## Key Methods
- `row_objects()` - Gets links
- `Capacity` - Gets ICM capacity

![Alt text](diagram(3).png)