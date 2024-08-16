# InfoWorks to SWMM5 Calibration File Generator

This script generates a SWMM5 Calibration file from an InfoWorks network.

## How it works

1. The script first imports the 'date' library and gets the current network object from InfoWorks.
2. It retrieves the list of timesteps and ensures there's more than one timestep before proceeding.
3. The script calculates the time interval in seconds assuming the time steps are evenly spaced.
4. It defines the result field name as 'RUNOFF'.
5. The script outputs the headers for the SWMM5 Calibration File.
6. It then iterates through the selected objects in the network.
7. For each selected object, the script tries to get the row object for the current link using the upstream node id.
8. If the row object is not a link, it skips the iteration.
9. The script uses the Asset ID in a puts statement for the SWMM5 Calibration file.
10. It gets the results for the specified field.
11. If the results size matches the timesteps size, it iterates through the results and updates statistics.
12. For each result, it calculates the exact time for this result.
13. The script then calculates the number of days, hours, and minutes from the current time.
14. It outputs the formatted data for SWMM5.
15. If the results size doesn't match the timesteps size, it outputs a mismatch error message.
16. If any error occurs during processing an object, it outputs an error message.

## Error Handling

The script has built-in error handling. If any error occurs during processing an object, it outputs an error message with the ID of the object and the field that caused the error.