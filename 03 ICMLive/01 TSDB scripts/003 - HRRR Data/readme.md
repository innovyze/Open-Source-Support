Powershell script that downloads the HRRR weather forecast data for ICMLive.


To setup ICMLive to download hourly HRRR data, 
* create a script folder on the server
* create a data folder on the server
* update the hrrr.bat with the input (see the file for more information)
   * paths for script and data
   * bounding box for the area
 * setup the TSDB
   * the data format, etc
   * the auto update schedule
 * data will be downloaded to the "data" folder
   * icmlive when runs will load when all the 18 files are all ready, otherwise, it will skip all the files
   * hrrr.log in the data has the logging information
   * loaded data will be placed in the "loaded" folder

# TSDB

A sample TSDB is shown below.

![](images/hrrr_tsdb1.png)

The auto update setting.

![](images/hrrr_tsdb2.png)