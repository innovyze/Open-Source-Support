@echo off
SET "ExchangePath=C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2027\ICMExchange.exe"
SET "RubyScriptPath=%~dp0EX_script.rb"
echo Running Fixed Runoff Surface Audit...
REM Autodesk ICMExchange: script path only (no /ICM product code). Set DATABASE_PATH in EX_script.rb,
REM or pass cloud path as first script arg: "%ExchangePath%" "%RubyScriptPath%" "cloud://Name@orgId/region"
"%ExchangePath%" "%RubyScriptPath%"
pause
