@echo off
set version=2025
set script=Copy_all_to_new_Transportable.rb

echo Running Autodesk InfoWorks ICM Exchange with script: %~dp0%script%
"C:\Program Files\Autodesk\InfoWorks ICM Ultimate %version%\ICMExchange" "%~dp0%script%" /ICM
PAUSE