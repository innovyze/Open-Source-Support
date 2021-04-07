@echo off
set version=2021.1
set bit=64
set script=EX_script.rb
if %bit%==32 (set "path=C:\Program Files (x86)")
if %bit%==64 (set "path=C:\Program Files")
"%path%\Innovyze Workgroup Client %version%\IExchange" "%~dp0%script%" ICM
PAUSE
