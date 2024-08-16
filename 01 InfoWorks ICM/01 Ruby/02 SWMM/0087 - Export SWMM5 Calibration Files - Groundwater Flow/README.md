
# Code Summary: Generating Subcatchment Runoff Data for SWMM5 Calibration in InfoWorks

## Library Utilization
- The script employs the `date` library for handling time-related data.

## Script Overview
- It begins by accessing the current network object in InfoWorks and retrieves the list of available timesteps.

## Key Functionalities
1. **Timestep Validation**:
   - Ensures that there are more than one timestep available before proceeding. If not, outputs a warning and exits the script.

2. **Time Interval Calculation**:
   - Calculates the time interval between timesteps in seconds, assuming an even distribution.

3. **Runoff Data Processing for SWMM5**:
   - Sets 'RUNOFF' as the result field name to be extracted.
   - Prints headers formatted for the SWMM5 calibration file.
   - Iterates over each selected subcatchment in the network:
     - Attempts to retrieve the corresponding row object using the subcatchment id.
     - Skips iterations for non-relevant objects (not a subcatchment).
     - Processes runoff results for each timestep.
     - Calculates the exact time for each result and converts it into days, hours, and minutes format.
     - Outputs formatted data, suitable for inclusion in a SWMM5 calibration file.

4. **Error Handling**:
   - Implements error handling to manage and report any issues encountered during data processing.

## Summary
This script is a vital tool for preparing subcatchment runoff data from an InfoWorks network for SWMM5 calibration. It ensures that the runoff data is accurately timed and formatted in accordance with SWMM5's requirements, aiding hydraulic modelers in their calibration efforts. The script's systematic approach and clear output format make it highly effective for integrating InfoWorks data into SWMM5 models.
