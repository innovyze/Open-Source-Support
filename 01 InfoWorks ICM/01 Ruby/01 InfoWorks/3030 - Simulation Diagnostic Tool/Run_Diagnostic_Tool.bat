@echo off
REM Batch file to run Initialization Phase-In Diagnostic Tool via Exchange
REM This script launches InfoWorks ICM Exchange and runs the diagnostic tool

set "ICM_PATH=C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2026\ICMExchange.exe"
set "SCRIPT_PATH=%~dp0EX_Script.rb"

echo ================================================================================
echo Initialization Phase-In Diagnostic Tool
echo ================================================================================
echo.
echo Script path: %SCRIPT_PATH%
echo ICM Exchange: %ICM_PATH%
echo.
echo This will launch InfoWorks ICM Exchange to analyze simulation logs.
echo.
set /p SIM_ID="Enter Simulation ID: "
echo.
echo Processing Simulation ID: %SIM_ID%
echo.

REM Write simulation ID to temporary file for the script to read
echo %SIM_ID% > "%TEMP%\icm_sim_id.txt"

"%ICM_PATH%" "%SCRIPT_PATH%"

REM Clean up temporary file
del "%TEMP%\icm_sim_id.txt" 2>nul

echo.
echo ================================================================================
echo Script execution completed. Press any key to close this window.
pause > nul
