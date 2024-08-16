echo off
SET "ExchangePath=C:\Program Files\Autodesk\InfoWorks ICM Ultimate 2025\ICMExchange.exe"
SET "RubyScriptPath=%~dp0main.rb"
SET "ProductCode=/ICM"
echo on
"%ExchangePath%" "%RubyScriptPath%" %ProductCode%
pause