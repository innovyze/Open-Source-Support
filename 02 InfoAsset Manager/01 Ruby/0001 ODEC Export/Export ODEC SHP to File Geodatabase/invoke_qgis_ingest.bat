@echo off
setlocal EnableExtensions
REM Called from IAM Ruby UI/IE QGIS scripts. Args: staging_folder output.gdb [QGIS_ROOT]
REM Writes messages to staging_folder\qgis_ingest.log

set "STAGING=%~1"
set "GDB=%~2"
set "QGIS_ROOT=%~3"
if "%QGIS_ROOT%"=="" set "QGIS_ROOT=C:\Program Files\QGIS 4.0.3"

set "LOG=%STAGING%\qgis_ingest.log"
set "OGR2OGR=%QGIS_ROOT%\bin\ogr2ogr.exe"
set "O4W=%QGIS_ROOT%\bin\o4w_env.bat"

echo === QGIS ingest %DATE% %TIME% === > "%LOG%"
echo Staging: %STAGING%>> "%LOG%"
echo Output:  %GDB%>> "%LOG%"
echo QGIS:    %QGIS_ROOT%>> "%LOG%"

if not exist "%O4W%" (
  echo ERROR: o4w_env.bat not found: %O4W%>> "%LOG%"
  exit /b 1
)
if not exist "%OGR2OGR%" (
  echo ERROR: ogr2ogr.exe not found: %OGR2OGR%>> "%LOG%"
  exit /b 1
)

set "NODE=%STAGING%\node.shp"
if not exist "%NODE%" set "NODE=%STAGING%\node.SHP"
set "PIPE=%STAGING%\pipe.shp"
if not exist "%PIPE%" set "PIPE=%STAGING%\pipe.SHP"

if not exist "%NODE%" (
  echo ERROR: node shapefile not found under %STAGING%>> "%LOG%"
  exit /b 1
)
if not exist "%PIPE%" (
  echo ERROR: pipe shapefile not found under %STAGING%>> "%LOG%"
  exit /b 1
)

call "%O4W%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo ERROR: o4w_env.bat failed>> "%LOG%"
  exit /b 1
)

if exist "%GDB%" (
  echo Removing existing geodatabase...>> "%LOG%"
  rmdir /s /q "%GDB%" >> "%LOG%" 2>&1
  if exist "%GDB%" (
    echo ERROR: Could not remove existing GDB - close QGIS/ArcGIS if it is open: %GDB%>> "%LOG%"
    exit /b 1
  )
)

echo Loading Node...>> "%LOG%"
"%OGR2OGR%" -f OpenFileGDB "%GDB%" "%NODE%" -nln Node -overwrite >> "%LOG%" 2>&1
if errorlevel 1 (
  echo ERROR: ogr2ogr Node failed>> "%LOG%"
  exit /b 1
)

echo Loading Pipe...>> "%LOG%"
"%OGR2OGR%" -f OpenFileGDB -update "%GDB%" "%PIPE%" -nln Pipe -overwrite >> "%LOG%" 2>&1
if errorlevel 1 (
  echo ERROR: ogr2ogr Pipe failed>> "%LOG%"
  exit /b 1
)

echo Done: %GDB%>> "%LOG%"
exit /b 0
