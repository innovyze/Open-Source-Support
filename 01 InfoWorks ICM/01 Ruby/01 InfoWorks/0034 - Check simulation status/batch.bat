@echo off
SET current_path=%cd%
SET client_path=C:\Program Files (x86)\Innovyze Workgroup Client 10.0
SET ruby_file=create_new_wds_database.rb
ECHO %client_path%\IExchange.exe
ECHO %current_path%\%ruby_file%
"%client_path%\IExchange.exe" "%current_path%\%ruby_file%" ICM
pause