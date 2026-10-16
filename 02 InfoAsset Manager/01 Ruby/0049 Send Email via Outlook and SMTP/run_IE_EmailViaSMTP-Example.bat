@echo off
REM InfoAsset Exchange launcher for IE-EmailViaSMTP-Example.rb
REM Edit IEXCHANGE to match your InfoAsset Manager install version/path.
REM SMTP: copy smtp.env.example.txt to smtp.local.env (gitignored) and set IAM_SMTP_PASSWORD.

set IEXCHANGE="C:\Program Files\Autodesk\InfoAsset Manager 2026\iexchange.exe"
set SCRIPT_DIR=%~dp0

if exist "%SCRIPT_DIR%smtp.local.env" (
  echo Loading SMTP settings from smtp.local.env
  for /f "usebackq eol=# tokens=1,* delims==" %%A in ("%SCRIPT_DIR%smtp.local.env") do (
    if not "%%A"=="" set "%%A=%%B"
  )
) else (
  echo Note: smtp.local.env not found — copy smtp.env.example.txt if you need SMTP send.
)

%IEXCHANGE% "%SCRIPT_DIR%IE-EmailViaSMTP-Example.rb" /ADSKASSET

REM Remove "pause" for Task Scheduler unattended runs.
pause
