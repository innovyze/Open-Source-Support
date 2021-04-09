# TSDB scripts
TSDBs can trigger `bat` files which run off the shelf on the Windows OS. This is a scripting language that can be used to get timeseries data or run other processes. This directory contains examples of scripts that can be triggered by ICMLive ahead of data consumption. This means users can setup the Live system to automatically get data from external sources just in time for a run, or at user defined intervals. ICMLive can pass some arguments to the script to tailor the data request further.

## Notes
It is common to have a `bat` file activating a secondary process which might be more efficient for a particular type of data request.

We will preferably post scripts that can run off the shelf from Windows without the need for third party software - such as by using PowerShell. 

In some cases it might be preferable to trigger processes using other freely available scripting software. For example, scriptable FTP software (such as [WinSCP](https://winscp.net/eng/index.php)) designed speficifically for this protocal often manages transfers more robustly, comes with simpler syntax and enhanced logging capabilities. But this will require installing third party software in the machine consuming the TSDB data.

We will not reference scripts that trigger paid third party software.