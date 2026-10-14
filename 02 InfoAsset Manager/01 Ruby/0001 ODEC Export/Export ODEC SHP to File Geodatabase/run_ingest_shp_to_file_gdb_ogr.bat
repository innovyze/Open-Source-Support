@echo off
setlocal EnableExtensions
REM Ingest staging shapefiles to File GDB using GDAL ogr2ogr (no ArcGIS Pro).
REM Edit paths below if your QGIS version or install folder differs.

set "QGIS_ROOT=C:\Program Files\QGIS 4.0.3"
set "SCRIPT_DIR=%~dp0"
set "STAGING=%SCRIPT_DIR%staging_shp"
set "GDB=C:\Temp\IAMFullSync.gdb"

echo.
echo === GDAL File Geodatabase ingest ===
echo Staging: %STAGING%
echo Output:  %GDB%
echo.

if not exist "%STAGING%\node.shp" (
  if not exist "%STAGING%\node.SHP" (
    echo ERROR: No staging shapefiles found under:
    echo   %STAGING%
    echo Run the IAM ODEC shapefile export first.
    goto :failed
  )
)

set "OGR2OGR="
if exist "%QGIS_ROOT%\bin\o4w_env.bat" (
  echo Initialising QGIS/OSGeo4W environment: %QGIS_ROOT%
  call "%QGIS_ROOT%\bin\o4w_env.bat"
  if exist "%QGIS_ROOT%\bin\ogr2ogr.exe" set "OGR2OGR=%QGIS_ROOT%\bin\ogr2ogr.exe"
)

if not defined OGR2OGR where ogr2ogr >nul 2>&1 && set "OGR2OGR=ogr2ogr"
if not defined OGR2OGR if exist "C:\OSGeo4W\bin\ogr2ogr.exe" (
  call "C:\OSGeo4W\bin\o4w_env.bat" 2>nul
  set "OGR2OGR=C:\OSGeo4W\bin\ogr2ogr.exe"
)

if not defined OGR2OGR (
  echo ERROR: Could not find ogr2ogr.
  echo Set QGIS_ROOT at the top of this batch file to your QGIS install folder.
  goto :failed
)

echo Using: %OGR2OGR%
if exist "%GDB%" (
  echo Removing existing geodatabase...
  rmdir /s /q "%GDB%"
)

set "NODE_SHP=%STAGING%\node.shp"
if not exist "%NODE_SHP%" set "NODE_SHP=%STAGING%\node.SHP"
set "PIPE_SHP=%STAGING%\pipe.shp"
if not exist "%PIPE_SHP%" set "PIPE_SHP=%STAGING%\pipe.SHP"

echo Loading Node...
"%OGR2OGR%" -f OpenFileGDB "%GDB%" "%NODE_SHP%" -nln Node -overwrite
if errorlevel 1 goto :failed

echo Loading Pipe...
"%OGR2OGR%" -f OpenFileGDB -update "%GDB%" "%PIPE_SHP%" -nln Pipe -overwrite
if errorlevel 1 goto :failed

goto :success

:success
echo.
echo Done: %GDB%
pause
exit /b 0

:failed
echo.
echo Ingest failed. See messages above.
pause
exit /b 1
