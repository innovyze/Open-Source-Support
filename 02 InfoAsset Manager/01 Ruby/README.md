# Ruby in InfoAsset Manager

This directory contains examples of tasks that can be performed using Ruby scripts. These are stored in sub-directories prefixed with a counter and a brief README.md description. They can be either IAM UI scripts or IAMExchange scripts.

## IAM Interface scripts
Scripts with `UI` within the name are run from within the InfoAsset Manager interface. A quick way to get started is:
1. Create a `test.rb` file in a known location, preferably close to the drive root and without special characters in the path.
2. Create an Action which points at the `test.rb` script.
3. Copy paste the code you are testing from GitHub into this file using a plain-text editor.
4. Run it in IAM in a relevant network using: **Network** > **Run Ruby Script...**.

## IExchange scripts
Scripts with `IE` within the name are designed to be run using InfoAsset Exchange.

The Exchange applications are run by running the IExchange program from the command line with suitable arguments. The two required arguments are the script name and the application code.

Relative paths are permitted for the script names but if you are running a script from the current working directory then this follows the convention (inherited from the ‘normal’ Ruby program) of requiring the script name to be preceded by "./".

The application code for InfoAsset Exchange is: `IA` (or `IN`).


e.g. 

`"C:\Program Files\Innovyze Workgroup Client 2021.1\IExchange.exe" "c:\temp\script.rb" IA`

`"C:\Program Files\Innovyze Workgroup Client 2021.1\IExchange.exe" "./script.rb" IA`

`"C:\Program Files\Innovyze Workgroup Client 2021.1\IExchange.exe" "\\server\dir\script.rb" IA`

The command line can be written into a `.bat` file using a text editor, to allow quick running of the referenced script.



## Note
See the README in the top-level of the repository for more information.