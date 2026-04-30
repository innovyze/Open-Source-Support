@echo off
REM =============================================================================
REM  ICM → ArcGIS Online: Daily Automation Workflow
REM =============================================================================
REM
REM  Runs all four steps in sequence:
REM    1. Download NWS rainfall data and optionally import to ICM
REM    2. Create and run 24h and 48h ICM simulations
REM    3. Export simulation results to shapefiles (24h.zip, 48h.zip)
REM    4. Publish shapefiles to ArcGIS Online as hosted feature layers
REM
REM  CONFIGURATION: edit the values in the section below before running.
REM =============================================================================

REM --- PATHS (edit these) ------------------------------------------------------

REM Full path to ICMExchange.exe (adjust version year if needed)
set "EXCHANGE=C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2026\ICMExchange.exe"

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
echo ========== 1. Download NWS rainfall data ==========
"%EXCHANGE%" "%SCRIPTS_DIR%Download_NWS_Rainfall.rb" /ICM
if errorlevel 1 (
    echo ERROR: Step 1 failed. Aborting workflow.
    pause
    exit /b 1
)

echo.
echo ========== 2. Create and run ICM simulations ==========
"%EXCHANGE%" "%SCRIPTS_DIR%Create and Run Simulations.rb" /ICM
if errorlevel 1 (
    echo ERROR: Step 2 failed. Aborting workflow.
    pause
    exit /b 1
)

echo.
echo ========== 3. Export 2D ICM results to shapefiles ==========
"%EXCHANGE%" "%SCRIPTS_DIR%Export 2D ICM Results.rb" /ICM
if errorlevel 1 (
    echo ERROR: Step 3 failed. Aborting workflow.
    pause
    exit /b 1
)

echo.
echo ========== 4. Publish shapefiles to ArcGIS Online ==========
%PYTHON% "%SCRIPTS_DIR%Publish_Shapefiles_to_AGOL.py"
if errorlevel 1 (
    echo WARNING: Step 4 completed with errors.
)

echo.
echo ========== Workflow complete ==========
pause
