# USGS data download script
This script downloads data from USGS via a REST API into Simple CSV format that can be used to feed ICM Live TSDBs.

In this example, the following types are downloaded for a number of sites:
* Observed tidal
* Observed levels
* Observed rainfall

These can be easily added to the list, alongside parameter codes.
The code is run by calling the `Get-Data` function with parameters relative to the gauges that are required to be downloaded.
Times are determined by USGS as the site local time, but are all converted to UTC+00 by the script for consistency.
