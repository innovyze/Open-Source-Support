# Run Parameters Retrieval Script

This script retrieves all parameters from a specified run in an InfoWorks ICM model.

## How it Works

1. The script first defines a method `retrieve_run_parameters` that takes a run ID as an argument.

2. Inside this method, it opens the current database and gets the model object for the specified run.

3. It then initializes an empty hash to store the parameters.

4. The script iterates over each field in the list of read/write run fields, adding each field and its value in the specified run to the parameters hash.

5. Finally, the method returns the parameters hash.

6. Outside the method, the script specifies a run ID and calls the `retrieve_run_parameters` method with this run ID, printing the returned parameters hash.

## Usage

To use this script, simply run it in the context of an open database in InfoWorks ICM. You will need to specify the run ID in the `run_id` variable. The script will then retrieve all parameters from the specified run and print them.

## Naming Convention

The naming convention for tables in InfoWorks ICM is different. Instead of starting with sw_, tables in ICM usually start with hw_ (for "HydroWorks", the original name of InfoWorks ICM). The field names within these tables can also be different between SWMM and ICM.  Ruby code with the prefix hw_sw can be used in both ICM InfoWorks and SWMM Networks.