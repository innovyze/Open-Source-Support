@echo off
REM ===================================================================
REM ICMExchange Rainfall Event Export/Import Script Launcher
REM ===================================================================

REM Set the ICMExchange executable path (adjust if needed)
set ICMEXCHANGE=C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2026\ICMExchange.exe

REM Get the directory where this batch file is located
set SCRIPT_DIR=%~dp0

REM Display menu
echo ===================================================================
echo   RAINFALL EVENT EXPORT/IMPORT SCRIPT LAUNCHER
echo ===================================================================
echo.
echo   1. Export Rainfall Events to CSV
echo   2. Import Rainfall Events from CSV
echo   3. Exit
echo.
echo ===================================================================

REM Get user choice
set /p CHOICE="Enter your choice (1, 2, or 3): "

if "%CHOICE%"=="1" goto EXPORT
if "%CHOICE%"=="2" goto IMPORT
if "%CHOICE%"=="3" goto END

echo Invalid choice. Please run the script again and select 1, 2, or 3.
pause
goto END

:EXPORT
echo.
echo Starting Export Script...
echo.
"%ICMEXCHANGE%" "%SCRIPT_DIR%hw_export_rainfall_events_to_csv.rb"
echo.
pause
goto END

:IMPORT
echo.
echo Starting Import Script...
echo.
"%ICMEXCHANGE%" "%SCRIPT_DIR%hw_import_rainfall_events_from_csv.rb"
echo.
pause
goto END

:END
