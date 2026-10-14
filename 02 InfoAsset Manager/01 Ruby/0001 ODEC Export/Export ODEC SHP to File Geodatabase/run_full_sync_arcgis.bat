@echo off
REM Run IAM Exchange export then ArcGIS Pro ingest (no Ruby system() call).
REM Edit paths below.

set SCRIPT_DIR=%~dp0
set IEXCHANGE="C:\Program Files\Autodesk\InfoAsset Manager 2027\iexchange.exe"
set PROPY="C:\Program Files\ArcGIS\Pro\bin\Python\Scripts\propy.bat"
set STAGING=%SCRIPT_DIR%staging_shp
set GDB=C:\Temp\IAMFullSync.gdb

echo === InfoAsset Exchange: shapefile staging ===
%IEXCHANGE% "%SCRIPT_DIR%IE-odec_export_ex-SHP-for-GDB-sync-ArcGIS.rb" /ADSKASSET
if errorlevel 1 (
  echo Exchange export failed.
  exit /b 1
)

echo === ArcGIS Pro: new File Geodatabase ===
%PROPY% "%SCRIPT_DIR%ingest_shp_to_file_gdb_arcgis.py" --staging "%STAGING%" --gdb "%GDB%"
if errorlevel 1 (
  echo ArcPy ingest failed.
  exit /b 1
)

echo Done: %GDB%
exit /b 0
