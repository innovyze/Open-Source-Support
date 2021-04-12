# NOAA data download script
This script downloads data from NOAA via a REST API into Simple CSV format that can be used in ICMLive TSDBs.

In this example, the following data types are downloaded for a number of sites:
* observed tide levels from specified NOAA sites
* predicted tide levels for specified NOAA sites

More sites can be easily added to the list, as well as different product codes.
The code is run by calling the `Get-Data` function with parameters relative to the gauges that are required to be downloaded.
Times can come from NOAA in different timezones, but are downloaded as GMT for consistency in ICMLive.