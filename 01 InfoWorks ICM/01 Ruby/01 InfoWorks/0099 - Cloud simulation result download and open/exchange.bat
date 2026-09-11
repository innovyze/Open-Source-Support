@echo off
setlocal

set "ExchangePath=C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2027\ICMExchange.exe"
set "ScriptDir=%~dp0"

REM Set CLOUD_DB and SIM_ID in the Ruby scripts, or uncomment and pass them below:
REM set "CLOUD_DB=cloud://My Database@orgId/region"
REM set "SIM_ID=19108"

if defined CLOUD_DB (
  if defined SIM_ID (
    "%ExchangePath%" "%ScriptDir%cloud_download.rb" "%CLOUD_DB%" %SIM_ID%
    "%ExchangePath%" "%ScriptDir%cloud_open.rb" "%CLOUD_DB%" %SIM_ID%
  ) else (
    "%ExchangePath%" "%ScriptDir%cloud_download.rb" "%CLOUD_DB%"
    "%ExchangePath%" "%ScriptDir%cloud_open.rb" "%CLOUD_DB%"
  )
) else (
  "%ExchangePath%" "%ScriptDir%cloud_download.rb"
  "%ExchangePath%" "%ScriptDir%cloud_open.rb"
)

pause
