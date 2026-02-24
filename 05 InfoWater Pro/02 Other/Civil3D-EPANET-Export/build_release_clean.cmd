@echo off
setlocal
set "ROOT=%~dp0"
cd /d "%ROOT%"

echo Cleaning bin/obj...
if exist "%ROOT%bin" rmdir /s /q "%ROOT%bin"
if exist "%ROOT%obj" rmdir /s /q "%ROOT%obj"

echo Building Civil3dEpanetExport (release)...
dotnet build -c Release
if errorlevel 1 goto :fail

set "DLL=%ROOT%bin\Release\net8.0-windows\Civil3dEpanetExport.dll"
if not exist "%DLL%" (
  echo Build succeeded but DLL not found at:
  echo %DLL%
  echo Listing Release output:
  dir "%ROOT%bin\Release\net8.0-windows"
  pause
  exit /b 1
)

copy /y "%DLL%" "%ROOT%Civil3dEpanetExport.dll" >nul
echo DLL copied to: %ROOT%Civil3dEpanetExport.dll

echo Cleaning build artifacts...
if exist "%ROOT%bin" rmdir /s /q "%ROOT%bin"
if exist "%ROOT%obj" rmdir /s /q "%ROOT%obj"
pause
exit /b 0

:fail
echo Build failed. Please share the output above.
pause
exit /b 1
