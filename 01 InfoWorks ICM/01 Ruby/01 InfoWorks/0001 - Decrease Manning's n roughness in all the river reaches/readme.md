# Roughness Adjustment Script

This script adjusts the roughness of all river reaches in an InfoWorks ICM model network by decreasing it by 20%.

## How it Works

1. The script first accesses the current network and sets the current scenario to 'Roughness -20%'.

2. It then clears any existing selection and begins a transaction.

3. The script iterates over each river reach in the network. For each river reach, it iterates over each section and decreases the roughness (`roughness_N`) by 20%.

4. After adjusting the roughness of all sections in a river reach, the script writes the changes to the sections and the river reach.

5. Once all river reaches have been processed, the script commits the transaction.

6. Finally, the script prints a message indicating that the roughness has been decreased by 20% and commits the changes to the network with a description of the changes.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically decrease the roughness of all river reaches by 20% and commit the changes to the network.

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks