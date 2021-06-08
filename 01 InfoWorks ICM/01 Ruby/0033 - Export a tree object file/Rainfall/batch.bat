rem @echo off
set path="C:\Program Files\Innovyze Workgroup Client 10.5"
set script=exchange_test.rb
%path%\IExchange ./%script% ICM
PAUSE