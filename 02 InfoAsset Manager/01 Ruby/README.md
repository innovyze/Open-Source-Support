# Ruby in InfoAsset Manager

This directory contains examples of tasks that can be performed using Ruby scripts. These are stored in sub-directories prefixed with a counter and a brief README.md description. They can be either IAM UI scripts or IAM Exchange scripts.  
Note, the sub-directory counter is arbitrary and may not be complete as they have been initially derived from an internal datastore.

## IAM Interface scripts
Scripts with `UI` at the start of the filename are run from within the InfoAsset Manager interface. A quick way to get started is:  
1. Create a file with the file-type suffix of `.rb` in a known location on your PC, preferably close to the drive root and without special characters in the path.  
2. Copy paste the code you are testing from GitHub into this file.  
    Ruby (.rb) files can be created/edited in any plain-text editor, such as MS Notepad or Notepad++†, etc.  
3. Run the script in IAM with a relevant network type open from the main menu using: **Network** > **Run Ruby Script...**.  

## IExchange scripts
Scripts with `IE` at the start of the filename are designed to be run using InfoAsset Exchange.  
The Exchange applications are run by running the IExchange program from the command line with suitable arguments. The two required arguments are the script name and the application code.  
Relative paths are permitted for the script names but if you are running a script from the current working directory then this follows the convention (inherited from the 'normal' Ruby program) of requiring the script name to be preceded by "./".  
The application code for InfoAsset Exchange is: `IA` (or `IN`).  


e.g.  
`"C:\Program Files\Innovyze Workgroup Client 2021.1\IExchange.exe" "c:\temp\script.rb" IA`  
`"C:\Program Files\Innovyze Workgroup Client 2021.1\IExchange.exe" "./script.rb" IA`  
`"C:\Program Files\Innovyze Workgroup Client 2021.1\IExchange.exe" "\\server\dir\script.rb" IA`  
The command line can be written into a `.bat` file using a text editor, to allow quick running of the referenced script.  


### UIIE scripts
Some scripts in this repository might have `UIIE` at the start of the filename, these scritps will have syntax to identify if it is being run from the UI, if so will use current network, otherwise will run on the defined network/object.


## Note
See the README in the top-level of the Innovyze/Open-Source-Support repository for more information.  
† Third-party application, this is not an endorsement.  