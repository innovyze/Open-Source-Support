@echo off
REM One-step Exchange export + QGIS/GDAL File Geodatabase (no ArcGIS Pro).
REM Edit paths below.

set SCRIPT_DIR=%~dp0
set IEXCHANGE="C:\Program Files\Autodesk\InfoAsset Manager 2027\iexchange.exe"

echo === InfoAsset Exchange: shapefile export + QGIS GDB ===
%IEXCHANGE% "%SCRIPT_DIR%IE-odec_export_ex-SHP-for-GDB-sync-QGIS.rb" /ADSKASSET
if errorlevel 1 (
  echo Exchange / QGIS ingest failed.
  exit /b 1
)

echo Done. See OUTPUT_GDB in the IE QGIS Ruby script (default C:\Temp\IAMFullSync.gdb).
exit /b 0
