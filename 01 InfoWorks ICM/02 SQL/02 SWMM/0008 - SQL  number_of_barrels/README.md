# InfoWorks Networks
These SQLs are intended to work with the ICM InfoWorks 

# Number of Barrels Adjustment Script for InfoWorks ICM

This SQL script adjusts the number of barrels for all links in an InfoWorks ICM model network. It specifically targets links with a number of barrels set to 0.

## How it Works

The script operates in one main step:

1. **Number of Barrels Adjustment**: The script updates the 'number_of_barrels' field to 1 for all links where 'number_of_barrels' is equal to 0. This ensures that all links have at least one barrel.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically adjust the number of barrels for all links where the current number of barrels is 0.

![Alt text](image.png)