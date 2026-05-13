@echo off
setlocal enabledelayedexpansion
set "fileCounter=1"
set "lineCounter=0"
set "maxLines=25000"

if exist combined_all_!fileCounter!.rb del combined_all_!fileCounter!.rb

for /R %%f in (*.rb) do (
    echo Processing "%%f"...
    for /f "delims=" %%i in ('type "%%f" ^| find /c /v ""') do set /a "lines=%%i"
    set /a "lineCounter+=lines+1"
    if !lineCounter! gtr !maxLines! (
        set /a "fileCounter+=1"
        set "lineCounter=lines"
    )
    echo # FILENAME: "%%f" >> combined_all_!fileCounter!.rb
    type "%%f" >> combined_all_!fileCounter!.rb
    echo. >> combined_all_!fileCounter!.rb
)

echo Done.
endlocal
pause
