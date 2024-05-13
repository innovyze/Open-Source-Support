@echo off
setlocal enabledelayedexpansion
set "fileCounter=1"
set "lineCounter=0"
set "maxLines=25000"

if exist master_all_!fileCounter!.rb del master_all_!fileCounter!.rb

for /R %%f in (*.rb) do (
    echo Processing "%%f"...
    for /f "delims=" %%i in ('type "%%f" ^| find /c /v ""') do set /a "lines=%%i"
    set /a "lineCounter+=lines+1"
    if !lineCounter! gtr !maxLines! (
        set /a "fileCounter+=1"
        set "lineCounter=lines"
    )
    echo # FILENAME: "%%f" >> master_all_!fileCounter!.rb
    type "%%f" >> master_all_!fileCounter!.rb
    echo. >> master_all_!fileCounter!.rb
)

echo Done.
endlocal
pause
