@echo off
rem This script lists all subfolders in a directory and saves them to a log file.

set "DIRECTORY=C:\Users\dickinre\Documents\Open-Source-Support-main\01 InfoWorks ICM\InfoSewer to ICM\Open-Source-Support\01 InfoWorks ICM\01 Ruby\02 SWMM"
set "LOGFILE=subfolders_list.log"

echo Listing subfolders in %DIRECTORY%...
dir "%DIRECTORY%" /AD /B /S > "%LOGFILE%"

echo The list of subfolders has been saved to %LOGFILE%.