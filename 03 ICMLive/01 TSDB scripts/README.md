# TSDB scripts
This directory contains examples of scripts that can be triggered by ICMLive ahead of data consumption. This means users can setup the Live system to automatically get data from external sources just in time for a run, or at user defined intervals. ICMLive can pass some arguments to the script to tailor the data request further.

TSDBs can call `bat` files which run off the shelf in Windows OS. This is a scripting language that can be used to get timeseries data or run other processes. 

## Notes
It is common to have a `bat` file activating secondary processes which might be more efficient for particular types of data request. See an example below of a `bat` file which calls a Powershell script from the same folder:
```bat
@echo off
Powershell.exe -File "%~dp0%Get_NOAA.ps1" -WindowStyle Hidden
```

We will preferably post scripts that can run without the need for third party software - such as by using PowerShell. 

In some cases it might be preferable to trigger processes using other freely available scripting software. For example, scriptable FTP software (such as [WinSCP](https://winscp.net/eng/index.php)) is designed specifically for this protocol and often manages transfers more robustly, comes with simpler syntax and enhanced logging capabilities. But this will require installing additional software in the machine consuming the TSDB data.

We will not reference scripts that trigger paid third party software.
