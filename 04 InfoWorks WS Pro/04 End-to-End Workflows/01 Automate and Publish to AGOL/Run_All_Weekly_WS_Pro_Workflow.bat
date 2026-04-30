@echo off
REM =============================================================================
REM  WS Pro → ArcGIS Online: Weekly Automation Workflow
REM =============================================================================
REM
REM  Runs all three steps in sequence:
REM    1. Create and run a weekly WS Pro simulation
REM    2. Export maximum results to a flat shapefile ZIP
REM    3. Publish the ZIP to ArcGIS Online as a hosted feature layer
REM
REM  CONFIGURATION: edit the values in the section below before running.
REM =============================================================================

REM --- PATHS (edit these) ------------------------------------------------------

REM Full path to WSProExchange.exe (adjust version year if needed)
set "EXCHANGE=C:\Program Files\Autodesk\InfoWorks WS Pro 2026\WSProExchange.exe"

REM Full path to the folder containing these scripts
set "SCRIPTS_DIR=%~dp0"

REM Full path to Python 3 executable
set "PYTHON=py -3.12"

REM --- AGOL CREDENTIALS (edit these) ------------------------------------------

set "AGOL_URL=https://www.arcgis.com"
set "AGOL_USERNAME=your.username@example.com"
set "AGOL_PASSWORD=your_password_here"

REM =============================================================================
REM  DO NOT EDIT BELOW THIS LINE
REM =============================================================================

echo.
echo ========== 1. Create and run weekly WS Pro simulation ==========
"%EXCHANGE%" "%SCRIPTS_DIR%WS_Pro_Create_and_Run_Weekly_Simulation.rb" /WS
if errorlevel 1 (
    echo ERROR: Step 1 failed. Aborting workflow.
    pause
    exit /b 1
)

echo.
echo ========== 2. Export simulation results to shapefiles ==========
"%EXCHANGE%" "%SCRIPTS_DIR%WS_Pro_Export_Simulation_Results_to_Shapefile.rb" /WS
if errorlevel 1 (
    echo ERROR: Step 2 failed. Aborting workflow.
    pause
    exit /b 1
)

echo.
echo ========== 3. Publish shapefiles to ArcGIS Online ==========
%PYTHON% "%SCRIPTS_DIR%Publish_WS_Pro_Weekly_Shapefiles_to_AGOL.py"
if errorlevel 1 (
    echo WARNING: Step 3 completed with errors.
)

echo.
echo ========== Workflow complete ==========
pause
