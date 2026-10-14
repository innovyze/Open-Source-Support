@echo off
REM Edit paths below, then run after IAM shapefile export.

set PROPY="C:\Program Files\ArcGIS\Pro\bin\Python\Scripts\propy.bat"
set SCRIPT_DIR=%~dp0
set STAGING=%SCRIPT_DIR%staging_shp
set GDB=C:\Temp\IAMFullSync.gdb

%PROPY% "%SCRIPT_DIR%ingest_shp_to_file_gdb_arcgis.py" --staging "%STAGING%" --gdb "%GDB%"
pause
