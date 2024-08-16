# SUDS Control Data Exporter Script

This script exports SUDS (Sustainable Urban Drainage Systems) control data from each subcatchment in an InfoWorks ICM model to a CSV file.

## How it Works

1. The script first prompts the user to enter the output folder where the CSV file will be saved.

2. It then defines the header row for the CSV file, which includes the names of all the SUDS control properties that will be exported.

3. The script iterates over each subcatchment in the network. For each subcatchment, it iterates over each SUDS control and adds a new row to the CSV data array. Each row includes the subcatchment ID and the properties of the SUDS control.

4. Finally, the script opens the specified CSV file and writes the CSV data array to the file.

## Usage

To use this script, simply run it in the context of an open network in InfoWorks ICM. The script will automatically prompt you to enter the output folder where the CSV file will be saved. The script will then export the SUDS control data from each subcatchment to the CSV file.

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks