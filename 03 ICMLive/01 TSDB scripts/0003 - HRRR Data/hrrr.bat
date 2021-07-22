@echo off
rem set the script path
set psscriptpath=C:\Users\Mel.Meng\Documents\azure\innovyze_repo\innovyze\source\icmlive\hrrr
rem set the bounding box of the HRRR area
set Lonmin=-97.5
set Lonmax=-96.9
set Latmin=49.7
set Latmax=50
rem make sure to have two traling slashes
rem eg. set LocalPath=C:\Users\Mel.Meng\Innovyze, INC\ICMLive Implementation Projects - Documents\Winnipeg\tasks\HRRR Script\data\\
set LocalPath=C:\Users\Mel.Meng\Documents\azure\innovyze_repo\innovyze\source\icmlive\hrrr\data\\
rem somehow I need to echo this to get the values assigned before running powershell
echo -WindowStyle Hidden -File "%psscriptpath%"\HRRR.ps1 -Lon_min %Lonmin% -Lon_max %Lonmax% -Lat_min %Latmin% -Lat_max %Latmax% -Local_Path "%LocalPath%" 
Powershell.exe -WindowStyle Hidden -File "%psscriptpath%"\HRRR.ps1 -Lon_min %Lonmin% -Lon_max %Lonmax% -Lat_min %Latmin% -Lat_max %Latmax% -Local_Path "%LocalPath%" 
rem below is an example to load for a specific date time
rem set datetime=2021-07-17 01:00
rem echo "%psscriptpath%"\HRRR.ps1 -Lon_min %Lonmin% -Lon_max %Lonmax% -Lat_min %Latmin% -Lat_max %Latmax% -Local_Path "%LocalPath%" -datetime "%datetime%"
rem Powershell.exe -WindowStyle Hidden -File "%psscriptpath%"\HRRR.ps1 -Lon_min %Lonmin% -Lon_max %Lonmax% -Lat_min %Latmin% -Lat_max %Latmax% -Local_Path "%LocalPath%" -datetime "%datetime%"
